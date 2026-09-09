enum AdminDestination {
  dashboard('/(admin)/dashboard'),
  dos('/(admin)/dos'),
  fiveS('/(admin)/five-s'),
  reports('/(admin)/reports'),
  users('/(admin)/users'),
  notifications('/(admin)/notifications'),
  profile('/(admin)/profile'),
  settings('/(admin)/settings');

  const AdminDestination(this.route);

  final String route;

  static AdminDestination? fromPath(String path) {
    for (final destination in values) {
      if (destination.route == path) return destination;
    }
    return null;
  }
}

typedef AdminNavigationCallback = void Function(AdminDestination destination);
