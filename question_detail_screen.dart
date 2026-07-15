import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'question_card.dart';
import 'home_screen.dart';

class QuestionDetailScreen extends StatefulWidget {
  final String questionId;
  // 💡 جعلنا الـ themeNotifier اختيارياً بإضافة علامة الاستفهام (?) وحذف كلمة required
  final ValueNotifier<ThemeMode>? themeNotifier;

  const QuestionDetailScreen({
    super.key,
    required this.questionId,
    this.themeNotifier, // تم إزالة required لكي لا تخرب الشاشات الأخرى
  });

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  final int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      // 🎨 الخلفية الداكنة الفخمة الموحدة للتطبيق بدلاً من التدرج القديم
      decoration: const BoxDecoration(
        color: Color(0xFF121212), 
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('questions')
                  .doc(widget.questionId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  );
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    !snapshot.data!.exists) {
                  return const Center(
                    child: Text(
                      "عذراً، لم يتم العثور على الاستفسار",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Cairo',
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                var doc = snapshot.data!;
                var data = doc.data() as Map<String, dynamic>;

                Timestamp? timestamp = data['timestamp'] as Timestamp?;
                DateTime postDate = timestamp?.toDate() ?? DateTime.now();

                return Padding(
                  padding: const EdgeInsets.only(
                      top: 70.0, bottom: 10.0, left: 16.0, right: 16.0),
                  child: Center(
                    child: QuestionCard(
                      document: doc,
                      docId: doc.id,
                      // 🌟 تمرير الفئة لكرت السؤال لكي تظهر الخلفية المناسبة له
                      category: data.containsKey('category')
                          ? data['category']
                          : 'استفسارات عامة',
                      questionText: data['text'] ?? '',
                      postDate: postDate,
                      userName: data.containsKey('userName')
                          ? data['userName']
                          : 'مستخدم',
                      profileImageUrl: data.containsKey('profileImageUrl')
                          ? data['profileImageUrl']
                          : 'https://via.placeholder.com/150',
                      likes: data.containsKey('likes')
                          ? (data['likes'] as num).toInt()
                          : 0,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 20,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937).withOpacity(0.95),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _bottomNavItem(Icons.notifications_none, "النشاطات", 0, () {
                  _navigateToHomeWithIndex(0);
                }),
                _bottomNavItem(Icons.explore_outlined, "تصفح الاستفسارات", 1,
                    () {
                  _navigateToHomeWithIndex(1);
                }),
                _bottomNavItem(Icons.person_outline, "الملف الشخصي", 2, () {
                  _navigateToHomeWithIndex(2);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToHomeWithIndex(int index) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          // 💡 هنا نضع حماية: إذا لم يكن هناك themeNotifier، ننشئ واحداً افتراضياً لتفادي أي كراش
          themeNotifier: widget.themeNotifier ?? ValueNotifier(ThemeMode.dark),
        ),
      ),
      (route) => false,
    );
  }

  Widget _bottomNavItem(
      IconData icon, String label, int index, VoidCallback onTap) {
    final bool isActive = _currentIndex == index;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.orange : Colors.white54,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.orange : Colors.white54,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}