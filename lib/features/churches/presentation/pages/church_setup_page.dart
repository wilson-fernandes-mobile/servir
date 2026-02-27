import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/cnpj_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/church_notifier.dart';
import '../providers/church_provider.dart';

enum _SetupOption { create, join }

class ChurchSetupPage extends ConsumerStatefulWidget {
  const ChurchSetupPage({super.key});

  @override
  ConsumerState<ChurchSetupPage> createState() => _ChurchSetupPageState();
}

class _ChurchSetupPageState extends ConsumerState<ChurchSetupPage> {
  _SetupOption? _selectedOption;

  // Create form
  final _createFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();

  // Join form
  final _joinFormKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    _cnpjCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onCreate() async {
    if (!(_createFormKey.currentState?.validate() ?? false)) return;
    final user = ref.read(authStateChangesProvider).asData?.value;
    if (user == null) return;

    // Strip da máscara antes de persistir
    final cnpjRaw = CnpjUtils.strip(_cnpjCtrl.text.trim());
    final ok = await ref.read(churchNotifierProvider.notifier).createChurch(
          adminId: user.id,
          name: _nameCtrl.text.trim(),
          city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          cnpj: cnpjRaw.isEmpty ? null : cnpjRaw,
        );

    if (ok && mounted) {
      // Invalidate the auth stream → it re-fetches Firestore user (now with churchId)
      // → router sees churchId and redirects to home automatically
      ref.invalidate(authStateChangesProvider);
    }
  }

  Future<void> _onJoin() async {
    if (!(_joinFormKey.currentState?.validate() ?? false)) return;
    final user = ref.read(authStateChangesProvider).asData?.value;
    if (user == null) return;

    final ok = await ref.read(churchNotifierProvider.notifier).joinChurch(
          userId: user.id,
          inviteCode: _codeCtrl.text.trim().toUpperCase(),
        );

    if (ok && mounted) {
      ref.invalidate(authStateChangesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final churchState = ref.watch(churchNotifierProvider);

    ref.listen<ChurchState>(churchNotifierProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(churchNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Image.asset('assets/icon/icon_login.png', height: 80),
              const SizedBox(height: 24),
              const Text(
                'Bem-vindo ao Servir+',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Para continuar, crie uma organização\nou entre com um código de convite.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              // Option cards
              Row(
                children: [
                  Expanded(
                    child: _OptionCard(
                      icon: Icons.add_business_outlined,
                      label: 'Criar\norganização',
                      selected: _selectedOption == _SetupOption.create,
                      onTap: () => setState(
                          () => _selectedOption = _SetupOption.create),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _OptionCard(
                      icon: Icons.group_add_outlined,
                      label: 'Entrar com\ncódigo',
                      selected: _selectedOption == _SetupOption.join,
                      onTap: () =>
                          setState(() => _selectedOption = _SetupOption.join),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Forms
              if (_selectedOption == _SetupOption.create)
                _CreateForm(
                  formKey: _createFormKey,
                  nameCtrl: _nameCtrl,
                  cityCtrl: _cityCtrl,
                  phoneCtrl: _phoneCtrl,
                  cnpjCtrl: _cnpjCtrl,
                  isLoading: churchState.isLoading,
                  onSubmit: _onCreate,
                ),
              if (_selectedOption == _SetupOption.join)
                _JoinForm(
                  formKey: _joinFormKey,
                  codeCtrl: _codeCtrl,
                  isLoading: churchState.isLoading,
                  onSubmit: _onJoin,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: selected ? Colors.white : AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController cnpjCtrl;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _CreateForm({
    required this.formKey,
    required this.nameCtrl,
    required this.cityCtrl,
    required this.phoneCtrl,
    required this.cnpjCtrl,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome da organização *',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: cityCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Cidade',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefone',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: cnpjCtrl,
            // Teclado alfanumérico — suporta letras do novo formato jul/2026
            keyboardType: TextInputType.visiblePassword,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [CnpjInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'CNPJ (opcional)',
              prefixIcon: Icon(Icons.badge_outlined),
              hintText: 'Ex: 11.222.333/0001-81',
              helperText: 'Aceita o novo formato alfanumérico (jul/2026)',
            ),
            validator: Validators.cnpj,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Criar organização'),
          ),
        ],
      ),
    );
  }
}

class _JoinForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController codeCtrl;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _JoinForm({
    required this.formKey,
    required this.codeCtrl,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: codeCtrl,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              labelText: 'Código de convite *',
              prefixIcon: Icon(Icons.vpn_key_outlined),
              hintText: 'Ex: ABC123',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Informe o código';
              if (v.trim().length != 6) return 'O código deve ter 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Entrar na organização'),
          ),
        ],
      ),
    );
  }
}

