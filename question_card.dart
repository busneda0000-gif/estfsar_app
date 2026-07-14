import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionCard extends StatefulWidget {
  final String docId;
  final String questionText;
  final String userName;
  final String profileImageUrl;
  final int likes;
  final DateTime postDate;
  final DocumentSnapshot document;

  const QuestionCard({
    Key? key,
    required this.docId,
    required this.questionText,
    required this.userName,
    required this.profileImageUrl,
    required this.likes,
    required this.postDate,
    required this.document,
  }) : super(key: key);

  @override
  _QuestionCardState createState() => _QuestionCardState();
}

void onReplyTap(dynamic widget, BuildContext context) {
  // الحصول على البيانات كخريطة (Map)
  Map<String, dynamic> data = widget.document.data() as Map<String, dynamic>;

  // التحقق من وجود الحقل قبل استخدامه
  String ownerId = data.containsKey('ownerId') ? data['ownerId'] : '';

  // إذا كان الـ ownerId فارغاً، يمكنك طباعة خطأ أو إيقاف العملية
  if (ownerId.isEmpty) {
    print("خطأ: لا يوجد ownerId في هذا المستند!");
    return;
  }
}

String? _replyingToUser; // لتخزين اسم المستخدم الذي يتم الرد عليه حالياً
final TextEditingController _commentController =
    TextEditingController(); // للتحكم بنص التعليق
void _showCommentsBottomSheet(BuildContext context, String questionId,
    fs.DocumentSnapshot<Object?> document) {
  print(
      "تم فتح قائمة التعليقات للاستفسار رقم: $questionId"); // 👈 أضف هذا السطر الحين

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // ضرورية جداً عشان الكيبورد ما يغطي الحقل
    backgroundColor: Colors.transparent, // لجعل الأطراف دائرية ونظيفة
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            // 👇 هنا السحر الحقيقي: نحدد أن الارتفاع لا يتجاوز 70% من حجم الشاشة
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E), // لون خلفيتك الداكن
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.only(
              bottom:
                  MediaQuery.of(context).viewInsets.bottom, // تفادي الكيبورد
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // تجعله ينكمش لو كانت التعليقات قليلة
              children: [
                // 1. مؤشر السحب الجمالي بالأعلى
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),

                // 1. قائمة عرض الردود والتعليقات الحالية
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('questions')
                          .doc(questionId)
                          .collection('comments')
                          .orderBy('timestamp', descending: true)
                          .limit(20) // أضف هذا السطر فقط!
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        var comments = snapshot.data!.docs;

                        if (comments.isEmpty) {
                          return const Center(
                              child: Text("لا توجد ردود بعد",
                                  style: TextStyle(color: Colors.white54)));
                        }

                        return ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            var comment = comments[index];
                            var commentData =
                                comment.data() as Map<String, dynamic>;

                            // 1. استخراج الـ id للشخص الذي كتب هذا التعليق بأمان
                            String commenterUid = commentData['userId'] ?? '';

                            // 📌 جلب وقت نزول التعليق ديناميكياً وتنسيقه باللغة العربية
                            String commentTime = "الآن";
                            if (commentData.containsKey('timestamp') &&
                                commentData['timestamp'] != null) {
                              // تحويل الـ Timestamp القادم من الفايربيس إلى DateTime
                              DateTime postDateTime =
                                  (commentData['timestamp'] as Timestamp)
                                      .toDate();
                              // تحويل الوقت إلى صيغة نصية مثل "منذ ٥ دقائق"
                              commentTime =
                                  timeago.format(postDateTime, locale: 'ar');
                            }

                            // 2. 🔥 فحص أمان: لو حقل الـ userId غير موجود أو فارغ لتجنب انهيار الشاشة (الشاشة الحمراء)
                            if (commenterUid.isEmpty) {
                              return _buildSwipeableComment(
                                "مستخدم",
                                commentData['text'] ?? '',
                                commentTime, // 👈 وقت نزول التعليق
                                "مستخدم",
                                null,
                                () {
                                  setModalState(() {
                                    _replyingToUser = "مستخدم";
                                  });
                                },
                                setModalState,
                              );
                            }

                            // 3. استخدام FutureBuilder لجلب الاسم والصورة الحقيقية من مجموعة الـ users الرئيسية
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(commenterUid)
                                  .get(),
                              builder: (context, userSnapshot) {
                                // القيم الافتراضية في حال لم تكتمل عملية الجلب بعد أو لم يجد المستخدم
                                String realUsername = "مستخدم";
                                String? realProfileImage;

                                if (userSnapshot.hasData &&
                                    userSnapshot.data!.exists) {
                                  var userData = userSnapshot.data!.data()
                                      as Map<String, dynamic>;
                                  realUsername = userData['username'] ??
                                      'مستخدم'; // حرف N كبير
                                  realProfileImage =
                                      userData['profileImageUrl']; // حرف I كبير
                                }

                                // 4. تمرير البيانات الحقيقية المستخرجة مع الوقت للدالة الخاصة بك
                                return _buildSwipeableComment(
                                  realUsername, // 👈 الاسم الحقيقي
                                  commentData['text'] ?? '',
                                  commentTime, // 👈 الوقت الحقيقي للتعليق (بدل كلمة "الآن")
                                  realUsername,
                                  realProfileImage, // 👈 رابط الصورة الشخصية الحقيقي
                                  () {
                                    setModalState(() {
                                      _replyingToUser = realUsername;
                                    });
                                  },
                                  setModalState,
                                );
                              },
                            );
                          },
                        );
                      }),
                ),

                const SizedBox(height: 12),

                // 📌 شريط المنشن العلوي (يظهر فقط إذا اختار المستخدم الرد على شخص معين مثل الواتساب)
                if (_replyingToUser != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                          right: BorderSide(
                              color: Colors.orange, width: 4)), // خط جانبي مميز
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.reply_rounded,
                                color: Colors.orange, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              "الرد على $_replyingToUser",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _replyingToUser = null;
                              _commentController
                                  .clear(); // مسح المنشن عند الإلغاء
                            });
                          },
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white54, size: 18),
                        ),
                      ],
                    ),
                  ),

                // 2. حقل إرسال رد أو تعليق جديد في الأسفل
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "اكتب ردك أو مساعدتك هنا...",
                          hintStyle: const TextStyle(
                              color: Colors.white30, fontSize: 14),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Colors.orange),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                        backgroundColor: Colors.orange,
                        radius: 22,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.amber),
                          onPressed: () async {
                            final text = _commentController.text.trim();
                            if (text.isEmpty) return;

                            final currentUser =
                                FirebaseAuth.instance.currentUser;
                            if (currentUser == null) return;

                            String currentUserId = currentUser.uid;

                            try {
                              await FirebaseFirestore.instance
                                  .collection('questions')
                                  .doc(
                                      questionId) // 👈 تم تعديلها إلى questionId لتطابق السطر 49 فوق
                                  .collection('comments')
                                  .add({
                                'text': text,
                                'userId': currentUserId,
                                'timestamp': FieldValue.serverTimestamp(),
                              });

                              _commentController.clear();
                            } catch (e) {
                              print("خطأ في حفظ الرد: $e");
                            }

                            // 2. كود الإشعارات المستقل والمحمي تماماً من التوقف
                            try {
                              // جلب تفاصيل السؤال لمعرفة من صاحبه
                              final questionDoc = await FirebaseFirestore
                                  .instance
                                  .collection('questions')
                                  .doc(questionId)
                                  .get();

                              String targetUserId = currentUser
                                  .uid; // كقيمة افتراضية لإرساله لنفسك للاختبار
                              String questionTitle = 'سؤالك';

                              if (questionDoc.exists &&
                                  questionDoc.data() != null) {
                                final qData = questionDoc.data()!;
                                // جرب جلب المعرف بكل التسميات الممكنة في تطبيقك
                                targetUserId = qData['userId'] ??
                                    qData['uid'] ??
                                    qData['user_id'] ??
                                    currentUser.uid;
                                questionTitle = qData['title'] ?? 'سؤالك';
                              }

                              // جلب بيانات حسابك الحالي
                              String realName =
                                  currentUser.displayName ?? 'مستخدم استفسر';
                              String realImage = currentUser.photoURL ?? '';

                              final userDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser.uid)
                                  .get();

                              if (userDoc.exists && userDoc.data() != null) {
                                final userData = userDoc.data()!;
                                realName = userData['name'] ??
                                    userData['username'] ??
                                    realName;
                                realImage = userData['image'] ??
                                    userData['profileUrl'] ??
                                    realImage;
                              }

                              // 🔥 الشرط السحري: نكتب في كولكشن الإشعارات فقط إذا كان كاتب الرد ليس هو صاحب السؤال
                              if (currentUser.uid != targetUserId) {
                                await FirebaseFirestore.instance
                                    .collection('notifications')
                                    .add({
                                  'to': targetUserId,
                                  'fromId': currentUser.uid,
                                  'fromName': realName,
                                  'fromImage': realImage,
                                  'type': 'reply',
                                  'questionId': questionId,
                                  'questionTitle': questionTitle,
                                  'replyText': text,
                                  'timestamp': FieldValue.serverTimestamp(),
                                  'isRead': false,
                                });
                                print(
                                    "🔥 نجاح تام: تم إرسال الإشعار لصاحب السؤال بنجاح!");
                              } else {
                                print(
                                    "💡 تنبيه: أنت صاحب الاستفسار، تم إلغاء إنشاء وثيقة الإشعار منعاً لإزعاجك.");
                              }
                            } catch (e) {
                              // لو حدث أي خطأ في الجلب سيطبع هنا بدقة دون إيقاف الزر
                              print(
                                  "🚨 فشل في منطق الإشعارات ولكن تم تجاوز الخطأ: $e");
                            }

                            // 3. تفريغ النص وإغلاق المنشن
                            setModalState(() {
                              _replyingToUser = null;
                              _commentController.clear();
                            });
                          },
                        ))
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// ويدجت داخلي لبناء شكل التعليق المفرد بشكل مرتب ونظيف

class _QuestionCardState extends State<QuestionCard> {
  // دالة ذكية لإرجاع علم الدولة بناءً على اسمها المخزن في قاعدة البيانات
  String _getCountryFlag(String countryName) {
    switch (countryName) {
      case "البحرين":
        return "🇧🇭";
      case "السعودية":
        return "🇸🇦";
      case "الإمارات":
        return "🇦🇪";
      case "الكويت":
        return "🇰🇼";
      case "قطر":
        return "🇶🇦";
      case "عُمان":
        return "🇴🇲";
      default:
        return "📍"; // رمز افتراضي في حال عدم التحديد
    }
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('questions')
          .doc(widget.docId)
          .collection('likes')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        bool isLiked = snapshot.hasData && snapshot.data!.exists;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('questions')
              .doc(widget.docId)
              .get(),
          builder: (context, qSnapshot) {
            String questionTitle = "استفسار جديد";
            String questionCountry = "البحرين"; // افتراضي

            if (qSnapshot.hasData && qSnapshot.data!.exists) {
              var qData = qSnapshot.data!.data() as Map<String, dynamic>;
              if (qData.containsKey('title') && qData['title'] != null) {
                questionTitle = qData['title'];
              }
              // 📌 قراءة الدولة ديناميكياً من المستند في Firestore
              if (qData.containsKey('country') && qData['country'] != null) {
                questionCountry = qData['country'];
              }
            }

            return ClipRRect(
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: double.infinity, // تمدد لعرض الشاشة
                    height: 400, // الطول المناسب للكرت الخاص بك

                    // 1. 🔥 التحكم الكامل في شفافية الخلفية ودمجها بشكل فخم
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C).withOpacity(
                          0.7), // جعل اللون الأساسي شفافاً ليعمل الـ Blur
                      borderRadius: BorderRadius.circular(
                          28), // مطابقة الحواف تماماً مع الـ ClipRRect
                      image: DecorationImage(
                        image: const NetworkImage(
                          'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?q=80&w=1200&auto=format&fit=crop',
                        ),
                        fit: BoxFit.cover,
                        // 🌟 الفلتر السحري: يجعل الصورة الخلفية هادئة وشفافة جداً (0.2) لتبرز النصوص البيضاء فوقها
                        colorFilter: ColorFilter.mode(
                          const Color(0xFF1E1E2C).withOpacity(0.2),
                          BlendMode.dstATop,
                        ),
                      ),
                    ),

                    // 2. المحتوى الداخلي مع مسافة أمان (Padding) لحماية العناصر من الخروج
                    child: Padding(
                      padding: const EdgeInsets.all(
                          20.0), // 👈 مسافة أمان داخلية تمنع الأيقونات من الالتصاق بالحواف
                      child: Stack(
                        children: [
                          // 💡 [ملاحظة]: تم حذف الـ Image.network المكرر القديم لكي تظهر الشفافية الحقيقية!

                          Positioned.fill(
                            // 📌 تم إزالة الـ right: 65 وجعلها تتوزع بالتساوي داخل مسافة الأمان لكي لا يخرج أي عنصر
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // اسم الفئة وعلم الدولة ديناميكياً في أعلى اليمين
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // 1. علم الدولة
                                    Text(
                                      _getCountryFlag(questionCountry),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(
                                        width: 8), // مسافة بسيطة ومريحة

                                    // 2. الوقت بجانب العلم
                                    Text(
                                      timeago.format(widget.postDate,
                                          locale: 'ar'),
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),

                                    const Spacer(),
                                  ],
                                ),
                                const SizedBox(height: 25),

                                // العنوان الرئيسي
                                Text(
                                  questionTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // تفاصيل الاستفسار
                                Expanded(
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Text(
                                        widget.questionText,
                                        maxLines: 7,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 16,
                                          height: 1.5,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // ترك مساحة مريحة بالأسفل للأزرار وصورة البروفايل "بوسنيده"
                                const SizedBox(height: 60),
                              ],
                            ),
                          ),

                          // 2. عمود الأزرار الجانبية في أقصى اليمين
                          Positioned(
                            right: 0,
                            bottom: 80,
                            child: Column(
                              children: [
                                _actionButton(
                                  Icons.chat_bubble,
                                  "المساعدة",
                                  () {
                                    // نقرأ الحقل الصحيح الموجود في الفايربيس وهو 'userId'
                                    final String ownerId =
                                        widget.document.get('userId');

                                    // 👈 التعديل الصحيح: استبدله بهذا السطر بالظبط
                                    _showCommentsBottomSheet(
                                        context, widget.docId, widget.document);
                                  },
                                ),
                                const SizedBox(height: 16),
                                _actionButton(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  "${widget.likes}",
                                  () async {
                                    DocumentReference likeRef =
                                        FirebaseFirestore.instance
                                            .collection('questions')
                                            .doc(widget.docId)
                                            .collection('likes')
                                            .doc(uid);

                                    DocumentSnapshot likeDoc =
                                        await likeRef.get();

                                    if (likeDoc.exists) {
                                      await likeRef.delete();
                                      await FirebaseFirestore.instance
                                          .collection('questions')
                                          .doc(widget.docId)
                                          .update({
                                        'likes': FieldValue.increment(-1),
                                      });
                                    } else {
                                      await likeRef.set({
                                        'timestamp':
                                            FieldValue.serverTimestamp()
                                      });
                                      await FirebaseFirestore.instance
                                          .collection('questions')
                                          .doc(widget.docId)
                                          .update({
                                        'likes': FieldValue.increment(1),
                                      });
                                    }
                                  },
                                  iconColor:
                                      isLiked ? Colors.red : Colors.white,
                                ),
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('bookmarks')
                                      .doc(
                                          '${FirebaseAuth.instance.currentUser?.uid}_${widget.docId}')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    bool isBookmarked = snapshot.hasData &&
                                        snapshot.data!.exists;

                                    return Padding(
                                      // هنا أضفنا مسافة (Padding) من الأعلى ليفصل عن زر اللايك
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: _actionButton(
                                        isBookmarked
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        isBookmarked ? "محفوظ" : "حفظ",
                                        () => _toggleBookmark(widget.docId),
                                        // هنا حددنا اللون الأصفر (Colors.amber) عند الحفظ
                                        iconColor: isBookmarked
                                            ? Colors.amber
                                            : Colors.white,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                _actionButton(
                                    Icons.reply_rounded, "مشاركة", () {}),
                              ],
                            ),
                          ),

                          // 3. الجزء السفلي: بيانات الكاتب وزر إضافة استفسار
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage:
                                          NetworkImage(widget.profileImageUrl),
                                      backgroundColor: Colors.grey,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      widget.userName,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ));
          },
        );
      },
    );
  }

  Future<void> sendNotificationOnReply({
    required String questionId,
    required String replyText,
    required String currentUserId,
  }) async {
    try {
      // 1. جلب بيانات صاحب الرد الحقيقي
      String realName = 'مستخدم استفسر';
      String realImage = '';

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        realName = userData['name'] ?? userData['username'] ?? 'مستخدم استفسر';
        realImage = userData['image'] ?? userData['profileUrl'] ?? '';
      }

      // 2. جلب صاحب السؤال الأصلي
      final questionDoc = await FirebaseFirestore.instance
          .collection('questions')
          .doc(questionId)
          .get();
      if (questionDoc.exists && questionDoc.data() != null) {
        final qData = questionDoc.data()!;
        final targetUserId = qData['userName'] ?? qData['uid'];
        final questionTitle = qData['title'] ?? 'سؤالك';

        if (targetUserId != null) {
          // 3. كتابة الإشعار في الفايربيس
          await FirebaseFirestore.instance.collection('notifications').add({
            'to': targetUserId,
            'fromId': currentUserId,
            'fromName': realName,
            'fromImage': realImage,
            'type': 'reply',
            'questionId': questionId,
            'questionTitle': questionTitle,
            'replyText': replyText,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
    } catch (e) {
      print("خطأ في إرسال الإشعار بالطريقة الثانية: $e");
    }
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap,
      {Color iconColor = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// هذا الكود يجمع كل مزاياك: السحب للرد (Dismissible)، وتصميم الـ ListTile
Widget _buildSwipeableComment(
    String name,
    String text,
    String time,
    String username,
    String? imageUrl,
    VoidCallback onReplyTrigger,
    StateSetter setModalState) {
  return Dismissible(
    key: UniqueKey(), // مفتاح فريد لضمان عمل الـ Dismissible
    direction: DismissDirection.endToStart, // السحب من اليمين لليسار
    confirmDismiss: (direction) async {
      onReplyTrigger(); // تفعيل المنشن
      return false; // يمنع حذف العنصر من الواجهة
    },
    background: Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.reply_rounded, color: Colors.orange, size: 24),
    ),
    // استدعاء دالة عرض التعليق
    child: _buildCommentItem(name, text, time, imageUrl),
  );
}

// دالة عرض العنصر (تم تصحيحها لتعرض الصورة)
Widget _buildCommentItem(
    String name, String text, String time, String? imageUrl) {
  return ListTile(
    leading: CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white12,
      // المنطق الصحيح لعرض الصورة من الرابط أو إظهار الأيقونة الافتراضية
      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
          ? NetworkImage(imageUrl)
          : null,
      child: (imageUrl == null || imageUrl.isEmpty)
          ? const Icon(Icons.person, color: Colors.white54)
          : null,
    ),
    title: Text(name,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    subtitle: Text(text, style: const TextStyle(color: Colors.white70)),
    trailing:
        Text(time, style: const TextStyle(color: Colors.white30, fontSize: 12)),
  );
}

Future<void> _toggleBookmark(String docId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final docRef = FirebaseFirestore.instance
      .collection('bookmarks')
      .doc('${user.uid}_$docId');
  final doc = await docRef.get();

  if (doc.exists) {
    await docRef.delete(); // إذا كان موجوداً، يحذفه
  } else {
    await docRef.set({
      'userId': user.uid,
      'questionId': docId,
      'timestamp': FieldValue.serverTimestamp(), // الوقت تلقائياً من السيرفر
    });
  }
}
