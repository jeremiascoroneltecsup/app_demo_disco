import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/sale_provider.dart';
import '../../models/table.dart' as models;
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';
import 'select_products_screen.dart';

class SelectTableScreen extends StatefulWidget {
  const SelectTableScreen({super.key});

  @override
  State<SelectTableScreen> createState() => _SelectTableScreenState();
}

class _SelectTableScreenState extends State<SelectTableScreen> {
  int? _selectedFloor;
  models.Table? _selectedTable;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProvider = context.read<DataProvider>();
      if (dataProvider.tables.isEmpty) {
        dataProvider.loadTables();
      }
      // Reset sale state
      context.read<SaleProvider>().resetSale();
    });
  }

  void _continueToProducts() {
    if (_selectedTable != null) {
      context.read<SaleProvider>().setSelectedTable(_selectedTable!);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SelectProductsScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        if (dataProvider.isLoading) {
          return const LoadingWidget(message: 'Cargando mesas...');
        }

        if (dataProvider.errorMessage != null) {
          return AppErrorWidget(
            message: dataProvider.errorMessage!,
            onRetry: () => dataProvider.loadTables(),
          );
        }

        if (dataProvider.tables.isEmpty) {
          return const EmptyStateWidget(
            title: 'No hay mesas disponibles',
            subtitle: 'Configure las mesas del establecimiento',
            icon: Icons.table_restaurant_outlined,
          );
        }

        final floors = dataProvider.floors;

        return Scaffold(
          body: Column(
            children: [
              // Header with back button
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                color: Theme.of(context).primaryColor,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Seleccionar Mesa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Progress indicator
              _buildProgressIndicator(),
              
              // Floor selection
              if (floors.isNotEmpty) ...[
                const SectionHeader(
                  title: 'Seleccionar Piso',
                  subtitle: 'Elige el piso donde se encuentra la mesa',
                ),
                SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingM,
                    ),
                    children: floors.map((floor) {
                      final isSelected = _selectedFloor == floor;
                      return Container(
                        margin: const EdgeInsets.only(right: AppConstants.spacingS),
                        child: FilterChip(
                          label: Text('Piso $floor'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFloor = selected ? floor : null;
                              _selectedTable = null; // Reset table selection
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              
              // Tables grid
              if (_selectedFloor != null) ...[
                const SectionHeader(
                  title: 'Seleccionar Mesa',
                  subtitle: 'Elige la mesa del cliente',
                ),
                Expanded(
                  child: _buildTablesGrid(dataProvider.getTablesByFloor(_selectedFloor!)),
                ),
              ] else ...[
                const Expanded(
                  child: EmptyStateWidget(
                    title: 'Selecciona un piso',
                    subtitle: 'Primero elige el piso para ver las mesas disponibles',
                    icon: Icons.arrow_upward,
                  ),
                ),
              ],
              
              // Bottom action
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: ElevatedButton(
                  onPressed: _selectedTable != null ? _continueToProducts : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    _selectedTable != null 
                        ? 'Continuar a Productos'
                        : 'Selecciona una mesa',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        children: [
          _buildProgressStep(1, 'Mesa', isActive: true, isCompleted: false),
          _buildProgressConnector(isCompleted: false),
          _buildProgressStep(2, 'Productos', isActive: false, isCompleted: false),
          _buildProgressConnector(isCompleted: false),
          _buildProgressStep(3, 'Pago', isActive: false, isCompleted: false),
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

  Widget _buildTablesGrid(List<models.Table> tables) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppConstants.spacingM,
        mainAxisSpacing: AppConstants.spacingM,
        childAspectRatio: 1.2,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        final isSelected = _selectedTable?.id == table.id;
        
        return AppCard(
          onTap: () {
            setState(() {
              _selectedTable = isSelected ? null : table;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: isSelected 
                  ? Border.all(
                      color: AppConstants.primaryColor,
                      width: 2,
                    )
                  : null,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.table_restaurant,
                  size: 32,
                  color: isSelected 
                      ? AppConstants.primaryColor 
                      : AppConstants.primaryColor.withOpacity(0.7),
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  'Mesa ${table.tableNumber}',
                  style: AppConstants.titleMedium.copyWith(
                    color: isSelected 
                        ? AppConstants.primaryColor 
                        : AppConstants.primaryColor.withOpacity(0.9),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  'Piso ${table.floorNumber}',
                  style: AppConstants.bodyMedium.copyWith(
                    color: isSelected 
                        ? AppConstants.primaryColor 
                        : AppConstants.primaryColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
