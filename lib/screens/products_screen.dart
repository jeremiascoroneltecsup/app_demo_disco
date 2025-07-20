import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../utils/constants.dart';
import '../utils/app_utils.dart';
import '../widgets/common_widgets.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  int? _selectedCategoryId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProvider = context.read<DataProvider>();
      if (dataProvider.products.isEmpty) {
        dataProvider.loadProducts();
      }
      if (dataProvider.categories.isEmpty) {
        dataProvider.loadCategories();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _getFilteredProducts(DataProvider dataProvider) {
    var products = dataProvider.products;

    // Filter by category
    if (_selectedCategoryId != null) {
      products =
          products.where((p) => p.categoryId == _selectedCategoryId).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      products =
          products
              .where(
                (p) =>
                    p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();
    }

    return products;
  }

  String _getCategoryName(int categoryId, List<Category> categories) {
    final category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category(id: 0, name: 'Sin categoría'),
    );
    return category.name;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        if (dataProvider.isLoading) {
          return const LoadingWidget(message: 'Cargando productos...');
        }

        if (dataProvider.errorMessage != null) {
          return AppErrorWidget(
            message: dataProvider.errorMessage!,
            onRetry: () {
              dataProvider.loadProducts();
              dataProvider.loadCategories();
            },
          );
        }

        final filteredProducts = _getFilteredProducts(dataProvider);

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar productos...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                          : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Category filters
            if (dataProvider.categories.isNotEmpty) ...[
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        right: AppConstants.spacingS,
                      ),
                      child: FilterChip(
                        label: const Text('Todos'),
                        selected: _selectedCategoryId == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryId = null;
                          });
                        },
                      ),
                    ),
                    ...dataProvider.categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: AppConstants.spacingS,
                        ),
                        child: FilterChip(
                          label: Text(category.name),
                          selected: _selectedCategoryId == category.id,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryId =
                                  selected ? category.id : null;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
            ],

            // Products list
            Expanded(
              child:
                  filteredProducts.isEmpty
                      ? EmptyStateWidget(
                        title:
                            _searchQuery.isEmpty && _selectedCategoryId == null
                                ? 'No hay productos'
                                : 'No se encontraron productos',
                        subtitle:
                            _searchQuery.isEmpty && _selectedCategoryId == null
                                ? 'No hay productos registrados en el sistema'
                                : 'Intenta ajustar los filtros de búsqueda',
                        icon: Icons.inventory_2_outlined,
                        onAction:
                            _searchQuery.isNotEmpty ||
                                    _selectedCategoryId != null
                                ? () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedCategoryId = null;
                                  });
                                }
                                : null,
                        actionText: 'Limpiar filtros',
                      )
                      : RefreshIndicator(
                        onRefresh: () async {
                          await dataProvider.loadProducts();
                          await dataProvider.loadCategories();
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 1;
                            if (constraints.maxWidth >= 1200) {
                              crossAxisCount = 5;
                            } else if (constraints.maxWidth >= 900) {
                              crossAxisCount = 4;
                            } else if (constraints.maxWidth >= 600) {
                              crossAxisCount = 3;
                            }
                            return Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 1200),
                                child: GridView.builder(
                                  padding: const EdgeInsets.all(
                                    AppConstants.spacingM,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        childAspectRatio: 1.0,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = filteredProducts[index];
                                    return _buildProductCard(
                                      product,
                                      dataProvider.categories,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(Product product, List<Category> categories) {
    final stock = product.stock ?? 0;
    final isLowStock = stock <= 10;
    final isOutOfStock = stock <= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppConstants.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getCategoryName(product.categoryId ?? 0, categories),
                      style: AppConstants.bodyMedium.copyWith(
                        color: AppConstants.primaryColor.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOutOfStock || isLowStock) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isOutOfStock
                            ? Colors.red.shade100
                            : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isOutOfStock
                              ? Colors.red.shade300
                              : Colors.orange.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOutOfStock
                            ? Icons.remove_circle_outline
                            : Icons.warning_amber,
                        color:
                            isOutOfStock
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                        size: 13,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        isOutOfStock ? 'Sin stock' : 'Stock bajo',
                        style: AppConstants.bodyMedium.copyWith(
                          color:
                              isOutOfStock
                                  ? Colors.red.shade700
                                  : Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppConstants.successColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.attach_money,
                      color: AppConstants.successColor,
                      size: 15,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppUtils.formatCurrency(product.price),
                      style: AppConstants.labelLarge.copyWith(
                        color: AppConstants.successColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'precio',
                      style: AppConstants.bodyMedium.copyWith(
                        color: AppConstants.successColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppConstants.secondaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      color: AppConstants.secondaryColor,
                      size: 15,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.stock}',
                      style: AppConstants.labelLarge.copyWith(
                        color: AppConstants.secondaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'stock',
                      style: AppConstants.bodyMedium.copyWith(
                        color: AppConstants.secondaryColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
