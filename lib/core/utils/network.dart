import 'package:connectivity_plus/connectivity_plus.dart';

bool networkFrom(List<ConnectivityResult> results) {
  return results.any((result) => result != ConnectivityResult.none);
}

Future<bool> hasNetwork() async {
  return networkFrom(await Connectivity().checkConnectivity());
}

Stream<bool> watchNetwork() async* {
  yield await hasNetwork();
  yield* Connectivity().onConnectivityChanged.map(networkFrom);
}
