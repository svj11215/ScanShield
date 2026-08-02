import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';
import '../utils/text_styles.dart';
import 'chat_message.dart';
import 'chat_service.dart';

class ChatbotScreen extends StatefulWidget {
  final List<ChatMessage>? initialMessages;
  final String? reportContext;
  final String? reportFileName;

  const ChatbotScreen({
    super.key,
    this.initialMessages,
    this.reportContext,
    this.reportFileName,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with SingleTickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  bool _isTyping = false;
  late AnimationController _dotController;

  final List<String> _suggestions = [
    '🔍 How does scanning work?',
    '🛡️ What is a risk score?',
    '📱 What are dangerous permissions?',
    '⚠️ Explain OTP theft',
    '📄 Can PDFs contain malware?',
  ];

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    if (widget.initialMessages != null) {
      _messages.addAll(widget.initialMessages!);
    } else if (widget.reportContext != null && widget.reportFileName != null) {
      _messages.add(ChatMessage.assistant(
        '👋 Hi! I analyzed your report for **${widget.reportFileName}**. Ask me anything about it — permissions, risks, or what to do next!',
      ));
    }
  }

  @override
  void dispose() {
    _dotController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage.user(text.trim()));
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(
        _messages,
        reportContext: widget.reportContext,
      );
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage.assistant(response));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage.assistant(
            '❌ Something went wrong. Please try again.',
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      if (widget.reportContext != null && widget.reportFileName != null) {
        _messages.add(ChatMessage.assistant(
          '👋 Hi! I analyzed your report for **${widget.reportFileName}**. Ask me anything about it — permissions, risks, or what to do next!',
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ShieldBot 🛡️',
                  style: AppTextStyles.titleMedium,
                ),
                Text(
                  _isTyping ? 'Typing...' : 'Online',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _isTyping ? AppColors.primary : AppColors.textTertiary,
                    fontWeight: _isTyping ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary),
            tooltip: 'Clear Chat',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? _buildEmptyState() : _buildMessageList(),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceTint,
              border: Border.all(color: AppColors.primary.withAlpha(30)),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'ShieldBot 🛡️',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Your AI cybersecurity assistant.\nAsk me anything about app security,\npermissions, or scan results!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _suggestions.map((s) {
              return ActionChip(
                label: Text(
                  s,
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: AppColors.surfaceTint,
                side: const BorderSide(color: AppColors.border),
                onPressed: () => _sendMessage(s),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg.role == 'user';
        return _buildMessageBubble(msg.content, isUser);
      },
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: _buildFormattedText(content, isUser),
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isUser) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    final baseColor = isUser ? AppColors.textOnPrimary : AppColors.textPrimary;
    final boldColor = isUser ? AppColors.textOnPrimary : AppColors.primary;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: GoogleFonts.inter(
            color: baseColor,
            fontSize: 14,
            height: 1.45,
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: GoogleFonts.inter(
          color: boldColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          height: 1.45,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: GoogleFonts.inter(
          color: baseColor,
          fontSize: 14,
          height: 1.45,
        ),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (context, _) {
        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final offset = (_dotController.value + i * 0.3) % 1.0;
                final opacity = 0.3 + (0.7 * (1 - (offset - 0.5).abs() * 2).clamp(0.0, 1.0));
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withAlpha((255 * opacity).toInt()),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) => _sendMessage(text),
                decoration: InputDecoration(
                  hintText: 'Ask ShieldBot anything...',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _sendMessage(_textController.text),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
              ),
              icon: const Icon(Icons.send_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
