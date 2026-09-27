import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const LbAiSuperEngineApp());
}

class LbAiSuperEngineApp extends StatelessWidget {
  const LbAiSuperEngineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LB AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF04060C),
        primaryColor: const Color(0xFF00E5FF),
      ),
      home: const LbAiHomeScreen(),
    );
  }
}

class LbAiHomeScreen extends StatefulWidget {
  const LbAiHomeScreen({super.key});

  @override
  State<LbAiHomeScreen> createState() => _LbAiHomeScreenState();
}

class _LbAiHomeScreenState extends State<LbAiHomeScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text': 'أهلاً بك! أنا LB AI، محرك الذكاء الفائق المستقل. تفضل بسؤالي عن أي موضوع، مقال، برمجة، أو استفسار وسأجيبك فوراً.'
    }
  ];
  bool _isTyping = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final userText = _msgController.text.trim();
    if (userText.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': userText});
      _isTyping = true;
      _msgController.clear();
    });
    _scrollToBottom();

    try {
      // الاتصال بسيرفر الذكاء الاصطناعي الحقيقي المباشر بدون قيود
      final encodedPrompt = Uri.encodeComponent(
        'أنت LB AI - مساعد ذكاء اصطناعي فائق الذكاء ومتميز. أجب بتفصيل ودقة وبأسلوب راقٍ باللغة العربية على هذا الطلب: $userText',
      );

      final url = Uri.parse(
        'https://text.pollinations.ai/$encodedPrompt?model=openai&system=أنت%20LB%20AI%20الذكي',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final reply = utf8.decode(response.bodyBytes);
        setState(() {
          _messages.add({
            'role': 'assistant',
            'text': reply.isNotEmpty ? reply.trim() : 'تمت معالجة طلبك بنجاح بواسطة LB AI.',
          });
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'text': 'حدث تأخير في استجابة الخادم السحابي، يرجى إعادة إرسال السؤال مرة أخرى.',
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': 'عذراً، يرجى التأكد من اتصال الإنترنت والمحاولة ثانية.',
        });
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF7000FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.bolt, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LB AI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Autonomous Super-Engine',
                  style: TextStyle(fontSize: 11, color: Color(0xFF00E5FF)),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF00E5FF) : const Color(0xFF131B2E),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isUser
                              ? const Color(0xFF00E5FF).withOpacity(0.2)
                              : Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      msg['text']!,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: isUser ? Colors.black : Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 20, right: 20),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LB AI يفكّر ويكتب الإجابة الآن...',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF0A0F1D),
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white),
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'اسأل LB AI أي سؤال...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF131B2E),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF00E5FF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
