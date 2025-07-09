import 'package:hive/hive.dart';

part 'chat_message.g.dart'; // This line tells build_runner to generate code

@HiveType(typeId: 0)
class ChatMessage extends HiveObject {
  @HiveField(0)
  String role;

  @HiveField(1)
  String text;

  ChatMessage({required this.role, required this.text});
}
