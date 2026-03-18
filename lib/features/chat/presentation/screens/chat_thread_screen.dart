import 'package:flutter/material.dart';
class ChatThreadScreen extends StatelessWidget {
  final String chatId;
  const ChatThreadScreen({super.key, required this.chatId});
  @override Widget build(BuildContext c) => Scaffold(appBar: AppBar(title: Text('Chat $chatId')), body: const Center(child: Text('Chat — coming in V2')));
}
