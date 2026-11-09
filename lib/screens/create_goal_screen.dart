import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/goal_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/subscription_service.dart';
import 'paywall_screen.dart';

class CreateGoalScreen extends ConsumerStatefulWidget {
  final int currentGoalsCount;

  const CreateGoalScreen({
    super.key,
    required this.currentGoalsCount,
  });

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();

  String _selectedCurrency = 'BRL';
  String _selectedLayoutId = GoalLayoutTheme.basicJar.id;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  void _onLayoutSelected(GoalLayoutTheme theme, bool isPremium) {
    if (theme.isPremium && !isPremium) {
      // User tapped on a locked Pro layout
      _openPaywall();
      return;
    }
    setState(() {
      _selectedLayoutId = theme.id;
    });
  }

  void _openPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final isPremium = ref.read(isPremiumProvider);
    final subscriptionService = ref.read(subscriptionServiceProvider);

    // Enforce Freemium quota barrier
    if (!subscriptionService.canCreateNewGoal(
      isPremium: isPremium,
      currentActiveGoalsCount: widget.currentGoalsCount,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Limite de 1 meta no plano Gratuito atingido. Faça upgrade para o PRO para criar metas ilimitadas!',
          ),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      _openPaywall();
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para salvar suas metas.')),
      );
      return;
    }

    final targetAmount = double.tryParse(
      _targetAmountController.text.replaceAll(',', '.'),
    );

    if (targetAmount == null || targetAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insira um valor válido maior que zero.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final newGoal = GoalModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        targetAmount: targetAmount,
        savedAmount: 0.0,
        currency: _selectedCurrency,
        layoutId: _selectedLayoutId,
        createdAt: now,
        updatedAt: now,
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createGoal(userId: user.uid, goal: newGoal);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎯 Nova meta criada com sucesso!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar meta: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final isQuotaExceeded = !isPremium && widget.currentGoalsCount >= 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Meta Financeira'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isQuotaExceeded) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_person_rounded,
                            color: Colors.amber.shade900),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Você já tem 1 meta ativa. Usuários PRO podem criar metas ilimitadas!',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _openPaywall,
                          child: const Text('PRO',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],

                // Goal Title Input
                const Text(
                  'Nome do Objetivo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  maxLength: 100,
                  decoration: InputDecoration(
                    hintText: 'Ex: Viagem de Férias, Reserva de Emergência...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Dê um nome para o seu objetivo'
                      : null,
                ),
                const SizedBox(height: 16),

                // Amount & Currency Row
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Valor Alvo',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _targetAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              hintText: '0,00',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Informe o valor';
                              final val = double.tryParse(v.replaceAll(',', '.'));
                              if (val == null || val <= 0) return 'Valor inválido';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Moeda',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedCurrency,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'BRL', child: Text('BRL (R\$)')),
                              DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                              DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCurrency = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Layout Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Escolha o Layout Visual',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (!isPremium)
                      GestureDetector(
                        onTap: _openPaywall,
                        child: const Text(
                          'Desbloquear PRO ⚡',
                          style: TextStyle(
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Horizontal list of layout choices
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: GoalLayoutTheme.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final theme = GoalLayoutTheme.values[index];
                      final isSelected = _selectedLayoutId == theme.id;
                      final isLocked = theme.isPremium && !isPremium;

                      return GestureDetector(
                        onTap: () => _onLayoutSelected(theme, isPremium),
                        child: Container(
                          width: 110,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6C63FF).withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6C63FF)
                                  : Colors.grey.withOpacity(0.2),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getThemeIcon(theme),
                                    size: 32,
                                    color: isSelected
                                        ? const Color(0xFF6C63FF)
                                        : Colors.grey[700],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    theme.label,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF6C63FF)
                                          : Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              if (isLocked)
                                const Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Icon(
                                    Icons.lock_rounded,
                                    size: 16,
                                    color: Color(0xFFE11D48),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 36),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Criar Meta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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

  IconData _getThemeIcon(GoalLayoutTheme theme) {
    switch (theme) {
      case GoalLayoutTheme.basicJar:
        return Icons.water_drop_outlined;
      case GoalLayoutTheme.interactiveCalendar:
        return Icons.calendar_month_rounded;
      case GoalLayoutTheme.techPiggy:
        return Icons.savings_rounded;
      case GoalLayoutTheme.spaceRocket:
        return Icons.rocket_launch_rounded;
      case GoalLayoutTheme.treasureChest:
        return Icons.inventory_2_rounded;
    }
  }
}
