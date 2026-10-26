import 'package:flutter/foundation.dart';

/// Velocidad de actualización de los datos en vivo.
enum LiveSpeed {
  fast('Rápida', 2),
  normal('Normal', 4),
  slow('Lenta', 8);

  const LiveSpeed(this.label, this.seconds);

  final String label;
  final int seconds;
}

/// Preferencias de la sesión. Viven en memoria: no se persisten todavía.
class SettingsStore extends ChangeNotifier {
  bool reduceMotion = false;
  bool liveUpdates = true;
  LiveSpeed speed = LiveSpeed.normal;
  bool notifyDeals = true;
  bool notifyTasks = true;
  bool notifyInvoices = false;

  void setReduceMotion(bool value) => _set(() => reduceMotion = value);
  void setLiveUpdates(bool value) => _set(() => liveUpdates = value);
  void setSpeed(LiveSpeed value) => _set(() => speed = value);
  void setNotifyDeals(bool value) => _set(() => notifyDeals = value);
  void setNotifyTasks(bool value) => _set(() => notifyTasks = value);
  void setNotifyInvoices(bool value) => _set(() => notifyInvoices = value);

  void _set(VoidCallback change) {
    change();
    notifyListeners();
  }
}
