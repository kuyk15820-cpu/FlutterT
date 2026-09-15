import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/model.dart';
import '../services/api_service.dart';

class PackageTab extends StatefulWidget {
  const PackageTab({super.key});

  @override
  State<PackageTab> createState() => _PackageTabState();
}

class _PackageTabState extends State<PackageTab> {
  String _selectedTab = 'active'; // 'active', 'maint', 'deleted'
  late Future<List<PackageItem>> _packagesFuture;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Multi-Selection State (Bulk Actions)
  bool _isMultiSelectMode = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _selectedIds.clear();
      _isMultiSelectMode = false;
      _packagesFuture = ApiService.fetchPackages(_selectedTab);
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isMultiSelectMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16161E),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(),
            if (_isSearching) _buildSearchBarWidget(),
            if (_isMultiSelectMode) _buildBulkActionBar(),
            Expanded(
              child: FutureBuilder<List<PackageItem>>(
                future: _packagesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CupertinoActivityIndicator(
                        radius: 14,
                        color: Colors.white,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No packages found.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    );
                  }

                  final filteredPackages = snapshot.data!.where((item) {
                    final query = _searchQuery.toLowerCase();
                    return item.name.toLowerCase().contains(query) ||
                        item.projectToken.toLowerCase().contains(query);
                  }).toList();

                  if (filteredPackages.isEmpty) {
                    return const Center(
                      child: Text(
                        'No matching package found.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filteredPackages.length,
                    itemBuilder: (context, index) {
                      final item = filteredPackages[index];
                      return _buildPackageCard(item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // APP BAR & HEADER & BULK ACTION BAR
  // ------------------------------------------------------------------

  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isMultiSelectMode
                ? 'Selected (${_selectedIds.length})'
                : 'Packages',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              if (!_isMultiSelectMode) ...[
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 24),
                  onPressed: () => _showPackageDialog(),
                  tooltip: 'Add Package',
                ),
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchQuery = '';
                        _searchController.clear();
                      }
                    });
                  },
                  tooltip: 'Search',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.tune,
                    color: Colors.white,
                    size: 22,
                  ),
                  color: const Color(0xFF232330),
                  onSelected: (tab) {
                    setState(() => _selectedTab = tab);
                    _refreshData();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'active',
                      child: Text('🟢 Active Packages', style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem(
                      value: 'maint',
                      child: Text('🛠️ Maintenance', style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem(
                      value: 'deleted',
                      child: Text('🔴 Deleted Packages', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.cleaning_services_outlined, color: Color(0xFFEF4444), size: 20),
                  onPressed: _showClearAllConfirmDialog,
                  tooltip: 'Clear All in Current Tab',
                ),
              ],
              if (_isMultiSelectMode)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () {
                    setState(() {
                      _isMultiSelectMode = false;
                      _selectedIds.clear();
                    });
                  },
                  tooltip: 'Cancel Selection',
                ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8), size: 22),
                onPressed: _refreshData,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF232330),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Search Package Name or Token...',
            hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Color(0xFF64748B), size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildBulkActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF232330),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (_selectedTab != 'deleted') ...[
            _buildBulkActionButton('Maintenance', Icons.build, Colors.orange, () => _executeBulkAction('maint_selected')),
            _buildBulkActionButton('Delete', Icons.delete, Colors.red, () => _executeBulkAction('delete_selected')),
          ] else ...[
            _buildBulkActionButton('Restore', Icons.restore, Colors.green, () => _executeBulkAction('restore_selected')),
            _buildBulkActionButton('Purge Permanently', Icons.delete_forever, Colors.red, () => _executeBulkAction('purge_selected_history')),
          ],
        ],
      ),
    );
  }

  Widget _buildBulkActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // PACKAGE CARD ITEM
  // ------------------------------------------------------------------

  Widget _buildPackageCard(PackageItem item) {
    final bool isSelected = _selectedIds.contains(item.id);

    String statusText = 'ACTIVE';
    Color badgeColor = const Color(0xFF22C55E);

    if (item.isMaintenance) {
      statusText = 'MAINTENANCE';
      badgeColor = const Color(0xFFEAB308);
    } else if (_selectedTab == 'deleted') {
      statusText = 'DELETED';
      badgeColor = const Color(0xFFEF4444);
    }

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isMultiSelectMode = true;
          _toggleSelection(item.id);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF312E81) : const Color(0xFF232330),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: const Color(0xFF6366F1), width: 1.5) : null,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: _isMultiSelectMode
                ? Checkbox(
                    value: isSelected,
                    activeColor: const Color(0xFF6366F1),
                    onChanged: (_) => _toggleSelection(item.id),
                  )
                : null,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Token: ${item.projectToken}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            children: [
              const SizedBox(height: 8),
              _buildDetailRow('Package ID', '#${item.id}'),
              _buildDetailRow('Contact / Link', item.contactLink ?? 'None'),
              if (_selectedTab == 'deleted')
                _buildDetailRow('Deleted At', item.deletedAt ?? 'N/A'),
              const SizedBox(height: 16),
              _buildCardActionButtons(item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardActionButtons(PackageItem item) {
    if (_selectedTab == 'deleted') {
      return Row(
        children: [
          Expanded(
            child: _buildSmallButton(
              label: 'Restore',
              icon: Icons.restore,
              color: const Color(0xFF22C55E),
              onTap: () async {
                await ApiService.restorePackage(item.id);
                _refreshData();
              },
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildSmallButton(
            label: 'Copy Token',
            icon: Icons.copy,
            color: const Color(0xFF3B82F6),
            onTap: () {
              Clipboard.setData(ClipboardData(text: item.projectToken));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied Project Token to Clipboard')),
              );
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildSmallButton(
            label: 'Edit',
            icon: Icons.edit,
            color: const Color(0xFF6366F1),
            onTap: () => _showPackageDialog(item: item),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildSmallButton(
            label: item.isMaintenance ? 'Normal' : 'Maint',
            icon: item.isMaintenance ? Icons.check_circle_outline : Icons.build_outlined,
            color: item.isMaintenance ? const Color(0xFF22C55E) : const Color(0xFFEAB308),
            onTap: () async {
              await ApiService.togglePackageMaintenance(item.id, item.isMaintenance ? 1 : 0);
              _refreshData();
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildSmallButton(
            label: 'Delete',
            icon: Icons.delete_outline,
            color: const Color(0xFFEF4444),
            onTap: () async {
              await ApiService.deletePackage(item.id);
              _refreshData();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSmallButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // BULK ACTIONS & CLEAR ALL EXECUTION
  // ------------------------------------------------------------------

  Future<void> _executeBulkAction(String action) async {
    if (_selectedIds.isEmpty) return;
    try {
      await ApiService.bulkPackageAction(
        bulkAction: action,
        ids: _selectedIds.toList(),
      );
      _refreshData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showClearAllConfirmDialog() {
    String targetTabAction = '';
    String title = '';

    if (_selectedTab == 'active') {
      targetTabAction = 'clear_active_packages';
      title = 'Clear All Active Packages';
    } else if (_selectedTab == 'maint') {
      targetTabAction = 'clear_maint_packages';
      title = 'Clear All Maintenance Packages';
    } else if (_selectedTab == 'deleted') {
      targetTabAction = 'clear_deleted_packages';
      title = 'Purge Deleted Packages History';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232330),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Are you sure you want to clear all items in current section ($_selectedTab)? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.clearAllPackages(targetTabAction);
              _refreshData();
            },
            child: const Text('Confirm Clear All'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // DIALOGS (CREATE / EDIT PACKAGE)
  // ------------------------------------------------------------------

  void _showPackageDialog({PackageItem? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final contactController = TextEditingController(text: item?.contactLink ?? '');
    final isEditing = item != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232330),
        title: Text(
          isEditing ? 'Edit Package' : 'Create New Package',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Package Name',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contactController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Contact / Social Link (Optional)',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              bool success;
              if (isEditing) {
                success = await ApiService.editPackage(
                  id: item.id,
                  name: nameController.text.trim(),
                  contact: contactController.text.trim(),
                );
              } else {
                success = await ApiService.createPackage(
                  name: nameController.text.trim(),
                  contact: contactController.text.trim(),
                );
              }

              if (context.mounted) Navigator.pop(context);
              if (success) _refreshData();
            },
            child: Text(isEditing ? 'Save Changes' : 'Create'),
          ),
        ],
      ),
    );
  }
}
