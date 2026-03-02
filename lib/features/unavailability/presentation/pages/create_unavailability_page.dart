import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/unavailability_model.dart';

class CreateUnavailabilityPage extends ConsumerStatefulWidget {
  const CreateUnavailabilityPage({super.key});

  @override
  ConsumerState<CreateUnavailabilityPage> createState() =>
      _CreateUnavailabilityPageState();
}

class _CreateUnavailabilityPageState
    extends ConsumerState<CreateUnavailabilityPage> {
  final _descriptionCtrl = TextEditingController();
  bool _isPeriod = false;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 23, minute: 59);
  bool _saving = false;

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authStateChangesProvider).asData?.value;
    if (user == null || user.churchId == null) return;

    setState(() => _saving = true);

    try {
      final model = UnavailabilityModel(
        id: const Uuid().v4(),
        userId: user.id,
        churchId: user.churchId!,
        startDate: _startDate,
        endDate: _isPeriod ? _endDate : null,
        startTime: _isPeriod ? _formatTime(_startTime) : null,
        endTime: _isPeriod ? _formatTime(_endTime) : null,
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('unavailabilities')
          .doc(model.id)
          .set(model.toFirestore());

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Indisponibilidade cadastrada'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? _startDate),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Se a data de término for antes da nova data de início, ajusta
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nova Indisponibilidade'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Descrição ───────────────────────────────────────────────────
          TextField(
            controller: _descriptionCtrl,
            decoration: const InputDecoration(
              labelText: 'Descrição *',
              hintText: 'Ex: Viagem, compromisso pessoal...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          const Text(
            'Apenas os administradores do ministério podem visualizar a descrição da indisponibilidade.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // ── Toggle de período ───────────────────────────────────────────
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Selecionar período',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              Switch(
                value: _isPeriod,
                onChanged: (value) {
                  setState(() {
                    _isPeriod = value;
                    if (value && _endDate == null) {
                      _endDate = _startDate;
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Data única OU período ───────────────────────────────────────
          if (!_isPeriod) ...[
            // Data única
            _buildDateField(
              label: 'Data',
              value: fmt.format(_startDate),
              onTap: () => _pickDate(true),
            ),
          ] else ...[
            // Período com horários
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Data de Início',
                    value: fmt.format(_startDate),
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeField(
                    label: 'Hora',
                    value: _formatTime(_startTime),
                    onTap: () => _pickTime(true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Data de Término',
                    value: fmt.format(_endDate ?? _startDate),
                    onTap: () => _pickDate(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeField(
                    label: 'Hora',
                    value: _formatTime(_endTime),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check, size: 20),
                      SizedBox(width: 8),
                      Text('Salvar'),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(child: Text(value)),
            const Icon(Icons.calendar_today, size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(child: Text(value)),
            const Icon(Icons.access_time, size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}


