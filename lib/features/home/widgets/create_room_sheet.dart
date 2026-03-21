import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../rooms/providers/room_providers.dart';

const _kChunkSize = 5 * 1024 * 1024; // 5 MB

class CreateRoomSheet extends ConsumerStatefulWidget {
  const CreateRoomSheet({super.key});

  @override
  ConsumerState<CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends ConsumerState<CreateRoomSheet> {
  String _selectedSource = 'upload';
  final _urlController = TextEditingController();
  bool _loading = false;
  PlatformFile? _pickedFile;
  double _uploadProgress = 0;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'avi', 'mov', 'webm'],
      withData: true, // load bytes into memory for cross-platform support
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _uploadFile(String roomId) async {
    final file = _pickedFile;
    if (file == null) return;

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Не удалось прочитать файл');
    }

    final fileSize = bytes.length;
    final totalChunks = (fileSize / _kChunkSize).ceil();
    final dio = ref.read(dioProvider);

    for (var i = 0; i < totalChunks; i++) {
      final start = i * _kChunkSize;
      final end = (start + _kChunkSize > fileSize) ? fileSize : start + _kChunkSize;
      final chunkBytes = bytes.sublist(start, end);

      final formData = FormData.fromMap({
        'chunk': MultipartFile.fromBytes(
          chunkBytes,
          filename: 'chunk_$i',
        ),
        'chunk_index': i,
        'total_chunks': totalChunks,
        'room_id': roomId,
        'filename': file.name,
      });

      await dio.post(ApiEndpoints.mediaUpload, data: formData);

      if (mounted) {
        setState(() => _uploadProgress = (i + 1) / totalChunks);
      }
    }
  }

  Future<void> _createRoom() async {
    // Validate inputs
    if (_selectedSource == 'upload' && _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите файл')),
      );
      return;
    }
    if (_selectedSource != 'upload' && _urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вставьте ссылку')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _uploadProgress = 0;
    });

    try {
      final result = await createRoom(ref);
      final roomId = result.roomId;

      // Send media to backend
      if (_selectedSource == 'upload') {
        await _uploadFile(roomId);
      } else if (_selectedSource == 'youtube') {
        await ref.read(dioProvider).post(
          ApiEndpoints.mediaYoutube,
          data: {'room_id': roomId, 'url': _urlController.text.trim()},
        );
      } else if (_selectedSource == 'torrent') {
        await ref.read(dioProvider).post(
          ApiEndpoints.mediaTorrent,
          data: {
            'room_id': roomId,
            'magnet_link': _urlController.text.trim(),
          },
        );
      }

      ref.invalidate(myRoomsProvider);
      if (mounted) {
        Navigator.of(context).pop();
        context.push('/room/$roomId');
      }
    } catch (e) {
      debugPrint('CreateRoom error: $e');
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
              'Создать комнату',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 24),

            // Source type selector
            Text(
              'Источник контента',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _SourceChip(
                  icon: Icons.upload_file_rounded,
                  label: 'Файл',
                  selected: _selectedSource == 'upload',
                  onTap: () => setState(() => _selectedSource = 'upload'),
                ),
                const SizedBox(width: 10),
                _SourceChip(
                  icon: Icons.link_rounded,
                  label: 'Торрент',
                  selected: _selectedSource == 'torrent',
                  onTap: () => setState(() => _selectedSource = 'torrent'),
                ),
                const SizedBox(width: 10),
                _SourceChip(
                  icon: Icons.play_arrow_rounded,
                  label: 'Rutube',
                  selected: _selectedSource == 'youtube',
                  onTap: () => setState(() => _selectedSource = 'youtube'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Source-specific input
            if (_selectedSource == 'upload') ...[
              _UploadArea(
                pickedFile: _pickedFile,
                onTap: _loading ? null : _pickFile,
                uploadProgress: _loading ? _uploadProgress : null,
              ),
            ] else ...[
              TextField(
                controller: _urlController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: _selectedSource == 'torrent'
                      ? 'magnet:// или ссылка на .torrent'
                      : 'Ссылка на Rutube',
                  prefixIcon: Icon(
                    _selectedSource == 'torrent'
                        ? Icons.link_rounded
                        : Icons.play_arrow_rounded,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _createRoom,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Создать'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SourceChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

class _UploadArea extends StatelessWidget {
  final PlatformFile? pickedFile;
  final VoidCallback? onTap;
  final double? uploadProgress;

  const _UploadArea({
    required this.pickedFile,
    required this.onTap,
    this.uploadProgress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: pickedFile != null ? AppColors.primary : AppColors.border,
          ),
        ),
        child: pickedFile != null
            ? Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.movie_outlined,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pickedFile!.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatFileSize(pickedFile!.size),
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                  if (uploadProgress != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: uploadProgress,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        color: AppColors.primary,
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(uploadProgress! * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              )
            : Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cloud_upload_outlined,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Нажмите для выбора файла',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MP4, MKV, AVI, MOV — до 10 ГБ',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
