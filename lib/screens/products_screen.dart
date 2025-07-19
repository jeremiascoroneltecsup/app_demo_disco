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
      products = products.where((p) => p.categoryId == _selectedCategoryId).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      products = products
          .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DataProvider>().loadProducts();
              context.read<DataProvider>().loadCategories();
            },
          ),
        ],
      ),
      body: Consumer<DataProvider>(
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
                    suffixIcon: _searchQuery.isNotEmpty
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
                        padding: const EdgeInsets.only(right: AppConstants.spacingS),
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
                          padding: const EdgeInsets.only(right: AppConstants.spacingS),
                          child: FilterChip(
                            label: Text(category.name),
                            selected: _selectedCategoryId == category.id,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryId = selected ? category.id : null;
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
                child: filteredProducts.isEmpty
                    ? EmptyStateWidget(
                        title: _searchQuery.isEmpty && _selectedCategoryId == null
                            ? 'No hay productos'
                            : 'No se encontraron productos',
                        subtitle: _searchQuery.isEmpty && _selectedCategoryId == null
                            ? 'No hay productos registrados en el sistema'
                            : 'Intenta ajustar los filtros de búsqueda',
                        icon: Icons.inventory_2_outlined,
                        onAction: _searchQuery.isNotEmpty || _selectedCategoryId != null
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
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppConstants.spacingM),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return _buildProductCard(product, dataProvider.categories);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product, List<Category> categories) {
    final stock = product.stock ?? 0;
    final isLowStock = stock <= 10;
    final isOutOfStock = stock <= 0;

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppConstants.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      _getCategoryName(product.categoryId ?? 0, categories),
                      style: AppConstants.bodyMedium.copyWith(
                        color: AppConstants.primaryColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppUtils.formatCurrency(product.price),
                    style: AppConstants.titleMedium.copyWith(
                      color: AppConstants.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingS,
                      vertical: AppConstants.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? AppConstants.errorColor.withOpacity(0.1)
                          : isLowStock
                              ? AppConstants.warningColor.withOpacity(0.1)
                              : AppConstants.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                      border: Border.all(
                        color: isOutOfStock
                            ? AppConstants.errorColor.withOpacity(0.3)
                            : isLowStock
                                ? AppConstants.warningColor.withOpacity(0.3)
                                : AppConstants.successColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOutOfStock
                              ? Icons.remove_circle_outline
                              : isLowStock
                                  ? Icons.warning_amber
                                  : Icons.check_circle_outline,
                          size: 16,
                          color: isOutOfStock
                              ? AppConstants.errorColor
                              : isLowStock
                                  ? AppConstants.warningColor
                                  : AppConstants.successColor,
                        ),
                        const SizedBox(width: AppConstants.spacingXS),
                        Text(
                          'Stock: ${product.stock}',
                          style: AppConstants.bodyMedium.copyWith(
                            color: isOutOfStock
                                ? AppConstants.errorColor
                                : isLowStock
                                    ? AppConstants.warningColor
                                    : AppConstants.successColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
