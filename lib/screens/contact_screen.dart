import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/utils/constants.dart';
import '../animations/fade_animation.dart';
import '../animations/slide_animation.dart';
import '../widgets/tab_page_header.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const String _websiteUrl = 'https://almurakib.com';
  static const String _email = 'info@almurakib.com';
  static const String _phone = '+3197010284689';
  static const String _whatsAppNumber = '3197010284689';
  static const String _telegramUrl = 'https://t.me/Almurakib';

  // =========================
  // ✅ سياسة الخصوصية (كاملة)
  // =========================
  static const String _privacyPolicyText = '''
نحن في تطبيق "مراقب الأسهم السعودية" (التابع لمنصة المراقب almurakib.com) نحترم خصوصيتك ونسعى لحماية بياناتك وفق أفضل الممارسات.

المعلومات التي قد نقوم بجمعها
قد يقوم التطبيق بجمع أنواع محدودة من البيانات بهدف تحسين الخدمة، وتشمل:
• معلومات الاستخدام العامة داخل التطبيق (مثل الصفحات التي تفتحها والأحداث العامة داخل الواجهة).
• بيانات الجهاز (نوع الجهاز، إصدار النظام، لغة الجهاز) لأغراض التوافق وحل المشاكل.
• بيانات تحليلية مجهولة (Anonymous Analytics) لتحسين الأداء وتجربة المستخدم.

ملاحظات مهمة
• لا يطلب التطبيق منك إنشاء حساب.
• لا يجمع التطبيق بشكل افتراضي بيانات تعريف شخصية حساسة مثل الاسم أو العنوان أو الموقع الجغرافي الدقيق.
• عند تواصلك معنا طوعاً عبر البريد الإلكتروني أو الواتساب، قد يتم استخدام بيانات التواصل التي ترسلها أنت فقط للرد على استفسارك.

كيفية استخدام المعلومات
نستخدم البيانات فقط من أجل:
• تحسين تجربة المستخدم.
• تطوير ميزات التطبيق.
• تحليل الأداء وحل المشاكل التقنية.
• حماية الخدمة ومنع إساءة الاستخدام عند الحاجة.

مشاركة البيانات مع أطراف ثالثة
لا نقوم ببيع بيانات المستخدم. قد تتم مشاركة بيانات تقنية محدودة (غير تعريفية) مع مزودي خدمات التحليلات/الأعطال أو مزودي البنية التحتية فقط عند الضرورة التشغيلية أو وفقاً للقانون.

الروابط الخارجية
قد يحتوي التطبيق على روابط لموقع المراقب أو منصات خارجية. استخدامك لتلك الروابط يخضع لسياسات الجهات الخارجية.

حماية البيانات
نعتمد إجراءات تقنية وتنظيمية للمحافظة على أمان المعلومات وتقليل مخاطر الوصول غير المصرح به.

التعديلات على سياسة الخصوصية
قد نقوم بتحديث هذه السياسة من وقت لآخر، وسيتم نشر النسخة المحدّثة داخل التطبيق.

باستخدامك للتطبيق فإنك توافق على سياسة الخصوصية هذه.
''';

  // =========================
  // ✅ إخلاء المسؤولية (كاملة)
  // =========================
  static const String _disclaimerText = '''
تطبيق "مراقب الأسهم السعودية" يوفّر بيانات الأسهم والمؤشرات لأغراض معلوماتية فقط، ولا يضمن دقّتها بنسبة 100% في جميع الأوقات.

مصدر البيانات
يتم جمع البيانات من مزوّدي بيانات خارجيين عبر واجهات برمجية (APIs)، وقد تتغير القيم دون إشعار مسبق نتيجة:
• تقلبات السوق.
• تأخر التحديث أو انقطاع الاتصال.
• اختلاف مصادر التسعير بين المزودين.
• فروقات بين السعر المعروض في التطبيق والسعر لدى منصات التداول/الجهات الرسمية.

لا يُعدّ التطبيق استشارة مالية
المحتوى المعروض لا يُعدّ توصية أو استشارة مالية أو دعوة للشراء/البيع/التداول. يُنصح المستخدم دائماً بالتحقق من الأسعار من مصادر رسمية قبل اتخاذ أي قرار.

حدود المسؤولية
لا يتحمل التطبيق أو موقع المراقب أي مسؤولية عن:
• أي خسائر مالية أو قرارات يتم اتخاذها اعتماداً على المعلومات المعروضة.
• تأخر أو انقطاع في عرض البيانات أو عدم توفرها.
• اختلاف البيانات بين التطبيق والأسواق الفعلية أو مزودي الخدمة.
• أي أضرار مباشرة أو غير مباشرة ناتجة عن استخدام التطبيق.

باستخدامك للتطبيق فإنك تقر بأن استخدامك يتم على مسؤوليتك الشخصية.
''';

  // =========================
  // ✅ الشروط والأحكام (كاملة)
  // =========================
  static const String _termsText = '''
يرجى قراءة هذه الشروط بعناية قبل استخدام تطبيق "مراقب الأسهم السعودية". استخدامك للتطبيق يعني موافقتك الكاملة على جميع الشروط أدناه وعلى السياسات المرتبطة بها مثل سياسة الخصوصية وإخلاء المسؤولية.

1. قبول الشروط
باستخدام التطبيق، أنت توافق على الالتزام بهذه الشروط وأي تحديثات مستقبلية لها.

2. استخدام التطبيق
• يهدف التطبيق لتوفير معلومات عن الأسهم والمؤشرات فقط، ولا يُعدّ أداة تداول أو محفظة أو منصة استثمار.
• يُحظر استخدام التطبيق لأي نشاط غير قانوني أو يضر بالخدمة أو بالمستخدمين الآخرين.
• قد نقوم بإيقاف أو تعديل الخدمة أو بعض الميزات دون إشعار مسبق لأسباب تقنية أو تشغيلية.

3. الملكية الفكرية
جميع المحتويات والبيانات والتصاميم داخل التطبيق تعود للجهة المالكة/موقع المراقب، ولا يجوز إعادة استخدامها أو نسخها دون إذن خطي.

4. دقة البيانات
رغم سعينا لتوفير بيانات دقيقة ومحدثة، قد تظهر فروقات أو تأخر. لا نتحمل مسؤولية أي قرارات مالية تعتمد على البيانات داخل التطبيق.

5. تحديثات التطبيق
قد نقوم بتحديث التطبيق وتحسينه بشكل دوري. قد تتغير بعض الميزات أو تختفي دون إشعار مسبق.

6. حدود المسؤولية
لا يتحمل التطبيق أو موقع المراقب أي خسائر ناتجة عن:
• الاعتماد على أسعار أو بيانات غير محدثة.
• توقف الخدمة أو حدوث أعطال تقنية أو انقطاع من مزود البيانات.
• سوء استخدام التطبيق من قبل المستخدم.

7. إنهاء الاستخدام
يحق لنا إنهاء أو تعليق وصول المستخدم للتطبيق في حال مخالفة الشروط أو إساءة استخدام الخدمة.

8. القانون المُطبق
تخضع هذه الشروط للقوانين واللوائح المعمول بها لدى الجهة المالكة، وأي نزاعات تُحل وفق الإجراءات القانونية المعتمدة.

باستخدامك للتطبيق، فإنك تؤكد موافقتك على هذه الشروط والأحكام.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        top: false,
        child: FadeAnimation(
          child: Column(
            children: [
              const TabPageHeaderBlock(title: 'التواصل والدعم'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    SlideAnimation(child: _buildCompanyCard()),
                    const SizedBox(height: 32),
                    const SlideAnimation(
                      delay: Duration(milliseconds: 100),
                      child: _UnifiedSectionTitle(title: "قنوات التواصل"),
                    ),
                    const SizedBox(height: 16),
                    SlideAnimation(
                      delay: const Duration(milliseconds: 150),
                      child: _buildContactInfo(),
                    ),
                    const SizedBox(height: 24),
                    SlideAnimation(
                      delay: const Duration(milliseconds: 200),
                      child: _buildWhatsAppButton(),
                    ),
                    const SizedBox(height: 12),
                    SlideAnimation(
                      delay: const Duration(milliseconds: 225),
                      child: _buildTelegramButton(),
                    ),
                    const SizedBox(height: 32),
                    const SlideAnimation(
                      delay: Duration(milliseconds: 250),
                      child: _UnifiedSectionTitle(title: "المعلومات القانونية"),
                    ),
                    const SizedBox(height: 16),
                    SlideAnimation(
                      delay: const Duration(milliseconds: 300),
                      child: _buildLegalSection(context),
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

  Widget _buildCompanyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.business_rounded,
                    color: AppColors.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'شركة وموقع المراقب',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'شركة رسمية مرخصة في دولة بيليز تحت اسم (Almurakib LLC).',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تطبيق "مراقب الأسهم السعودية" هو أحد منتجات منصة المراقب لتسهيل متابعة السوق السعودي بشكل مبسّط وواضح.',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    final items = <_ContactItem>[
      _ContactItem(
        icon: Icons.language_rounded,
        title: 'الموقع الإلكتروني',
        value: _websiteUrl,
        ltr: true,
        onTap: () => _launchUrl(Uri.parse(_websiteUrl)),
      ),
      _ContactItem(
        icon: Icons.email_outlined,
        title: 'البريد الإلكتروني',
        value: _email,
        ltr: true,
        onTap: () => _launchUrl(Uri(scheme: 'mailto', path: _email)),
      ),
      _ContactItem(
        icon: Icons.phone_android_rounded,
        title: 'رقم الهاتف',
        value: _phone,
        ltr: true,
        onTap: () => _launchUrl(Uri(scheme: 'tel', path: _phone)),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;
          return _buildListTile(
            title: item.title,
            subtitle: item.value,
            icon: item.icon,
            onTap: item.onTap,
            showDivider: !isLast,
            ltr: item.ltr,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWhatsAppButton() {
    final waUri = Uri.parse('https://wa.me/$_whatsAppNumber');
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => _launchUrl(waUri),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0xFF25D366).withOpacity(0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 22),
        label: const Text(
          'تواصل معنا عبر واتساب',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTelegramButton() {
    final tgUri = Uri.parse(_telegramUrl);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => _launchUrl(tgUri),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF229ED9),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0xFF229ED9).withOpacity(0.35),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.send_rounded, size: 22),
        label: const Text(
          'تواصل معنا عبر تيليجرام',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    final items = [
      {
        'title': 'إخلاء المسؤولية',
        'icon': Icons.warning_amber_rounded,
        'content': _disclaimerText
      },
      {
        'title': 'سياسة الخصوصية',
        'icon': Icons.privacy_tip_outlined,
        'content': _privacyPolicyText
      },
      {
        'title': 'الشروط والأحكام',
        'icon': Icons.gavel_rounded,
        'content': _termsText
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;
          return _buildListTile(
            title: item['title'] as String,
            icon: item['icon'] as IconData,
            onTap: () => _showPolicySheet(
              context: context,
              title: item['title'] as String,
              content: item['content'] as String,
            ),
            showDivider: !isLast,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? subtitle,
    bool showDivider = true,
    bool ltr = false,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            textDirection:
                                ltr ? TextDirection.ltr : TextDirection.rtl,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Color(0xFFDDDDDD)),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
              height: 1,
              thickness: 1,
              indent: 60,
              endIndent: 20,
              color: Color(0xFFF5F5F5)),
      ],
    );
  }

  void _showPolicySheet({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    const Icon(Icons.article_rounded,
                        color: AppColors.primaryBlue),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      height: 1.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _launchUrl(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $uri');
    }
  }
}

// ✅ ويدجت العنوان الموحد للأقسام
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

class _ContactItem {
  final IconData icon;
  final String title;
  final String value;
  final bool ltr;
  final VoidCallback onTap;

  _ContactItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.ltr = false,
  });
}
