import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/logic/calculators.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_state.dart';
import '../../data/mock_data.dart';

/// Holds the 5-step onboarding answers (survives back/forward navigation).
class OnboardingData {
  static final instance = OnboardingData();

  String pincode = '';
  String district = 'Ahmedabad';
  int householdSize = 4;
  String homeType = 'flat';
  String roofAccess = 'yes';
  String electricityMethod = 'units'; // units | bill | quiz
  double units = 0;
  double billAmount = 0;
  Map<String, (int, double)> quiz = {
    'ac': (1, 6),
    'fridge': (1, 24),
    'geyser': (1, 0.5),
    'fan': (3, 10),
    'led': (6, 5)
  };
  double lpgCylinders = 1;
  String travelMode = 'two_wheeler';
  double weeklyKm = 70;
  Set<String> appliances = {'ac', 'fridge', 'washing_machine', 'geyser'};
  int goalPercent = 15;

  double resolvedUnits(AppState s) => switch (electricityMethod) {
        'bill' => s.footprintCalc.unitsFromBill(billAmount),
        'quiz' => s.footprintCalc.unitsFromAppliances(quiz),
        _ => units,
      };

  void reset() {
    final fresh = OnboardingData();
    pincode = fresh.pincode;
    district = fresh.district;
    householdSize = fresh.householdSize;
    homeType = fresh.homeType;
    roofAccess = fresh.roofAccess;
    electricityMethod = fresh.electricityMethod;
    units = 0;
    billAmount = 0;
    quiz = fresh.quiz;
    lpgCylinders = fresh.lpgCylinders;
    travelMode = fresh.travelMode;
    weeklyKm = fresh.weeklyKm;
    appliances = fresh.appliances;
    goalPercent = fresh.goalPercent;
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.step});
  final int step;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final d = OnboardingData.instance;
  late final _pin = TextEditingController(text: d.pincode);
  late final _units = TextEditingController(
      text: d.units > 0 ? d.units.round().toString() : '');
  late final _bill = TextEditingController(
      text: d.billAmount > 0 ? d.billAmount.round().toString() : '');

  @override
  void dispose() {
    _pin.dispose();
    _units.dispose();
    _bill.dispose();
    super.dispose();
  }

  bool get _valid => switch (widget.step) {
        1 => d.pincode.length == 6,
        3 => d.electricityMethod == 'quiz' ||
            (d.electricityMethod == 'units' ? d.units > 0 : d.billAmount > 0),
        _ => true,
      };

  void _next() {
    if (widget.step < 5) {
      context.push('/onboarding/${widget.step + 1}');
    } else {
      context.push('/onboarding/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final titles = [
      'Where do you live?',
      'Tell us about your home',
      'Your electricity',
      'Cooking fuel',
      'How do you travel?'
    ];
    final subtitles = [
      'We use this to find your DISCOM, community and solar potential.',
      'Helps us personalise tasks and check rooftop solar feasibility.',
      'Pick whichever is easiest — you can refine it later.',
      'Cooking fuel is the second-largest home emission source.',
      'Last step! Then we reveal your footprint.',
    ];
    return Scaffold(
      body: PhoneFrame(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => widget.step == 1
                          ? context.go('/login')
                          : context.safePop('/onboarding/${widget.step - 1}'),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          for (var i = 1; i <= 5; i++) ...[
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                height: 5,
                                decoration: BoxDecoration(
                                  color: i <= widget.step
                                      ? AppColors.primary
                                      : AppColors.border,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            if (i < 5) const SizedBox(width: 4),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Step ${widget.step} of 5', style: t.labelMedium),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titles[widget.step - 1], style: t.headlineMedium),
                      const SizedBox(height: 6),
                      Text(subtitles[widget.step - 1],
                          style: t.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      _buildStep(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: PrimaryButton(
                  label: widget.step == 5 ? 'Reveal my footprint' : 'Continue',
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: _valid ? _next : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (widget.step) {
      case 1:
        return _stepLocation();
      case 2:
        return _stepHome();
      case 3:
        return _stepElectricity();
      case 4:
        return _stepCooking();
      default:
        return _stepTravel();
    }
  }

  // Step 1 -------------------------------------------------------------
  Widget _stepLocation() {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'PIN code',
          controller: _pin,
          hint: 'e.g. 380015',
          keyboardType: TextInputType.number,
          maxLength: 6,
          prefixIcon: Icons.location_on_outlined,
          onChanged: (v) => setState(() {
            d.pincode = v;
            if (v.length == 6) d.district = MockData.districtFromPin(v);
          }),
        ),
        const SizedBox(height: 12),
        if (d.pincode.length == 6)
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 18),
              const SizedBox(width: 6),
              Text('Detected district: ', style: t.bodySmall),
              Pill(
                  label: d.district,
                  color: AppColors.primarySoft,
                  textColor: AppColors.primary,
                  icon: Icons.map_outlined),
            ],
          ),
        const SizedBox(height: 16),
        SecondaryButton(
          label: 'Use my location',
          icon: Icons.my_location_rounded,
          onPressed: () => setState(() {
            d.pincode = '380015';
            _pin.text = d.pincode;
            d.district = 'Ahmedabad';
          }),
        ),
        const SizedBox(height: 24),
        Text('Or pick your district', style: t.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey(d.district),
          initialValue: d.district,
          isExpanded: true,
          items: MockData.gujaratDistricts
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => d.district = v ?? d.district),
          decoration: const InputDecoration(
              prefixIcon: Icon(Icons.map_outlined, size: 20)),
        ),
      ],
    );
  }

  // Step 2 -------------------------------------------------------------
  Widget _stepHome() {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Household size', style: t.titleSmall),
        const SizedBox(height: 8),
        StepperField(
            value: d.householdSize,
            min: 1,
            max: 12,
            label: 'People at home',
            onChanged: (v) => setState(() => d.householdSize = v)),
        const SizedBox(height: 24),
        Text('Home type', style: t.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: SelectableTile(
                    label: 'Flat',
                    icon: Icons.apartment_rounded,
                    selected: d.homeType == 'flat',
                    onTap: () => setState(() => d.homeType = 'flat'))),
            const SizedBox(width: 12),
            Expanded(
                child: SelectableTile(
                    label: 'House',
                    icon: Icons.house_rounded,
                    selected: d.homeType == 'house',
                    onTap: () => setState(() => d.homeType = 'house'))),
          ],
        ),
        const SizedBox(height: 24),
        Text('Do you have roof access for solar?', style: t.titleSmall),
        const SizedBox(height: 8),
        for (final (v, l, s) in [
          ('yes', 'Yes, my own roof', 'Best for rooftop solar'),
          ('shared', 'Shared / society roof', 'Group solar possible'),
          ('no', 'No roof access', "We'll focus on savings")
        ]) ...[
          SelectableTile(
              label: l,
              subtitle: s,
              icon: Icons.roofing_rounded,
              selected: d.roofAccess == v,
              onTap: () => setState(() => d.roofAccess = v)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  // Step 3 -------------------------------------------------------------
  Widget _stepElectricity() {
    final t = Theme.of(context).textTheme;
    final s = AppScope.read(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
                value: 'units',
                label: Text('Units'),
                icon: Icon(Icons.bolt_rounded, size: 16)),
            ButtonSegment(
                value: 'bill',
                label: Text('Bill ₹'),
                icon: Icon(Icons.receipt_long_rounded, size: 16)),
            ButtonSegment(
                value: 'quiz',
                label: Text('Estimate'),
                icon: Icon(Icons.calculate_rounded, size: 16)),
          ],
          selected: {d.electricityMethod},
          onSelectionChanged: (v) =>
              setState(() => d.electricityMethod = v.first),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.primarySoft,
            selectedForegroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
            textStyle: t.labelMedium,
          ),
        ),
        const SizedBox(height: 20),
        if (d.electricityMethod == 'units')
          AppTextField(
            label: 'Units (kWh) on last month\'s bill',
            controller: _units,
            hint: 'e.g. 250',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.bolt_rounded,
            helper:
                'Look for "Units consumed" on your DGVCL / MGVCL / PGVCL / UGVCL / Torrent bill',
            onChanged: (v) => setState(() => d.units = double.tryParse(v) ?? 0),
          )
        else if (d.electricityMethod == 'bill')
          AppTextField(
            label: 'Last month\'s bill amount (₹)',
            controller: _bill,
            hint: 'e.g. 1800',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.currency_rupee_rounded,
            helper: 'We estimate units at an average ₹6 per unit',
            onChanged: (v) =>
                setState(() => d.billAmount = double.tryParse(v) ?? 0),
          )
        else
          _ApplianceQuiz(data: d, onChanged: () => setState(() {})),
        const SizedBox(height: 20),
        if (_valid)
          AppCard(
            color: AppColors.primarySoft,
            border: false,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.insights_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Text('≈ ${d.resolvedUnits(s).round()} units / month',
                    style: t.titleMedium?.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
      ],
    );
  }

  // Step 4 -------------------------------------------------------------
  Widget _stepCooking() {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LPG cylinders per month', style: t.titleSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final v in [0.0, 0.5, 1.0, 1.5, 2.0])
              ChoiceChip(
                label: Text(v == 0 ? 'None / PNG' : v.toString()),
                selected: d.lpgCylinders == v,
                onSelected: (_) => setState(() => d.lpgCylinders = v),
                labelStyle: t.labelLarge?.copyWith(
                    color: d.lpgCylinders == v
                        ? AppColors.primary
                        : AppColors.textPrimary),
                selectedColor: AppColors.primarySoft,
                side: BorderSide(
                    color: d.lpgCylinders == v
                        ? AppColors.primary
                        : AppColors.border),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const InfoBanner(
          bold: 'Did you know?',
          text:
              'One 14.2 kg LPG cylinder releases about 42 kg CO₂. Pressure cooking and covering pans can cut usage by 20%.',
          icon: Icons.lightbulb_outline_rounded,
        ),
      ],
    );
  }

  // Step 5 -------------------------------------------------------------
  Widget _stepTravel() {
    final t = Theme.of(context).textTheme;
    const modes = [
      ('none', 'None', Icons.directions_walk_rounded),
      ('two_wheeler', 'Two-wheeler', Icons.two_wheeler_rounded),
      ('car', 'Car', Icons.directions_car_rounded),
      ('bus_metro', 'Bus / Metro', Icons.directions_bus_rounded),
      ('ev', 'EV', Icons.electric_bolt_rounded),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Primary travel mode', style: t.titleSmall),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: [
            for (final (v, l, i) in modes)
              SelectableTile(
                  label: l,
                  icon: i,
                  compact: true,
                  selected: d.travelMode == v,
                  onTap: () => setState(() => d.travelMode = v)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Text('Weekly distance', style: t.titleSmall)),
            Text('${d.weeklyKm.round()} km',
                style: t.titleSmall?.copyWith(color: AppColors.primary)),
          ],
        ),
        Slider(
            value: d.weeklyKm,
            min: 0,
            max: 300,
            divisions: 30,
            onChanged: d.travelMode == 'none'
                ? null
                : (v) => setState(() => d.weeklyKm = v)),
        const SizedBox(height: 16),
        Text('Appliances at home', style: t.titleSmall),
        const SizedBox(height: 4),
        Text('Used to personalise your daily nudges', style: t.bodySmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (id, label, icon) in MockData.appliances)
              FilterChip(
                avatar: Icon(icon,
                    size: 16,
                    color: d.appliances.contains(id)
                        ? AppColors.primary
                        : AppColors.textSecondary),
                label: Text(label),
                selected: d.appliances.contains(id),
                onSelected: (v) => setState(
                    () => v ? d.appliances.add(id) : d.appliances.remove(id)),
                selectedColor: AppColors.primarySoft,
                side: BorderSide(
                    color: d.appliances.contains(id)
                        ? AppColors.primary
                        : AppColors.border),
              ),
          ],
        ),
      ],
    );
  }
}

class _ApplianceQuiz extends StatelessWidget {
  const _ApplianceQuiz({required this.data, required this.onChanged});
  final OnboardingData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const rows = [
      ('ac', 'AC', Icons.ac_unit_rounded),
      ('geyser', 'Geyser', Icons.hot_tub_rounded),
      ('fridge', 'Fridge', Icons.kitchen_rounded),
      ('fan', 'Fans', Icons.mode_fan_off_rounded),
      ('led', 'Lights', Icons.lightbulb_outline_rounded),
      ('tv', 'TV', Icons.tv_rounded)
    ];
    return Column(
      children: [
        for (final (id, label, icon) in rows)
          AppCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(label, style: t.titleSmall)),
                    _MiniStepper(
                      value: data.quiz[id]?.$1 ?? 0,
                      onChanged: (v) {
                        data.quiz[id] = (v, data.quiz[id]?.$2 ?? 4);
                        onChanged();
                      },
                    ),
                  ],
                ),
                if ((data.quiz[id]?.$1 ?? 0) > 0)
                  Row(
                    children: [
                      Text(
                          '${(data.quiz[id]!.$2).toStringAsFixed(data.quiz[id]!.$2 < 1 ? 1 : 0)} h/day',
                          style: t.labelSmall),
                      Expanded(
                        child: Slider(
                          value: data.quiz[id]!.$2,
                          min: 0.5,
                          max: 24,
                          divisions: 47,
                          onChanged: (v) {
                            data.quiz[id] = (data.quiz[id]!.$1, v);
                            onChanged();
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MiniStepper extends StatelessWidget {
  const _MiniStepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded)),
        SizedBox(
            width: 22,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall)),
        IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value < 9 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Baseline result
// ---------------------------------------------------------------------------
class BaselineResultScreen extends StatefulWidget {
  const BaselineResultScreen({super.key});

  @override
  State<BaselineResultScreen> createState() => _BaselineResultScreenState();
}

class _BaselineResultScreenState extends State<BaselineResultScreen> {
  final d = OnboardingData.instance;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = AppScope.of(context);
    final units = d.resolvedUnits(s);
    final calc = s.footprintCalc;
    final r = calc.calculate(FootprintInput(
      electricityUnits: units,
      lpgKg: d.lpgCylinders * 14.2,
      petrolL: calc.petrolLitresFromKm(d.travelMode, d.weeklyKm),
      busKm: d.travelMode == 'bus_metro' ? d.weeklyKm * 4.33 : 0,
    ));
    final avg = s.config.gujaratAvgHouseholdCo2Kg;
    final ratio = (r.totalKg / (avg * 1.6)).clamp(0.05, 1.0);
    final target = r.totalKg * (1 - d.goalPercent / 100);
    const white = Colors.white;

    return Scaffold(
      body: PhoneFrame(
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGreen),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                                onPressed: () =>
                                    context.safePop('/onboarding/5'),
                                icon: Icon(Icons.arrow_back_rounded,
                                    color: white)),
                            const Spacer(),
                            Pill(
                                label: 'Baseline set',
                                icon: Icons.verified_rounded),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Your monthly footprint',
                            style: t.titleMedium?.copyWith(
                                color: white.withValues(alpha: 0.85)),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CountUpText(
                                value: r.totalKg,
                                decimals: 1,
                                style: t.displayLarge?.copyWith(
                                    color: white, fontSize: 56, height: 1)),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('kg CO₂\n/ month',
                                  style: t.labelMedium?.copyWith(
                                      color: white.withValues(alpha: 0.85))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ProgressRing(
                            value: 1,
                            size: 150,
                            stroke: 14,
                            color: white.withValues(alpha: 0.0),
                            track: Colors.transparent,
                            child: _SplitRing(r: r),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 14,
                          children: [
                            _Legend(
                                color: AppColors.secondaryLight,
                                label:
                                    'Electricity ${Fmt.pct(r.electricityKg / r.totalKg * 100)}'),
                            _Legend(
                                color: white,
                                label:
                                    'Cooking ${Fmt.pct(r.cookingKg / r.totalKg * 100)}'),
                            _Legend(
                                color: const Color(0xFF90CAF9),
                                label:
                                    'Travel ${Fmt.pct(r.transportKg / r.totalKg * 100)}'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _EquivCard(
                                emoji: '🌳',
                                value: Fmt.int(r.treesPerYear),
                                label: 'trees / yr to absorb'),
                            const SizedBox(width: 10),
                            _EquivCard(
                                emoji: '🛵',
                                value: Fmt.int(r.kmDrivenEquivalent),
                                label: 'km on a scooter'),
                            const SizedBox(width: 10),
                            _EquivCard(
                                emoji: '📱',
                                value: Fmt.compact(r.phoneCharges),
                                label: 'phone charges'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(
                                          'You vs Gujarat average household',
                                          style: t.labelLarge
                                              ?.copyWith(color: white))),
                                  Text('${avg.round()} kg',
                                      style: t.labelMedium?.copyWith(
                                          color: white.withValues(alpha: 0.8))),
                                ],
                              ),
                              const SizedBox(height: 10),
                              LayoutBuilder(
                                builder: (_, c) => SizedBox(
                                  height: 26,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        top: 9,
                                        bottom: 9,
                                        child: Container(
                                            decoration: BoxDecoration(
                                                color: white.withValues(
                                                    alpha: 0.25),
                                                borderRadius:
                                                    BorderRadius.circular(4))),
                                      ),
                                      Positioned(
                                        left: c.maxWidth * (avg / (avg * 1.6)) -
                                            1,
                                        top: 0,
                                        bottom: 0,
                                        child: Container(
                                            width: 2,
                                            color:
                                                white.withValues(alpha: 0.7)),
                                      ),
                                      Positioned(
                                        left: c.maxWidth * ratio - 13,
                                        top: 0,
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                              color: r.totalKg <= avg
                                                  ? AppColors.secondaryLight
                                                  : white,
                                              shape: BoxShape.circle,
                                              boxShadow: AppShadows.level2),
                                          child: Icon(Icons.person_rounded,
                                              size: 16,
                                              color: AppColors.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                r.totalKg <= avg
                                    ? 'Great start — you are already below the state average.'
                                    : 'About ${Fmt.pct((r.totalKg - avg) / avg * 100)} above average — plenty of easy wins ahead.',
                                style: t.bodySmall?.copyWith(
                                    color: white.withValues(alpha: 0.9)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Pick a 90-day goal',
                            style: t.titleMedium?.copyWith(color: white)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            for (final g in [10, 15, 20]) ...[
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => d.goalPercent = g),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: d.goalPercent == g
                                          ? white
                                          : white.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: white.withValues(
                                              alpha: d.goalPercent == g
                                                  ? 1
                                                  : 0.3)),
                                    ),
                                    child: Column(
                                      children: [
                                        Text('-$g%',
                                            style: t.titleLarge?.copyWith(
                                                color: d.goalPercent == g
                                                    ? AppColors.primary
                                                    : white)),
                                        Text(
                                            '→ ${(r.totalKg * (1 - g / 100)).round()} kg',
                                            style: t.labelSmall?.copyWith(
                                                color: d.goalPercent == g
                                                    ? AppColors.textSecondary
                                                    : white.withValues(
                                                        alpha: 0.8))),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (g != 20) const SizedBox(width: 10),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'Target: ${target.toStringAsFixed(0)} kg CO₂ / month by ${Fmt.date(DateTime.now().add(const Duration(days: 90)))}',
                            style: t.bodySmall?.copyWith(
                                color: white.withValues(alpha: 0.85)),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: PrimaryButton(
                    label: 'Start my journey',
                    color: white,
                    foreground: AppColors.primary,
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      s.completeOnboarding(
                        pincode: d.pincode.isEmpty ? '380015' : d.pincode,
                        district: d.district,
                        householdSize: d.householdSize,
                        homeType: d.homeType,
                        roofAccess: d.roofAccess,
                        electricityUnits: units,
                        lpgCylinders: d.lpgCylinders,
                        travelMode: d.travelMode,
                        weeklyKm: d.weeklyKm,
                        appliances: d.appliances.toList(),
                        goalPercent: d.goalPercent,
                        source:
                            d.electricityMethod == 'quiz' ? 'quiz' : 'manual',
                      );
                      HapticFeedback.mediumImpact();
                      context.go('/community/join?onboarding=1');
                    },
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

class _SplitRing extends StatelessWidget {
  const _SplitRing({required this.r});
  final FootprintResult r;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: CustomPaint(
        painter: _SplitRingPainter([
          (r.electricityKg / r.totalKg, AppColors.secondaryLight),
          (r.cookingKg / r.totalKg, Colors.white),
          (r.transportKg / r.totalKg, const Color(0xFF90CAF9)),
        ]),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(r.totalKg * 12 / 1000).toStringAsFixed(1)} t',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white)),
              Text('per year',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitRingPainter extends CustomPainter {
  _SplitRingPainter(this.parts);
  final List<(double, Color)> parts;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(8);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.butt;
    var start = -1.5708;
    for (final (f, c) in parts) {
      final sweep = 6.2832 * f;
      canvas.drawArc(rect, start, sweep - 0.06, false, p..color = c);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.white)),
      ],
    );
  }
}

class _EquivCard extends StatelessWidget {
  const _EquivCard(
      {required this.emoji, required this.value, required this.label});
  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(value,
                style: t.titleMedium?.copyWith(color: AppColors.primary)),
            Text(label,
                style: t.labelSmall, textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      ),
    );
  }
}
