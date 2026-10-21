import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Loading / error / content switcher with a retry button.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.future, required this.builder, this.onRetry, this.loadingHeight = 120});

  final Future<T> future;
  final Widget Function(BuildContext, T) builder;
  final VoidCallback? onRetry;
  final double loadingHeight;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(
            height: loadingHeight,
            child: const Center(
              child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary)),
            ),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('Could not load. Check your connection.', style: AppTextStyles.small, textAlign: TextAlign.center),
                if (onRetry != null)
                  TextButton(onPressed: onRetry, child: Text('Retry', style: AppTextStyles.smallBold.copyWith(color: AppColors.primary))),
              ],
            ),
          );
        }
        return AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: builder(context, snap.data as T));
      },
    );
  }
}

/// Friendly empty state.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: const Color(0x1AFD6B22), borderRadius: BorderRadius.circular(28)),
            child: Icon(icon, color: AppColors.primary, size: 38),
          ),
          const SizedBox(height: 20),
          Text(title, style: AppTextStyles.navTitle, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message, style: AppTextStyles.small, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
  }
}
