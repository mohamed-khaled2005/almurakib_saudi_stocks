import 'package:flutter/material.dart';
import '../core/utils/constants.dart';
import '../animations/fade_animation.dart';
import '../animations/slide_animation.dart';
import '../widgets/tab_page_header.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        top: false,
        child: FadeAnimation(
          child: Column(
            children: [
              const TabPageHeaderBlock(title: 'حول التطبيق'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 1. كارت النبذة التعريفية
                    SlideAnimation(
                      delay: const Duration(milliseconds: 100),
                      child: _buildInfoCard(
                        title: 'مراقب الأسهم السعودية',
                        // ✅ تم حذف "(تاسي)"
                        content:
                            'هو التطبيق الرسمي لمنصة المراقب، تم تصميمه ليمنحك رؤية شاملة وسريعة لسوق الأسهم السعودي وتحديثات الأسعار لحظة بلحظة.',
                        icon: Icons.info_outline_rounded,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ✅ عنوان المميزات (موحد مع باقي التطبيق)
                    const SlideAnimation(
                      delay: Duration(milliseconds: 150),
                      child: _UnifiedSectionTitle(title: "مميزات التطبيق"),
                    ),
                    const SizedBox(height: 16),

                    // 2. قائمة المميزات (3 فقط - عمودية)
                    SlideAnimation(
                      delay: const Duration(milliseconds: 200),
                      child: _buildFeaturesList(),
                    ),

                    const SizedBox(height: 32),

                    // 3. كارت المنصة
                    SlideAnimation(
                      delay: const Duration(milliseconds: 300),
                      child: _buildInfoCard(
                        title: 'عن منصة المراقب',
                        content:
                            'Almurakib.com هي منصة مالية رائدة تهدف لتبسيط البيانات المالية للمستثمر العربي، ومساعدته على اتخاذ قرارات استثمارية مدروسة.',
                        icon: Icons.language_rounded,
                        isPrimary: true,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 4. حقوق الملكية
                    const SlideAnimation(
                      delay: Duration(milliseconds: 400),
                      child: Center(
                        child: Text(
                          '© 2024 جميع الحقوق محفوظة لمنصة المراقب',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================= Info Card =======================
  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    bool isPrimary = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primaryBlue : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? AppColors.primaryBlue.withOpacity(0.3)
                : Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  color: isPrimary ? Colors.white : AppColors.primaryBlue,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isPrimary ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: isPrimary
                  ? Colors.white.withOpacity(0.9)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ======================= Features List (New) =======================
  Widget _buildFeaturesList() {
    // ✅ المميزات الـ 3 المطلوبة فقط
    final features = <_FeatureItem>[
      const _FeatureItem(
          icon: Icons.bolt_rounded,
          title: 'بيانات لحظية',
          desc:
              'نوفر أسعار الأسهم السعودية والمؤشرات بتحديثات مستمرة لحظة بلحظة لمساعدتك على اتخاذ قراراتك الاستثمارية.'),
      const _FeatureItem(
          icon: Icons.star_rounded,
          title: 'المفضلة',
          desc:
              'أضف الشركات التي تهمك إلى قائمة المفضلة وتابع أداءها بسهولة وسرعة من مكان واحد.'),
      const _FeatureItem(
          icon: Icons.security_rounded,
          title: 'الموثوقية',
          desc:
              'نعتمد على مصادر بيانات معتمدة ونلتزم بعرض معلومات شفافة ودقيقة لتعزيز ثقتك أثناء متابعة السوق.'),
    ];

    return Column(
      children: features.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16), // مسافة بين كل ميزة
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الأيقونة
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 22, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 16),
              // النصوص
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.desc,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13, // حجم خط مريح للقراءة
                        height: 1.5, // مسافة بين السطور
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ✅ ويدجت العنوان الموحد للأقسام (نفس المستخدمة في Home و MarketToday)
class _UnifiedSectionTitle extends StatelessWidget {
  final String title;
  const _UnifiedSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String desc;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.desc,
  });
}
