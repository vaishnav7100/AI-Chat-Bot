import 'package:ai_chat/services/deepseek_api.dart';
import 'package:ai_chat/models/chat_message.dart';
import 'package:ai_chat/providers/theme_manager.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  late Box _chatBox;
  List<ChatMessage> _messages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      _chatBox = await Hive.openBox<ChatMessage>('chat_messages');
      setState(() {
        _messages = _chatBox.values.cast<ChatMessage>().toList();
      });
    });
    if (_messages.isNotEmpty &&
        _messages.last.text.contains("Infrastructure is at maximum capacity")) {
      _chatBox.deleteAt(_messages.length - 1);
      _messages.removeLast();
    }
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
        if (scaffoldMessenger != null) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                'For best experience, please open this app on a mobile device',
                style: TextStyle(color: Colors.white, fontFamily: 'Urbanist'),
              ),
              backgroundColor: Colors.black87,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  void handleSend() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;
    final userMessage = ChatMessage(role: 'user', text: input);
    setState(() {
      _messages.add(userMessage);
      isLoading = true;
    });
    await _chatBox.add(userMessage);

    _controller.clear();
    try {
      final response = await sendMessageToBackend(input);
      final botMessage = ChatMessage(role: 'bot', text: response);
      setState(() {
        _messages.add(botMessage);
      });
      await _chatBox.add(botMessage);
    } catch (e) {
      final errorMessage = ChatMessage(role: 'bot', text: 'Error: $e');
      // await _chatBox.add(errorMessage);
      setState(() {
        _messages.add(errorMessage);
      });
      await _chatBox.add(errorMessage);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E2A38)
        : Color.fromARGB(230, 25, 70, 170);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade900
          : Colors.white,
      appBar: AppBar(
        toolbarHeight: 65,
        shadowColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white10
            : Colors.black45,
        elevation: 2,
        backgroundColor: color,
        title: Text("AI Chat Bot"),
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Urbanist',
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.white,
          fontSize: 22,
        ),
        leading: IconButton(
          onPressed: () {
            Provider.of<ThemeManager>(context, listen: false).toggleTheme();
          },
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? RemixIcons.sun_line
                : RemixIcons.moon_line,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.white,
          ),
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 28,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.white,
              ),
              tooltip: "Clear Chat",
              onPressed: () async {
                final confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.white,
                    title: Text("Clear Chat"),
                    titleTextStyle: TextStyle(
                      fontFamily: 'Urbanist',
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[200]
                          : Colors.black,
                      fontSize: 20,
                    ),
                    content: Text("Are you sure you want to delete all chats?"),
                    contentTextStyle: TextStyle(
                      fontFamily: 'Urbanist',
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[200]
                          : Colors.black,
                      fontSize: 17,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[200]
                                : color,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          "Clear",
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[200]
                                : color,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _chatBox.clear();
                  setState(() {
                    _messages.clear();
                  });
                }
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: DefaultTextStyle(
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.6,
                            fontSize: 18,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[900],
                          ),
                          child: AnimatedTextKit(
                            isRepeatingAnimation: false,
                            totalRepeatCount: 1,
                            animatedTexts: [
                              TypewriterAnimatedText(
                                'Hi, How can i help you today?',
                                speed: Duration(milliseconds: 80),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        itemCount: _messages.length + (isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (isLoading && index == _messages.length) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromARGB(20, 0, 0, 0),
                                      offset: Offset(0, 4),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[800]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Lottie.asset(
                                  'assets/loading_dot1.json',
                                  width: 75,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          }
                          final msg = _messages[index];
                          final isUser = msg.role == 'user';
                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: isUser
                                  ? EdgeInsets.only(
                                      top: 5,
                                      bottom: 5,
                                      left:
                                          MediaQuery.of(context).size.width *
                                          0.15,
                                      right: 2,
                                    )
                                  : EdgeInsets.symmetric(
                                      vertical: 5,
                                      horizontal: 2,
                                    ),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Color.fromARGB(20, 0, 0, 0)
                                        : const Color.fromARGB(50, 0, 0, 0),
                                    offset: Offset(0, 4),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                                color: isUser
                                    ? Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey[800]
                                          : Colors.black45
                                    : color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: isUser
                                  ? Text(
                                      msg.text,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    )
                                  : GptMarkdown(
                                      msg.text,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        cursorColor: color,
                        cursorWidth: 1.5,
                        cursorHeight: 25,
                        controller: _controller,
                        onSubmitted: (_) => handleSend(),
                        textInputAction: TextInputAction.send,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[700],
                        ),
                        onTapOutside: (event) {
                          FocusManager.instance.primaryFocus!.unfocus();
                        },
                        decoration: InputDecoration(
                          hintText: "Type your message...",
                          hintStyle: TextStyle(
                            fontFamily: 'Urbanist',
                            fontWeight: FontWeight.w600,

                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[300],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16.6,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: handleSend,
                        tooltip: "Send",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
