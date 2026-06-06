import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/gemini_config.dart';
import '../controllers/ai_chat_controller.dart';
import '../models/chat_session.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AiChatController _controller;

  final List<String> _suggestions = [
    "Mending ambil matkul apaan ya buat perbaikan IPK?",
    "Cara ngajuin judul skripsi ke dosen PA gimana?",
    "Syarat minimal SKS buat lulus Universitas Mataram berapa?",
  ];

  @override
  void initState() {
    super.initState();
    _controller = AiChatController();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    await _controller.sendMessage(text);
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Riwayat?"),
        content: const Text("Apakah kamu yakin ingin menghapus percakapan ini secara permanen?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String initial = user?.displayName?.isNotEmpty == true
        ? user!.displayName![0].toUpperCase()
        : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : 'U');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF2D3142)),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Riwayat Chat',
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2B5CFA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF2B5CFA), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              "Tanya AI Gradventure",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded, color: Color(0xFF2B5CFA)),
            onPressed: () {
              _controller.startNewChat();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Sesi chat baru dimulai 🆕"),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Chat Baru',
          ),
        ],
      ),

      // --- HISTORY DRAWER ---
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2B5CFA), Color(0xFF4C7BFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Gradventure AI",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Asisten Akademik Pintarmu 🎓",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            // New Chat Button inside Drawer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  _controller.startNewChat();
                  Navigator.pop(context); // Close drawer
                },
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text("Mulai Percakapan Baru", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B5CFA),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(),
            ),

            // History Label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Text(
                    "Riwayat Percakapan",
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),

            // History List
            Expanded(
              child: StreamBuilder<List<AiChatSession>>(
                stream: _controller.getSessionsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFA)));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        "Belum ada riwayat chat",
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                    );
                  }

                  final sessions = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final isSelected = session.id == _controller.currentSessionId;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2B5CFA).withOpacity(0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          leading: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: isSelected ? const Color(0xFF2B5CFA) : Colors.grey.shade600,
                            size: 18,
                          ),
                          title: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF2B5CFA) : const Color(0xFF2D3142),
                              fontSize: 13,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent.withOpacity(0.7)),
                            onPressed: () async {
                              final confirm = await _showDeleteConfirmDialog(context);
                              if (confirm == true) {
                                await _controller.deleteSession(session.id);
                              }
                            },
                          ),
                          onTap: () async {
                            Navigator.pop(context); // close drawer
                            await _controller.loadSession(session.id);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // --- BODY ---
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _controller.messages.isEmpty
                  ? _buildWelcomeScreen()
                  : _buildChatList(initial),
            ),

            // Visual Loading / Typing Indicator
            if (_controller.isLoading) _buildTypingIndicator(),

            // Input Area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // Welcome / Suggestion Screen
  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Large Animated/Styled robot icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2B5CFA).withOpacity(0.08),
                  blurRadius: 24,
                  spreadRadius: 4,
                )
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 64, color: Color(0xFF2B5CFA)),
          ),
          const SizedBox(height: 24),
          const Text(
            "Halo! Mau tanya apa hari ini? 👋",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Tanya apa saja seputar akademik, KRS, strategi SKS, dosen PA, atau kehidupan kampus Universitas Mataram.",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFF2B5CFA)),
                const SizedBox(width: 8),
                Text(
                  "Pertanyaan Rekomendasi",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Render Suggestions Cards
          ..._suggestions.map((suggestion) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  _textController.text = suggestion;
                  _handleSendMessage();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          suggestion,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2D3142),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF2B5CFA)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Messages Chat List
  Widget _buildChatList(String initial) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
      itemCount: _controller.messages.length,
      itemBuilder: (context, index) {
        final message = _controller.messages[index];
        final isUser = message.role == 'user';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              bottom: 16,
              left: isUser ? 60 : 0,
              right: isUser ? 0 : 60,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  // AI Avatar
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B5CFA).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF2B5CFA), size: 18),
                  ),
                ],
                
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF2B5CFA) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                      ),
                      border: isUser ? null : Border.all(color: Colors.grey.shade200),
                      boxShadow: isUser
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : const Color(0xFF2D3142),
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                if (isUser) ...[
                  // User Avatar
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: const Color(0xFF2B5CFA).withOpacity(0.1),
                      child: Text(
                        initial,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2B5CFA)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Typing/Loading Indicator Widget
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 20, right: 80),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2B5CFA).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF2B5CFA), size: 18),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "AI sedang berpikir",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  _AnimatedDots(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Message Input Bar
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Ketik pesan ke AI...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF4F6F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: const Color(0xFF2B5CFA),
            radius: 24,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _handleSendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

// Staggered dots animation for typing indicator
class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double animVal = _controller.value;
            double opacity = 0.2;
            if (index == 0 && animVal < 0.33) opacity = 1.0;
            if (index == 1 && animVal >= 0.33 && animVal < 0.66) opacity = 1.0;
            if (index == 2 && animVal >= 0.66) opacity = 1.0;
            return Opacity(
              opacity: opacity,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFF2B5CFA),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}