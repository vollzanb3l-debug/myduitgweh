import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_state.dart';

/// Widget pembungkus AsyncValue dengan batas waktu (timeout 10 detik) bawaan.
/// Menangani kondisi: loading (maks 10 detik, jika lebih tampilkan error + Coba lagi), error, dan data.
class AppAsyncBuilder<T> extends StatefulWidget {
  final AsyncValue<T> asyncValue;
  final Widget Function(BuildContext context, T data) data;
  final Widget Function(BuildContext context, Object error, StackTrace? stack)? error;
  final Widget Function(BuildContext context)? loading;
  final VoidCallback? onRetry;
  final Duration timeout;
  final String timeoutMessage;

  const AppAsyncBuilder({
    super.key,
    required this.asyncValue,
    required this.data,
    this.error,
    this.loading,
    this.onRetry,
    this.timeout = const Duration(seconds: 10),
    this.timeoutMessage = 'Waktu memuat melebihi batas (10 detik). Silakan coba lagi.',
  });

  @override
  State<AppAsyncBuilder<T>> createState() => _AppAsyncBuilderState<T>();
}

class _AppAsyncBuilderState<T> extends State<AppAsyncBuilder<T>> {
  Timer? _timeoutTimer;
  bool _hasTimedOut = false;

  @override
  void initState() {
    super.initState();
    _checkLoadingTimeout();
  }

  @override
  void didUpdateWidget(covariant AppAsyncBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.asyncValue.isLoading && !oldWidget.asyncValue.isLoading) {
      _hasTimedOut = false;
      _checkLoadingTimeout();
    } else if (!widget.asyncValue.isLoading) {
      _cancelTimer();
      _hasTimedOut = false;
    }
  }

  void _checkLoadingTimeout() {
    _cancelTimer();
    if (widget.asyncValue.isLoading) {
      _timeoutTimer = Timer(widget.timeout, () {
        if (mounted && widget.asyncValue.isLoading) {
          setState(() {
            _hasTimedOut = true;
          });
        }
      });
    }
  }

  void _cancelTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasTimedOut && widget.asyncValue.isLoading) {
      return widget.error?.call(
            context,
            TimeoutException(widget.timeoutMessage),
            null,
          ) ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ErrorState(
                title: 'Gagal Memuat Data',
                message: widget.timeoutMessage,
                onRetry: () {
                  setState(() {
                    _hasTimedOut = false;
                  });
                  _checkLoadingTimeout();
                  widget.onRetry?.call();
                },
              ),
            ),
          );
    }

    return widget.asyncValue.when(
      data: (val) => widget.data(context, val),
      error: (err, stack) {
        return widget.error?.call(context, err, stack) ??
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ErrorState(
                  title: 'Terjadi Kendala',
                  message: 'Gagal memuat data: $err',
                  onRetry: () {
                    widget.onRetry?.call();
                  },
                ),
              ),
            );
      },
      loading: () {
        return widget.loading?.call(context) ??
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            );
      },
    );
  }
}
