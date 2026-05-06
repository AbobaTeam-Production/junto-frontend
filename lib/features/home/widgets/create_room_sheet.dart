import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../room/widgets/media_source_picker.dart';
import '../../rooms/providers/room_providers.dart';
import '../../../l10n/app_localizations.dart';

class CreateRoomSheet extends ConsumerWidget {
  const CreateRoomSheet({super.key});

  Future<void> _onUpload(
    WidgetRef ref,
    BuildContext context,
    PlatformFile file,
    void Function(double) onProgress,
  ) async {
    final dio = ref.read(dioProvider);
    final readErrorMessage = AppLocalizations.of(context).createRoomFileReadError;
    final result = await createRoom(ref);
    await uploadFileInChunks(
      dio: dio,
      file: file,
      roomId: result.roomId,
      onProgress: onProgress,
      readErrorMessage: readErrorMessage,
    );
    ref.invalidate(myRoomsProvider);
    if (context.mounted) {
      Navigator.of(context).pop();
      context.push('/room/${result.roomId}');
    }
  }

  Future<void> _onTorrent(WidgetRef ref, BuildContext context, String magnet) async {
    final dio = ref.read(dioProvider);
    final result = await createRoom(ref);
    await dio.post(ApiEndpoints.mediaTorrent, data: {
      'room_id': result.roomId,
      'magnet_link': magnet,
    });
    ref.invalidate(myRoomsProvider);
    if (context.mounted) {
      Navigator.of(context).pop();
      context.push('/room/${result.roomId}');
    }
  }

  Future<void> _onRutube(WidgetRef ref, BuildContext context, String url) async {
    final dio = ref.read(dioProvider);
    final result = await createRoom(ref);
    await dio.post(ApiEndpoints.mediaYoutube, data: {
      'room_id': result.roomId,
      'url': url,
    });
    ref.invalidate(myRoomsProvider);
    if (context.mounted) {
      Navigator.of(context).pop();
      context.push('/room/${result.roomId}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    final messages = MediaSourcePickerMessages(
      sourceLabel: l.createRoomSourceLabel,
      uploadHint: l.createRoomUploadHint,
      fileFormats: l.createRoomFileFormats,
      searchHint: l.createRoomSearchHint,
      magnetHint: l.createRoomMagnetHint,
      magnetButton: l.createRoomMagnetButton,
      rutubeHint: l.createRoomRutubeHint,
      submitButton: l.createRoomButton,
      fileError: l.createRoomFileError,
      urlError: l.createRoomUrlError,
      magnetEmptyError: l.createRoomMagnetError,
      searchError: l.createRoomSearchError,
      genericError: l.createRoomError,
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
              l.createRoomTitle,
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
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }
}
