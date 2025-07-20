import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../utils/app_utils.dart';

class DashboardFastScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSales;
  
  const DashboardFastScreen({
    super.key,
    this.onNavigateToSales,
  });

  @override
  State<DashboardFastScreen> createState() => _DashboardFastScreenState();
}

class _DashboardFastScreenState extends State<DashboardFastScreen> {
  // Timer para actualización automática
  Timer? _refreshTimer;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cargar datos iniciales sin delay
      _loadInitialData();
      
      // Configurar actualización periódica cada 2 minutos
      _startRefreshTimer();
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  void _loadInitialData() async {
    if (!mounted || _isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final dataProvider = context.read<DataProvider>();
      await Future.wait([
        dataProvider.loadSales(),
        dataProvider.loadProducts(),
        dataProvider.loadPromotions(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e')),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
  
  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted && !_isLoading) {
        _refreshData();
      }
    });
  }
  
  void _refreshData() async {
    if (!mounted || _isLoading) return;
    
    final dataProvider = context.read<DataProvider>();
    // Recargar solo ventas para estadísticas
    await dataProvider.loadSales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: () async {
          if (!_isLoading) {
            _loadInitialData();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20), // Reducido de 24 a 20
              _buildMetricsGrid(),
              const SizedBox(height: 20), // Reducido de 24 a 20
              _buildQuickActions(),
              const SizedBox(height: 20), // Reducido de 24 a 20
              _buildRecentSales(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final now = DateTime.now();
        final greeting = _getGreeting(now.hour);
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.name ?? 'Usuario',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppUtils.formatDate(now),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Botón de cerrar sesión
              Column(
                children: [
                  // Indicador de estado (sin WebSocket)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Botón de cerrar sesión
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _handleLogout(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Salir',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricsGrid() {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12, // Reducido de 16 a 12
          mainAxisSpacing: 12,  // Reducido de 16 a 12
          childAspectRatio: 2.0, // Aumentado de 1.5 a 2.0 para hacer los cuadros más anchos y menos altos
          children: [
            _buildMetricCard(
              'Ventas Hoy',
              AppUtils.formatCurrency(dataProvider.todayTotalSales),
              Icons.trending_up,
              Colors.green,
              onTap: widget.onNavigateToSales,
            ),
            _buildMetricCard(
              'Órdenes Hoy',
              '${dataProvider.todayOrdersCount}',
              Icons.receipt_long,
              Colors.blue,
              onTap: widget.onNavigateToSales,
            ),
            _buildMetricCard(
              'Productos',
              '${dataProvider.products.length}',
              Icons.inventory,
              Colors.orange,
            ),
            _buildMetricCard(
              'Promociones',
              '${dataProvider.promotions.length}',
              Icons.local_offer,
              Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title, 
    String value, 
    IconData icon, 
    Color color, 
    {VoidCallback? onTap}
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12), // Reducido de 16 a 12 para hacer los cuadros más compactos
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18), // Reducido de 20 a 18
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12, // Reducido de 14 a 12
                    color: Colors.grey[400],
                  ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18, // Reducido de 20 a 18
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2), // Reducido de 4 a 2
            Text(
              title,
              style: TextStyle(
                fontSize: 11, // Reducido de 12 a 11
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Nueva Venta',
                Icons.add_shopping_cart,
                Colors.green,
                () => widget.onNavigateToSales?.call(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Ver Reportes',
                Icons.analytics,
                Colors.blue,
                () => widget.onNavigateToSales?.call(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSales() {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final recentSales = dataProvider.sales
            .where((sale) => AppUtils.isToday(sale.createdAt))
            .toList()
          ..sort((a, b) {
            final aDate = a.createdAt ?? DateTime.now();
            final bDate = b.createdAt ?? DateTime.now();
            return bDate.compareTo(aDate);
          });
        
        final displaySales = recentSales.take(3).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ventas Recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (displaySales.isNotEmpty)
                  TextButton(
                    onPressed: widget.onNavigateToSales,
                    child: const Text('Ver todas'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (displaySales.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No hay ventas hoy',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...displaySales.map((sale) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt,
                        color: Colors.green,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Venta #${sale.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            AppUtils.formatDateTime(sale.createdAt ?? DateTime.now()),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppUtils.formatCurrency(sale.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              )),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await AppUtils.showConfirmDialog(
      context,
      title: 'Cerrar Sesión',
      message: '¿Estás seguro de que quieres cerrar sesión?',
      confirmText: 'Cerrar Sesión',
      cancelText: 'Cancelar',
    );

    if (confirmed && mounted) {
      try {
        await context.read<AuthProvider>().logout();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cerrar sesión: $e')),
          );
        }
      }
    }
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }
}
