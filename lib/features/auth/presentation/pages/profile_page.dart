import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _togglingDate = false;
  bool _profileInitialized = false;
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _initFields(UserEntity user) {
    if (_profileInitialized) return;
    _nameCtrl.text = user.name;
    _phoneCtrl.text = user.phone ?? '';
    _profileInitialized = true;
  }

  Future<void> _saveProfile(String userId) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('O nome não pode ser vazio.');
      return;
    }
    setState(() => _savingProfile = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': name,
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      });
      ref.invalidate(userByIdProvider(userId));
      _showSnack('Perfil atualizado com sucesso!');
    } catch (e) {
      _showSnack('Erro ao salvar perfil: $e');
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword(String email) async {
    final current = _currentPassCtrl.text;
    final newPass = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showSnack('Preencha todos os campos de senha.');
      return;
    }
    if (newPass != confirm) {
      _showSnack('A nova senha e a confirmação não coincidem.');
      return;
    }
    if (newPass.length < 6) {
      _showSnack('A nova senha deve ter pelo menos 6 caracteres.');
      return;
    }
    setState(() => _savingPassword = true);
    try {
      final auth = FirebaseAuth.instance;
      final credential =
          EmailAuthProvider.credential(email: email, password: current);
      await auth.currentUser!.reauthenticateWithCredential(credential);
      await auth.currentUser!.updatePassword(newPass);
      _currentPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      _showSnack('Senha alterada com sucesso!');
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'wrong-password'
          ? 'Senha atual incorreta.'
          : 'Erro ao alterar senha: ${e.message}';
      _showSnack(msg);
    } catch (e) {
      _showSnack('Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _toggleUnavailableDate(
      String userId, DateTime date, bool remove) async {
    setState(() => _togglingDate = true);
    final normalized = DateTime(date.year, date.month, date.day);
    final ts = Timestamp.fromDate(normalized);
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'unavailableDates': remove
            ? FieldValue.arrayRemove([ts])
            : FieldValue.arrayUnion([ts]),
      });
      ref.invalidate(userByIdProvider(userId));
    } catch (e) {
      _showSnack('Erro ao atualizar indisponibilidade: $e');
    } finally {
      if (mounted) setState(() => _togglingDate = false);
    }
  }

  Future<void> _pickUnavailableDate(String userId) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked == null) return;
    await _toggleUnavailableDate(userId, picked, false);
  }

  Future<void> _pickAndUploadPhoto(String userId) async {
    try {
      // Mostra opções: câmera ou galeria
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Câmera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Seleciona a imagem
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile == null) return;

      setState(() => _uploadingPhoto = true);

      // Faz upload da foto compactada
      final uploadUseCase = ref.read(uploadProfilePhotoUseCaseProvider);
      final result = await uploadUseCase(userId, pickedFile.path);

      result.fold(
        (failure) => _showSnack('Erro ao fazer upload da foto'),
        (photoUrl) {
          ref.invalidate(userByIdProvider(userId));
          _showSnack('Foto atualizada com sucesso!');
        },
      );
    } catch (e) {
      _showSnack('Erro ao selecionar foto: $e');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Constrói a imagem de perfil - suporta base64 ou URL de rede
  Widget _buildProfileImage(String photoUrl, String userName) {
    // Verifica se é base64
    if (photoUrl.startsWith('data:image')) {
      try {
        final base64String = photoUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: 84,
          height: 84,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        );
      } catch (e) {
        // Se falhar ao decodificar, mostra inicial
        return Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        );
      }
    }

    // Se for URL de rede (Firebase Storage)
    return CachedNetworkImage(
      imageUrl: photoUrl,
      width: 84,
      height: 84,
      fit: BoxFit.cover,
      placeholder: (context, url) => const CircularProgressIndicator(),
      errorWidget: (context, url, error) => Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateChangesProvider).asData?.value;
    if (authUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final userAsync = ref.watch(userByIdProvider(authUser.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('Usuário não encontrado.'));
          _initFields(user);
          return _buildBody(user);
        },
      ),
    );
  }

  Widget _buildBody(UserEntity user) {
    return CustomScrollView(
      slivers: [
        // ── Header com gradiente ──────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 56), // Espaço para o AppBar
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.white,
                              child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: _buildProfileImage(user.photoUrl!, user.name),
                                    )
                                  : Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _uploadingPhoto ? null : () => _pickAndUploadPhoto(user.id),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: _uploadingPhoto
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Conteúdo ──────────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Dados Pessoais ───────────────────────────────────────────────
              _ModernCard(
                icon: Icons.person_outline,
                title: 'Dados Pessoais',
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefone (opcional)',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _savingProfile ? null : () => _saveProfile(user.id),
                      icon: _savingProfile
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined, size: 20),
                      label: const Text('Salvar Alterações'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Alterar Senha ────────────────────────────────────────────────
              _ModernCard(
                icon: Icons.lock_outline,
                title: 'Segurança',
                children: [
                  TextField(
                    controller: _currentPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha atual',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nova senha',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar nova senha',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _savingPassword
                          ? null
                          : () => _changePassword(user.email),
                      icon: _savingPassword
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.key_outlined, size: 20),
                      label: const Text('Alterar Senha'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ModernCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _ModernCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

