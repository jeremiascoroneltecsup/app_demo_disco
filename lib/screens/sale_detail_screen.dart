import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sale.dart';
import '../models/sale_detail.dart';
import '../models/sale_with_details.dart';
import '../providers/data_provider.dart';
import '../utils/constants.dart';
import '../utils/app_utils.dart';
import '../widgets/common_widgets.dart';

class SaleDetailScreen extends StatefulWidget {
  final Sale sale;

  const SaleDetailScreen({
    super.key,
    required this.sale,
  });

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  SaleWithDetails? _saleWithDetails;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _loadSaleDetails();
  }

  Future<void> _loadSaleDetails() async {
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      final dataProvider = context.read<DataProvider>();
      final saleWithDetails = await dataProvider.getSaleWithDetails(widget.sale.id);
      setState(() {
        _saleWithDetails = saleWithDetails;
        _isLoadingDetails = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDetails = false;
      });
      print('Error loading sale details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Venta #${widget.sale.id}'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sale Information Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información de la Venta',
                    style: AppConstants.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildDetailRow('ID de Venta', '#${widget.sale.id}'),
                  _buildDetailRow('Fecha y Hora', AppUtils.formatDateTime(widget.sale.saleDate)),
                  _buildDetailRow('Fecha de Creación', 
                    widget.sale.createdAt != null ? AppUtils.formatDateTime(widget.sale.createdAt!) : 'No disponible'),
                  _buildDetailRow('Última Actualización', 
                    widget.sale.updatedAt != null ? AppUtils.formatDateTime(widget.sale.updatedAt!) : 'No disponible'),
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Staff and Table Information
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal y Mesa',
                    style: AppConstants.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildDetailRow('Mesero', widget.sale.user?.name ?? 'No disponible'),
                  _buildDetailRow('Usuario', widget.sale.user?.username ?? 'No disponible'),
                  _buildDetailRow('Mesa', 
                    widget.sale.table != null 
                        ? 'Mesa ${widget.sale.table!.tableNumber}'
                        : 'No disponible'),
                  _buildDetailRow('Piso', 
                    widget.sale.table != null 
                        ? 'Piso ${widget.sale.table!.floorNumber}'
                        : 'No disponible'),
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Products and Promotions
            _buildItemsSection(),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Payment Information
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información de Pago',
                    style: AppConstants.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildDetailRow('Método de Pago', widget.sale.paymentType?.name ?? 'No disponible'),
                  const Divider(height: AppConstants.spacingL),
                  _buildDetailRow('Subtotal', AppUtils.formatCurrency(widget.sale.subtotal)),
                  _buildDetailRow('Propina', AppUtils.formatCurrency(widget.sale.tip)),
                  const Divider(height: AppConstants.spacingL),
                  _buildDetailRow(
                    'Total', 
                    AppUtils.formatCurrency(widget.sale.total),
                    isTotal: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // IDs Information (for debugging/reference)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Referencias del Sistema',
                    style: AppConstants.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildDetailRow('ID Usuario', '${widget.sale.userId}'),
                  _buildDetailRow('ID Mesa', '${widget.sale.tableId}'),
                  _buildDetailRow('ID Tipo de Pago', '${widget.sale.paymentTypeId}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Productos y Promociones',
            style: AppConstants.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          
          if (_isLoadingDetails)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.spacingM),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_saleWithDetails == null || !_saleWithDetails!.hasItems)
            const Padding(
              padding: EdgeInsets.all(AppConstants.spacingM),
              child: Text(
                'No se encontraron productos o promociones en esta venta.',
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
                          'Artículo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Cant.',
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
                          'Precio Unit.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Subtotal',
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
                
                // Items list
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _saleWithDetails!.getAllItems().length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _saleWithDetails!.getAllItems()[index];
                    return _buildItemRow(item);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildItemRow(SaleItemDetail item) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingS),
      child: Row(
        children: [
          // Item name and type
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: AppConstants.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.itemType,
                  style: AppConstants.bodyMedium.copyWith(
                    color: item.itemType == 'Producto'
                        ? AppConstants.primaryColor 
                        : AppConstants.accentColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Quantity
          Expanded(
            flex: 1,
            child: Text(
              '${item.quantity}',
              style: AppConstants.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          
          // Unit price
          Expanded(
            flex: 2,
            child: Text(
              AppUtils.formatCurrency(item.unitPrice),
              style: AppConstants.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
          
          // Subtotal
          Expanded(
            flex: 2,
            child: Text(
              AppUtils.formatCurrency(item.subtotal),
              style: AppConstants.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppConstants.successColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
              style: isTotal 
                  ? AppConstants.titleMedium.copyWith(
                      color: AppConstants.successColor,
                      fontWeight: FontWeight.bold,
                    )
                  : AppConstants.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
