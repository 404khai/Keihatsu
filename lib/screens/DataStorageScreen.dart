import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/CustomBackButton.dart';
import 'package:keihatsu/services/file_service.dart';
import 'package:keihatsu/theme_provider.dart';
import 'package:provider/provider.dart';

class DataStorageScreen extends StatefulWidget {
  const DataStorageScreen({super.key});

  @override
  State<DataStorageScreen> createState() => _DataStorageScreenState();
}

class _DataStorageScreenState extends State<DataStorageScreen> {
  static const MethodChannel _storageChannel = MethodChannel(
    'keihatsu/storage',
  );
  final FileService _fileService = FileService();

  String? _downloadsPath;
  int _downloadsBytes = 0;
  int? _totalBytes;
  int? _freeBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStorage();
  }

  Future<void> _loadStorage() async {
    try {
      final results = await Future.wait([
        _fileService.getDownloadsDirectoryPath(),
        _fileService.getDownloadsSize(),
        _storageChannel.invokeMethod<Map<Object?, Object?>>('getStorageStats'),
      ]);
      final stats = results[2] as Map<Object?, Object?>?;

      if (!mounted) return;
      setState(() {
        _downloadsPath = results[0] as String;
        _downloadsBytes = results[1] as int;
        _totalBytes = (stats?['totalBytes'] as num?)?.toInt();
        _freeBytes = (stats?['freeBytes'] as num?)?.toInt();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color brandColor = themeProvider.brandColor;
    final int usedBytes = _totalBytes != null && _freeBytes != null
        ? (_totalBytes! - _freeBytes!).clamp(0, _totalBytes!).toInt()
        : _downloadsBytes;
    final double storageFraction = _totalBytes == null || _totalBytes == 0
        ? (_downloadsBytes == 0 ? 0 : 1)
        : (usedBytes / _totalBytes!).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        leading: const CustomBackButton(),
        title: Text(
          'Data & Storage',
          style: GoogleFonts.unbounded(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: brandColor))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _sectionLabel(context, 'Downloads'),
                const SizedBox(height: 10),
                _surfaceCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            color: brandColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Download directory',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _downloadsPath ?? 'Unavailable',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${_formatBytes(_downloadsBytes)} used by Keihatsu downloads',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _sectionLabel(context, 'Device storage'),
                const SizedBox(height: 10),
                _surfaceCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _totalBytes == null
                                ? 'Storage usage'
                                : '${_formatBytes(usedBytes)} used',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (_totalBytes != null)
                            Text(
                              '${_formatBytes(_freeBytes ?? 0)} free',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          minHeight: 12,
                          value: storageFraction,
                          color: brandColor,
                          backgroundColor: cs.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _totalBytes == null
                            ? 'Storage details will appear when the device reports them.'
                            : '${_formatBytes(_totalBytes!)} total storage',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        letterSpacing: 1.1,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _surfaceCard(BuildContext context, {required Widget child}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}
