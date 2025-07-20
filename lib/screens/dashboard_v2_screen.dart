import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../providers/sale_provider.dart';
import '../utils/constants.dart';
import '../utils/app_utils.dart';
import '../widgets/common_widgets.dart';

class DashboardV2Screen extends StatefulWidget {
  final VoidCallback? onNavigateToSales;
  
  const DashboardV2Screen({
    super.key,
    this.onNavigateToSales,
  });

  @override
  State<DashboardV2Screen> createState() => _DashboardV2ScreenState();
}

class _DashboardV2ScreenState extends State<DashboardV2Screen> with WidgetsBindingObserver {
  // Estado para guardar valores previos y animar cambios
  double _previousTotalSales = 0.0;
  int _previousOrderCount = 0;
  bool _showChangeAnimation = false;
  
  // Timer para actualización automática
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    // Registrar para eventos de ciclo de vida
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cargar datos iniciales
      _loadInitialData();
      
      // Escuchar eventos de venta completada
      _setupSaleListener();
      
      // Configurar actualización periódica cada minuto
      _startRefreshTimer();
    });
  }
  
  @override
  void dispose() {
    // Detener el timer y eliminar listeners
    _refreshTimer?.cancel();
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
  
  void _loadInitialData() async {
    final dataProvider = context.read<DataProvider>();
    await dataProvider.loadAllData();
    
    // Guardar valores iniciales para animaciones
    setState(() {
      _previousTotalSales = dataProvider.todayTotalSales;
      _previousOrderCount = dataProvider.todayOrdersCount;
    });
  }
  
  void _setupSaleListener() {
    context.read<SaleProvider>().addOnSaleCompletedListener(_onSaleCompleted);
  }
  
  void _startRefreshTimer() {
    // Actualizar cada minuto
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _refreshData();
      }
    });
  }
  
  void _refreshData() async {
    if (!mounted) return;
    
    final dataProvider = context.read<DataProvider>();
    
    // Guardar valores previos para detectar cambios
    final previousSales = dataProvider.todayTotalSales;
    final previousOrders = dataProvider.todayOrdersCount;
    
    // Recargar solo los datos necesarios
    await dataProvider.loadSales();
    await dataProvider.loadProducts();
    await dataProvider.loadPromotions();
    
    // Si hubo cambios, actualizar valores previos y mostrar animación
    if (previousSales != dataProvider.todayTotalSales || 
        previousOrders != dataProvider.todayOrdersCount) {
      setState(() {
        _previousTotalSales = previousSales;
        _previousOrderCount = previousOrders;
        _showChangeAnimation = true;
      });
      
      // Quitar animación después de 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showChangeAnimation = false;
          });
        }
      });
    }
  }
  
  void _onSaleCompleted() {
    // Actualizar inmediatamente después de completar una venta
    _refreshData();
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

        final now = DateTime.now();
        final formattedDate = '${now.day}/${now.month}/${now.year}';
        final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        
        return RefreshIndicator(
          onRefresh: () async {
            _refreshData();
            return Future.value();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con información del usuario y hora
                  _buildHeader(authProvider.currentUser?.name ?? 'Usuario', formattedDate, formattedTime),
                  const SizedBox(height: 24),
                  
                  // Tarjetas principales (Ventas y Órdenes)
                  _buildMainMetricsCards(dataProvider),
                  const SizedBox(height: 24),
                  
                  // Tarjetas secundarias (Promociones y Productos)
                  _buildSecondaryMetricsCards(dataProvider),
                  const SizedBox(height: 24),
                  
                  // Gráfico/Indicador de rendimiento
                  _buildPerformanceIndicator(dataProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String userName, String date, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppConstants.primaryColor,
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido, $userName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _refreshData(),
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
          color: AppConstants.primaryColor,
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar Sesión',
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildMainMetricsCards(DataProvider dataProvider) {
    // Determinar si hay un aumento en las ventas o pedidos
    final isOrdersIncreased = dataProvider.todayOrdersCount > _previousOrderCount;
    final isSalesIncreased = dataProvider.todayTotalSales > _previousTotalSales;
    
    return Row(
      children: [
        // Tarjeta de Ventas del Día
        Expanded(
          child: _buildMetricCard(
            title: 'Ventas del Día',
            value: AppUtils.formatCurrency(dataProvider.todayTotalSales),
            icon: Icons.attach_money,
            color: AppConstants.successColor,
            showChangeIndicator: _showChangeAnimation && isSalesIncreased,
            changeValue: isSalesIncreased 
                ? '+${AppUtils.formatCurrency(dataProvider.todayTotalSales - _previousTotalSales)}'
                : null,
          ),
        ),
        const SizedBox(width: 16),
        // Tarjeta de Órdenes
        Expanded(
          child: _buildMetricCard(
            title: 'Órdenes',
            value: '${dataProvider.todayOrdersCount}',
            icon: Icons.receipt_long,
            color: AppConstants.secondaryColor,
            showChangeIndicator: _showChangeAnimation && isOrdersIncreased,
            changeValue: isOrdersIncreased 
                ? '+${dataProvider.todayOrdersCount - _previousOrderCount}'
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryMetricsCards(DataProvider dataProvider) {
    return Row(
      children: [
        // Tarjeta de Promociones Activas
        Expanded(
          child: _buildMetricCard(
            title: 'Promociones',
            value: '${dataProvider.activePromotions.length}',
            subtitle: 'Activas',
            icon: Icons.local_offer,
            color: AppConstants.warningColor,
          ),
        ),
        const SizedBox(width: 16),
        // Tarjeta de Productos
        Expanded(
          child: _buildMetricCard(
            title: 'Productos',
            value: '${dataProvider.availableProducts.length}',
            subtitle: 'En stock',
            icon: Icons.inventory_2,
            color: AppConstants.accentColor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    bool showChangeIndicator = false,
    String? changeValue,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.analytics, size: 12, color: color),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (showChangeIndicator && changeValue != null)
                  Positioned(
                    right: -8,
                    top: -20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_upward, color: Colors.green.shade800, size: 12),
                          Text(
                            changeValue,
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPerformanceIndicator(DataProvider dataProvider) {
    // Calculamos el objetivo diario basado en la historia de ventas
    final targetSales = dataProvider.todayTotalSales > 0 ? dataProvider.todayTotalSales * 1.2 : 2000.0;
    final progress = dataProvider.todayTotalSales / targetSales;
    final formattedTarget = AppUtils.formatCurrency(targetSales);
    final formattedCurrent = AppUtils.formatCurrency(dataProvider.todayTotalSales);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Meta de ventas diaria',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: progress >= 1.0 
                      ? Colors.green.shade100 
                      : (progress >= 0.7 ? Colors.amber.shade100 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    progress >= 1.0 
                      ? '¡Completado!' 
                      : '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: progress >= 1.0 
                        ? Colors.green.shade800 
                        : (progress >= 0.7 ? Colors.amber.shade800 : Colors.grey.shade700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress > 1.0 ? 1.0 : progress,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 
                    ? Colors.green 
                    : (progress >= 0.7 ? Colors.amber : AppConstants.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedCurrent,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Meta: $formattedTarget',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                if (widget.onNavigateToSales != null) {
                  widget.onNavigateToSales!();
                } else {
                  Navigator.of(context).pushNamed('/sales');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppConstants.primaryColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Ver ventas detalladas',
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
