import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/promotion.dart';
import '../providers/data_provider.dart';
import '../utils/constants.dart';
import '../utils/app_utils.dart';
import '../widgets/common_widgets.dart';

class PromotionDetailScreen extends StatefulWidget {
  final Promotion promotion;

  const PromotionDetailScreen({
    super.key,
    required this.promotion,
  });

  @override
  State<PromotionDetailScreen> createState() => _PromotionDetailScreenState();
}

class _PromotionDetailScreenState extends State<PromotionDetailScreen> {
  Promotion? _fullPromotionDetails;
  bool _isLoadingPromotionDetails = false;

  @override
  void initState() {
    super.initState();
    // Cargar productos si es necesario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProvider = context.read<DataProvider>();
      if (dataProvider.products.isEmpty) {
        dataProvider.loadProducts();
      }
      _loadFullPromotionDetails();
    });
  }

  Future<void> _loadFullPromotionDetails() async {
    setState(() {
      _isLoadingPromotionDetails = true;
    });

    try {
      final dataProvider = context.read<DataProvider>();
      final fullDetails = await dataProvider.getPromotionDetails(widget.promotion.id);
      setState(() {
        _fullPromotionDetails = fullDetails;
        _isLoadingPromotionDetails = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPromotionDetails = false;
      });
      print('Error loading full promotion details: $e');
    }
  }

  // Método para obtener la promoción con detalles completos
  Promotion get _promotion => _fullPromotionDetails ?? widget.promotion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de Promoción'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          return _isLoadingPromotionDetails 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Promotion Information Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_offer,
                            color: AppConstants.accentColor,
                            size: 32,
                          ),
                          const SizedBox(width: AppConstants.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _promotion.name,
                                  style: AppConstants.titleLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: AppConstants.spacingS),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.spacingS,
                                    vertical: AppConstants.spacingXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _promotion.enabled 
                                        ? AppConstants.successColor 
                                        : AppConstants.errorColor,
                                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                                  ),
                                  child: Text(
                                    _promotion.enabled ? 'ACTIVA' : 'INACTIVA',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      _buildDetailRow('ID de Promoción', '#${_promotion.id}'),
                      _buildDetailRow('Precio', AppUtils.formatCurrency(_promotion.price)),
                      _buildDetailRow('Fecha de Creación', 
                        _promotion.createdAt != null 
                            ? AppUtils.formatDateTime(_promotion.createdAt!) 
                            : 'No disponible'),
                      _buildDetailRow('Última Actualización', 
                        _promotion.updatedAt != null 
                            ? AppUtils.formatDateTime(_promotion.updatedAt!) 
                            : 'No disponible'),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppConstants.spacingM),
                
                // Products included in promotion
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2,
                            color: AppConstants.primaryColor,
                          ),
                          const SizedBox(width: AppConstants.spacingS),
                          Text(
                            'Productos Incluidos',
                            style: AppConstants.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      
                      if (_promotion.promotionDetails.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppConstants.spacingM),
                          child: Text(
                            'No hay productos específicos configurados para esta promoción.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        Column(
                          children: [
                            // Table header
                            Container(
                              padding: const EdgeInsets.all(AppConstants.spacingS),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Producto',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Cantidad',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Precio Individual',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Products list
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _promotion.promotionDetails.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final detail = _promotion.promotionDetails[index];
                                return _buildProductRow(detail, dataProvider);
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: AppConstants.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryColor.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppConstants.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(PromotionDetail detail, DataProvider dataProvider) {
    try {
      // Usar el producto que viene en el detalle de la promoción
      // Si no está disponible, buscar en la lista general como fallback
      final product = detail.product ?? dataProvider.products.firstWhere(
        (p) => p.id == detail.productId,
        orElse: () => throw Exception('Producto con ID ${detail.productId} no encontrado'),
      );

      return Padding(
        padding: const EdgeInsets.all(AppConstants.spacingS),
        child: Row(
          children: [
            // Product name
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppConstants.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ID: ${product.id}',
                    style: AppConstants.bodyMedium.copyWith(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Quantity
            Expanded(
              flex: 2,
              child: Text(
                '${detail.quantity} und.',
                style: AppConstants.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            
            // Individual price
            Expanded(
              flex: 2,
              child: Text(
                AppUtils.formatCurrency(product.price),
                style: AppConstants.bodyMedium,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Mostrar información básica si no se puede cargar el producto
      return Padding(
        padding: const EdgeInsets.all(AppConstants.spacingS),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Producto ID: ${detail.productId}',
                    style: AppConstants.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const Text(
                    'Información no disponible',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${detail.quantity} und.',
                style: AppConstants.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'N/A',
                style: AppConstants.bodyMedium.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }
  }

}
