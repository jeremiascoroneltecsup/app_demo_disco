import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/promotion.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import '../utils/app_utils.dart';
import '../widgets/common_widgets.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProvider = context.read<DataProvider>();
      if (dataProvider.promotions.isEmpty) {
        dataProvider.loadPromotions();
      }
      if (dataProvider.products.isEmpty) {
        dataProvider.loadProducts();
      }
    });
  }

  // Función para verificar si una promoción tiene productos sin stock
  bool _hasOutOfStockProducts(Promotion promotion, List<Product> products) {
    for (final detail in promotion.promotionDetails) {
      try {
        final product = products.firstWhere((p) => p.id == detail.productId);
        if ((product.stock ?? 0) == 0) {
          return true;
        }
      } catch (e) {
        return true;
      }
    }
    return false;
  }

  void _showPromotionDetails(Promotion promotion) {
    showDialog(
      context: context,
      builder: (context) => _PromotionDetailsDialog(promotion: promotion),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promociones'),
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.isLoading) {
            return const LoadingWidget();
          }

          if (dataProvider.promotions.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.local_offer,
              title: 'No hay promociones',
              subtitle: 'Las promociones aparecerán aquí cuando estén disponibles',
            );
          }

          return Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: AppConstants.spacingM,
                mainAxisSpacing: AppConstants.spacingM,
              ),
              itemCount: dataProvider.promotions.length,
              itemBuilder: (context, index) {
                final promotion = dataProvider.promotions[index];
                final hasOutOfStock = _hasOutOfStockProducts(
                  promotion,
                  dataProvider.products,
                );
                return _buildPromotionCard(promotion, hasOutOfStock);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromotionCard(Promotion promotion, bool hasOutOfStock) {
    return AppCard(
      onTap: () => _showPromotionDetails(promotion),
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
                      promotion.name,
                      style: AppConstants.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      AppUtils.formatCurrency(promotion.price),
                      style: AppConstants.titleLarge.copyWith(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Stock warning indicator
              if (hasOutOfStock) ...[
                const SizedBox(width: AppConstants.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingS,
                    vertical: AppConstants.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.red.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: AppConstants.spacingXS),
                      Text(
                        'Sin stock',
                        style: AppConstants.bodyMedium.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingM),
          
          // Stats row
          Row(
            children: [
              // Products count
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingS),
                decoration: BoxDecoration(
                  color: AppConstants.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      color: AppConstants.secondaryColor,
                      size: 20,
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      '${promotion.totalProducts}',
                      style: AppConstants.labelLarge.copyWith(
                        color: AppConstants.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'productos',
                      style: AppConstants.bodyMedium.copyWith(
                        color: AppConstants.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingM),
          
          // Products preview
          if (promotion.promotionDetails.isNotEmpty) ...[
            Text(
              'Productos incluidos:',
              style: AppConstants.labelLarge,
            ),
            const SizedBox(height: AppConstants.spacingS),
            ...promotion.promotionDetails.take(2).map((detail) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingXS),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Expanded(
                      child: Text(
                        '${detail.quantity}x ${detail.product?.name ?? 'Producto'}',
                        style: AppConstants.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            if (promotion.promotionDetails.length > 2) ...[
              Text(
                '+${promotion.promotionDetails.length - 2} más...',
                style: AppConstants.bodyMedium.copyWith(
                  color: AppConstants.primaryColor.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
          
          const Spacer(),
          
          // View details button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showPromotionDetails(promotion),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('Ver detalles', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionDetailsDialog extends StatelessWidget {
  final Promotion promotion;

  const _PromotionDetailsDialog({required this.promotion});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadiusM),
                  topRight: Radius.circular(AppConstants.borderRadiusM),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promotion.name,
                          style: AppConstants.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingXS),
                        Text(
                          AppUtils.formatCurrency(promotion.price),
                          style: AppConstants.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Productos incluidos en la promoción:',
                      style: AppConstants.titleMedium,
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: promotion.promotionDetails.length,
                        itemBuilder: (context, index) {
                          final detail = promotion.promotionDetails[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
                            padding: const EdgeInsets.all(AppConstants.spacingM),
                            decoration: BoxDecoration(
                              color: AppConstants.backgroundColor,
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                              border: Border.all(
                                color: AppConstants.primaryColor.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppConstants.spacingS),
                                  decoration: BoxDecoration(
                                    color: AppConstants.secondaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                                  ),
                                  child: Text(
                                    '${detail.quantity}x',
                                    style: AppConstants.labelLarge.copyWith(
                                      color: AppConstants.secondaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppConstants.spacingM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        detail.product?.name ?? 'Producto no disponible',
                                        style: AppConstants.bodyLarge,
                                      ),
                                      if (detail.product != null) ...[
                                        const SizedBox(height: AppConstants.spacingXS),
                                        Text(
                                          'Precio unitario: ${AppUtils.formatCurrency(detail.product!.price)}',
                                          style: AppConstants.bodyMedium.copyWith(
                                            color: AppConstants.primaryColor.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
