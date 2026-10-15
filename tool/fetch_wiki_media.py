#!/usr/bin/env python3
"""Fetch freely licensed photos and sourced descriptions from Wikipedia/Commons.

For every catalog entry (see tool/dump_catalog.dart) this searches English
Wikipedia and accepts an article only when:
  * the article's coordinates are near the place (food 2 km, sights 12 km,
    destinations 40 km),
  * the article title shares a meaningful word with the place name,
  * no other entry already uses that article, and
  * its lead image lives on Wikimedia Commons under a free licence.

Output: lib/data/mock/wiki_media.dart (generated — do not edit by hand).

Usage:
  dart run tool/dump_catalog.dart > build/catalog.json
  python3 tool/fetch_wiki_media.py build/catalog.json lib/data/mock/wiki_media.dart
"""
import html
import json
import math
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

UA = "TravelExplorerCatalogBuilder/1.0 (offline catalog build script)"
WP = "https://en.wikipedia.org/w/api.php"
COMMONS = "https://commons.wikimedia.org/w/api.php"
STOP = {"the", "of", "and", "a", "at", "in", "on", "de", "la", "point", "area", "beach", "lake", "dam",
        "falls", "temple", "fort", "palace", "village", "museum", "hill", "peak", "view", "viewpoint",
        "national", "park", "valley", "island", "market", "street", "food", "shops", "cafe", "cafes"}
BAD_IMAGE = re.compile(r"(\.svg$|map|locator|logo|flag|seal|emblem|coat_of_arms|icon|diagram)", re.I)
# Articles that are clearly a different kind of thing than a sight/food spot.
BAD_TITLE = re.compile(r"\b(school|college|university|hospital|airport|railway station|constituency|"
                       r"assembly|district court|municipal corporation|cricket|film|novel|album)\b", re.I)
# Exact article titles where search ranks the wrong article first. Still subject
# to the same distance and licence checks.
OVERRIDES = {
    "kodaikanal.kodai-lake": "Kodaikanal Lake",
    "ooty.toy-train": "Nilgiri Mountain Railway",
    "jaipur.amber-fort": "Amer Fort",
    "ubud": "Ubud",
    # No coordinates on the article; identity verified by hand from its intro.
    "udaipur.monsoon-palace": "Monsoon Palace",
}
LIMITS_KM = {"destination": 40, "attraction": 12, "hiddenGem": 12, "foodSpot": 2}


_CACHE_PATH = "build/wiki_cache.json"
try:
    _CACHE = json.load(open(_CACHE_PATH))
except (OSError, ValueError):
    _CACHE = {}
_last = [0.0]


def get(url, params):
    """GET with a disk cache, ~1 req/s throttle and Retry-After-aware backoff."""
    q = url + "?" + urllib.parse.urlencode({**params, "format": "json", "formatversion": 2})
    if q in _CACHE:
        return _CACHE[q]
    req = urllib.request.Request(q, headers={"User-Agent": UA})
    for attempt in range(8):
        wait = 1.0 - (time.time() - _last[0])
        if wait > 0:
            time.sleep(wait)
        _last[0] = time.time()
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                data = json.load(r)
            _CACHE[q] = data
            json.dump(_CACHE, open(_CACHE_PATH, "w"))
            return data
        except urllib.error.HTTPError as e:
            if e.code == 429 or e.code >= 500:
                delay = float(e.headers.get("Retry-After") or 20 * (attempt + 1))
                print(f"    rate limited, waiting {delay:.0f}s", file=sys.stderr)
                time.sleep(delay)
                continue
            raise
        except Exception:  # noqa: BLE001 - transient network error
            time.sleep(5 * (attempt + 1))
    raise RuntimeError(f"giving up on {q}")


def km(a, b):
    r = 6371
    dlat, dlng = math.radians(b[0] - a[0]), math.radians(b[1] - a[1])
    h = math.sin(dlat / 2) ** 2 + math.cos(math.radians(a[0])) * math.cos(math.radians(b[0])) * math.sin(dlng / 2) ** 2
    return 2 * r * math.asin(math.sqrt(h))


def tokens(s):
    return {t for t in re.findall(r"[a-z]+", s.lower()) if t not in STOP and len(t) > 2}


def strip_html(s):
    return html.unescape(re.sub(r"<[^>]+>", "", s or "")).strip()


def sentences(text, n, max_chars):
    parts = re.split(r"(?<=[.!?])\s+(?=[A-Z])", text.strip())
    out = ""
    for p in parts[:n]:
        if len(out) + len(p) > max_chars and out:
            break
        out = (out + " " + p).strip()
    return out


_NOISY_PAREN = re.compile(r"\s*\((?:[^()]*?(?::|;|\[|[^\x00-\u024F]|\bpronounced\b|\blisten\b)[^()]*?|\s*)\)")


def clean_extract(t):
    """Drops pronunciation / native-script / 'Language: …' asides, keeps the rest."""
    prev = None
    while prev != t:  # nested parentheses: strip innermost first
        prev = t
        t = _NOISY_PAREN.sub("", t)
    t = re.sub(r"\s+([,.;])", r"\1", t)
    t = re.sub(r"\s+", " ", t)
    return t.strip()


def _search(query):
    data = get(WP, {
        "action": "query", "generator": "search", "gsrsearch": query, "gsrlimit": 6,
        "prop": "coordinates|pageimages", "piprop": "name", "colimit": "max",
    })
    return sorted(data.get("query", {}).get("pages", []), key=lambda p: p.get("index", 99))


def candidates(item):
    """Override title first, then progressively broader searches."""
    if item["id"] in OVERRIDES:
        data = get(WP, {"action": "query", "titles": OVERRIDES[item["id"]], "redirects": 1,
                        "prop": "coordinates|pageimages", "piprop": "name"})
        yield from data.get("query", {}).get("pages", [])
        return  # explicit title: never fall back to a weaker guess
    name = re.sub(r"\s*\(.*?\)", "", item["name"]).replace("&", "and")
    seen = set()
    for q in (f'{item["name"]} {item["context"] or ""}', name, f"{name} India" if item["id"] not in ("kyoto", "ubud") else name):
        for page in _search(q.strip()):
            if page["title"] not in seen:
                seen.add(page["title"])
                yield page


def commons_image(name):
    data = get(COMMONS, {
        "action": "query", "titles": f"File:{name}", "prop": "imageinfo",
        "iiprop": "url|extmetadata|size", "iiurlwidth": 1280,
    })
    pages = data.get("query", {}).get("pages", [])
    if not pages or "imageinfo" not in pages[0]:
        return None  # not on Commons (likely a local, possibly non-free file)
    info = pages[0]["imageinfo"][0]
    meta = info.get("extmetadata", {})
    lic = strip_html(meta.get("LicenseShortName", {}).get("value", ""))
    nonfree = strip_html(meta.get("NonFree", {}).get("value", "")).lower() == "true"
    if nonfree or not lic or not re.search(r"(cc|public domain|pd|gfdl)", lic, re.I):
        return None
    if info.get("width", 0) < 640:
        return None
    artist = strip_html(meta.get("Artist", {}).get("value", "")) or "Unknown author"
    artist = re.sub(r"\s+", " ", artist)[:80]
    return {
        "url": info.get("thumburl") or info["url"],
        "author": artist,
        "license": lic,
        "source": info.get("descriptionurl", ""),
    }


def article_text(title):
    data = get(WP, {"action": "query", "titles": title, "prop": "extracts|info", "explaintext": 1,
                    "exsectionformat": "wiki", "inprop": "url", "redirects": 1})
    page = data["query"]["pages"][0]
    text = page.get("extract", "")
    intro = clean_extract(text.split("\n==", 1)[0])
    history = ""
    m = re.search(r"\n==\s*(History|Etymology and history|History and legend|Legend)\s*==\n(.*?)(?=\n==[^=]|\Z)", text, re.S)
    if m:
        body = re.sub(r"\n===.*?===\n", "\n", m.group(2))
        history = clean_extract(body)
    return intro, history, page.get("fullurl", f"https://en.wikipedia.org/wiki/{urllib.parse.quote(title)}")


def dart_str(s):
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$").replace("\n", " ") + "'"


def main():
    items = json.load(open(sys.argv[1]))
    out_path = sys.argv[2]
    # Destinations first so their (broad) articles are claimed before places.
    items.sort(key=lambda i: 0 if i["type"] == "destination" else 1)
    used = set()
    used_images = set()  # one photo per entry: no duplicates across the app
    results = {}
    for item in items:
        name_tokens = tokens(item["name"])
        limit = LIMITS_KM[item["type"]]
        chosen = None
        try:
            for page in candidates(item):
                title = page["title"]
                pinned = item["id"] in OVERRIDES
                if title in used or "pageimage" not in page:
                    continue
                if "coordinates" in page:
                    c = page["coordinates"][0]
                    d = km((item["lat"], item["lng"]), (c["lat"], c["lon"]))
                    if d > limit:
                        continue
                elif pinned:
                    d = float("nan")  # explicitly pinned and verified by hand
                else:
                    continue
                if item["id"] not in OVERRIDES and name_tokens and not (name_tokens & tokens(title)):
                    continue
                if BAD_TITLE.search(title):
                    continue
                # Places never share a photo with another place; a destination
                # cover may reuse its headline landmark's photo.
                if BAD_IMAGE.search(page["pageimage"]) or (
                    item["type"] != "destination" and page["pageimage"] in used_images
                ):
                    continue
                img = commons_image(page["pageimage"])
                if not img:
                    continue
                chosen = (title, d, img, page["pageimage"])
                break
        except Exception as e:  # noqa: BLE001
            print(f"  ! {item['id']}: {e}", file=sys.stderr)
        if not chosen:
            print(f"  - {item['id']}: no verified match", file=sys.stderr)
            continue
        title, d, img, _ = chosen
        intro, history, url = article_text(title)
        used.add(title)
        if item["type"] != "destination":
            used_images.add(chosen[3])
        results[item["id"]] = {
            "title": title,
            "url": url,
            "summary": sentences(intro, 4, 650),
            "history": sentences(history, 3, 520),
            **{f"img_{k}": v for k, v in img.items()},
        }
        print(f"  + {item['id']} -> {title} ({d:.1f} km) [{img['license']}]", file=sys.stderr)

    lines = [
        "// GENERATED by tool/fetch_wiki_media.py — do not edit by hand.",
        "// Photos: Wikimedia Commons (licence per entry). Text: Wikipedia, CC BY-SA 4.0.",
        "// ignore_for_file: lines_longer_than_80_chars",
        "",
        "import '../../domain/entities/media.dart';",
        "",
        "const wikiMedia = <String, WikiEntry>{",
    ]
    for key in sorted(results):
        r = results[key]
        lines.append(f"  {dart_str(key)}: WikiEntry(")
        lines.append(f"    photo: RemotePhoto(url: {dart_str(r['img_url'])}, author: {dart_str(r['img_author'])}, "
                     f"license: {dart_str(r['img_license'])}, sourceUrl: {dart_str(r['img_source'])}),")
        lines.append(f"    about: SourcedText(text: {dart_str(r['summary'])}, history: {dart_str(r['history'])}, "
                     f"sourceTitle: {dart_str(r['title'])}, sourceUrl: {dart_str(r['url'])}),")
        lines.append("  ),")
    lines.append("};")
    open(out_path, "w").write("\n".join(lines) + "\n")
    print(f"\n{len(results)}/{len(items)} entries matched -> {out_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
