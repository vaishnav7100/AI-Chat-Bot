import 'package:ai_chat/screens/chatpage.dart';
import 'package:ai_chat/models/chat_message.dart';
import 'package:ai_chat/providers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ChatMessageAdapter());
  await Hive.openBox<ChatMessage>('chat_messages');
  runApp(
    ChangeNotifierProvider(create: (_) => ThemeManager(), child: const MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          themeMode: themeManager.themeMode,
          theme: ThemeData.light().copyWith(
            textTheme: ThemeData.light().textTheme.apply(
              fontFamily: 'Urbanist',
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            textTheme: ThemeData().textTheme.apply(fontFamily: 'Urbanist'),
          ),
          home: ChatPage(),
        );
      },
    );
  }
}
