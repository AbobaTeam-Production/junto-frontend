import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key});

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  bool _loading = false;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _usernameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageName = image.name;
      });
    }
  }

  Future<void> _save() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Имя пользователя не может быть пустым')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier).updateProfile(
            username: username,
            email: email.isNotEmpty ? email : null,
            avatarBytes: _pickedImageBytes,
            avatarFileName: _pickedImageName,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('UpdateProfile error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final user = ref.watch(currentUserProvider);
    final initial =
        user != null && user.username.isNotEmpty ? user.username[0].toUpperCase() : '?';

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Редактировать профиль',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 24),

            // Avatar picker
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    // Avatar circle
                    if (_pickedImageBytes != null)
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: MemoryImage(_pickedImageBytes!),
                      )
                    else if (user?.avatarUrl != null)
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: NetworkImage(user!.avatarUrl!),
                      )
                    else
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    // Camera badge
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Username
            Text(
              'Имя пользователя',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Имя пользователя',
                prefixIcon: Icon(Icons.person_outline_rounded,
                    color: AppColors.textHint, size: 20),
              ),
            ),
            const SizedBox(height: 20),

            // Email
            Text(
              'Email',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: AppColors.textPrimary),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'email@example.com',
                prefixIcon: Icon(Icons.email_outlined,
                    color: AppColors.textHint, size: 20),
              ),
            ),
            const SizedBox(height: 28),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Сохранить'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }
}
