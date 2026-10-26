import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/desktop_shell.dart';
import '../widgets/simple_markdown.dart';
import '../theme/app_colors.dart';

class EducationalResourcesScreen extends StatelessWidget {
  const EducationalResourcesScreen({super.key});

  static const List<Map<String, dynamic>> _articles = [
    {
      'title': 'Nutrition Basics & Macronutrients',
      'subtitle': 'Fundamentals of proteins, carbs, and healthy fats',
      'icon': Icons.restaurant_outlined,
      'readTime': '5 min read',
      'content': '''
# Understanding Macronutrients

Eating a balanced diet requires understanding the three primary macronutrients:

### 1. Proteins
* **Role**: Muscle repair, enzyme production, and immune health.
* **Good sources**: Chicken breast, eggs, tofu, Greek yogurt, lentils, and fish.
* **Target**: Aim for 1.2 to 2.0 grams per kilogram of body weight depending on your activity level.

### 2. Carbohydrates
* **Role**: The body's primary energy fuel, especially for brain and intense exercise.
* **Good sources**: Oats, sweet potatoes, brown rice, quinoa, berries, and whole wheat.
* **Tip**: Focus on complex carbohydrates rich in dietary fiber to keep blood sugar stable.

### 3. Healthy Fats
* **Role**: Hormone production, joint health, and nutrient absorption.
* **Good sources**: Avocados, extra virgin olive oil, almonds, walnuts, and chia seeds.
''',
    },
    {
      'title': 'Yoga & Mobility for Beginners',
      'subtitle': 'Essential stretches and posture alignment',
      'icon': Icons.self_improvement_outlined,
      'readTime': '4 min read',
      'content': '''
# Beginner Yoga & Daily Mobility

Incorporating 10–15 minutes of mobility daily improves flexibility and prevents injuries.

### Essential Poses:
1. **Child’s Pose (Balasana)**: Gently stretches hips, thighs, and ankles while calming the mind.
2. **Cat-Cow Stretch (Marjaryasana-Bitilasana)**: Warms up the spine and relieves lower back tension.
3. **Downward-Facing Dog (Adho Mukha Svanasana)**: Strengthens arms and legs while lengthening the hamstrings and calves.
4. **Warrior II (Virabhadrasana II)**: Builds stamina, strengthens leg muscles, and opens hips and chest.

### Breathing Tip:
Synchronize your breath with movement: inhale as you expand/open the chest, exhale as you fold or contract.
''',
    },
    {
      'title': 'Healthy High-Protein Recipes',
      'subtitle': 'Quick, delicious, and nutrient-dense meal ideas',
      'icon': Icons.menu_book_outlined,
      'readTime': '6 min read',
      'content': '''
# Quick & Nutritious Meal Ideas

### 1. Overnight Berry Protein Oats
* **Ingredients**: 50g rolled oats, 1 scoop protein powder, 150ml almond milk, 1 tbsp chia seeds, handful of fresh berries.
* **Preparation**: Mix oats, protein powder, and chia seeds with milk. Refrigerate overnight. Top with fresh berries before serving.
* **Nutritional Highlights**: ~32g Protein, 8g Fiber.

### 2. Grilled Mediterranean Chicken Bowl
* **Ingredients**: 150g grilled chicken breast, 1 cup cooked quinoa, cucumber, cherry tomatoes, olives, 1 tbsp olive oil, lemon juice.
* **Preparation**: Layer quinoa in bowl, top with sliced chicken and veggies. Drizzle with olive oil and lemon.
* **Nutritional Highlights**: ~42g Protein, 6g Fiber.

### 3. Tofu & Veggie Stir-Fry
* **Ingredients**: 200g firm tofu, broccoli florets, bell peppers, snap peas, low-sodium soy sauce, garlic, ginger.
* **Preparation**: Sauté cubed tofu until golden. Toss in veggies with garlic and ginger. Drizzle soy sauce and cook for 3 minutes.
* **Nutritional Highlights**: ~24g Protein, Plant-Based.
''',
    },
    {
      'title': 'Hydration, Sleep & Recovery',
      'subtitle': 'The pillars of sustained wellness and fitness progress',
      'icon': Icons.water_drop_outlined,
      'readTime': '4 min read',
      'content': '''
# Recovery: The Unsung Hero of Fitness

Your workout provides the stimulus, but real growth and fat loss happen during recovery.

### 1. Daily Hydration
* Drink at least 2.5 to 3.5 liters of water daily.
* Add electrolytes if training intensely or in warm environments.
* Monitor urine color: pale yellow indicates optimal hydration.

### 2. Sleep Architecture
* Aim for 7 to 9 hours of uninterrupted sleep every night.
* Turn off screens 30–60 minutes before bedtime.
* Keep your bedroom cool, dark, and quiet to support deep REM and slow-wave sleep.

### 3. Active Recovery
* Walk 20–30 minutes on rest days to promote blood circulation and reduce muscle soreness.
''',
    },
  ];

  void _openArticle(BuildContext context, Map<String, dynamic> article) {
    final isDark = ThemeService.instance.isDark(context);
    if (DesktopPaneScope.of(context)) return _openArticleDialog(context, article, isDark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.radiusXL)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border(isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.brandMuted(isDark),
                      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                    ),
                    child: Icon(
                      article['icon'] as IconData,
                      color: AppColors.brand(isDark),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article['title'] as String,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary(isDark),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          article['readTime'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted(isDark),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted(isDark)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Divider(
                height: 28,
                color: AppColors.border(isDark),
              ),
              SimpleMarkdown(text: article['content'] as String, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }

  // Articles read in a centred dialog at a comfortable line length.
  void _openArticleDialog(BuildContext context, Map<String, dynamic> article, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface(isDark),
        insetPadding: const EdgeInsets.all(40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 16, 8),
                child: Row(children: [
                  Expanded(
                    child: Text(article['readTime'] as String,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark))),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: Icon(Icons.close_rounded, color: AppColors.textSecondary(isDark)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ]),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: SimpleMarkdown(text: article['content'] as String, isDark: isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          PaneToolbar(title: 'Educational library', subtitle: '${_articles.length} articles'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: LayoutBuilder(builder: (context, constraints) {
              final columns = (constraints.maxWidth / 300).floor().clamp(1, 4);
              final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final article in _articles)
                    SizedBox(width: width, child: _articleCard(context, article, isDark)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _articleCard(BuildContext context, Map<String, dynamic> article, bool isDark) {
    return Material(
      color: AppColors.surface(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        side: BorderSide(color: AppColors.border(isDark)),
      ),
      child: InkWell(
        onTap: () => _openArticle(context, article),
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandMuted(isDark),
                  borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                ),
                child: Icon(article['icon'] as IconData, color: AppColors.brand(isDark), size: 22),
              ),
              const SizedBox(height: 16),
              Text(article['title'] as String,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark))),
              const SizedBox(height: 4),
              Text(article['subtitle'] as String,
                  style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary(isDark))),
              const SizedBox(height: 12),
              Text(article['readTime'] as String,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.brand(isDark))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark(context);

        if (DesktopPaneScope.of(context)) return _buildDesktop(context, isDark);

        return Scaffold(
          backgroundColor: AppColors.bg(isDark),
          appBar: AppBar(
            title: Text(
              "Educational Resources",
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            actions: [
              ThemeToggleButton(color: AppColors.textSecondary(isDark)),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: _articles.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.border(isDark)),
                itemBuilder: (context, index) {
                  final article = _articles[index];
                  return InkWell(
                    onTap: () => _openArticle(context, article),
                    borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.brandMuted(isDark),
                              borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                            ),
                            child: Icon(
                              article['icon'] as IconData,
                              color: AppColors.brand(isDark),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  article['title'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: AppColors.textPrimary(isDark),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${article['subtitle']} • ${article['readTime']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary(isDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.textMuted(isDark),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
