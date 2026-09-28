part of 'inventory_bloc.dart';

enum InventoryStatus { initial, loading, loaded, empty, error }

class InventoryState extends Equatable {
  const InventoryState({
    required this.status,
    this.items = const [],
    this.query = '',
    this.filter = InventoryFilter.all,
    this.category = 'All',
    this.categories = const ['All'],
    this.errorMessage,
  });

  const InventoryState.initial() : this(status: InventoryStatus.initial);

  final InventoryStatus status;
  final List<InventoryItem> items;
  final String query;
  final InventoryFilter filter;
  final String category;
  final List<String> categories;
  final String? errorMessage;

  List<InventoryItem> get visible {
    return items.where((item) {
      final q = query.trim().toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          item.material.name.toLowerCase().contains(q) ||
          item.material.sku.toLowerCase().contains(q);
      final matchesCategory =
          category == 'All' || item.material.category == category;
      final matchesFilter = switch (filter) {
        InventoryFilter.all => true,
        InventoryFilter.available => item.available > 0,
        InventoryFilter.reserved => item.reserved > 0,
        InventoryFilter.lowStock => item.isLowStock,
      };
      return matchesQuery && matchesCategory && matchesFilter;
    }).toList();
  }

  InventoryState copyWith({
    InventoryStatus? status,
    List<InventoryItem>? items,
    String? query,
    InventoryFilter? filter,
    String? category,
    List<String>? categories,
    String? errorMessage,
  }) {
    return InventoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      category: category ?? this.category,
      categories: categories ?? this.categories,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    query,
    filter,
    category,
    categories,
    errorMessage,
  ];
}
