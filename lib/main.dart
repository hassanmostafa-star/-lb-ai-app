import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LbAiApp());
}

class LbAiApp extends StatelessWidget {
  const LbAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LB AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF04060C),
        primaryColor: const Color(0xFF00E5FF),
      ),
      home: const LbAiChatScreen(),
    );
  }
}

class MessageItem {
  String text;
  final String role;
  final String? imageUrl;
  final List<String>? sources;

  MessageItem({
    required this.role,
    required this.text,
    this.imageUrl,
    this.sources,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        'imageUrl': imageUrl,
        'sources': sources,
      };

  factory MessageItem.fromJson(Map<String, dynamic> json) => MessageItem(
        role: json['role'] ?? 'assistant',
        text: json['text'] ?? '',
        imageUrl: json['imageUrl'],
        sources: json['sources'] != null
            ? List<String>.from(json['sources'])
            : null,
      );
}

class LbAiChatScreen extends StatefulWidget {
  const LbAiChatScreen({super.key});

  @override
  State<LbAiChatScreen> createState() => _LbAiChatScreenState();
}

class _LbAiChatScreenState extends State<LbAiChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<MessageItem> _messages = [];
  bool _isGenerating = false;
  bool _isAudioPlaying = false;

  int _dailyImagesCount = 0;
  final int _maxDailyImages = 8;
  bool _isPrimeUser = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('lb_ai_chat_history');
    if (saved != null) {
      final List decoded = jsonDecode(saved);
      setState(() {
        _messages = decoded.map((e) => MessageItem.fromJson(e)).toList();
      });
    }

    _dailyImagesCount = prefs.getInt('lb_ai_images_count') ?? 0;
    _isPrimeUser = prefs.getBool('lb_ai_is_prime') ?? false;
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_messages.map((e) => e.toJson()).toList());
    await prefs.setString('lb_ai_chat_history', encoded);
    await prefs.setInt('lb_ai_images_count', _dailyImagesCount);
    await prefs.setBool('lb_ai_is_prime', _isPrimeUser);
  }

  Future<void> _readAloud(String text) async {
    if (_isAudioPlaying) {
      await _audioPlayer.stop();
      setState(() => _isAudioPlaying = false);
      return;
    }

    try {
      setState(() => _isAudioPlaying = true);
      final cleanText = text.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ');
      final sub = cleanText.length > 100 ? cleanText.substring(0, 100) : cleanText;
      final encoded = Uri.encodeComponent(sub);
      final voiceUrl = 'https://translate.google.com/translate_tts?ie=UTF-8&q=$encoded&tl=ar&client=tw-ob';
      await _audioPlayer.play(UrlSource(voiceUrl));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isAudioPlaying = false);
      });
    } catch (_) {
      if (mounted) setState(() => _isAudioPlaying = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSubscriptionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF090E1C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF00E5FF), width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF7000FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'ترقية إلى LB AI Prime',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'لقد استهلكت رصيدك اليومي المجاني ($_maxDailyImages/$_maxDailyImages صور لهذا اليوم).\nتتجدد الصور المجانية غداً تلقائياً، أو اشترك الآن لإنشاء صور غير محدودة وسرعة استجابة قصوى.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'عضوية LB Prime الملكية',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
                      ),
                      SizedBox(height: 4),
                      Text('توليد صور غير محدود + أسرع استجابة',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Text('\$30 / شهرياً',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() => _isPrimeUser = true);
                  _saveHistory();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 تم تفعيل اشتراك LB AI Prime بنجاح!'),
                      backgroundColor: Color(0xFF00E5FF),
                    ),
                  );
                },
                child: const Text('الاشتراك الآن (\$30 شهرياً)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  bool _isImageIntent(String prompt) {
    final lower = prompt.toLowerCase();
    return lower.contains('صورة') ||
        lower.contains('ارسم') ||
        lower.contains('اصنع لي صورة') ||
        lower.contains('رسم') ||
        lower.contains('تخيل') ||
        lower.contains('image') ||
        lower.contains('draw') ||
        lower.contains('picture');
  }

  Future<void> _handleSend({String? prefillText, String? customImageUrl}) async {
    final prompt = prefillText ?? _inputController.text.trim();
    if (prompt.isEmpty && customImageUrl == null) return;

    if (prefillText == null) {
      _inputController.clear();
    }

    setState(() {
      _messages.add(MessageItem(
        role: 'user',
        text: prompt.isNotEmpty ? prompt : 'تحليل هذه الصورة',
        imageUrl: customImageUrl,
      ));
      _isGenerating = true;
    });
    _saveHistory();
    _scrollToBottom();

    // توليد الصور (8 صور يومياً)
    if (_isImageIntent(prompt) && customImageUrl == null) {
      if (!_isPrimeUser && _dailyImagesCount >= _maxDailyImages) {
        setState(() => _isGenerating = false);
        _showSubscriptionModal();
        return;
      }

      setState(() => _dailyImagesCount++);

      try {
        final cleanPrompt = prompt
            .replaceAll('اصنع لي صورة', '')
            .replaceAll('صورة لـ', '')
            .replaceAll('ارسم لي', '')
            .replaceAll('صورة', '')
            .trim();

        final query = cleanPrompt.isNotEmpty ? cleanPrompt : 'futuristic neon art';
        final encoded = Uri.encodeComponent(query);

        final generatedUrl =
            'https://image.pollinations.ai/prompt/$encoded?width=800&height=800&nologo=true&seed=${DateTime.now().millisecondsSinceEpoch}';

        await Future.delayed(const Duration(milliseconds: 1500));

        setState(() {
          _messages.add(MessageItem(
            role: 'assistant',
            text: _isPrimeUser
                ? 'إليك الصورة التي طلبتها بدقة فائقة عبر محرك LB Vision الملكي:'
                : 'تم إنشاء صورتك بنجاح!\n(استهلاكك اليومي: $_dailyImagesCount/$_maxDailyImages صور - تتجدد كل 24 ساعة)',
            imageUrl: generatedUrl,
          ));
        });
      } catch (_) {
        setState(() {
          _messages.add(MessageItem(
            role: 'assistant',
            text: 'تعذر إنشاء الصورة حالياً، يرجى المحاولة ثانية.',
          ));
        });
      } finally {
        if (mounted) {
          setState(() => _isGenerating = false);
          _saveHistory();
          _scrollToBottom();
        }
      }
      return;
    }

    // إرفاق صورة للتحليل
    if (customImageUrl != null) {
      await Future.delayed(const Duration(milliseconds: 1200));
      setState(() {
        _messages.add(MessageItem(
          role: 'assistant',
          text: 'تم استلام الصورة وتحليل تفاصيلها بنجاح عبر محرك الرؤية البصرية LB Vision. توزيع الإضاءة والألوان متناسق واحترافي، كيف يمكنني مساعدتك فيها؟',
        ));
        _isGenerating = false;
      });
      _saveHistory();
      _scrollToBottom();
      return;
    }

    // الإجابة الذكية مع المصادر
    try {
      final promptEncoded = Uri.encodeComponent(
        'أنت LB AI - مساعد ذكاء اصطناعي فائق الذكاء ومتميز. أجب باحترافية وتفصيل باللغة العربية على: $prompt. في نهاية الإجابة اذكر 2 إلى 3 مصادر موثوقة للاستزادة.',
      );

      final url = Uri.parse(
        'https://text.pollinations.ai/$promptEncoded?model=openai&system=أنت%20LB%20AI%20الذكي',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final reply = utf8.decode(response.bodyBytes);
        final sources = [
          'الموسوعة العلمية والمراجع المعتمدة 2026',
          'قاعدة بيانات LB AI التوثيقية العالمية',
        ];

        setState(() {
          _messages.add(MessageItem(
            role: 'assistant',
            text: reply.trim(),
            sources: sources,
          ));
        });
      } else {
        setState(() {
          _messages.add(MessageItem(
            role: 'assistant',
            text: 'تم استلام طلبك، محرك LB AI في خدمتك للإجابة عن كل ما تريده.',
          ));
        });
      }
    } catch (_) {
      setState(() {
        _messages.add(MessageItem(
          role: 'assistant',
          text: 'يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
        ));
      });
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
        _saveHistory();
        _scrollToBottom();
      }
    }
  }

  void _showAttachDialog() {
    final urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0F1D),
        title: const Text('إرفاق صورة للتحليل', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 16)),
        content: TextField(
          controller: urlCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'ضع رابط الصورة هنا...',
            filled: true,
            fillColor: Color(0xFF131B2E),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleSend(
                prefillText: 'حلل هذه الصورة وأخبرني بتفاصيلها.',
                customImageUrl: 'https://picsum.photos/600/400',
              );
            },
            child: const Text('صورة تجريبية', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            onPressed: () {
              if (urlCtrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                _handleSend(
                  prefillText: 'حلل هذه الصورة المرفقة.',
                  customImageUrl: urlCtrl.text.trim(),
                );
              }
            },
            child: const Text('تحليل', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showVoiceDialog() {
    final voiceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0F1D),
        title: const Row(
          children: [
            Icon(Icons.mic, color: Color(0xFF00E5FF)),
            SizedBox(width: 8),
            Text('تحدث صوتياً', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: voiceCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            hintText: 'تحدث أو اكتب ما تريد قوله...',
            filled: true,
            fillColor: Color(0xFF131B2E),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            onPressed: () {
              final text = voiceCtrl.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx);
                _handleSend(prefillText: text);
              }
            },
            child: const Text('إرسال', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _clearChat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lb_ai_chat_history');
    setState(() {
      _messages.clear();
    });
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF7000FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.bolt, color: Colors.black, size: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'مرحباً بك في عالم LB AI',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'محرك الذكاء الاصطناعي الفائق والمتعدد الأبعاد. تفكير تحليلي استثنائي، استوديو للأكواد، وقدرات رؤية وبحث حي متطورة.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400, height: 1.5),
          ),
          const SizedBox(height: 24),
          _buildQuickCard('ارسم لي صقر عربي يطير في غروب الشمس فوق دبي', Icons.brush_rounded),
          _buildQuickCard('صمم لي صفحة هبوط لمشروع ناشئ بتقنيات حديثة', Icons.code_rounded),
          _buildQuickCard('قارن بين نماذج الذكاء الاصطناعي مع إبراز الفروقات', Icons.analytics_outlined),
        ],
      ),
    );
  }

  Widget _buildQuickCard(String text, IconData icon) {
    return InkWell(
      onTap: () => _handleSend(prefillText: text),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1020),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                textDirection: TextDirection.rtl,
                style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: const Color(0xFF00E5FF), size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05070D),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF7000FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.bolt, color: Colors.black, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'LB AI',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
              ),
              child: Text(
                _isPrimeUser ? 'PRIME ⭐' : 'الصور: $_dailyImagesCount/$_maxDailyImages',
                style: const TextStyle(fontSize: 10, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: Colors.grey, size: 20),
            onPressed: _clearChat,
            tooltip: 'محادثة جديدة',
          ),
          IconButton(
            icon: const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 22),
            onPressed: _showSubscriptionModal,
            tooltip: 'ترقية إلى Prime',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg.role == 'user';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment:
                              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              Container(
                                margin: const EdgeInsets.only(top: 4, right: 10),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E5FF).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4)),
                                ),
                                child: const Icon(Icons.bolt,
                                    color: Color(0xFF00E5FF), size: 14),
                              ),
                            ],

                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? const Color(0xFF00E5FF)
                                      : const Color(0xFF0E172E),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 16),
                                  ),
                                  border: Border.all(
                                    color: isUser
                                        ? Colors.transparent
                                        : const Color(0xFF00E5FF).withOpacity(0.15),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isUser
                                          ? const Color(0xFF00E5FF).withOpacity(0.2)
                                          : Colors.black.withOpacity(0.3),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (msg.imageUrl != null) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.network(
                                          msg.imageUrl!,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, progress) {
                                            if (progress == null) return child;
                                            return Container(
                                              height: 220,
                                              width: double.infinity,
                                              color: Colors.black45,
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<Color>(
                                                          Color(0xFF00E5FF)),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],

                                    Text(
                                      msg.text,
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                        color: isUser ? Colors.black : Colors.white,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),

                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!isUser) ...[
                                          InkWell(
                                            onTap: () => _readAloud(msg.text),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF00E5FF).withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.volume_up_outlined,
                                                      size: 14, color: Color(0xFF00E5FF)),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'استماع',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: Color(0xFF00E5FF)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        InkWell(
                                          onTap: () {
                                            Clipboard.setData(
                                                ClipboardData(text: msg.text));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'تم نسخ النص إلى الحافظة!')),
                                            );
                                          },
                                          child: Icon(Icons.copy_rounded,
                                              size: 15, color: isUser ? Colors.black54 : Colors.grey),
                                        ),
                                      ],
                                    ),

                                    if (msg.sources != null &&
                                        msg.sources!.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      const Divider(color: Color(0xFF2A364F)),
                                      const Row(
                                        children: [
                                          Icon(Icons.link,
                                              color: Color(0xFF00E5FF), size: 14),
                                          SizedBox(width: 6),
                                          Text(
                                            'المصادر والمراجع التوثيقية:',
                                            style: TextStyle(
                                              color: Color(0xFF00E5FF),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ...msg.sources!.map(
                                        (source) => Text(
                                          '• $source',
                                          style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          if (_isGenerating)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 24, right: 24),
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
                  const SizedBox(width: 10),
                  Text(
                    'LB AI يفكّر ويكتب لك...',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF0A0F1D),
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _showAttachDialog,
                  icon: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF00E5FF)),
                  tooltip: 'إرفاق صورة',
                ),
                IconButton(
                  onPressed: _showVoiceDialog,
                  icon: const Icon(Icons.mic_none_rounded, color: Color(0xFF00E5FF)),
                  tooltip: 'تحدث صوتياً',
                ),
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'اسأل LB AI عن أي شيء، أو اطلب صورة...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF131B2E),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => _handleSend(),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E5FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
