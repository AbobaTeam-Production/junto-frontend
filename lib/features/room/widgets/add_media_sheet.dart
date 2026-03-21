import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../rooms/providers/room_providers.dart';

const _kChunkSize = 5 * 1024 * 1024;

class AddMediaSheet extends ConsumerStatefulWidget {
  final String roomId;

  const AddMediaSheet({super.key, required this.roomId});

  @override
  ConsumerState<AddMediaSheet> createState() => _AddMediaSheetState();
}

class _AddMediaSheetState extends ConsumerState<AddMediaSheet> {
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
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _uploadFile() async {
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
        'chunk': MultipartFile.fromBytes(chunkBytes, filename: 'chunk_$i'),
        'chunk_index': i,
        'total_chunks': totalChunks,
        'room_id': widget.roomId,
        'filename': file.name,
      });

      await dio.post(ApiEndpoints.mediaUpload, data: formData);
      if (mounted) setState(() => _uploadProgress = (i + 1) / totalChunks);
    }
  }

  Future<void> _addMedia() async {
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
      final dio = ref.read(dioProvider);

      if (_selectedSource == 'upload') {
        await _uploadFile();
      } else if (_selectedSource == 'youtube') {
        await dio.post(ApiEndpoints.mediaYoutube, data: {
          'room_id': widget.roomId,
          'url': _urlController.text.trim(),
        });
      } else if (_selectedSource == 'torrent') {
        await dio.post(ApiEndpoints.mediaTorrent, data: {
          'room_id': widget.roomId,
          'magnet_link': _urlController.text.trim(),
        });
      }

      ref.invalidate(roomDetailProvider(widget.roomId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
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
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Добавить в очередь',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Источник',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildChip(Icons.upload_file_rounded, 'Файл', 'upload'),
                const SizedBox(width: 10),
                _buildChip(Icons.link_rounded, 'Торрент', 'torrent'),
                const SizedBox(width: 10),
                _buildChip(Icons.play_arrow_rounded, 'Rutube', 'youtube'),
              ],
            ),
            const SizedBox(height: 24),
            if (_selectedSource == 'upload') ...[
              GestureDetector(
                onTap: _loading ? null : _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _pickedFile != null ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: _pickedFile != null
                      ? Column(
                          children: [
                            const Icon(Icons.movie_outlined, color: AppColors.primary, size: 24),
                            const SizedBox(height: 8),
                            Text(
                              _pickedFile!.name,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_loading) ...[
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: _uploadProgress,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                color: AppColors.primary,
                                minHeight: 4,
                              ),
                              const SizedBox(height: 4),
                              Text('${(_uploadProgress * 100).toInt()}%',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ],
                        )
                      : const Column(
                          children: [
                            Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 24),
                            SizedBox(height: 8),
                            Text('Нажмите для выбора файла',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          ],
                        ),
                ),
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
                    _selectedSource == 'torrent' ? Icons.link_rounded : Icons.play_arrow_rounded,
                    color: AppColors.textHint, size: 20,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _addMedia,
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Добавить'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, String value) {
    final selected = _selectedSource == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSource = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: selected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
