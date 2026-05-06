import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../rooms/providers/room_providers.dart';
import 'media_source_picker.dart';
import '../../../l10n/app_localizations.dart';

class AddMediaSheet extends ConsumerWidget {
  final String roomId;

  const AddMediaSheet({super.key, required this.roomId});

  Future<void> _onUpload(
    WidgetRef ref,
    BuildContext context,
    PlatformFile file,
    void Function(double) onProgress,
  ) async {
    final dio = ref.read(dioProvider);
    final readErrorMessage = AppLocalizations.of(context).addMediaFileReadError;
    await uploadFileInChunks(
      dio: dio,
      file: file,
      roomId: roomId,
      onProgress: onProgress,
      readErrorMessage: readErrorMessage,
    );
    ref.invalidate(roomDetailProvider(roomId));
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _onTorrent(WidgetRef ref, BuildContext context, String magnet) async {
    final dio = ref.read(dioProvider);
    await dio.post(ApiEndpoints.mediaTorrent, data: {
      'room_id': roomId,
      'magnet_link': magnet,
    });
    ref.invalidate(roomDetailProvider(roomId));
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _onRutube(WidgetRef ref, BuildContext context, String url) async {
    final dio = ref.read(dioProvider);
    await dio.post(ApiEndpoints.mediaYoutube, data: {
      'room_id': roomId,
      'url': url,
    });
    ref.invalidate(roomDetailProvider(roomId));
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    final messages = MediaSourcePickerMessages(
      sourceLabel: l.addMediaSourceLabel,
      uploadHint: l.addMediaUploadHint,
      fileFormats: null,
      searchHint: l.addMediaSearchHint,
      magnetHint: l.addMediaMagnetHint,
      magnetButton: l.addMediaMagnetButton,
      rutubeHint: l.addMediaRutubeHint,
      submitButton: l.addMediaButton,
      fileError: l.addMediaFileError,
      urlError: l.addMediaUrlError,
      magnetEmptyError: l.addMediaMagnetError,
      searchError: l.addMediaSearchError,
      genericError: l.addMediaError,
    );

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
              l.addMediaTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 24),
            MediaSourcePicker(
              messages: messages,
              onUpload: (file, onProgress) =>
                  _onUpload(ref, context, file, onProgress),
              onTorrent: (magnet) => _onTorrent(ref, context, magnet),
              onRutube: (url) => _onRutube(ref, context, url),
            ),
          ],
        ),
      ),
    );
  }
}
