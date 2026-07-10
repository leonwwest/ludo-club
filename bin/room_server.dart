import 'dart:io';

import 'package:ludo_club/online/online_room_server.dart';

Future<void> main(List<String> arguments) async {
  final hostValue = Platform.environment['LUDO_ROOM_HOST'] ??
      InternetAddress.loopbackIPv4.address;
  final portValue = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = OnlineRoomServer(
    host: InternetAddress(hostValue),
    port: portValue,
  );
  await server.start();
  stdout.writeln(
    'Ludo Club room server listening on http://$hostValue:${server.boundPort}',
  );

  ProcessSignal.sigint.watch().listen((_) async {
    await server.close();
    exit(0);
  });
}
