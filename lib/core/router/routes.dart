/// Route paths in one place so screens never hard-code strings.
abstract final class Routes {
  static const welcome = '/welcome';
  static const countries = '/countries';
  static const home = '/home';
  static const explore = '/explore';
  static const map = '/map';
  static const travels = '/travels';
  static const bucket = '/bucket';
  static const profile = '/profile';

  /// My Travels on a given tab: overview, history, timeline or journal.
  static String travelsTab(String tab) => '$travels?tab=$tab';

  /// Bucket list on a given tab: saved, food or trips.
  static String bucketTab(String tab) => '$bucket?tab=$tab';

  static const search = '/search';
  static const gems = '/gems';
  static const food = '/food';
  static const seasons = '/seasons';
  static const addPlace = '/add-place';
  static const myPlaces = '/my-places';
  static const analytics = '/analytics';
  static const achievements = '/achievements';
  static const settings = '/settings';
  static const notifications = '/notifications';
  static const newTrip = '/trip/new';

  static String region(String id) => '/region/$id';
  static String destination(String id) => '/destination/$id';
  static String place(String id) => '/place/$id';
  static String category(String name) => '/category/$name';
  static String gemsIn({String? destinationId}) => destinationId == null ? gems : '$gems?destination=$destinationId';
  static String foodIn({String? destinationId}) => destinationId == null ? food : '$food?destination=$destinationId';
  static String editPlace(String id) => '$addPlace?edit=$id';
  static String newMemory(String placeId) => '/memory/new?place=$placeId';
  static String memory(String id) => '/memory/$id';
  static String editMemory(String id) => '/memory/$id/edit';
  static String trip(String id) => '/trip/$id';
  static String visitedIn(String destinationId) => '/visited/$destinationId';
}
