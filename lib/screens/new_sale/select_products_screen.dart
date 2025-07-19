import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/sale_provider.dart';
import '../../models/product.dart';
import '../../models/promotion.dart';
import '../../models/category.dart' as models;
import '../../utils/constants.dart';
import '../../utils/app_utils.dart';
import '../../widgets/common_widgets.dart';
import 'cart_screen.dart';

class SelectProductsScreen extends StatefulWidget {
  const SelectProductsScreen({super.key});

  @override
  State<SelectProductsScreen> createState() => _SelectProductsScreenState();
}

class _SelectProductsScreenState extends State<SelectProductsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedCategoryId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProvider = context.read<DataProvider>();
      if (dataProvider.products.isEmpty) {
        dataProvider.loadProducts();
      }
      if (dataProvider.categories.isEmpty) {
        dataProvider.loadCategories();
      }
      if (dataProvider.promotions.isEmpty) {
        dataProvider.loadPromotions();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _getFilteredProducts(DataProvider dataProvider) {
    var products = dataProvider.availableProducts; // Only products with stock

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

  List<Promotion> _getFilteredPromotions(DataProvider dataProvider) {
    var promotions = dataProvider.activePromotions;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      promotions = promotions
          .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return promotions;
  }

  String _getCategoryName(int categoryId, List<models.Category> categories) {
    final category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => models.Category(id: 0, name: 'Sin categoría'),
    );
    return category.name;
  }

  void _goToCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CartScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta - Seleccionar Productos'),
        actions: [
          Consumer<SaleProvider>(
            builder: (context, saleProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: saleProvider.cart.isEmpty ? null : _goToCart,
                  ),
                  if (saleProvider.cart.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppConstants.errorColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '${saleProvider.cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Productos', icon: Icon(Icons.inventory_2)),
            Tab(text: 'Promociones', icon: Icon(Icons.local_offer)),
          ],
        ),
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
                dataProvider.loadPromotions();
              },
            );
          }

          return Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              
              // Search bar
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar productos o promociones...',
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

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProductsTab(dataProvider),
                    _buildPromotionsTab(dataProvider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<SaleProvider>(
        builder: (context, saleProvider, child) {
          return Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: ${AppUtils.formatCurrency(saleProvider.subtotal)}',
                        style: AppConstants.titleMedium.copyWith(
                          color: AppConstants.successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (saleProvider.cart.itemCount > 0)
                        Text(
                          '${saleProvider.cart.itemCount} productos en el carrito',
                          style: AppConstants.bodyMedium.copyWith(
                            color: AppConstants.primaryColor.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                ElevatedButton(
                  onPressed: saleProvider.cart.isEmpty ? null : _goToCart,
                  child: const Text('Ver Carrito'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        children: [
          _buildProgressStep(1, 'Mesa', isActive: false, isCompleted: true),
          _buildProgressConnector(isCompleted: true),
          _buildProgressStep(2, 'Productos', isActive: true, isCompleted: false),
          _buildProgressConnector(isCompleted: false),
          _buildProgressStep(3, 'Pago', isActive: false, isCompleted: false),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, {required bool isActive, required bool isCompleted}) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isCompleted 
                ? AppConstants.successColor 
                : isActive 
                    ? AppConstants.primaryColor 
                    : AppConstants.primaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    step.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingXS),
        Text(
          label,
          style: AppConstants.bodyMedium.copyWith(
            color: isActive 
                ? AppConstants.primaryColor 
                : AppConstants.primaryColor.withOpacity(0.7),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressConnector({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingS),
        decoration: BoxDecoration(
          color: isCompleted 
              ? AppConstants.successColor 
              : AppConstants.primaryColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildProductsTab(DataProvider dataProvider) {
    final filteredProducts = _getFilteredProducts(dataProvider);

    return Column(
      children: [
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

        // Products grid
        Expanded(
          child: filteredProducts.isEmpty
              ? EmptyStateWidget(
                  title: 'No hay productos disponibles',
                  subtitle: _searchQuery.isEmpty && _selectedCategoryId == null
                      ? 'No hay productos con stock disponible'
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
              : GridView.builder(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppConstants.spacingM,
                    mainAxisSpacing: AppConstants.spacingM,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(product, dataProvider.categories);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPromotionsTab(DataProvider dataProvider) {
    final filteredPromotions = _getFilteredPromotions(dataProvider);

    return filteredPromotions.isEmpty
        ? EmptyStateWidget(
            title: 'No hay promociones disponibles',
            subtitle: _searchQuery.isEmpty
                ? 'No hay promociones activas en este momento'
                : 'No se encontraron promociones con ese nombre',
            icon: Icons.local_offer_outlined,
            onAction: _searchQuery.isNotEmpty
                ? () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  }
                : null,
            actionText: 'Limpiar búsqueda',
          )
        : ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            itemCount: filteredPromotions.length,
            itemBuilder: (context, index) {
              final promotion = filteredPromotions[index];
              return _buildPromotionCard(promotion);
            },
          );
  }

  Widget _buildProductCard(Product product, List<models.Category> categories) {
    return Consumer<SaleProvider>(
      builder: (context, saleProvider, child) {
        return AppCard(
          onTap: () {
            saleProvider.addProductToCart(product);
            AppUtils.showSuccessSnackBar(
              context,
              '${product.name} agregado al carrito',
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      _getCategoryName(product.categoryId, categories),
                      style: AppConstants.bodyMedium.copyWith(
                        color: AppConstants.primaryColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      AppUtils.formatCurrency(product.price),
                      style: AppConstants.titleMedium.copyWith(
                        color: AppConstants.successColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stock: ${product.stock}',
                    style: AppConstants.bodyMedium.copyWith(
                      color: product.stock <= 10
                          ? AppConstants.warningColor
                          : AppConstants.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.add_circle,
                    color: AppConstants.primaryColor,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPromotionCard(Promotion promotion) {
    return Consumer<SaleProvider>(
      builder: (context, saleProvider, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
          child: AppCard(
            onTap: () {
              saleProvider.addPromotionToCart(promotion);
              AppUtils.showSuccessSnackBar(
                context,
                '${promotion.name} agregado al carrito',
              );
            },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promotion.name,
                        style: AppConstants.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      Text(
                        '${promotion.totalProducts} productos incluidos',
                        style: AppConstants.bodyMedium.copyWith(
                          color: AppConstants.primaryColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      Text(
                        AppUtils.formatCurrency(promotion.price),
                        style: AppConstants.titleMedium.copyWith(
                          color: AppConstants.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingS),
                  decoration: BoxDecoration(
                    color: AppConstants.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                  ),
                  child: Icon(
                    Icons.local_offer,
                    color: AppConstants.warningColor,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
