import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/sale.dart';
import '../utils/constants.dart';
import '../utils/app_utils.dart';
import '../widgets/common_widgets.dart';

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
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            itemCount: dataProvider.sales.length,
            itemBuilder: (context, index) {
              final sale = dataProvider.sales[index];
              return _buildSaleCard(sale);
            },
          ),
        );
      },
    );
  }

  Widget _buildSaleCard(Sale sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with sale ID and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Venta #${sale.id}',
                  style: AppConstants.titleMedium,
                ),
                Text(
                  AppUtils.formatDateTime(sale.saleDate),
                  style: AppConstants.bodyMedium.copyWith(
                    color: AppConstants.primaryColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            // Sale details
            Row(
              children: [
                Expanded(
                  child: _buildSaleDetailItem(
                    'Mesero',
                    sale.user?.name ?? 'No disponible',
                    Icons.person,
                  ),
                ),
                Expanded(
                  child: _buildSaleDetailItem(
                    'Mesa',
                    sale.table != null 
                        ? 'Mesa ${sale.table!.tableNumber} - Piso ${sale.table!.floorNumber}'
                        : 'No disponible',
                    Icons.table_restaurant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            Row(
              children: [
                Expanded(
                  child: _buildSaleDetailItem(
                    'Pago',
                    sale.paymentType?.name ?? 'No disponible',
                    Icons.payment,
                  ),
                ),
                Expanded(
                  child: _buildSaleDetailItem(
                    'Propina',
                    AppUtils.formatCurrency(sale.tip),
                    Icons.volunteer_activism,
                  ),
                ),
              ],
            ),
            
            const Divider(height: AppConstants.spacingL),
            
            // Financial summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subtotal: ${AppUtils.formatCurrency(sale.subtotal)}',
                      style: AppConstants.bodyMedium,
                    ),
                    Text(
                      'Propina: ${AppUtils.formatCurrency(sale.tip)}',
                      style: AppConstants.bodyMedium,
                    ),
                  ],
                ),
                Text(
                  'Total: ${AppUtils.formatCurrency(sale.total)}',
                  style: AppConstants.titleMedium.copyWith(
                    color: AppConstants.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppConstants.primaryColor.withOpacity(0.7),
        ),
        const SizedBox(width: AppConstants.spacingXS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppConstants.bodyMedium.copyWith(
                  color: AppConstants.primaryColor.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: AppConstants.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
