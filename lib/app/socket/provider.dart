import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final socketProvider = Provider<WebSocketChannel>((ref) {
  final channel = WebSocketChannel.connect(
    Uri.parse("wss://api.bia.com.ng"),
  );

  ref.onDispose(() {
    channel.sink.close();
  });

  return channel;
});