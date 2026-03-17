import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../animations/fade_animation.dart';
import '../animations/slide_animation.dart';
import '../core/utils/constants.dart';
import '../core/utils/responsive.dart';
import '../models/educational_article_model.dart';
import '../providers/app_manager_provider.dart';
import '../widgets/tab_page_header.dart';

const String _kEducationTitle = 'المحتوى التعليمي';
const String _kEducationSubtitle =
    'دروس ومقالات مبسطة تساعدك على فهم السوق السعودي وقراءة الفرص بصورة أوضح.';
const String _kNoEducationContent =
    'لا يوجد محتوى تعليمي متاح حاليًا. جرّب التحديث بعد قليل.';
const String _kFeaturedBadge = 'محتوى مميز';
const String _kLessonBadge = 'درس تعليمي';
const String _kOpenContentHint =
    'افتح المحتوى لقراءة التفاصيل الكاملة والاستفادة من الشرح المبسط.';
const String _kStartReading = 'ابدأ القراءة';
const String _kLoadContentError = 'تعذر تحميل المحتوى.';
const String _kNoBodyText = 'لا يوجد نص متاح لهذا المحتوى.';

class EducationalContentScreen extends StatefulWidget {
  const EducationalContentScreen({super.key});

  @override
  State<EducationalContentScreen> createState() =>
      _EducationalContentScreenState();
}

class _EducationalContentScreenState extends State<EducationalContentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppManagerProvider>().refreshEducationalContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AppManagerProvider>();
    final items = manager.articles;

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
                const TabPageHeaderBlock(
                  title: _kEducationTitle,
                  subtitle: _kEducationSubtitle,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: manager.refreshEducationalContent,
                    color: AppColors.primaryBlue,
                    backgroundColor: Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SlideAnimation(
                            child: _EducationIntroCard(),
                          ),
                          const SizedBox(height: 16),
                          if (items.isEmpty)
                            const SlideAnimation(
                              delay: Duration(milliseconds: 120),
                              child: _EmptyEducationalState(),
                            )
                          else
                            SlideAnimation(
                              delay: const Duration(milliseconds: 120),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth >= 760;
                                  final spacing = isWide ? 14.0 : 0.0;
                                  final cardWidth = isWide
                                      ? (constraints.maxWidth - spacing) / 2
                                      : constraints.maxWidth;

                                  return Wrap(
                                    spacing: spacing,
                                    runSpacing: 14,
                                    children: items
                                        .map(
                                          (article) => SizedBox(
                                            width: cardWidth,
                                            child: _LearningModuleCard(
                                              article: article,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 10),
                        ],
                      ),
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
}

class _EducationIntroCard extends StatelessWidget {
  const _EducationIntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 0.2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.25),
                width: 0.9,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.auto_stories_rounded,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  'دروس ومقالات',
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
            _kEducationTitle,
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _kEducationSubtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEducationalState extends StatelessWidget {
  const _EmptyEducationalState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 0.2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.primaryBlue,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _kNoEducationContent,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningModuleCard extends StatelessWidget {
  const _LearningModuleCard({required this.article});

  final EducationalArticleSummary article;

  @override
  Widget build(BuildContext context) {
    final category = article.category?.trim() ?? '';
    final badgeText = category.isNotEmpty
        ? category
        : (article.isFeatured ? _kFeaturedBadge : _kLessonBadge);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EducationalArticleDetailsScreen(slug: article.slug),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 0.2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(21)),
                child: SizedBox(
                  height: 176,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      if (article.coverImageUrl != null &&
                          article.coverImageUrl!.isNotEmpty)
                        Image.network(
                          article.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderCover(),
                        )
                      else
                        _placeholderCover(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.62),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _BadgeChip(
                          text: badgeText,
                          backgroundColor: article.isFeatured
                              ? AppColors.primaryBlue.withValues(alpha: 0.94)
                              : Colors.white.withValues(alpha: 0.90),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _MetaPill(
                          icon: Icons.schedule_rounded,
                          text: '${article.readingMinutes} دقائق',
                        ),
                        if (category.isNotEmpty)
                          _MetaPill(
                            icon: Icons.sell_outlined,
                            text: category,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSmall.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.excerpt.trim().isEmpty
                          ? _kOpenContentHint
                          : article.excerpt,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.arrow_back_rounded,
                          size: 18,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _kStartReading,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w900,
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
    );
  }

  Widget _placeholderCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF028800), Color(0xFF015700)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.school_rounded,
          color: Colors.white,
          size: 34,
        ),
      ),
    );
  }
}

class EducationalArticleDetailsScreen extends StatefulWidget {
  const EducationalArticleDetailsScreen({
    super.key,
    required this.slug,
  });

  final String slug;

  @override
  State<EducationalArticleDetailsScreen> createState() =>
      _EducationalArticleDetailsScreenState();
}

class _EducationalArticleDetailsScreenState
    extends State<EducationalArticleDetailsScreen> {
  EducationalArticleDetail? _article;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final manager = context.read<AppManagerProvider>();
    final article = await manager.getEducationalArticleDetail(widget.slug);
    if (!mounted) return;
    setState(() {
      _article = article;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.primaryBlue,
        title: const Text(
          _kEducationTitle,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w900,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : _article == null
              ? Center(
                  child: Text(
                    _kLoadContentError,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView(
                  padding: Responsive.responsivePadding(context),
                  children: <Widget>[
                    _DetailsHero(article: _article!),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            spreadRadius: 0.2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _MetaPill(
                                icon: Icons.schedule_rounded,
                                text: '${_article!.readingMinutes} دقائق',
                              ),
                              if ((_article!.category ?? '').trim().isNotEmpty)
                                _MetaPill(
                                  icon: Icons.sell_outlined,
                                  text: _article!.category!.trim(),
                                ),
                              if (_article!.isFeatured)
                                const _MetaPill(
                                  icon: Icons.star_rounded,
                                  text: _kFeaturedBadge,
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ..._buildBodyParagraphs(
                            body: _article!.body,
                            title: _article!.title,
                            excerpt: _article!.excerpt,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
    );
  }

  List<Widget> _buildBodyParagraphs({
    required String body,
    String? title,
    String? excerpt,
  }) {
    final cleaned = body.trim();
    if (cleaned.isEmpty) {
      return const <Widget>[
        Text(
          _kNoBodyText,
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: AppColors.textSecondary,
            height: 1.8,
          ),
        ),
      ];
    }

    final sourceParagraphs = cleaned
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (sourceParagraphs.isEmpty) {
      sourceParagraphs.add(cleaned);
    }

    final blocked = <String>{
      _normalizeForCompare(title),
      _normalizeForCompare(excerpt),
    }..removeWhere((value) => value.isEmpty);

    final seen = <String>{};
    final paragraphs = <String>[];

    for (final text in sourceParagraphs) {
      final normalized = _normalizeForCompare(text);
      if (normalized.isEmpty) continue;
      if (blocked.contains(normalized)) continue;
      if (seen.contains(normalized)) continue;
      seen.add(normalized);
      paragraphs.add(text);
    }

    if (paragraphs.isEmpty && cleaned.isNotEmpty) {
      paragraphs.add(cleaned);
    }

    return paragraphs
        .map(
          (text) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15.5,
                height: 1.95,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        )
        .toList();
  }

  String _normalizeForCompare(String? value) {
    if (value == null) return '';
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F]'), '')
        .replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '')
        .trim();
  }
}

class _DetailsHero extends StatelessWidget {
  const _DetailsHero({required this.article});

  final EducationalArticleDetail article;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 0.2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (article.coverImageUrl != null &&
                  article.coverImageUrl!.isNotEmpty)
                Image.network(
                  article.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _heroFallback(),
                )
              else
                _heroFallback(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.76),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (article.isFeatured)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            _kFeaturedBadge,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Text(
                        article.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF028800), Color(0xFF015700)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_stories_rounded,
          color: Colors.white70,
          size: 42,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppColors.primaryBlue),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: foregroundColor,
        ),
      ),
    );
  }
}
