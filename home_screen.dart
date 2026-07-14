import 'package:estfsar_app/question_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'question_card.dart';
import 'profile_screen.dart';
import 'add_question_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'activity_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  const HomeScreen({super.key, required this.themeNotifier});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

final Map<String, List<String>> countryCategories = {
  'البحرين': ['الكل', 'نصيحة', 'فكرة', 'سيارات', 'عقارات', 'استفسارات عامة'],
  'السعودية': [
    'الكل',
    'نصيحة',
    'فكرة',
    'سياحة وفعاليات',
    'سيارات',
    'استفسارات عامة'
  ],
  'الإمارات': [
    'الكل',
    'نصيحة',
    'فكرة',
    'أعمال واستثمار',
    'عقارات',
    'استفسارات عامة'
  ],
  'الكويت': ['الكل', 'نصيحة', 'فكرة', 'ديوانيات', 'سيارات', 'استفسارات عامة'],
  'قطر': ['الكل', 'نصيحة', 'فكرة', 'فعاليات', 'سياحة', 'استفسارات عامة'],
  'عُمان': ['الكل', 'نصيحة', 'فكرة', 'سياحة طبيعية', 'تراث', 'استفسارات عامة'],
};

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(initialPage: 1);
  final PageController _questionsScrollController = PageController();

  int _currentIndex = 1;
  String _selectedCountry = "البحرين";
  String _selectedCategory = 'الكل';

  final List<String> _gccCountries = [
    "البحرين",
    "السعودية",
    "الإمارات",
    "الكويت",
    "قطر",
    "عُمان",
  ];

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "اختر الدولة الخليجية",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _gccCountries.length,
                  itemBuilder: (context, index) {
                    String country = _gccCountries[index];
                    bool isCurrent = _selectedCountry == country;
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      title: Text(
                        country,
                        style: TextStyle(
                          color: isCurrent ? Colors.orange : Colors.white,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      trailing: isCurrent
                          ? const Icon(Icons.check_circle, color: Colors.orange)
                          : const Icon(Icons.circle_outlined,
                              color: Colors.white24),
                      onTap: () {
                        setState(() {
                          _selectedCountry = country;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F2027),
            Color(0xFF203A43),
            Color(0xFF2C5364),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _currentIndex == 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(100),
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: 20, left: 16, right: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AddQuestionScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.add_comment_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  "اسأل الحين",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _topCapsule(Icons.flag, _selectedCountry, () {
                          _showCountryPicker();
                        }),
                        const SizedBox(width: 12),
                        PopupMenuButton<String>(
                          offset: const Offset(0, 50),
                          color: const Color(0xFF2C2C2C),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2C),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.category,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(_selectedCategory,
                                    style:
                                        const TextStyle(color: Colors.white)),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down,
                                    color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                          onSelected: (String value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                          itemBuilder: (BuildContext context) {
                            List<String> categories =
                                countryCategories[_selectedCountry] ?? ['الكل'];
                            return categories.map((String choice) {
                              return PopupMenuItem<String>(
                                value: choice,
                                child: Text(choice,
                                    style:
                                        const TextStyle(color: Colors.white)),
                              );
                            }).toList();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,

        // 💡 استخدام Material شفاف هنا يسرّع عملية الرسم ويقضي على الـ Lag
        body: Material(
          color: Colors.transparent,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            physics: const BouncingScrollPhysics(),
            children: [
              _KeepAliveWrapper(child: _buildMainContent(0)), // النشاطات
              _KeepAliveWrapper(child: _buildMainContent(1)), // التصفح
              _KeepAliveWrapper(child: ProfileScreen()), // البروفايل
            ],
          ),
        ),

        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937).withOpacity(0.95),
            border:
                Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _bottomNavItem(Icons.notifications_none, "النشاطات", 0, () {
                  _pageController.animateToPage(0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.decelerate);
                  setState(() {
                    _currentIndex = 0;
                  });
                }),
                _bottomNavItem(Icons.explore_outlined, "تصفح الاستفسارات", 1,
                    () {
                  _pageController.animateToPage(1,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.decelerate);
                  setState(() {
                    _currentIndex = 1;
                  });
                }),
                _bottomNavItem(Icons.person_outline, "الملف الشخصي", 2, () {
                  _pageController.animateToPage(2,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.decelerate);
                  setState(() {
                    _currentIndex = 2;
                  });
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _questionsScrollController.dispose();
    super.dispose();
  }

  Widget _buildMainContent(int pageIndex) {
    if (pageIndex == 0) {
      return const ActivityScreen();
    } else if (pageIndex == 1) {
      return _buildQuestionsListBody();
    }
    return const SizedBox.shrink();
  }

  Widget _buildQuestionsListBody() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('questions')
          .where('country', isEqualTo: _selectedCountry)
          .where('category',
              isEqualTo: _selectedCategory == 'الكل' ? null : _selectedCategory)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('خطأ: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "لا توجد استفسارات حالياً في $_selectedCountry",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        var validDocs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return data.containsKey('text') &&
              data['text'] != null &&
              data['text'].toString().isNotEmpty;
        }).toList();

        if (validDocs.isEmpty) {
          return Center(
            child: Text("لا توجد استفسارات حالياً في $_selectedCountry",
                style: const TextStyle(color: Colors.white)),
          );
        }

        return PageView.builder(
          key: ValueKey("${_currentIndex}_$_selectedCountry"),
          controller: _questionsScrollController,
          scrollDirection: Axis.vertical,
          itemCount: validDocs.length,
          itemBuilder: (context, index) {
            var doc = validDocs[index];
            var data = doc.data() as Map<String, dynamic>;

            Timestamp? timestamp = data['timestamp'] as Timestamp?;
            DateTime postDate = timestamp?.toDate() ?? DateTime.now();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: QuestionCard(
                document: validDocs[index],
                docId: doc.id,
                questionText: data['text'],
                postDate: postDate,
                userName:
                    data.containsKey('userName') ? data['userName'] : 'مستخدم',
                profileImageUrl: data.containsKey('profileImageUrl')
                    ? data['profileImageUrl']
                    : 'https://via.placeholder.com/150',
                likes: data.containsKey('likes')
                    ? (data['likes'] as num).toInt()
                    : 0,
              ),
            );
          },
        );
      },
    );
  }

  Widget _topCapsule(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                color: Colors.white70, size: 18),
          ],
        ),
      ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 💡 ويدجت ذكية تمنع الشاشات من الموت وإعادة تحميل السيرفر لتسريع الأداء 100%
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  __KeepAliveWrapperState createState() => __KeepAliveWrapperState();
}

class __KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
