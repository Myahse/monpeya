class AppStackRoute {
  static const main = 'Main';
  static const billetterieTransport = 'BilletterieTransport';
  static const billetterieEvent = 'BilletterieEvent';

  /// @Deprecated('Use billetterieTransport')
  static const billetterie = billetterieTransport;

  static const leadwayAssurance = 'LeadwayAssurance';
  static const simAssurance = 'SimAssurance';
  static const mrImmoRental = 'MrImmoRental';
  static const mrImmoConstruction = 'MrImmoConstruction';
  static const mrImmoCollection = 'MrImmoCollection';
  static const monGrenier = 'MonGrenier';
  static const serviceModule = 'ServiceModule';
  static const webModule = 'WebModule';

  static bool isModuleRoute(String name) => name != main;
}

class AppStackItem {
  AppStackItem({required this.id, required this.name, required this.params});
  final String id;
  final String name;
  final Map<String, Object?> params;
}

class AppStackState {
  const AppStackState({required this.stack, required this.menuVisible});
  final List<AppStackItem> stack;
  final bool menuVisible;

  AppStackItem get current => stack.isNotEmpty
      ? stack.last
      : AppStackItem(id: 'main-0', name: AppStackRoute.main, params: const {});
}

