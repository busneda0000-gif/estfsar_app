import 'dart:ui'; // مهم جداً لتشغيل الـ ImageFilter والـ Blur
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class QuestionDetailScreen extends StatefulWidget {
  final String questionId;

  const QuestionDetailScreen({Key? key, required this.questionId})
      : super(key: key);

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  final TextEditingController _replyController = TextEditingController();

  // دالة مساعدة للحصول على علم الدولة ديناميكياً
  String _getCountryFlag(String country) {
    switch (country.trim()) {
      case 'البحرين':
        return '🇧🇭';
      case 'السعودية':
      case 'المملكة العربية السعودية':
        return '🇸🇦';
      case 'الإمارات':
      case 'الكويت':
        return '🇰🇼';
      case 'قطر':
        return '🇶🇦';
      case 'عمان':
        return '🇴🇲';
      default:
        return '🇧🇭'; // الافتراضي
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    return Scaffold(
      backgroundColor:
          const Color(0xFF111827), // خلفية داكنة فخمة تناسب التصميم الزجاجي
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: const Text(
          "تفاصيل الاستفسار",
          style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('questions')
            .doc(widget.questionId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "هذا السؤال لم يعد موجوداً",
                style: TextStyle(color: Colors.white38, fontFamily: 'Cairo'),
              ),
            );
          }

          final questionData = snapshot.data!.data() as Map<String, dynamic>;

          // قراءة البيانات من الفايربيس بدقة
          String questionTitle = questionData['title'] ?? "استفسر";
          String questionText = questionData['text'] ?? "";
          String questionCountry = questionData['country'] ?? "البحرين";
          String profileImageUrl = questionData['userImage'] ?? "";
          String userName = questionData['userName'] ?? "مستفسر مجهول";

          DateTime postDate = DateTime.now();
          if (questionData['timestamp'] != null) {
            postDate = (questionData['timestamp'] as Timestamp).toDate();
          }

          return Column(
            children: [
              // 🟢 1. كارت السؤال الزجاجي الفخم المطابق للرئيسية 100%
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  clipBehavior: Clip.antiAlias,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: double.infinity,
                      height: 320, // طول متناسق لشاشة التفاصيل
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(28),
                        image: DecorationImage(
                          image: const NetworkImage(
                            'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?q=80&w=1200&auto=format&fit=crop',
                          ),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            const Color(0xFF1E1E2C).withOpacity(0.2),
                            BlendMode.dstATop,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Stack(
                          children: [
                            // المحتوى النصي الداخلي مرتب في المنتصف
                            Positioned.fill(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // العلم والوقت بالأعلى
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getCountryFlag(questionCountry),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        timeago.format(postDate, locale: 'ar'),
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontFamily: 'Cairo',
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // عنوان السؤال الذهبي الفخم
                                  Text(
                                    questionTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // تفاصيل ونص الاستفسار
                                  Expanded(
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: Text(
                                          questionText,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.85),
                                            fontSize: 15,
                                            height: 1.5,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                      height: 45), // مساحة للبروفايل بالأسفل
                                ],
                              ),
                            ),

                            // بيانات كاتب الاستفسار (بالأسفل يسار)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundImage:
                                            profileImageUrl.isNotEmpty
                                                ? NetworkImage(profileImageUrl)
                                                : null,
                                        backgroundColor: Colors.grey,
                                        child: profileImageUrl.isEmpty
                                            ? const Icon(Icons.person,
                                                color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // خط فاصل أنيق ومميز للردود والمناقشات
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      "الردود والمناقشات",
                      style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'Cairo'),
                    ),
                    Expanded(
                        child: Divider(
                            color: Colors.white10,
                            indent: 10,
                            endIndent: 10,
                            thickness: 1)),
                  ],
                ),
              ),

              // 2. قائمة الردود والمناقشات المنسقة
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('questions')
                      .doc(widget.questionId)
                      .collection('replies')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, replySnapshot) {
                    if (!replySnapshot.hasData) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.amber));
                    }
                    final replies = replySnapshot.data!.docs;

                    if (replies.isEmpty) {
                      return const Center(
                        child: Text(
                          "لا توجد ردود بعد. كن أول من يرد!",
                          style: TextStyle(
                              color: Colors.white38, fontFamily: 'Cairo'),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: replies.length,
                      itemBuilder: (context, index) {
                        final reply =
                            replies[index].data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937).withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.1),
                                    backgroundImage:
                                        reply['fromImage'] != null &&
                                                reply['fromImage']
                                                    .toString()
                                                    .isNotEmpty
                                            ? NetworkImage(reply['fromImage'])
                                            : null,
                                    child: reply['fromImage'] == null ||
                                            reply['fromImage']
                                                .toString()
                                                .isEmpty
                                        ? const Icon(Icons.person,
                                            size: 16, color: Colors.white54)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    reply['fromName'] ?? 'مستفسر',
                                    style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Cairo'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                reply['text'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.4,
                                    fontFamily: 'Cairo'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // 3. حقل إدخال الرد في الأسفل وتنبيه الإشعار للفايربيس
              _buildReplyInput(questionData['userId'], questionTitle),
            ],
          );
        },
      ),
    );
  }

  // ويدجت حقل إرسال الردود
  Widget _buildReplyInput(String? fallbackTargetUserId, String? questionTitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _replyController,
                  style:
                      const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                  decoration: const InputDecoration(
                    hintText: "اكتب ردك هنا...",
                    hintStyle: TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                        fontFamily: 'Cairo'),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.amber,
              radius: 22,
              child: IconButton(
                icon: const Icon(Icons.send_rounded,
                    color: Color(0xFF111827), size: 20),
                onPressed: () async {
                  final text = _replyController.text.trim();
                  if (text.isEmpty) return;

                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) return;

                  _replyController.clear(); // مسح سريع للتجربة وسلاسة الاستخدام

                  String? finalTargetUserId = fallbackTargetUserId;
                  String? finalQuestionTitle = questionTitle;

                  try {
                    final qDoc = await FirebaseFirestore.instance
                        .collection('questions')
                        .doc(widget.questionId)
                        .get();
                    if (qDoc.exists && qDoc.data() != null) {
                      final qData = qDoc.data()!;
                      finalTargetUserId = qData['userId'] ?? qData['uid'];
                      finalQuestionTitle = qData['title'] ?? finalQuestionTitle;
                    }
                  } catch (e) {
                    print("خطأ في جلب المستند: $e");
                  }

                  if (finalTargetUserId == null) return;

                  String realName = 'مستفسر';
                  String realImage = '';

                  try {
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .get();

                    if (userDoc.exists && userDoc.data() != null) {
                      final userData = userDoc.data()!;
                      realName = userData['name'] ??
                          userData['username'] ??
                          currentUser.displayName ??
                          'مستفسر';
                      realImage = userData['image'] ??
                          userData['profileUrl'] ??
                          currentUser.photoURL ??
                          '';
                    }
                  } catch (e) {
                    print("خطأ في جلب بيانات المستخدم: $e");
                  }

                  // 📌 حفظ الرد في الكولكشن الفرعي داخل السؤال
                  await FirebaseFirestore.instance
                      .collection('questions')
                      .doc(widget.questionId)
                      .collection('replies')
                      .add({
                    'text': text,
                    'fromId': currentUser.uid,
                    'fromName': realName,
                    'fromImage': realImage,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  // 🔔 إرسال الإشعار لصاحب السؤال في الفايربيس ليفتح له من دارت النشاطات
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .add({
                    'to': finalTargetUserId,
                    'fromId': currentUser.uid,
                    'fromName': realName,
                    'fromImage': realImage,
                    'type': 'reply',
                    'questionId': widget.questionId,
                    'questionTitle': finalQuestionTitle ?? 'سؤالك',
                    'replyText': text,
                    'timestamp': FieldValue.serverTimestamp(),
                    'isRead': false,
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
