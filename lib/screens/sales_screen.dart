import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/sale.dart';
import '../utils/constants.dart';
import '../utils/app_utils.dart';
import '../widgets/common_widgets.dart';
import 'sale_detail_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProvider = context.read<DataProvider>();
      if (dataProvider.sales.isEmpty) {
        dataProvider.loadSales();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        if (dataProvider.isLoading) {
          return const LoadingWidget(message: 'Cargando ventas...');
        }

        if (dataProvider.errorMessage != null) {
          return AppErrorWidget(
            message: dataProvider.errorMessage!,
            onRetry: () => dataProvider.loadSales(),
          );
        }

        if (dataProvider.sales.isEmpty) {
          return const EmptyStateWidget(
            title: 'No hay ventas registradas',
            subtitle: 'Cuando realices ventas aparecerán aquí',
            icon: Icons.receipt_long_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () => dataProvider.loadSales(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Header
                Text(
                  'Registro de Ventas (${dataProvider.sales.length})',
                  style: AppConstants.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                
                // Sales Table
                AppCard(
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spacingM),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(AppConstants.borderRadiusM),
                            topRight: Radius.circular(AppConstants.borderRadiusM),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                'ID',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Fecha',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Mesero',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Mesa',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Acción',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Table Body
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dataProvider.sales.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final sale = dataProvider.sales[index];
                          return _buildSaleRow(sale, index);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaleRow(Sale sale, int index) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      color: index % 2 == 0 ? Colors.transparent : Colors.grey.withOpacity(0.05),
      child: Row(
        children: [
          // ID
          Expanded(
            flex: 1,
            child: Text(
              '#${sale.id}',
              style: AppConstants.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Fecha
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppUtils.formatDate(sale.saleDate),
                  style: AppConstants.bodyMedium,
                ),
                Text(
                  AppUtils.formatTime(sale.saleDate),
                  style: AppConstants.bodyMedium.copyWith(
                    color: AppConstants.primaryColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Mesero
          Expanded(
            flex: 2,
            child: Text(
              sale.user?.name ?? 'N/A',
              style: AppConstants.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Mesa
          Expanded(
            flex: 1,
            child: Text(
              sale.table != null ? '${sale.table!.tableNumber}' : 'N/A',
              style: AppConstants.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          
          // Total
          Expanded(
            flex: 2,
            child: Text(
              AppUtils.formatCurrency(sale.total),
              style: AppConstants.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppConstants.successColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          
          // Botón Ver detalles
          Expanded(
            flex: 1,
            child: Center(
              child: IconButton(
                onPressed: () => _viewSaleDetails(sale),
                icon: const Icon(Icons.visibility),
                iconSize: 20,
                color: AppConstants.primaryColor,
                tooltip: 'Ver detalles',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewSaleDetails(Sale sale) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaleDetailScreen(sale: sale),
      ),
    );
  }
}
