import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/currency_formatter.dart';
import '../models/goal_model.dart';
import '../screens/paywall_screen.dart';
import '../services/subscription_service.dart';

/// Modal bottom sheet providing smart deposit calculations and breakdown.
/// Premium-only feature with Freemium teaser barrier.
class SmartCalculatorSheet extends ConsumerStatefulWidget {
  final GoalModel goal;
  final ValueChanged<double>? onApplySuggestion;

  const SmartCalculatorSheet({
    super.key,
    required this.goal,
    this.onApplySuggestion,
  });

  static Future<void> show(
    BuildContext context, {
    required GoalModel goal,
    ValueChanged<double>? onApplySuggestion,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SmartCalculatorSheet(
        goal: goal,
        onApplySuggestion: onApplySuggestion,
      ),
    );
  }

  @override
  ConsumerState<SmartCalculatorSheet> createState() =>
      _SmartCalculatorSheetState();
}

class _SmartCalculatorSheetState extends ConsumerState<SmartCalculatorSheet> {
  int _targetMonths = 3; // 1, 3, 6, 12 months
  String _frequency = 'semanal'; // 'diario', 'semanal', 'mensal'

  double get _suggestedDeposit {
    final remaining = widget.goal.remainingAmount;
    if (remaining <= 0) return 0.0;

    final totalDays = _targetMonths * 30;
    switch (_frequency) {
      case 'diario':
        return remaining / totalDays;
      case 'semanal':
        final totalWeeks = (_targetMonths * 30) / 7;
        return remaining / (totalWeeks > 0 ? totalWeeks : 1);
      case 'mensal':
      default:
        return remaining / _targetMonths;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calculate_rounded, color: Color(0xFF6C63FF)),
                    SizedBox(width: 8),
                    Text(
                      'Calculadora Inteligente',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Planejamento automático para concluir sua meta no prazo',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 20),

            if (!isPremium) ...[
              // Free User Teaser
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.lock_clock_rounded,
                      color: Color(0xFF6C63FF),
                      size: 38,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Recurso Exclusivo Color Fund PRO',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'A Calculadora Inteligente divide automaticamente o saldo restante (${CurrencyFormatter.format(amount: widget.goal.remainingAmount, currencyCode: widget.goal.currency)}) em depósitos ideais.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const PaywallScreen()),
                          );
                        },
                        child: const Text(
                          'Desbloquear PRO',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Premium User Calculator Controls
              const Text(
                'Em quanto tempo quer alcançar?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _TimeChip(
                    label: '1 Mês',
                    selected: _targetMonths == 1,
                    onTap: () => setState(() => _targetMonths = 1),
                  ),
                  const SizedBox(width: 8),
                  _TimeChip(
                    label: '3 Meses',
                    selected: _targetMonths == 3,
                    onTap: () => setState(() => _targetMonths = 3),
                  ),
                  const SizedBox(width: 8),
                  _TimeChip(
                    label: '6 Meses',
                    selected: _targetMonths == 6,
                    onTap: () => setState(() => _targetMonths = 6),
                  ),
                  const SizedBox(width: 8),
                  _TimeChip(
                    label: '1 Ano',
                    selected: _targetMonths == 12,
                    onTap: () => setState(() => _targetMonths = 12),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              const Text(
                'Frequência de Depósito',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _FrequencyChip(
                    label: 'Diário',
                    selected: _frequency == 'diario',
                    onTap: () => setState(() => _frequency = 'diario'),
                  ),
                  const SizedBox(width: 8),
                  _FrequencyChip(
                    label: 'Semanal',
                    selected: _frequency == 'semanal',
                    onTap: () => setState(() => _frequency = 'semanal'),
                  ),
                  const SizedBox(width: 8),
                  _FrequencyChip(
                    label: 'Mensal',
                    selected: _frequency == 'mensal',
                    onTap: () => setState(() => _frequency = 'mensal'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Suggestion Result Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Depósito Sugerido',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(
                        amount: _suggestedDeposit,
                        currencyCode: widget.goal.currency,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'por ${_frequency == 'diario' ? 'dia' : _frequency == 'semanal' ? 'semana' : 'mês'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Apply Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    widget.onApplySuggestion?.call(_suggestedDeposit);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Aplicar Sugestão de Depósito',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF6C63FF).withOpacity(0.12)
                : Colors.grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF6C63FF) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? const Color(0xFF6C63FF) : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FrequencyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FrequencyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF6C63FF).withOpacity(0.12)
                : Colors.grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF6C63FF) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? const Color(0xFF6C63FF) : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
