import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../providers/sale_provider.dart';
import '../utils/constants.dart';
import '../utils/app_utils.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  // Para actualizar periódicamente
  late Timer _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    // Registrar para eventos de ciclo de vida
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cargar datos iniciales
      context.read<DataProvider>().loadAllData();
      
      // Escuchar eventos de venta completada
      context.read<SaleProvider>().addOnSaleCompletedListener(_refreshData);
      
      // Configurar actualización periódica cada 3 minutos
      _startRefreshTimer();
    });
  }
  
  @override
  void dispose() {
    // Detener el timer y eliminar listeners
    _refreshTimer.cancel();
    context.read<SaleProvider>().removeOnSaleCompletedListener(_refreshData);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Actualizar datos cuando la app vuelve al primer plano
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }
  
  void _startRefreshTimer() {
    // Timer optimizado cada 5 minutos para reducir carga
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) {
        _refreshData();
      }
    });
  }
  
  void _refreshData() {
    if (mounted) {
      // Solo recargar datos críticos para mejorar rendimiento
      final dataProvider = context.read<DataProvider>();
      Future.wait([
        dataProvider.loadSales(),
        dataProvider.loadProducts(),
      ]);
    }
  }

  void _handleLogout() async {
    final confirmed = await AppUtils.showConfirmDialog(
      context,
      title: 'Cerrar Sesión',
      message: '¿Está seguro que desea cerrar sesión?',
      confirmText: 'Sí, cerrar sesión',
      cancelText: 'Cancelar',
    );

    if (confirmed && mounted) {
      await context.read<AuthProvider>().logout();
    }
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
                
                const SizedBox(height: AppConstants.spacingL),
                
                // Recent sales section
                _buildRecentSalesSection(dataProvider),
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
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(DataProvider dataProvider) {
    final timestamp = DateTime.now();
    final formattedDate = '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    
    return Column(
      children: [
        SectionHeader(
          title: 'Estadísticas del Día',
          subtitle: 'Resumen de ventas y actividad - $formattedDate',
          action: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Actualizar datos',
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildAnimatedStatCard(
                title: 'Ventas del Día',
                value: AppUtils.formatCurrency(dataProvider.todayTotalSales),
                icon: Icons.attach_money,
                color: AppConstants.successColor,
                onTap: () {
                  // Navegar a detalles de ventas
                  Navigator.of(context).pushNamed('/sales');
                },
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: _buildAnimatedStatCard(
                title: 'Órdenes',
                value: dataProvider.todayOrdersCount.toString(),
                icon: Icons.receipt,
                color: AppConstants.secondaryColor,
                onTap: () {
                  // Navegar a detalles de órdenes
                  Navigator.of(context).pushNamed('/sales');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildAnimatedStatCard(
                title: 'Promociones Activas',
                value: dataProvider.activePromotions.length.toString(),
                icon: Icons.local_offer,
                color: AppConstants.warningColor,
                onTap: () {
                  // Navegar a promociones
                  Navigator.of(context).pushNamed('/promotions');
                },
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: _buildAnimatedStatCard(
                title: 'Productos',
                value: dataProvider.availableProducts.length.toString(),
                icon: Icons.inventory,
                color: AppConstants.accentColor,
                onTap: () {
                  // Navegar a productos
                  Navigator.of(context).pushNamed('/products');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Versión animada y con interactividad para las tarjetas de estadísticas
  Widget _buildAnimatedStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    Function()? onTap,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: AppCard(
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
                    child: const Icon(Icons.arrow_forward, size: 16),
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
        ),
      ),
    );
  }

  // Este método ha sido reemplazado por _buildAnimatedStatCard
  
  // Método para mostrar ventas recientes
  Widget _buildRecentSalesSection(DataProvider dataProvider) {
    // Filtrar ventas del día
    final today = DateTime.now();
    final todaySales = dataProvider.sales.where((sale) {
      return sale.saleDate.year == today.year &&
             sale.saleDate.month == today.month &&
             sale.saleDate.day == today.day;
    }).toList();
    
    // Limitar a las 5 ventas más recientes
    final recentSales = todaySales.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Ventas Recientes',
          subtitle: 'Últimas transacciones del día',
          action: Icon(Icons.receipt_long),
        ),
        if (recentSales.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppConstants.spacingM),
            child: Center(
              child: Text('No hay ventas registradas hoy'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentSales.length,
            itemBuilder: (context, index) {
              final sale = recentSales[index];
              final time = '${sale.saleDate.hour.toString().padLeft(2, '0')}:${sale.saleDate.minute.toString().padLeft(2, '0')}';
              
              return AppCard(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppConstants.primaryColor.withOpacity(0.2),
                    child: const Icon(Icons.point_of_sale, color: AppConstants.primaryColor),
                  ),
                  title: Text('Venta #${sale.id}'),
                  subtitle: Text('Mesa ${sale.tableId} - $time'),
                  trailing: Text(
                    AppUtils.formatCurrency(sale.total),
                    style: AppConstants.titleMedium.copyWith(
                      color: AppConstants.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    // Navegar al detalle de la venta
                    Navigator.pushNamed(
                      context, 
                      '/sale_detail',
                      arguments: sale.id,
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }

}
