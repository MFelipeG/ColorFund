import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/goal_model.dart';
import 'widgets/paintable_goal_widget.dart';
import 'core/utils/currency_formatter.dart';
import 'services/subscription_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load Environment Variables (.env)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found or failed to load: $e");
  }

  // 2. Initialize Stripe SDK (if key provided)
  final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
  if (stripeKey != null && stripeKey.isNotEmpty) {
    Stripe.publishableKey = stripeKey;
    await Stripe.instance.applySettings();
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
      home: const ColorFundHomeScreen(),
    );
  }
}

class ColorFundHomeScreen extends ConsumerStatefulWidget {
  const ColorFundHomeScreen({super.key});

  @override
  ConsumerState<ColorFundHomeScreen> createState() => _ColorFundHomeScreenState();
}

class _ColorFundHomeScreenState extends ConsumerState<ColorFundHomeScreen> {
  // Demo interactive goal state
  late GoalModel _currentGoal;

  @override
  void initState() {
    super.initState();
    _currentGoal = GoalModel(
      id: 'demo_goal_1',
      title: 'Viagem dos Sonhos ✈️',
      targetAmount: 5000.00,
      savedAmount: 1250.00,
      currency: 'BRL',
      layoutId: GoalLayoutTheme.basicJar.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _depositAmount(double amount) {
    setState(() {
      final newAmount = (_currentGoal.savedAmount + amount).clamp(
        0.0,
        _currentGoal.targetAmount,
      );
      _currentGoal = _currentGoal.copyWith(
        savedAmount: newAmount,
        updatedAt: DateTime.now(),
        isCompleted: newAmount >= _currentGoal.targetAmount,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Color Fund',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: isPremium
                  ? const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    )
                  : null,
              color: isPremium ? null : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPremium ? Icons.star_rounded : Icons.lock_outline_rounded,
                  size: 16,
                  color: isPremium ? Colors.black87 : Colors.grey[700],
                ),
                const SizedBox(width: 4),
                Text(
                  isPremium ? 'PRO' : 'FREE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPremium ? Colors.black87 : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _currentGoal.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${CurrencyFormatter.format(amount: _currentGoal.savedAmount, currencyCode: _currentGoal.currency)} de ${CurrencyFormatter.format(amount: _currentGoal.targetAmount, currencyCode: _currentGoal.currency)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Gamified Interactive Painter
              PaintableGoalWidget(
                goal: _currentGoal,
                onDepositTap: () => _depositAmount(250.0),
              ),

              const SizedBox(height: 28),

              // Quick Action Deposit Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DepositButton(
                    label: '+ ${CurrencyFormatter.formatCompact(amount: 50, currencyCode: _currentGoal.currency)}',
                    onTap: () => _depositAmount(50.0),
                  ),
                  const SizedBox(width: 12),
                  _DepositButton(
                    label: '+ ${CurrencyFormatter.formatCompact(amount: 100, currencyCode: _currentGoal.currency)}',
                    onTap: () => _depositAmount(100.0),
                  ),
                  const SizedBox(width: 12),
                  _DepositButton(
                    label: '+ ${CurrencyFormatter.formatCompact(amount: 250, currencyCode: _currentGoal.currency)}',
                    isHighlighted: true,
                    onTap: () => _depositAmount(250.0),
                  ),
                ],
              ),
            ],
          ),
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
