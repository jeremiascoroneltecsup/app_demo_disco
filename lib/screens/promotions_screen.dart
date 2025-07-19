import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/promotion.dart';
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
    });
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DataProvider>().loadPromotions(),
          ),
        ],
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.isLoading) {
            return const LoadingWidget(message: 'Cargando promociones...');
          }

          if (dataProvider.errorMessage != null) {
            return AppErrorWidget(
              message: dataProvider.errorMessage!,
              onRetry: () => dataProvider.loadPromotions(),
            );
          }

          final activePromotions = dataProvider.activePromotions;

          if (activePromotions.isEmpty) {
            return const EmptyStateWidget(
              title: 'No hay promociones activas',
              subtitle: 'Las promociones aparecerán aquí cuando estén disponibles',
              icon: Icons.local_offer_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () => dataProvider.loadPromotions(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              itemCount: activePromotions.length,
              itemBuilder: (context, index) {
                final promotion = activePromotions[index];
                return _buildPromotionCard(promotion);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromotionCard(Promotion promotion) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: AppCard(
        onTap: () => _showPromotionDetails(promotion),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    promotion.name,
                    style: AppConstants.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingS,
                    vertical: AppConstants.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                    border: Border.all(
                      color: AppConstants.successColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppConstants.successColor,
                      ),
                      const SizedBox(width: AppConstants.spacingXS),
                      Text(
                        'Activa',
                        style: AppConstants.bodyMedium.copyWith(
                          color: AppConstants.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            // Price and products info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Precio de la promoción',
                        style: AppConstants.bodyMedium.copyWith(
                          color: AppConstants.primaryColor.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        AppUtils.formatCurrency(promotion.price),
                        style: AppConstants.titleLarge.copyWith(
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
                    color: AppConstants.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        color: AppConstants.secondaryColor,
                        size: 24,
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        '${promotion.totalProducts}',
                        style: AppConstants.titleMedium.copyWith(
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
              ...promotion.promotionDetails.take(3).map((detail) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.spacingXS),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingS),
                      Expanded(
                        child: Text(
                          '${detail.quantity}x ${detail.product?.name ?? 'Producto'}',
                          style: AppConstants.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (promotion.promotionDetails.length > 3) ...[
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  'y ${promotion.promotionDetails.length - 3} producto(s) más...',
                  style: AppConstants.bodyMedium.copyWith(
                    color: AppConstants.primaryColor.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
            
            const SizedBox(height: AppConstants.spacingM),
            
            // View details button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _showPromotionDetails(promotion),
                icon: const Icon(Icons.visibility),
                label: const Text('Ver detalles completos'),
              ),
            ),
          ],
        ),
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
