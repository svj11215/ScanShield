import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';
import '../utils/text_styles.dart';
import 'chat_message.dart';
import 'chat_service.dart';
import 'chatbot_screen.dart';

/// Singleton to hold the chatbot's position and conversation state
/// across different screens (Home, Report, etc.)
class ChatbotPositionController {
  static final ChatbotPositionController _instance = ChatbotPositionController._internal();
  factory ChatbotPositionController() => _instance;
  ChatbotPositionController._internal();

  Offset? position;
  List<ChatMessage> messages = [];
  
  void clearMessages() {
    messages.clear();
  }
}

class DraggableChatbotOverlay extends StatefulWidget {
  final String? reportContext;
  final String? reportFileName;

  const DraggableChatbotOverlay({
    super.key,
    this.reportContext,
    this.reportFileName,
  });

  @override
  State<DraggableChatbotOverlay> createState() => _DraggableChatbotOverlayState();
}

class _DraggableChatbotOverlayState extends State<DraggableChatbotOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Dragging state
  bool _isDragging = false;
  Offset? _dragStartPosition;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Add proactive greeting if there's a new report context
    if (widget.reportContext != null && widget.reportFileName != null) {
      final greetingMsg = '👋 Hi! I analyzed your report for **${widget.reportFileName}**. Ask me anything about it — permissions, risks, or what to do next!';
      final state = ChatbotPositionController();
      if (!state.messages.any((m) => m.content == greetingMsg)) {
        state.messages.add(ChatMessage.assistant(greetingMsg));
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final size = MediaQuery.of(context).size;
      // Default position: bottom right, above nav bar
      final defaultPosition = Offset(size.width - 60 - 20, size.height - 90 - 60);
      ChatbotPositionController().position ??= defaultPosition;
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartPosition = details.globalPosition;
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      ChatbotPositionController().position = 
          ChatbotPositionController().position! + details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    const bubbleSize = 60.0;
    
    // Check distance to distinguish tap vs drag
    if (_dragStartPosition != null) {
      final distance = (details.globalPosition - _dragStartPosition!).distance;
      if (distance < 10) {
        // It's a tap -> Open Chatbot Bottom Sheet (fixes keyboard layout issues)
        setState(() {
          _isDragging = false;
        });
        _openChatBottomSheet();
        return;
      }
    }

    Offset currentPos = ChatbotPositionController().position!;
    
    // Clamp Y to safe area and bottom nav buffer (approx 90)
    double newY = currentPos.dy.clamp(
      padding.top,
      size.height - 90 - bubbleSize,
    );

    // Snap to nearest edge (X)
    double newX = currentPos.dx;
    if (currentPos.dx + (bubbleSize / 2) < size.width / 2) {
      newX = 16.0; // Snap to left
    } else {
      newX = size.width - bubbleSize - 16.0; // Snap to right
    }

    setState(() {
      ChatbotPositionController().position = Offset(newX, newY);
      _isDragging = false;
    });
  }

  void _openChatBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ChatBottomSheetContent(
          reportContext: widget.reportContext,
          reportFileName: widget.reportFileName,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    // Hide bubble if keyboard is open
    if (keyboardHeight > 0) {
      return const SizedBox.shrink();
    }

    // Re-clamp position on build to handle orientation/resize
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    const bubbleSize = 60.0;
    
    if (!_isDragging && _isInitialized) {
      Offset pos = ChatbotPositionController().position!;
      double newY = pos.dy.clamp(padding.top, size.height - 90 - bubbleSize);
      double newX = pos.dx.clamp(0.0, size.width - bubbleSize);
      if (newY != pos.dy || newX != pos.dx) {
        Future.microtask(() {
          if (mounted) {
            setState(() {
              ChatbotPositionController().position = Offset(newX, newY);
            });
          }
        });
      }
    }

    final pos = ChatbotPositionController().position!;

    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: RepaintBoundary(
          child: _buildFloatingBubble(),
        ),
      ),
    );
  }

  Widget _buildFloatingBubble() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final baseScale = _isDragging ? 1.1 : 1.0;
        final pulseScale = _isDragging ? 0.0 : (_pulseAnimation.value * 0.04);
        final scale = baseScale + pulseScale;
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(_isDragging ? 120 : 70),
                  blurRadius: _isDragging ? 20 : 14,
                  spreadRadius: _isDragging ? 4 : 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Light-Themed Chat Bottom Sheet Content
// ─────────────────────────────────────────────

class _ChatBottomSheetContent extends StatefulWidget {
  final String? reportContext;
  final String? reportFileName;

  const _ChatBottomSheetContent({
    this.reportContext,
    this.reportFileName,
  });

  @override
  State<_ChatBottomSheetContent> createState() => _ChatBottomSheetContentState();
}

class _ChatBottomSheetContentState extends State<_ChatBottomSheetContent>
    with SingleTickerProviderStateMixin {
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

    // Scroll to bottom on open
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
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
    
    final state = ChatbotPositionController();

    setState(() {
      state.messages.add(ChatMessage.user(text.trim()));
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(
        state.messages,
        reportContext: widget.reportContext,
      );
      if (mounted) {
        setState(() {
          state.messages.add(ChatMessage.assistant(response));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          state.messages.add(ChatMessage.assistant(
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
      ChatbotPositionController().clearMessages();
      if (widget.reportContext != null && widget.reportFileName != null) {
        ChatbotPositionController().messages.add(ChatMessage.assistant(
          '👋 Hi! I analyzed your report for **${widget.reportFileName}**. Ask me anything about it — permissions, risks, or what to do next!',
        ));
      }
    });
  }

  void _openFullScreen() {
    Navigator.pop(context); // Close bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatbotScreen(
          initialMessages: List.from(ChatbotPositionController().messages),
          reportContext: widget.reportContext,
          reportFileName: widget.reportFileName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height * 0.78;

    return Container(
      height: height,
      margin: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  ),
                  child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ShieldBot 🛡️',
                        style: AppTextStyles.titleMedium,
                      ),
                      Text(
                        'AI Security Assistant',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 20),
                  tooltip: 'Clear Chat',
                  onPressed: _clearChat,
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_full_rounded, color: AppColors.textSecondary, size: 20),
                  tooltip: 'Full Screen',
                  onPressed: _openFullScreen,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: _buildMessageList(),
          ),

          if (_isTyping) _buildTypingIndicator(),

          // Input Bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final messages = ChatbotPositionController().messages;
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isUser = msg.role == 'user';
        return _buildMessageBubble(msg.content, isUser);
      },
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceTint,
              border: Border.all(color: AppColors.primary.withAlpha(30)),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            'ShieldBot 🛡️',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Your AI cybersecurity assistant.\nAsk me anything about security!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _suggestions.map((s) => _buildSuggestionChip(s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(
        text,
        style: GoogleFonts.inter(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: AppColors.surfaceTint,
      side: const BorderSide(color: AppColors.border),
      onPressed: () => _sendMessage(text),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(color: AppColors.border, width: 1),
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
            fontSize: 13.5,
            height: 1.4,
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: GoogleFonts.inter(
          color: boldColor,
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: GoogleFonts.inter(
          color: baseColor,
          fontSize: 13.5,
          height: 1.4,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
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
                  width: 7,
                  height: 7,
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
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) => _sendMessage(text),
                decoration: InputDecoration(
                  hintText: 'Ask ShieldBot...',
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
              icon: const Icon(Icons.send_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
