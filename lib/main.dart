import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/utils/currency_formatter.dart';
import 'models/goal_model.dart';
import 'screens/auth_screen.dart';
import 'screens/create_goal_screen.dart';
import 'screens/paywall_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/subscription_service.dart';
import 'widgets/paintable_goal_widget.dart';
import 'widgets/smart_calculator_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load Environment Variables (.env)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found: $e");
  }

  // 2. Initialize Stripe SDK (if key configured)
  final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
  if (stripeKey != null && stripeKey.isNotEmpty) {
    Stripe.publishableKey = stripeKey;
    try {
      await Stripe.instance.applySettings();
    } catch (_) {}
  }

  // 3. Run App wrapped in Riverpod ProviderScope
  runApp(
    const ProviderScope(
      child: ColorFundApp(),
    ),
  );
}

class ColorFundApp extends StatelessWidget {
  const ColorFundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Fund',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

/// Dynamic gate directing authenticated users to Dashboard and guests to AuthScreen.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const ColorFundDashboard();
        }
        return const AuthScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
      ),
      error: (_, __) => const AuthScreen(),
    );
  }
}

class ColorFundDashboard extends ConsumerStatefulWidget {
  const ColorFundDashboard({super.key});

  @override
  ConsumerState<ColorFundDashboard> createState() => _ColorFundDashboardState();
}

class _ColorFundDashboardState extends ConsumerState<ColorFundDashboard> {
  int _selectedGoalIndex = 0;

  // Fallback demo goal if no goals yet
  GoalModel _getDemoGoal() {
    return GoalModel(
      id: 'demo_goal_1',
      title: 'Minha Primeira Conquista 🚀',
      targetAmount: 2000.0,
      savedAmount: 600.0,
      currency: 'BRL',
      layoutId: GoalLayoutTheme.basicJar.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _depositAmount(GoalModel goal, double amount) {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(firestoreServiceProvider).addDeposit(
            userId: user.uid,
            goalId: goal.id,
            depositAmount: amount,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final user = ref.watch(currentUserProvider);
    final goalsAsync = ref.watch(userGoalsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Color Fund',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        actions: [
          // PRO / FREE status pill
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: isPremium
                    ? const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      )
                    : null,
                color: isPremium ? null : Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPremium ? Icons.star_rounded : Icons.lock_outline_rounded,
                    size: 14,
                    color: isPremium ? Colors.black87 : Colors.grey[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isPremium ? 'PRO' : 'FREE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isPremium ? Colors.black87 : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova Meta', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          final goals = goalsAsync.value ?? [];
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateGoalScreen(currentGoalsCount: goals.length),
            ),
          );
        },
      ),
      body: goalsAsync.when(
        data: (goals) {
          final currentGoal = goals.isNotEmpty
              ? goals[_selectedGoalIndex.clamp(0, goals.length - 1)]
              : _getDemoGoal();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Goal switcher if multiple goals exist (Premium)
                  if (goals.length > 1) ...[
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: goals.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final g = goals[index];
                          final isSelected = index == _selectedGoalIndex;
                          return ChoiceChip(
                            label: Text(g.title),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedGoalIndex = index),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Title & Progress Summary
                  Text(
                    currentGoal.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${CurrencyFormatter.format(amount: currentGoal.savedAmount, currencyCode: currentGoal.currency)} de ${CurrencyFormatter.format(amount: currentGoal.targetAmount, currencyCode: currentGoal.currency)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Core Gamified Paintable Widget
                  PaintableGoalWidget(
                    goal: currentGoal,
                    onDepositTap: () => _depositAmount(currentGoal, 100.0),
                  ),

                  const SizedBox(height: 24),

                  // Smart Calculator Trigger Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                        color: const Color(0xFF6C63FF).withOpacity(0.4),
                      ),
                    ),
                    icon: const Icon(Icons.calculate_rounded,
                        color: Color(0xFF6C63FF)),
                    label: const Text(
                      'Calculadora Inteligente',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                    onPressed: () {
                      SmartCalculatorSheet.show(
                        context,
                        goal: currentGoal,
                        onApplySuggestion: (suggested) {
                          _depositAmount(currentGoal, suggested);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Quick Action Deposit Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _DepositButton(
                        label:
                            '+ ${CurrencyFormatter.formatCompact(amount: 25, currencyCode: currentGoal.currency)}',
                        onTap: () => _depositAmount(currentGoal, 25.0),
                      ),
                      const SizedBox(width: 10),
                      _DepositButton(
                        label:
                            '+ ${CurrencyFormatter.formatCompact(amount: 50, currencyCode: currentGoal.currency)}',
                        onTap: () => _depositAmount(currentGoal, 50.0),
                      ),
                      const SizedBox(width: 10),
                      _DepositButton(
                        label:
                            '+ ${CurrencyFormatter.formatCompact(amount: 100, currencyCode: currentGoal.currency)}',
                        isHighlighted: true,
                        onTap: () => _depositAmount(currentGoal, 100.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80), // Padding for FAB
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
        error: (e, _) => Center(
          child: Text('Erro ao carregar metas: $e'),
        ),
      ),
    );
  }
}

class _DepositButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _DepositButton({
    required this.label,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isHighlighted ? const Color(0xFF6C63FF) : Colors.white,
        foregroundColor: isHighlighted ? Colors.white : const Color(0xFF1E293B),
        elevation: isHighlighted ? 4 : 1,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isHighlighted
              ? BorderSide.none
              : BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
