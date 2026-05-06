import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../l10n/app_localizations.dart';
import 'torrent_result_tile.dart';

const _kChunkSize = 5 * 1024 * 1024; // 5 MB

typedef SourceUploadHandler = Future<void> Function(
  PlatformFile file,
  void Function(double progress) onProgress,
);
typedef SourceTorrentHandler = Future<void> Function(String magnet);
typedef SourceRutubeHandler = Future<void> Function(String url);

class MediaSourcePickerMessages {
  final String sourceLabel;
  final String uploadHint;
  final String? fileFormats;
  final String searchHint;
  final String magnetHint;
  final String magnetButton;
  final String rutubeHint;
  final String submitButton;
  final String fileError;
  final String urlError;
  final String magnetEmptyError;
  final String Function(String details) searchError;
  final String Function(String details) genericError;

  const MediaSourcePickerMessages({
    required this.sourceLabel,
    required this.uploadHint,
    required this.fileFormats,
    required this.searchHint,
    required this.magnetHint,
    required this.magnetButton,
    required this.rutubeHint,
    required this.submitButton,
    required this.fileError,
    required this.urlError,
    required this.magnetEmptyError,
    required this.searchError,
    required this.genericError,
  });
}

/// Chunked file upload to `/api/media/upload/`. Caller must already have a roomId.
Future<void> uploadFileInChunks({
  required Dio dio,
  required PlatformFile file,
  required String roomId,
  required void Function(double progress) onProgress,
  String? readErrorMessage,
}) async {
  final bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) {
    throw Exception(readErrorMessage ?? 'Failed to read file bytes');
  }

  final fileSize = bytes.length;
  final totalChunks = (fileSize / _kChunkSize).ceil();

  for (var i = 0; i < totalChunks; i++) {
    final start = i * _kChunkSize;
    final end = (start + _kChunkSize > fileSize) ? fileSize : start + _kChunkSize;
    final chunkBytes = bytes.sublist(start, end);

    final formData = FormData.fromMap({
      'chunk': MultipartFile.fromBytes(chunkBytes, filename: 'chunk_$i'),
      'chunk_index': i,
      'total_chunks': totalChunks,
      'room_id': roomId,
      'filename': file.name,
    });

    await dio.post(ApiEndpoints.mediaUpload, data: formData);
    onProgress((i + 1) / totalChunks);
  }
}

class MediaSourcePicker extends ConsumerStatefulWidget {
  final MediaSourcePickerMessages messages;
  final SourceUploadHandler onUpload;
  final SourceTorrentHandler onTorrent;
  final SourceRutubeHandler onRutube;

  const MediaSourcePicker({
    super.key,
    required this.messages,
    required this.onUpload,
    required this.onTorrent,
    required this.onRutube,
  });

  @override
  ConsumerState<MediaSourcePicker> createState() => _MediaSourcePickerState();
}

class _MediaSourcePickerState extends ConsumerState<MediaSourcePicker> {
  String _selectedSource = 'upload';
  final _urlController = TextEditingController();
  final _searchController = TextEditingController();
  bool _loading = false;
  PlatformFile? _pickedFile;
  double _uploadProgress = 0;

  bool _searching = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _resolvingMagnet = false;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
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

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _runSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _searchResults = [];
    });

    try {
      final dio = ref.read(dioProvider);
      // Build URL manually: Dio's queryParameters has been observed to emit
      // CP1251-encoded bytes for Cyrillic on Flutter Web.
      final resp = await dio.get(
        '${ApiEndpoints.torrentSearch}?q=${Uri.encodeQueryComponent(query)}',
      );
      final list = (resp.data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (mounted) setState(() => _searchResults = list);
    } catch (e) {
      _showSnack(widget.messages.searchError(e.toString()));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _selectTorrent(Map<String, dynamic> item) async {
    final magnet = (item['magnet'] as String?)?.trim() ?? '';
    if (magnet.isEmpty) {
      _showSnack(widget.messages.magnetEmptyError);
      return;
    }
    setState(() => _resolvingMagnet = true);
    try {
      await widget.onTorrent(magnet);
      // On success the parent typically pops/navigates — we don't reset state.
    } catch (e) {
      if (mounted) {
        setState(() => _resolvingMagnet = false);
        _showSnack(widget.messages.genericError(e.toString()));
      }
    }
  }

  Future<void> _onSubmit() async {
    final m = widget.messages;
    if (_selectedSource == 'upload' && _pickedFile == null) {
      _showSnack(m.fileError);
      return;
    }
    if (_selectedSource != 'upload' && _urlController.text.trim().isEmpty) {
      _showSnack(m.urlError);
      return;
    }

    setState(() {
      _loading = true;
      _uploadProgress = 0;
    });

    try {
      if (_selectedSource == 'upload') {
        await widget.onUpload(_pickedFile!, (p) {
          if (mounted) setState(() => _uploadProgress = p);
        });
      } else if (_selectedSource == 'torrent') {
        await widget.onTorrent(_urlController.text.trim());
      } else {
        await widget.onRutube(_urlController.text.trim());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _uploadProgress = 0;
        });
        _showSnack(m.genericError(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = widget.messages;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          m.sourceLabel,
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
              label: l.sourceFile,
              selected: _selectedSource == 'upload',
              onTap: () => setState(() => _selectedSource = 'upload'),
            ),
            const SizedBox(width: 10),
            _SourceChip(
              icon: Icons.link_rounded,
              label: l.sourceTorrent,
              selected: _selectedSource == 'torrent',
              onTap: () => setState(() => _selectedSource = 'torrent'),
            ),
            const SizedBox(width: 10),
            _SourceChip(
              icon: Icons.play_arrow_rounded,
              label: l.sourceRutube,
              selected: _selectedSource == 'youtube',
              onTap: () => setState(() => _selectedSource = 'youtube'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_selectedSource == 'upload') ...[
          _UploadArea(
            pickedFile: _pickedFile,
            onTap: _loading ? null : _pickFile,
            uploadProgress: _loading ? _uploadProgress : null,
            uploadHint: m.uploadHint,
            fileFormats: m.fileFormats,
          ),
          const SizedBox(height: 28),
          _SubmitButton(
            label: m.submitButton,
            loading: _loading,
            onPressed: _loading ? null : _onSubmit,
          ),
        ] else if (_selectedSource == 'torrent') ...[
          TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _runSearch(),
            decoration: InputDecoration(
              hintText: m.searchHint,
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      onPressed: _runSearch,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: m.magnetHint,
              prefixIcon: const Icon(Icons.link_rounded, color: AppColors.textHint, size: 20),
            ),
          ),
          if (_urlController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _SubmitButton(
              label: m.magnetButton,
              loading: _loading,
              onPressed: _loading ? null : _onSubmit,
            ),
          ],
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            if (_resolvingMagnet)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: AppColors.divider, height: 1),
                  itemBuilder: (context, index) {
                    final r = _searchResults[index];
                    return TorrentResultTile(
                      result: r,
                      onTap: () => _selectTorrent(r),
                    );
                  },
                ),
              ),
          ],
        ] else ...[
          TextField(
            controller: _urlController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: m.rutubeHint,
              prefixIcon: const Icon(Icons.play_arrow_rounded, color: AppColors.textHint, size: 20),
            ),
          ),
          const SizedBox(height: 28),
          _SubmitButton(
            label: m.submitButton,
            loading: _loading,
            onPressed: _loading ? null : _onSubmit,
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label),
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
  final String uploadHint;
  final String? fileFormats;

  const _UploadArea({
    required this.pickedFile,
    required this.onTap,
    required this.uploadHint,
    required this.fileFormats,
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
                  Text(
                    uploadHint,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  if (fileFormats != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      fileFormats!,
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
