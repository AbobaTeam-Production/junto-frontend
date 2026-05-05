import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'language_picker_sheet.dart';

class MicPickerSheet extends ConsumerStatefulWidget {
  const MicPickerSheet({super.key});

  @override
  ConsumerState<MicPickerSheet> createState() => _MicPickerSheetState();
}

class _MicPickerSheetState extends ConsumerState<MicPickerSheet> {
  late Future<List<MediaDevice>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDevices();
  }

  Future<List<MediaDevice>> _loadDevices() async {
    // LiveKit's `enumerateDevices` returns mics, cams and speakers; filter to
    // audio inputs. The browser only fills `label` after the user has granted
    // mic permission once — before that we still show the entries with
    // generic ids so the user can at least choose by index.
    final all = await Hardware.instance.enumerateDevices();
    return all.where((d) => d.kind == 'audioinput').toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = ref.watch(settingsProvider).micDeviceId;

    return SettingsSheetShell(
      title: l.profileMicrophone,
      children: [
        FutureBuilder<List<MediaDevice>>(
          future: _future,
          builder: (ctx, snap) {
            final loading = !snap.hasData && !snap.hasError;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SettingsSheetOption(
                  label: l.profileMicrophoneDefault,
                  selected: current.isEmpty,
                  onTap: () async {
                    await ref
                        .read(settingsProvider.notifier)
                        .setMicDeviceId('');
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (snap.hasError)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('${snap.error}',
                        style: AppTheme.text(size: 12, color: AppColors.ink3)),
                  )
                else
                  for (final d in snap.data!)
                    SettingsSheetOption(
                      label: d.label.isEmpty ? d.deviceId : d.label,
                      subtitle: d.label.isEmpty ? null : d.deviceId,
                      selected: current == d.deviceId,
                      onTap: () async {
                        await ref
                            .read(settingsProvider.notifier)
                            .setMicDeviceId(d.deviceId);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
              ],
            );
          },
        ),
      ],
    );
  }
}
