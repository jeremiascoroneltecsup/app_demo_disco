import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../utils/constants.dart';
import '../utils/app_utils.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, DataProvider>(
      builder: (context, authProvider, dataProvider, child) {
        if (dataProvider.isLoading) {
          return const LoadingWidget(
            message: 'Cargando datos...',
          );
        }

        if (dataProvider.errorMessage != null) {
          return AppErrorWidget(
            message: dataProvider.errorMessage!,
            onRetry: () => dataProvider.loadAllData(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => dataProvider.loadAllData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                _buildWelcomeSection(authProvider.currentUser?.name ?? 'Usuario'),
                const SizedBox(height: AppConstants.spacingL),
                
                // Statistics section
                _buildStatisticsSection(dataProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(String userName) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppConstants.primaryColor,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido',
                  style: AppConstants.bodyMedium.copyWith(
                    color: AppConstants.primaryColor.withOpacity(0.7),
                  ),
                ),
                Text(
                  userName,
                  style: AppConstants.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(DataProvider dataProvider) {
    return Column(
      children: [
        const SectionHeader(
          title: 'Estadísticas del Día',
          subtitle: 'Resumen de ventas y actividad',
        ),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Ventas del Día',
                value: AppUtils.formatCurrency(dataProvider.todayTotalSales),
                icon: Icons.attach_money,
                color: AppConstants.successColor,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: _buildStatCard(
                title: 'Órdenes',
                value: dataProvider.todayOrdersCount.toString(),
                icon: Icons.receipt,
                color: AppConstants.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Promociones Activas',
                value: dataProvider.activePromotions.length.toString(),
                icon: Icons.local_offer,
                color: AppConstants.warningColor,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: _buildStatCard(
                title: 'Productos',
                value: dataProvider.availableProducts.length.toString(),
                icon: Icons.inventory,
                color: AppConstants.accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingXS),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            value,
            style: AppConstants.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppConstants.bodyMedium.copyWith(
              color: AppConstants.primaryColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

}
