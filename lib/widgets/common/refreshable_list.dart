import 'package:flutter/material.dart';

/// Widget reutilizable que provee pull-to-refresh y lista scrolleable.
/// Maneja estados de loading, error, y empty state automáticamente.
///
/// Estados resueltos en orden:
/// 1. Si `isLoading` es true → CircularProgressIndicator centrado
/// 2. Si `errorMessage` es no-nulo → mensaje error + botón reintentar
/// 3. Si `items` está vacío → `emptyMessage`
/// 4. Si `items` tiene datos → lista con pull-to-refresh
///
/// Uso:
/// ```dart
/// RefreshableList<Documento>(
///   items: provider.documentos,
///   isLoading: provider.isLoading,
///   errorMessage: provider.errorMessage,
///   onRefresh: provider.reload,
///   itemBuilder: (context, doc, index) => DocumentCard(doc: doc),
/// )
/// ```
class RefreshableList<T> extends StatelessWidget {
  /// Lista de elementos a renderizar.
  final List<T> items;

  /// Indica si se está cargando la primera página.
  final bool isLoading;

  /// Mensaje de error a mostrar, o null si no hay error.
  final String? errorMessage;

  /// Mensaje a mostrar cuando la lista está vacía.
  final String emptyMessage;

  /// WidgetBuilder que renderiza cada item de la lista.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Callback ejecutado al hacer pull-to-refresh.
  /// Debe retornar un Future que se completa cuando el refresh termina.
  final Future<void> Function() onRefresh;

  /// Callback opcional para cargar más elementos (infinite scroll).
  final Future<void> Function()? onLoadMore;

  /// Callback opcional cuando se presiona el botón de reintentar en error.
  /// Si no se provee, usa `onRefresh` por defecto.
  final Future<void> Function()? onRetry;

  /// Padding horizontal de la lista. Por defecto 0.
  final double horizontalPadding;

  /// Separación entre items. Por defecto 8.
  final double itemSpacing;

  /// Altura fija del ListView interno. Si es null, usa expanded (para scroll propio).
  final double? height;

  const RefreshableList({
    super.key,
    required this.items,
    required this.isLoading,
    this.errorMessage,
    this.emptyMessage = 'No hay elementos',
    required this.itemBuilder,
    required this.onRefresh,
    this.onLoadMore,
    this.onRetry,
    this.horizontalPadding = 0,
    this.itemSpacing = 8,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          height: height ?? 200,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (errorMessage != null) {
      return SizedBox(
        height: height ?? 200,
        child: _ErrorState(
          message: errorMessage!,
          onRetry: onRetry ?? onRefresh,
        ),
      );
    }

    if (items.isEmpty) {
      return SizedBox(
        height: height ?? 200,
        child: Center(
          child: Text(
            emptyMessage,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
          ),
        ),
      );
    }

    Widget listView = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (onLoadMore != null &&
            notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 100) {
          onLoadMore!();
        }
        return false;
      },
      child: ListView.separated(
        shrinkWrap: height == null,
        physics: height == null ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, index) => SizedBox(height: itemSpacing),
        itemBuilder: (context, index) => itemBuilder(context, items[index], index),
      ),
    );

    if (height != null) {
      return SizedBox(
        height: height,
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: listView,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: listView,
    );
  }
}

/// Widget interno que muestra el estado de error con botón de reintentar.
class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
