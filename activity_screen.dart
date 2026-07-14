import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'question_detail_screen.dart'; // تأكد من وجود عمل Import لشاشتك الجديدة

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _selectedFilter = 'الكل';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // تغليف الشاشة بالـ Directionality لضمان توجيه التطبيق من اليمين إلى اليسار بالكامل
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. عنوان احترافي في منتصف الشاشة
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "النشاطات",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // 2. شريط الفلاتر العلوي متناسق مع التوجيه العربي
              _buildFilterBar(),

              const SizedBox(height: 10),

              // قائمة الإشعارات الحية
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .where('to', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.amber));
                    }
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text("حدث خطأ ما",
                              style: TextStyle(color: Colors.white38)));
                    }

                    final docs = snapshot.data?.docs ?? [];

                    // ترتيب الإشعارات برمجياً (الأحدث أولاً)
                    final sortedDocs = List.from(docs);
                    sortedDocs.sort((a, b) {
                      final aTime = (a.data()
                          as Map<String, dynamic>)['timestamp'] as Timestamp?;
                      final bTime = (b.data()
                          as Map<String, dynamic>)['timestamp'] as Timestamp?;
                      if (aTime == null || bTime == null) return 0;
                      return bTime.compareTo(aTime);
                    });

                    // الفلترة البرمجية
                    final filteredDocs = sortedDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (_selectedFilter == 'الكل') return true;
                      if (_selectedFilter == 'الردود')
                        return data['type'] == 'reply';
                      if (_selectedFilter == 'الإعجابات')
                        return data['type'] == 'like';
                      return true;
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_off_outlined,
                                size: 64, color: Colors.white24),
                            const SizedBox(height: 16),
                            Text(
                              "لا توجد نشاطات في قسم $_selectedFilter",
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        return _buildActivityCard(doc.id, data);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // بناء شريط الفلاتر ليكون متناسقاً من اليمين
  Widget _buildFilterBar() {
    final filters = ['الكل', 'الردود', 'الإعجابات'];
    return SizedBox(
      height: 45,
      child: Center(
        // وضع الفلاتر بالمنتصف لتتكامل بصرياً مع العنوان
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true, // تجعل القائمة تأخذ مساحة العناصر فقط لتتوسط الشاشة
          physics:
              const NeverScrollableScrollPhysics(), // منع التمرير بما أنها تتسع بالمنتصف
          itemCount: filters.length,
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                selectedColor: Colors.amber,
                backgroundColor: const Color(0xFF1E1E1E),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                side: BorderSide.none,
              ),
            );
          },
        ),
      ),
    );
  }

  // بناء كرت التنبيهات باتجاه RTL (صورة اليمين، النص بالمنتصف، السهم لليسار)
  Widget _buildActivityCard(String docId, Map<String, dynamic> data) {
    final timestamp = data['timestamp'] as Timestamp?;
    final timeStr = timestamp != null
        ? timeago.format(timestamp.toDate(), locale: 'ar')
        : '';
    final isRead = data['isRead'] ?? false;

    final fromUserName = data['fromName'] ?? 'مستخدم استفسر';
    final fromUserImage = data['fromImage'] ?? '';
    final replyText = data['replyText'] ?? '';
    final questionTitle = data['questionTitle'] ?? 'سؤالك';
    final questionId = data['questionId'];
    final type = data['type'] ?? 'reply';

    String actionText = '';
    IconData badgeIcon = Icons.notifications;
    Color badgeColor = Colors.amber;

    if (type == 'like') {
      actionText = ' أعجب بإجابتك على سؤالك ';
      badgeIcon = Icons.favorite;
      badgeColor = Colors.redAccent;
    } else if (type == 'reply') {
      actionText = ' رد على سؤالك ';
      badgeIcon = Icons.comment;
      badgeColor = Colors.blueAccent;
    }

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        FirebaseFirestore.instance
            .collection('notifications')
            .doc(docId)
            .delete();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          // 🔥 هنا التغيير السحري: استبدال السواد الحاد بألوان شفافة تندمج مع الخلفية
          color: isRead
              ? Colors.white.withOpacity(
                  0.02) // إذا مقروء: شفاف جداً يظهر الخلفية الزرقاء
              : Colors.white.withOpacity(
                  0.06), // إذا غير مقروء: أفتح قليلاً ليعطي إيحاء بالتنبيه
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isRead
                  ? Colors.white.withOpacity(0.03)
                  : Colors.amber.withOpacity(0.2),
              width: 1),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF2A2A2A),
                backgroundImage: fromUserImage.isNotEmpty
                    ? NetworkImage(fromUserImage)
                    : null,
                child: fromUserImage.isEmpty
                    ? const Icon(Icons.person, color: Colors.white60, size: 24)
                    : null,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    // 🔥 تعديل لون خلفية الشارة الصغيرة ليطابق الشفافية الجديدة
                    color: const Color(0xFF1E1E1E),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(badgeIcon, size: 12, color: badgeColor),
                ),
              ),
            ],
          ),
          title: RichText(
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Tajawal',
                  height: 1.4),
              children: [
                TextSpan(
                  text: '$fromUserName',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.amber),
                ),
                TextSpan(text: actionText),
                TextSpan(
                  text: '($questionTitle) ',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.6),
                      fontStyle: FontStyle.italic),
                ),
                if (type == 'reply' && replyText.isNotEmpty)
                  TextSpan(
                    text: '\n"$replyText"',
                    style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        fontWeight: FontWeight.normal),
                  ),
              ],
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(timeStr,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ),
          trailing:
              const Icon(Icons.chevron_left, color: Colors.white38, size: 18),
          onTap: () {
            FirebaseFirestore.instance
                .collection('notifications')
                .doc(docId)
                .update({'isRead': true});
            if (questionId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      QuestionDetailScreen(questionId: questionId),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
