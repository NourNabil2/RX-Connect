import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharmacist_assistant/features/chat/presentation/cubit/chat_provider.dart';

// ─────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────
const _kTeal = Color(0xFF0F6E56);
const _kTealDark = Color(0xFF085041);
const _kBg = Color(0xFFF5F6FA);
const _kBubbleOther = Color(0xFFF0F0F3);
const _kDangerRed = Color(0xFFD32F2F);
const _kWarningOrange = Color(0xFFF57C00);

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String currentUserId;
  final String currentUserRole;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.otherUserName,
    required this.currentUserId,
    required this.currentUserRole,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Send Message ───
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendMessage(
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      senderRole: widget.currentUserRole,
      text: text,
      type: 'text',
    );

    _messageController.clear();
    _focusNode.requestFocus();
  }

  // ─── Format timestamp ───
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return '';
    }
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // ─── Severity helpers ───
  Color _severityColor(String severity) {
    switch (severity) {
      case 'خطير':
        return _kDangerRed;
      case 'متوسط':
        return _kWarningOrange;
      case 'بسيط':
        return const Color(0xFF388E3C);
      default:
        return Colors.grey;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'خطير':
        return Icons.dangerous_rounded;
      case 'متوسط':
        return Icons.warning_amber_rounded;
      case 'بسيط':
        return Icons.info_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(child: _buildMessageList()),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  APP BAR
  // ═══════════════════════════════════════════
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kTeal, _kTealDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded, size: 22.r, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // ─ Avatar ─
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: Center(
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0] : '?',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // ─ Name + online ─
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4CAF50),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'متصل',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  MESSAGE LIST
  // ═══════════════════════════════════════════
  Widget _buildMessageList() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    return StreamBuilder<QuerySnapshot>(
      stream: chatProvider.getMessages(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _kTeal),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyChat();
        }

        final messages = snapshot.data!.docs;

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageData = messages[index].data() as Map<String, dynamic>;
            final type = messageData['type'] as String? ?? 'text';

            if (type == 'conflict') {
              return _buildConflictAlertCard(messageData);
            }

            final isMe = messageData['senderId'] == widget.currentUserId;
            return _buildChatBubble(messageData, isMe);
          },
        );
      },
    );
  }

  // ─── Empty state ───
  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.r,
            height: 80.r,
            decoration: BoxDecoration(
              color: _kTeal.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 36.r,
              color: _kTeal.withOpacity(0.4),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'ابدأ المحادثة الآن',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'أرسل رسالة للتواصل مع ${widget.otherUserName}',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  CHAT BUBBLE
  // ═══════════════════════════════════════════
  Widget _buildChatBubble(Map<String, dynamic> message, bool isMe) {
    final text = message['text'] as String? ?? '';
    final time = _formatTime(message['timestamp']);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 280.w),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // ─ Bubble ─
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [_kTeal, _kTealDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isMe ? null : _kBubbleOther,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18.r),
                    topRight: Radius.circular(18.r),
                    bottomLeft: isMe ? Radius.circular(18.r) : Radius.circular(4.r),
                    bottomRight: isMe ? Radius.circular(4.r) : Radius.circular(18.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isMe
                          ? _kTeal.withOpacity(0.18)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    color: isMe ? Colors.white : const Color(0xFF1A1A2E),
                    height: 1.45,
                  ),
                ),
              ),
              // ─ Time ─
              SizedBox(height: 4.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  CONFLICT ALERT CARD
  // ═══════════════════════════════════════════
  Widget _buildConflictAlertCard(Map<String, dynamic> message) {
    final conflictData = message['conflictData'] as Map<String, dynamic>? ?? {};
    final medicationName = conflictData['medicationName'] as String? ?? '';
    final interactions = conflictData['interactions'] as List<dynamic>? ?? [];
    final time = _formatTime(message['timestamp']);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _kDangerRed.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _kDangerRed.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─ Header with gradient ─
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF3E0), Color(0xFFFFEBEE)],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14.5.r),
                  topRight: Radius.circular(14.5.r),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      color: _kDangerRed.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: _kDangerRed,
                      size: 20.r,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تنبيه تعارض دوائي',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: _kDangerRed,
                          ),
                        ),
                        if (medicationName.isNotEmpty) ...[
                          SizedBox(height: 2.h),
                          Text(
                            medicationName,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: _kWarningOrange,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            // ─ Interactions list ─
            if (interactions.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
                child: Column(
                  children: interactions.asMap().entries.map((entry) {
                    final i = entry.key;
                    final interaction = entry.value as Map<String, dynamic>;
                    final drug1 = interaction['drug1'] as String? ?? '';
                    final drug2 = interaction['drug2'] as String? ?? '';
                    final severity = interaction['severity'] as String? ?? '';
                    final description = interaction['description'] as String? ?? '';

                    return Column(
                      children: [
                        if (i > 0)
                          Divider(height: 16.h, color: Colors.grey[200]),
                        _buildInteractionRow(drug1, drug2, severity, description),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionRow(
    String drug1,
    String drug2,
    String severity,
    String description,
  ) {
    final color = _severityColor(severity);
    final icon = _severityIcon(severity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─ Drug pair ─
        Row(
          children: [
            Icon(Icons.medication_rounded, size: 16.r, color: _kTeal),
            SizedBox(width: 6.w),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF1A1A2E),
                    fontFamily: 'Cairo',
                  ),
                  children: [
                    TextSpan(
                      text: drug1,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: ' ↔ ',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    TextSpan(
                      text: drug2,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        // ─ Severity badge ─
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13.r, color: color),
              SizedBox(width: 4.w),
              Text(
                severity,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        // ─ Description ─
        if (description.isNotEmpty) ...[
          SizedBox(height: 6.h),
          Text(
            description,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════
  //  INPUT AREA
  // ═══════════════════════════════════════════
  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, MediaQuery.of(context).padding.bottom + 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ─ Text field ─
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                textDirection: TextDirection.rtl,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF1A1A2E),
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: TextStyle(
                    fontSize: 13.5.sp,
                    color: Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // ─ Send button ─
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 46.r,
              height: 46.r,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_kTeal, _kTealDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22.r,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
