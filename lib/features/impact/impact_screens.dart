import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';

class ImpactScreen extends StatefulWidget {
  const ImpactScreen({super.key});

  @override
  State<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends State<ImpactScreen> {
  int _range = 6;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final u = s.user!;
    final t = Theme.of(context).textTheme;
    final baseline = s.baseline;
    final entries = s.footprints.where((f) => !f.isBaseline).toList();
    final latest = entries.isEmpty ? baseline : entries.last;

    return Scaffold(
      appBar: AppBar(title: const Text('Your impact')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/impact/add-month'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add month'),
      ),
      body: baseline == null
          ? EmptyState(
              icon: Icons.insights_rounded,
              title: 'Your journey starts here',
              body: "Add this month's units to see your progress",
              actionLabel: 'Add month',
              onAction: () => context.push('/impact/add-month'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.co2_rounded,
                        value: Fmt.kg(latest!.co2Kg, decimals: 0),
                        label: entries.isEmpty ? 'Baseline' : 'This month',
                        dense: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        icon: latest.percentChange <= 0
                            ? Icons.trending_down_rounded
                            : Icons.trending_up_rounded,
                        iconColor: latest.percentChange <= 0
                            ? AppColors.success
                            : AppColors.warning,
                        value: entries.isEmpty
                            ? '—'
                            : '${latest.percentChange <= 0 ? '▼' : '▲'} ${latest.percentChange.abs().toStringAsFixed(0)}%',
                        label: 'vs your baseline',
                        dense: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            ProgressRing(
                              value: _goalProgress(u, baseline, latest),
                              size: 56,
                              stroke: 6,
                              child: Text(
                                  '${(_goalProgress(u, baseline, latest) * 100).round()}%',
                                  style: t.labelMedium?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(height: 6),
                            Text('Goal −${u.goalPercent}%',
                                style: t.labelSmall,
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text('Footprint trend',
                                  style: t.titleMedium)),
                          for (final r in [3, 6, 12])
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: ChoiceChip(
                                label: Text('${r}M'),
                                selected: _range == r,
                                onSelected: (_) => setState(() => _range = r),
                                visualDensity: VisualDensity.compact,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _LegendDot(
                              color: AppColors.textTertiary,
                              label: 'Baseline',
                              dashed: true),
                          const SizedBox(width: 14),
                          const _LegendDot(
                              color: AppColors.primary, label: 'Actual'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                          height: 190,
                          child: _TrendChart(
                              baseline: baseline,
                              entries: entries,
                              months: _range)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Breakdown', style: t.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 130,
                            height: 130,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 36,
                                sections: [
                                  PieChartSectionData(
                                      value: latest.electricityKg,
                                      color: AppColors.secondary,
                                      radius: 26,
                                      showTitle: false),
                                  PieChartSectionData(
                                      value: latest.cookingKg,
                                      color: AppColors.primary,
                                      radius: 26,
                                      showTitle: false),
                                  PieChartSectionData(
                                      value: math.max(latest.transportKg, 0.01),
                                      color: AppColors.tertiary,
                                      radius: 26,
                                      showTitle: false),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _BreakRow(
                                    color: AppColors.secondary,
                                    label: 'Electricity',
                                    kg: latest.electricityKg,
                                    total: latest.co2Kg),
                                _BreakRow(
                                    color: AppColors.primary,
                                    label: 'Cooking',
                                    kg: latest.cookingKg,
                                    total: latest.co2Kg),
                                _BreakRow(
                                    color: AppColors.tertiary,
                                    label: 'Transport',
                                    kg: latest.transportKg,
                                    total: latest.co2Kg),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  gradient: AppColors.heroGreen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total saved so far',
                          style: t.titleMedium?.copyWith(color: Colors.white)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _TotalStat(
                              value: Fmt.int(s.totalUnitsSaved),
                              label: 'units'),
                          _TotalStat(
                              value: Fmt.rupees(s.totalRupeesSaved),
                              label: 'saved'),
                          _TotalStat(
                              value: Fmt.kg(s.totalCo2Saved, decimals: 0),
                              label: 'CO₂'),
                          _TotalStat(
                              value: (s.totalCo2Saved * 12 / 20 / 12)
                                  .toStringAsFixed(1),
                              label: 'trees / yr'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SectionHeader(
                    title: 'Monthly entries',
                    subtitle:
                        'Baseline: ${Fmt.int(baseline.electricityUnits)} units · ${Fmt.kg(baseline.co2Kg, decimals: 0)}'),
                if (entries.isEmpty)
                  const EmptyState(
                      icon: Icons.calendar_month_rounded,
                      title: 'No months yet',
                      body:
                          'Add your latest bill to start tracking real savings',
                      compact: true)
                else
                  for (final e in entries.reversed) _EntryTile(entry: e),
              ],
            ),
    );
  }

  double _goalProgress(
      AppUser u, FootprintEntry baseline, FootprintEntry latest) {
    if (latest.isBaseline) return 0;
    final targetDrop = baseline.co2Kg * u.goalPercent / 100;
    final achieved = baseline.co2Kg - latest.co2Kg;
    if (targetDrop <= 0) return 0;
    return (achieved / targetDrop).clamp(0, 1);
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart(
      {required this.baseline, required this.entries, required this.months});
  final FootprintEntry baseline;
  final List<FootprintEntry> entries;
  final int months;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();
    final xs = List.generate(
        months, (i) => DateTime(now.year, now.month - (months - 1 - i)));
    final spots = <FlSpot>[];
    for (var i = 0; i < xs.length; i++) {
      final m = xs[i];
      final e = entries
              .where((f) => f.month.year == m.year && f.month.month == m.month)
              .firstOrNull ??
          (baseline.month.year == m.year && baseline.month.month == m.month
              ? baseline
              : null);
      if (e != null) spots.add(FlSpot(i.toDouble(), e.co2Kg));
    }
    final maxY =
        [baseline.co2Kg, ...spots.map((s) => s.y)].reduce(math.max) * 1.25;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (months - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: maxY / 4,
              getTitlesWidget: (v, _) =>
                  Text(v.round().toString(), style: t.labelSmall),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.round();
                if (i < 0 || i >= xs.length) return const SizedBox.shrink();
                if (months == 12 && i.isOdd) return const SizedBox.shrink();
                return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(Fmt.monthShort(xs[i]), style: t.labelSmall));
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.textPrimary,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem('${s.y.toStringAsFixed(0)} kg',
                    t.labelMedium!.copyWith(color: Colors.white)))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              FlSpot(0, baseline.co2Kg),
              FlSpot((months - 1).toDouble(), baseline.co2Kg)
            ],
            color: AppColors.textTertiary,
            barWidth: 2,
            dashArray: [6, 5],
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: AppColors.primary),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.25),
                  AppColors.primary.withValues(alpha: 0.0)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(
      {required this.color, required this.label, this.dashed = false});
  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 18,
            height: 3,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _BreakRow extends StatelessWidget {
  const _BreakRow(
      {required this.color,
      required this.label,
      required this.kg,
      required this.total});
  final Color color;
  final String label;
  final double kg;
  final double total;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: t.bodyMedium)),
          Text(Fmt.kg(kg, decimals: 0), style: t.titleSmall),
          const SizedBox(width: 6),
          SizedBox(
              width: 38,
              child: Text(total == 0 ? '' : Fmt.pct(kg / total * 100),
                  style: t.labelSmall, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _TotalStat extends StatelessWidget {
  const _TotalStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
              child: Text(value,
                  style: t.titleMedium?.copyWith(color: Colors.white))),
          Text(label, style: t.labelSmall?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});
  final FootprintEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final bill = entry.source == 'bill';
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconTile(
              icon: bill ? Icons.receipt_long_rounded : Icons.edit_note_rounded,
              color: bill ? AppColors.tertiary : AppColors.textSecondary,
              size: 42,
              iconSize: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Fmt.month(entry.month), style: t.titleSmall),
                Text(
                    '${Fmt.units(entry.electricityUnits)} · ${bill ? 'Bill verified' : 'Manual entry'}',
                    style: t.labelSmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Fmt.kg(entry.co2Kg, decimals: 0), style: t.titleSmall),
              if (entry.unitsSaved > 0)
                DeltaChip(
                    label: '${Fmt.int(entry.unitsSaved)} units',
                    positive: true),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add month
// ---------------------------------------------------------------------------
class AddMonthScreen extends StatefulWidget {
  const AddMonthScreen({super.key});

  @override
  State<AddMonthScreen> createState() => _AddMonthScreenState();
}

class _AddMonthScreenState extends State<AddMonthScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _byBill = false;
  final _value = TextEditingController();
  bool _photo = false;
  bool _sameCooking = true;
  bool _sameTravel = true;
  bool _saving = false;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = AppScope.read(context);
    final raw = double.tryParse(_value.text) ?? 0;
    if (raw <= 0) {
      showAppSnack(context, 'Enter units or bill amount',
          icon: Icons.error_outline_rounded, color: AppColors.error);
      return;
    }
    final units = _byBill ? s.footprintCalc.unitsFromBill(raw) : raw;
    final exists = s.footprints.any((f) =>
        !f.isBaseline &&
        f.month.year == _month.year &&
        f.month.month == _month.month);
    if (exists) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Update existing entry?'),
          content: Text(
              'You already added ${Fmt.month(_month)}. Replace it with the new value?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                child: const Text('Replace')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final points = s.addMonth(month: _month, units: units, fromBill: _photo);
    final saved = math.max(0.0, s.user!.baselineUnits - units);
    if (points > 0) showConfetti(context);
    showAppSnack(
      context,
      points > 0
          ? 'Saved ${saved.round()} units vs baseline · +$points points (bill verified)'
          : saved > 0
              ? 'Saved ${saved.round()} units vs baseline. Add a bill photo next time to earn points!'
              : 'Entry saved. Check today\'s nudges for quick wins.',
      icon: Icons.check_circle_rounded,
      color: AppColors.primary,
    );
    context.safePop('/impact');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
          leading: const SafeBackButton(fallback: '/impact'),
          title: const Text('Add month')),
      body: PhoneFrame(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Billing month', style: t.titleSmall),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                      onPressed: () => setState(() =>
                          _month = DateTime(_month.year, _month.month - 1)),
                      icon: const Icon(Icons.chevron_left_rounded)),
                  Expanded(
                      child: Text(Fmt.month(_month),
                          textAlign: TextAlign.center, style: t.titleMedium)),
                  IconButton(
                    onPressed: _month.isBefore(
                            DateTime(DateTime.now().year, DateTime.now().month))
                        ? () => setState(() =>
                            _month = DateTime(_month.year, _month.month + 1))
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: false,
                    label: Text('Units (kWh)'),
                    icon: Icon(Icons.bolt_rounded, size: 16)),
                ButtonSegment(
                    value: true,
                    label: Text('Bill amount ₹'),
                    icon: Icon(Icons.currency_rupee_rounded, size: 16)),
              ],
              selected: {_byBill},
              onSelectionChanged: (v) => setState(() => _byBill = v.first),
              style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primarySoft,
                  selectedForegroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border)),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: _byBill ? 'Bill amount' : 'Units consumed',
              controller: _value,
              hint: _byBill ? 'e.g. 1,500' : 'e.g. 210',
              keyboardType: TextInputType.number,
              prefixIcon:
                  _byBill ? Icons.currency_rupee_rounded : Icons.bolt_rounded,
              helper:
                  'Your baseline is ${Fmt.int(s.user!.baselineUnits)} units / month',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Text('Bill photo (for verified points)', style: t.titleSmall),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _photo = !_photo),
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _photo ? AppColors.primarySoft : AppColors.surface,
                  border: Border.all(
                      color: _photo ? AppColors.primary : AppColors.border,
                      width: 1.5),
                ),
                child: _photo
                    ? Row(
                        children: [
                          Container(
                            width: 110,
                            margin: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: const Color(0xFFDDE7DD),
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.receipt_long_rounded,
                                size: 40, color: Colors.white),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'bill_${_month.year}${_month.month.toString().padLeft(2, '0')}.jpg',
                                    style: t.titleSmall),
                                const SizedBox(height: 4),
                                const StatusTag(
                                    label: 'OCR: units detected ✓',
                                    color: AppColors.success),
                                const SizedBox(height: 6),
                                Text('Tap to remove', style: t.labelSmall),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined,
                              color: AppColors.primary, size: 30),
                          const SizedBox(height: 8),
                          Text('Add bill photo',
                              style: t.labelLarge
                                  ?.copyWith(color: AppColors.primary)),
                          Text(
                              'Earn ${s.config.pointsPerUnitSaved} points per unit saved',
                              style: t.labelSmall),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Other sources', style: t.titleSmall),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cooking fuel same as before'),
              subtitle: const Text('LPG / PNG usage unchanged'),
              value: _sameCooking,
              onChanged: (v) => setState(() => _sameCooking = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Travel same as before'),
              subtitle: const Text('Weekly km unchanged'),
              value: _sameTravel,
              onChanged: (v) => setState(() => _sameTravel = v),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
                label: 'Save entry',
                onPressed: _save,
                loading: _saving,
                icon: Icons.check_rounded),
          ],
        ),
      ),
    );
  }
}
