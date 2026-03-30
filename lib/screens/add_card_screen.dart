import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/card_model.dart';
import '../providers/card_provider.dart';
import '../services/notification_service.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  final CardModel? existingCard;

  const AddCardScreen({super.key, this.existingCard});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _benefitCtrl;
  late double _alertThreshold;
  late Color _selectedColor;

  static const _presetColors = [
    Color(0xFF1A73E8),
    Color(0xFF34A853),
    Color(0xFFEA4335),
    Color(0xFFFBBC04),
    Color(0xFF9C27B0),
    Color(0xFFFF5722),
    Color(0xFF00BCD4),
    Color(0xFF607D8B),
  ];

  @override
  void initState() {
    super.initState();
    final card = widget.existingCard;
    _nameCtrl = TextEditingController(text: card?.name ?? '');
    _companyCtrl = TextEditingController(text: card?.company ?? '');
    _targetCtrl = TextEditingController(
      text: card != null ? card.targetAmount.toStringAsFixed(0) : '',
    );
    _benefitCtrl = TextEditingController(text: card?.benefit ?? '');
    _alertThreshold = card?.alertThreshold ?? 80.0;
    _selectedColor = card != null ? Color(card.colorValue) : _presetColors[0];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _targetCtrl.dispose();
    _benefitCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.existingCard != null;
    final card = CardModel(
      id: widget.existingCard?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      company: _companyCtrl.text.trim(),
      targetAmount: double.parse(_targetCtrl.text.trim()),
      benefit: _benefitCtrl.text.trim(),
      colorValue: _selectedColor.value,
      alertThreshold: _alertThreshold,
    );

    if (isEdit) {
      ref.read(cardsProvider.notifier).updateCard(card);
    } else {
      ref.read(cardsProvider.notifier).addCard(card);
    }

    await NotificationService().scheduleMonthEndReminders(card);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingCard != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '카드 수정' : '카드 추가'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('저장', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildField('카드 이름', _nameCtrl, '예) 신한 Deep Dream'),
            const SizedBox(height: 16),
            _buildField('카드사', _companyCtrl, '예) 신한카드'),
            const SizedBox(height: 16),
            _buildField(
              '월 목표 실적 (원)',
              _targetCtrl,
              '예) 300000',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return '목표 실적을 입력하세요';
                if (double.tryParse(v) == null) return '숫자를 입력하세요';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildField('혜택 설명', _benefitCtrl, '예) 전월 30만원 이상 사용 시 할인', maxLines: 2),
            const SizedBox(height: 24),
            _buildColorPicker(),
            const SizedBox(height: 24),
            _buildThresholdSlider(),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          validator: validator ??
              (v) => (v == null || v.isEmpty) ? '$label을(를) 입력하세요' : null,
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('카드 색상', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: _presetColors.map((color) {
            final isSelected = _selectedColor.value == color.value;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.black, width: 3)
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildThresholdSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('알림 임계값', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('${_alertThreshold.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '실적이 이 비율 이상 달성되면 즉시 알림을 받습니다.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Slider(
          value: _alertThreshold,
          min: 50,
          max: 100,
          divisions: 10,
          label: '${_alertThreshold.toStringAsFixed(0)}%',
          onChanged: (v) => setState(() => _alertThreshold = v),
        ),
      ],
    );
  }
}
