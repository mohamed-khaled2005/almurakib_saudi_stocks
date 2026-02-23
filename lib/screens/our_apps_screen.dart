import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/utils/constants.dart';
import '../animations/fade_animation.dart';
import '../animations/slide_animation.dart';
import '../widgets/tab_page_header.dart';

BoxDecoration buildCardDecoration({
  bool withShadow = true,
  Border? border,
  Color? color,
  double radius = 22,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: border ??
        Border.all(
          color: AppColors.border,
        ),
    boxShadow: withShadow
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0.2,
              offset: const Offset(0, 4),
            ),
          ]
        : <BoxShadow>[],
  );
}

class OurAppsScreen extends StatefulWidget {
  const OurAppsScreen({super.key});

  @override
  State<OurAppsScreen> createState() => _OurAppsScreenState();
}

class _OurAppsScreenState extends State<OurAppsScreen> {
  final List<_AppItem> _apps = const <_AppItem>[
    _AppItem(
      name: 'مراقب الاسهم المصرية',
      storeUrl:
          'https://play.google.com/store/apps/details?id=com.almurakib.egyptappstocks',
      imageUrl:
          'https://play-lh.googleusercontent.com/wVGNy3MT-L2zpkFHF_F9SCgjd8rEeJuK4OMNAeSDn8kRr_t2TMgwfl3ZWdtW1TNQJrclkEFvxIOYM7LjEEaICg=w480-h960-rw',
    ),
    _AppItem(
      name: 'مراقب الفضة',
      storeUrl:
          'https://play.google.com/store/apps/details?id=com.almurakib.silvermonitor',
      imageUrl:
          'https://play-lh.googleusercontent.com/yLohp0qB8efPmZnr4eUlNtrUUboyV7qXcm9aRWoFSM0n7-Zeb9Br4GhuHiGZSI_6flWXOqu9Vn6VT36mLfUp=w480-h960-rw',
    ),
    _AppItem(
      name: 'مراقب البيتكوين',
      storeUrl:
          'https://play.google.com/store/apps/details?id=com.almurakib.bitcoin',
      imageUrl:
          'https://play-lh.googleusercontent.com/xHhXxlevam5VlaSwJ7mR4dNiWilSR53b-AvSPqAmQlOB_0Id8kT6KjqDsCbumj41sSx7e37CCwS8IiAm6Vr41A=w480-h960-rw',
    ),
    _AppItem(
      name: 'مراقب الأسهم الأمريكية',
      storeUrl:
          'https://play.google.com/store/apps/details?id=com.almurakib.usaappstocks',
      imageUrl:
          'https://play-lh.googleusercontent.com/wqDKcI9Pga22rkZNzxssaiU7qVlk-36bd1EKHXV-greisW7XcQuqjdCBcm17QZVP8mgKs_-uwyvBgo6YXzRh2us=w480-h960-rw',
    ),
    _AppItem(
      name: 'مراقب الأسهم القطرية',
      storeUrl:
          'https://play.google.com/store/apps/details?id=com.almurakib.qatarappstocks',
      imageUrl:
          'https://play-lh.googleusercontent.com/rN4Htz4G-T7Y-5nVODMGNmmPE1vNRNsFBPQOlgYXp4-kwZMfrSKx-a0h-vRtMS9b19cx54Cfu_Y3psiVDXZ9XA4=w480-h960-rw',
    ),
    _AppItem(
      name: 'مراقب الاسهم الاماراتية',
      storeUrl:
          'https://play.google.com/store/apps/details?id=com.almurakib.emiratesappstocks',
      imageUrl:
          'https://play-lh.googleusercontent.com/ndvDmG-MD_KFP1ejcUg7hfsQOZh52okON9TeHVYg5WtjE5iUy6vbJfaaosQ5zEIx0RO3t4ac_uBCxzPDWNL7Qg=w480-h960-rw',
    ),
    _AppItem(
      name: 'مراقب الاسهم السعودية',
      storeUrl:
          'https://play.google.com/store/apps/details?id=com.almurakib.saudiappstocks',
      imageUrl:
          'https://play-lh.googleusercontent.com/mgW7dsDFDi8_fgwuFyUmgdzxGBnva3vDqDcwAvN7lRCK2-QzA1hhjiwk_wuR6z0n3xYfxCvhfUQf5rySXlPj=w480-h960-rw',
    ),
    _AppItem(
      name: 'مراقب الذهب',
      storeUrl:
          'https://play.google.com/store/apps/details?id=com.almurakib.goldmonitor',
      imageUrl:
          'https://play-lh.googleusercontent.com/gEft1mhy5KD6GwMC9P6Ge-zJLb2fB72BIOmDmxfzB3rSETTix2wT4lEydIhSaZKLztjHiAQIkTbTYNWmCRK8VA=w480-h960-rw',
    ),
    _AppItem(
      name: 'مراقب العملات',
      storeUrl:
          'https://play.google.com/store/apps/details?id=com.almurakib.currencyexchange.app',
      imageUrl:
          'https://play-lh.googleusercontent.com/BKkuz_2ZP_NG_KbfvBVpvebAYtPONoMpe5uLgzV_nFh8_9kjgL-4pC0WUk5sAuNlcBfUaJ4HilQGJO3o55iGxA=w480-h960-rw',
    ),
    _AppItem(
      name: 'مراقب الكريبتو',
      storeUrl:
          'https://play.google.com/store/apps/details?id=com.almurakib.cryptomonitor',
      imageUrl:
          'https://play-lh.googleusercontent.com/U4gMdj8FrCjKBT6n3Dw_7MpYnJCnvGISNPSkOw8leGaGkqiQ9ku5SM7uRJVT946DPP3IZqfOZmjAKlV2__cD-w=w480-h960-rw',
    ),
  ];

  TextStyle _paragraphStyle({Color? color}) {
    return AppTextStyles.bodySmall.copyWith(
      color: color ?? AppColors.textPrimary,
      fontWeight: FontWeight.w500,
      height: 1.55,
      letterSpacing: 0.05,
    );
  }

  Future<void> _openStore(String url) async {
    final Uri uri = Uri.parse(url);
    final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط الآن')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        top: false,
        child: FadeAnimation(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const TabPageHeaderBlock(title: 'تطبيقاتنا'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SlideAnimation(child: _buildHeaderCard()),
                        const SizedBox(height: 16),
                        SlideAnimation(
                          delay: const Duration(milliseconds: 160),
                          child: _buildAppsGrid(),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: buildCardDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        radius: 22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.25),
                width: 0.9,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.store_rounded,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  'Google Play',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: AppColors.primaryBlue,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'تطبيقات المراقب',
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'يسرنا أن نقدم لكم مجموعة تطبيقاتنا الرسمية، اضغط على التطبيق للانتقال لصفحة التحميل على متجر جوجل.',
            style: _paragraphStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAppsGrid() {
    if (_apps.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: buildCardDecoration(color: AppColors.cardDark),
        child: Text(
          'لا توجد تطبيقات للعرض حالياً.',
          style: _paragraphStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const int crossAxisCount = 2;
        final double aspect = constraints.maxWidth >= 520 ? 1.25 : 1.10;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _apps.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspect,
          ),
          itemBuilder: (context, index) {
            final item = _apps[index];
            return _MiniAppTile(
              item: item,
              onTap: () => _openStore(item.storeUrl),
            );
          },
        );
      },
    );
  }
}

class _AppItem {
  final String name;
  final String storeUrl;
  final String imageUrl;

  const _AppItem({
    required this.name,
    required this.storeUrl,
    required this.imageUrl,
  });
}

class _MiniAppTile extends StatelessWidget {
  const _MiniAppTile({required this.item, required this.onTap});

  final _AppItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: buildCardDecoration(
        color: Colors.white,
        radius: 18,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _AppIcon(url: item.imageUrl),
                  const SizedBox(height: 10),
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      height: 1.15,
                      letterSpacing: 0.1,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => const Icon(
            Icons.apps_outlined,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
