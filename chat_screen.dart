import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String qid;
  final String category;
  final String selectedCountry;
  final String questionText;
  final String ownerId;

  const ChatScreen({
    super.key,
    required this.qid,
    required this.category,
    required this.selectedCountry,
    required this.questionText,
    required this.ownerId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  // دالة إرسال التنبيه التلقائي لصاحب الاستفسار عند إضافة تعليق جديد
  Future<void> _sendNotificationToOwner({
    required String recipientId,
    required String notificationText,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid == recipientId) return;

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'to': recipientId,
        'from': currentUser.uid,
        'fromName': currentUser.displayName ?? 'مستفسر',
        'fromImage': currentUser.photoURL ?? '',
        'type': 'new_comment',
        'qid': widget.qid,
        'category': widget.category,
        'selectedCountry': widget.selectedCountry,
        'questionText': widget.questionText,
        'notificationText': notificationText,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("خطأ أثناء إرسال الإشعار: $e");
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('countries')
        .doc(widget.selectedCountry)
        .collection('categories')
        .doc(widget.category)
        .collection('questions')
        .doc(widget.qid)
        .collection('comments')
        .add({
      'text': text,
      'senderId': user.uid,
      'senderName': user.displayName ?? 'مستخدم استفسر',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _sendNotificationToOwner(
      recipientId: widget.ownerId,
      notificationText: text,
    );

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          TextDirection.rtl, // لضمان اتجاه الكتابة والدردشة العربي بالكامل
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // جعل الخلفية شفافة لتنسجم مع تصميم التطبيق
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "المحادثة والمناقشة",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // 1. كرت الاستفسار الأصلي المثبت في الأعلى بتصميم زجاجي أنيق
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.white.withOpacity(0.08), width: 1),
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "الاستفسار المطروح:",
                    style: TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.questionText,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.4),
                  ),
                ],
              ),
            ),

            // 2. قائمة التعليقات الحية بتصميم الفقاعات الشفافة الفخم
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('countries')
                    .doc(widget.selectedCountry)
                    .collection('categories')
                    .doc(widget.category)
                    .collection('questions')
                    .doc(widget.qid)
                    .collection('comments')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.amber));
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final isMe = data['senderId'] ==
                          FirebaseAuth.instance.currentUser?.uid;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerLeft
                            : Alignment
                                .centerRight, // محاذاة الرسائل حسب المرسل
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width *
                                0.75, // أقصى عرض للفقاعة
                          ),
                          decoration: BoxDecoration(
                            // التغيير البصري السحري هنا للدمج مع الخلفية
                            color: isMe
                                ? Colors.amber.withOpacity(
                                    0.12) // رسائلك بلمسة ذهبية شفافة
                                : Colors.white.withOpacity(
                                    0.05), // رسائلهم بلمسة بيضاء شفافة
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe
                                  ? Radius.zero
                                  : const Radius.circular(16),
                              bottomRight: isMe
                                  ? const Radius.circular(16)
                                  : Radius.zero,
                            ),
                            border: Border.all(
                              color: isMe
                                  ? Colors.amber.withOpacity(0.25)
                                  : Colors.white.withOpacity(0.08),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['senderName'] ?? 'مستفسر',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isMe ? Colors.amber : Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                data['text'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 3. حقل إرسال الرسائل الجديد بتصميمه الدائري الشفاف المتناسق
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 20, top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.08), width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "اكتب تعليقك هنا...",
                          hintStyle:
                              TextStyle(color: Colors.white38, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
