import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/sale_provider.dart';
import '../../models/cart.dart';
import '../../models/payment_type.dart';
import '../../utils/constants.dart';
import '../../utils/app_utils.dart';
import '../../widgets/common_widgets.dart';
import '../dashboard_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  PaymentType? _selectedPaymentType;
  final TextEditingController _tipController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProvider = context.read<DataProvider>();
      if (dataProvider.paymentTypes.isEmpty) {
        dataProvider.loadPaymentTypes();
      }
    });
  }

  @override
  void dispose() {
    _tipController.dispose();
    super.dispose();
  }

  void _updateTip() {
    final tipValue = double.tryParse(_tipController.text) ?? 0.0;
    context.read<SaleProvider>().setTip(tipValue);
  }

  Future<void> _processSale() async {
    if (_selectedPaymentType == null) {
      AppUtils.showErrorSnackBar(
        context,
        'Por favor selecciona un método de pago',
      );
      return;
    }

    final saleProvider = context.read<SaleProvider>();
    
    if (saleProvider.cart.isEmpty) {
      AppUtils.showErrorSnackBar(
        context,
        'El carrito está vacío',
      );
      return;
    }

    final confirmed = await AppUtils.showConfirmDialog(
      context,
      title: 'Procesar Venta',
      message: '¿Confirmar venta por ${AppUtils.formatCurrency(saleProvider.total)}?',
      confirmText: 'Confirmar Venta',
      cancelText: 'Cancelar',
    );

    if (!confirmed) return;

    saleProvider.setSelectedPaymentType(_selectedPaymentType!);
    final success = await saleProvider.processSale();

    if (mounted) {
      if (success) {
        AppUtils.showSuccessSnackBar(
          context,
          'Venta procesada exitosamente',
        );
        
        // Navigate back to dashboard and clear the stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        AppUtils.showErrorSnackBar(
          context,
          'Error al procesar la venta. Intente nuevamente.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta - Carrito y Pago'),
      ),
      body: Consumer2<SaleProvider, DataProvider>(
        builder: (context, saleProvider, dataProvider, child) {
          if (saleProvider.cart.isEmpty) {
            return const EmptyStateWidget(
              title: 'Carrito vacío',
              subtitle: 'Agrega productos o promociones para continuar',
              icon: Icons.shopping_cart_outlined,
            );
          }

          return Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              
              // Cart items
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selected table info
                      _buildTableInfo(saleProvider),
                      const SizedBox(height: AppConstants.spacingL),
                      
                      // Cart items
                      const SectionHeader(
                        title: 'Productos en el carrito',
                        subtitle: 'Modifica cantidades según sea necesario',
                      ),
                      ...saleProvider.cart.items.map((item) => _buildCartItem(item, saleProvider)),
                      
                      const SizedBox(height: AppConstants.spacingL),
                      
                      // Payment method selection
                      _buildPaymentMethodSection(dataProvider),
                      
                      const SizedBox(height: AppConstants.spacingL),
                      
                      // Tip input
                      _buildTipSection(saleProvider),
                      
                      const SizedBox(height: AppConstants.spacingL),
                      
                      // Order summary
                      _buildOrderSummary(saleProvider),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<SaleProvider>(
        builder: (context, saleProvider, child) {
          return Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: saleProvider.isProcessing ? null : _processSale,
              child: saleProvider.isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Procesar Venta - ${AppUtils.formatCurrency(saleProvider.total)}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        children: [
          _buildProgressStep(1, 'Mesa', isActive: false, isCompleted: true),
          _buildProgressConnector(isCompleted: true),
          _buildProgressStep(2, 'Productos', isActive: false, isCompleted: true),
          _buildProgressConnector(isCompleted: true),
          _buildProgressStep(3, 'Pago', isActive: true, isCompleted: false),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, {required bool isActive, required bool isCompleted}) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isCompleted 
                ? AppConstants.successColor 
                : isActive 
                    ? AppConstants.primaryColor 
                    : AppConstants.primaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    step.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingXS),
        Text(
          label,
          style: AppConstants.bodyMedium.copyWith(
            color: isActive 
                ? AppConstants.primaryColor 
                : AppConstants.primaryColor.withOpacity(0.7),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressConnector({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingS),
        decoration: BoxDecoration(
          color: isCompleted 
              ? AppConstants.successColor 
              : AppConstants.primaryColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildTableInfo(SaleProvider saleProvider) {
    final table = saleProvider.selectedTable;
    if (table == null) return const SizedBox.shrink();

    return AppCard(
      child: Row(
        children: [
          Icon(
            Icons.table_restaurant,
            size: 32,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mesa seleccionada',
                  style: AppConstants.bodyMedium.copyWith(
                    color: AppConstants.primaryColor.withOpacity(0.7),
                  ),
                ),
                Text(
                  'Mesa ${table.tableNumber} - Piso ${table.floorNumber}',
                  style: AppConstants.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, SaleProvider saleProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppConstants.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        item.type == CartItemType.product ? 'Producto' : 'Promoción',
                        style: AppConstants.bodyMedium.copyWith(
                          color: item.type == CartItemType.product 
                              ? AppConstants.secondaryColor
                              : AppConstants.warningColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  AppUtils.formatCurrency(item.unitPrice),
                  style: AppConstants.titleMedium.copyWith(
                    color: AppConstants.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quantity controls
                Row(
                  children: [
                    IconButton(
                      onPressed: item.quantity > 1
                          ? () => saleProvider.updateCartItemQuantity(item, item.quantity - 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppConstants.primaryColor,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingM,
                        vertical: AppConstants.spacingS,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppConstants.primaryColor.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                      ),
                      child: Text(
                        item.quantity.toString(),
                        style: AppConstants.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => saleProvider.updateCartItemQuantity(item, item.quantity + 1),
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppConstants.primaryColor,
                    ),
                  ],
                ),
                // Subtotal and remove button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Subtotal: ${AppUtils.formatCurrency(item.subtotal)}',
                      style: AppConstants.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => saleProvider.removeFromCart(item),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppConstants.errorColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(DataProvider dataProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Método de pago',
          subtitle: 'Selecciona la forma de pago',
        ),
        if (dataProvider.paymentTypes.isEmpty)
          const LoadingWidget(message: 'Cargando métodos de pago...')
        else
          ...dataProvider.paymentTypes.map((paymentType) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
              child: RadioListTile<PaymentType>(
                title: Text(paymentType.name),
                value: paymentType,
                groupValue: _selectedPaymentType,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentType = value;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                ),
                tileColor: AppConstants.surfaceColor,
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildTipSection(SaleProvider saleProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Propina',
          subtitle: 'Opcional - Ingresa el monto de propina',
        ),
        AppCard(
          child: Column(
            children: [
              TextFormField(
                controller: _tipController,
                decoration: const InputDecoration(
                  labelText: 'Monto de propina',
                  prefixText: 'S/ ',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _updateTip(),
              ),
              const SizedBox(height: AppConstants.spacingM),
              // Quick tip buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final tip = saleProvider.subtotal * 0.10;
                        _tipController.text = tip.toStringAsFixed(2);
                        _updateTip();
                      },
                      child: const Text('10%'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final tip = saleProvider.subtotal * 0.15;
                        _tipController.text = tip.toStringAsFixed(2);
                        _updateTip();
                      },
                      child: const Text('15%'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final tip = saleProvider.subtotal * 0.20;
                        _tipController.text = tip.toStringAsFixed(2);
                        _updateTip();
                      },
                      child: const Text('20%'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(SaleProvider saleProvider) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de la orden',
            style: AppConstants.titleMedium,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal:',
                style: AppConstants.bodyLarge,
              ),
              Text(
                AppUtils.formatCurrency(saleProvider.subtotal),
                style: AppConstants.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Propina:',
                style: AppConstants.bodyLarge,
              ),
              Text(
                AppUtils.formatCurrency(saleProvider.tip),
                style: AppConstants.bodyLarge,
              ),
            ],
          ),
          const Divider(height: AppConstants.spacingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL:',
                style: AppConstants.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                AppUtils.formatCurrency(saleProvider.total),
                style: AppConstants.titleLarge.copyWith(
                  color: AppConstants.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
