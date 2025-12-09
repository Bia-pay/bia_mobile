import 'dart:convert';
import 'package:bia/app/socket/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSocketListener extends ConsumerWidget {
  final Widget child;
  const AppSocketListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socket = ref.watch(socketProvider);

    return StreamBuilder(
      stream: socket.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          print("📥 WebSocket message: ${snapshot.data}");

          try {
            final json = jsonDecode(snapshot.data);

            /// 🔥 Handle events globally
            switch (json["event"]) {
              case "deposit_success":
                _showDepositNotification(context, json);
                break;

              case "transfer_received":
                _showTransferNotification(context, json);
                break;
            }
          } catch (_) {}
        }

        return child; // Continue app rendering
      },
    );
  }

  void _showDepositNotification(BuildContext context, Map data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Deposit of ₦${data['amount']} completed"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showTransferNotification(BuildContext context, Map data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("You received ₦${data['amount']} from ${data['sender']}"),
        backgroundColor: Colors.blue,
      ),
    );
  }
}