// Dio-based image loader with explicit retry, in-memory cache, and
// a global concurrency cap.
//
// Without the concurrency cap, opening the recs feed kicks off 30+
// poster fetches in parallel through a single TLS connection to the
// CF Worker; head-of-line blocking causes a fraction of streams to
// receive-timeout after 12s. With max-4 in flight at a time, every
// fetch completes in under a second.

import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class RetryableNetworkImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final Widget Function(BuildContext) placeholderBuilder;
  final int maxAttempts;

  const RetryableNetworkImage({
    super.key,
    required this.url,
    required this.placeholderBuilder,
    this.fit = BoxFit.cover,
    this.maxAttempts = 4,
  });

  @override
  State<RetryableNetworkImage> createState() => _RetryableNetworkImageState();
}

class _RetryableNetworkImageState extends State<RetryableNetworkImage> {
  static final Map<String, Uint8List> _memCache = {};
  static final Map<String, Future<Uint8List?>> _inflight = {};
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 8),
    responseType: ResponseType.bytes,
    followRedirects: true,
    validateStatus: (s) => s != null && s >= 200 && s < 400,
  ));
  static final _gate = _Semaphore(4);

  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant RetryableNetworkImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _bytes = null;
      _start();
    }
  }

  Future<void> _start() async {
    final cached = _memCache[widget.url];
    if (cached != null) {
      if (mounted) setState(() => _bytes = cached);
      return;
    }
    final fut = _inflight[widget.url] ?? _fetchWithRetry(widget.url);
    _inflight[widget.url] = fut;
    final bytes = await fut;
    _inflight.remove(widget.url);
    if (!mounted) return;
    if (bytes != null) {
      _memCache[widget.url] = bytes;
      setState(() => _bytes = bytes);
    } else {
      setState(() {});
    }
  }

  Future<Uint8List?> _fetchWithRetry(String url) async {
    for (var attempt = 0; attempt < widget.maxAttempts; attempt++) {
      await _gate.acquire();
      try {
        final resp = await _dio.get<List<int>>(url);
        final data = resp.data;
        if (data == null || data.isEmpty) {
          throw Exception('empty body');
        }
        final cl = resp.headers.value('content-length');
        if (cl != null) {
          final expected = int.tryParse(cl) ?? 0;
          if (expected > 0 && data.length < expected) {
            throw Exception('short read $expected vs ${data.length}');
          }
        }
        return Uint8List.fromList(data);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('RetryableNetworkImage attempt=$attempt url=$url err=$e');
        }
        await Future<void>.delayed(
            Duration(milliseconds: 300 * (attempt + 1)));
      } finally {
        _gate.release();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (ctx, _, _) => widget.placeholderBuilder(ctx),
      );
    }
    return widget.placeholderBuilder(context);
  }
}

class _Semaphore {
  final int max;
  int _current = 0;
  final Queue<Completer<void>> _waiters = Queue();
  _Semaphore(this.max);

  Future<void> acquire() {
    if (_current < max) {
      _current++;
      return Future.value();
    }
    final c = Completer<void>();
    _waiters.add(c);
    return c.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
    } else {
      _current--;
    }
  }
}
