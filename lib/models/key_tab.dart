import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/model.dart';
import '../services/api_service.dart';

class KeyTab extends StatefulWidget {
  const KeyTab({super.key});

  @override
  State<KeyTab> createState() => _KeyTabState();
}

class _KeyTabState extends State<KeyTab> {
  String _selectedTab = 'active'; // 'active', 'banned', 'expired', 'deleted'
  late Future<List<KeyItem>> _keysFuture;
  List<KeyItem> _currentKeyList = [];
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
      _keysFuture = ApiService.fetchKeys(_selectedTab);
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

  // 🟢 เลือกทั้งหมด / ยกเลิกทั้งหมด
  void _toggleSelectAll(List<KeyItem> displayedKeys) {
    setState(() {
      final allIds = displayedKeys.map((e) => e.id).toSet();
      if (_selectedIds.length == allIds.length) {
        _selectedIds.clear();
        _isMultiSelectMode = false;
      } else {
        _selectedIds.addAll(allIds);
        _isMultiSelectMode = true;
      }
    });
  }

  // 🟢 ฟังก์ชันคำนวณและแสดงผลระยะเวลาคงเหลืออย่างถูกต้อง (ชั่วโมง, วัน, สัปดาห์, เดือน, ปี)
  String _formatRemainingTime(KeyItem key) {
    if (key.type == 'lifetime' || key.duration == -1) {
      return '∞ Lifetime';
    }

    if (key.isPending) {
      return _formatHoursToReadableText(key.duration);
    }

    if (key.expireDate == null || key.expireDate!.isEmpty) {
      return 'Not Activated';
    }

    final DateTime? expire = DateTime.tryParse(key.expireDate!);
    if (expire == null) return 'Not Activated';

    final DateTime now = DateTime.now();
    final Duration diff = expire.difference(now);

    if (diff.isNegative) return 'Expired';

    final int minutes = diff.inMinutes;
    final int hours = diff.inHours;
    final int days = diff.inDays;

    if (minutes < 60) {
      return '$minutes Mins';
    } else if (hours < 24) {
      return '$hours Hours';
    } else if (days < 7) {
      return '$days Days';
    } else if (days < 30) {
      final weeks = (days / 7).floor();
      final remDays = days % 7;
      return remDays > 0 ? '$weeks Wks $remDays Days' : '$weeks Wks';
    } else if (days < 365) {
      final months = (days / 30).floor();
      final remDays = days % 30;
      return remDays > 0 ? '$months Mos $remDays Days' : '$months Mos';
    } else {
      final years = (days / 365).floor();
      final remMonths = ((days % 365) / 30).floor();
      return remMonths > 0 ? '$years Yrs $remMonths Mos' : '$years Yrs';
    }
  }

  String _formatHoursToReadableText(int hours) {
    if (hours <= 0) return '0 Hour';
    if (hours < 24) {
      return '$hours Hours';
    } else if (hours < 24 * 7) {
      return '${(hours / 24).round()} Days';
    } else if (hours < 24 * 30) {
      return '${(hours / (24 * 7)).round()} Weeks';
    } else if (hours < 24 * 365) {
      return '${(hours / (24 * 30)).round()} Months';
    } else {
      return '${(hours / (24 * 365)).round()} Years';
    }
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
              child: FutureBuilder<List<KeyItem>>(
                future: _keysFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CupertinoActivityIndicator(radius: 14, color: Colors.white),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}', style: const TextStyle(color: CupertinoColors.systemRed)),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No keys found.', style: TextStyle(color: Color(0xFF64748B))),
                    );
                  }

                  _currentKeyList = snapshot.data!.where((item) {
                    final query = _searchQuery.toLowerCase();
                    return item.tokenCode.toLowerCase().contains(query) ||
                        item.projectName.toLowerCase().contains(query);
                  }).toList();

                  if (_currentKeyList.isEmpty) {
                    return const Center(
                      child: Text('No matching key found.', style: TextStyle(color: Color(0xFF64748B))),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: _currentKeyList.length,
                    itemBuilder: (context, index) {
                      final item = _currentKeyList[index];
                      return _buildKeyCard(item);
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
            _isMultiSelectMode ? 'Selected (${_selectedIds.length})' : 'Keys',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Row(
            children: [
              if (!_isMultiSelectMode) ...[
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 24),
                  onPressed: _showCreateKeyDialog,
                  tooltip: 'Create Key',
                ),
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white, size: 22),
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
                  icon: const Icon(Icons.tune, color: Colors.white, size: 22),
                  color: const Color(0xFF232330),
                  onSelected: (tab) {
                    setState(() => _selectedTab = tab);
                    _refreshData();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'active', child: Text('🟢 Active Keys', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'banned', child: Text('🚫 Banned Keys', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'expired', child: Text('🟡 Expired Keys', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'deleted', child: Text('🔴 Deleted History', style: TextStyle(color: Colors.white))),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.cleaning_services_outlined, color: Color(0xFFEF4444), size: 20),
                  onPressed: _showClearAllConfirmDialog,
                  tooltip: 'Clear All in Current Tab',
                ),
              ],
              if (_isMultiSelectMode) ...[
                IconButton(
                  icon: Icon(
                    _selectedIds.length == _currentKeyList.length ? Icons.select_all : Icons.deselect,
                    color: const Color(0xFF6366F1),
                    size: 24,
                  ),
                  onPressed: () => _toggleSelectAll(_currentKeyList),
                  tooltip: 'Select All / Deselect',
                ),
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
              ],
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
        decoration: BoxDecoration(color: const Color(0xFF232330), borderRadius: BorderRadius.circular(12)),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Search Key or Package...',
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
            _buildBulkActionButton('Ban', Icons.lock, Colors.orange, () => _executeBulkAction('ban_selected')),
            _buildBulkActionButton('Unban', Icons.lock_open, Colors.green, () => _executeBulkAction('unban_selected')),
            _buildBulkActionButton('Reset Device', Icons.rotate_left, Colors.blue, () => _executeBulkAction('reset_selected_devices')),
            _buildBulkActionButton('Delete', Icons.delete, Colors.red, () => _executeBulkAction('delete_selected')),
          ] else ...[
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
  // KEY CARD ITEM
  // ------------------------------------------------------------------

  Widget _buildKeyCard(KeyItem item) {
    final bool isSelected = _selectedIds.contains(item.id);

    String statusText = 'PENDING';
    Color badgeColor = const Color(0xFF3B82F6);

    if (item.isBanned) {
      statusText = 'BANNED';
      badgeColor = const Color(0xFFEF4444);
    } else if (_selectedTab == 'expired') {
      statusText = 'EXPIRED';
      badgeColor = const Color(0xFFEF4444);
    } else if (!item.isPending) {
      statusText = 'ACTIVE';
      badgeColor = const Color(0xFF22C55E);
    } else if (_selectedTab == 'deleted') {
      statusText = 'DELETED';
      badgeColor = const Color(0xFF64748B);
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
                        item.tokenCode,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: badgeColor.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        statusText,
                        style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFF94A3B8), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _formatRemainingTime(item),
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              const SizedBox(height: 8),
              _buildDetailRow('Package', item.projectName.isNotEmpty ? item.projectName : 'N/A'),
              if (_selectedTab != 'deleted') ...[
                _buildDetailRow('Activated', !item.isPending ? 'Yes' : 'No'),
                _buildDetailRow('Device Limit', '${item.usedDevices}/${item.maxDevices}'),
                _buildDetailRow('Created At', item.createdAt ?? 'N/A'),
                _buildDetailRow('First Used', item.firstUsedAt ?? 'Not Started'),
                _buildDetailRow('Last Access', item.lastAccess ?? 'No Access Yet'),
                _buildDetailRow('Expire Date', item.expireDate ?? 'Not Activated'),
                if (item.isBanned) ...[
                  _buildDetailRow('Ban Expire', item.banExpire ?? 'Permanent'),
                  _buildDetailRow('Ban Reason', item.banReason ?? 'None'),
                ]
              ] else ...[
                _buildDetailRow('Delete Reason', item.reason ?? 'User Deleted'),
                _buildDetailRow('Deleted At', item.deletedAt ?? 'N/A'),
              ],
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
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardActionButtons(KeyItem item) {
    if (_selectedTab == 'deleted') {
      return Row(
        children: [
          Expanded(
            child: _buildSmallButton(
              label: 'Copy Key',
              icon: Icons.copy,
              color: const Color(0xFF3B82F6),
              onTap: () {
                Clipboard.setData(ClipboardData(text: item.tokenCode));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied Key to Clipboard')));
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
            label: 'Copy',
            icon: Icons.copy,
            color: const Color(0xFF3B82F6),
            onTap: () {
              Clipboard.setData(ClipboardData(text: item.tokenCode));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied Key to Clipboard')));
            },
          ),
        ),
        const SizedBox(width: 6),
        if (item.type != 'lifetime' && !item.isBanned) ...[
          Expanded(
            child: _buildSmallButton(
              label: 'Renew',
              icon: Icons.edit,
              color: const Color(0xFF6366F1),
              onTap: () => _showRenewDialog(item),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: _buildSmallButton(
            label: 'Reset',
            icon: Icons.rotate_left,
            color: const Color(0xFF3B82F6),
            onTap: () async {
              await ApiService.resetDevice(item.id);
              _refreshData();
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildSmallButton(
            label: item.isBanned ? 'Unlock' : 'Lock',
            icon: item.isBanned ? Icons.lock_open : Icons.lock,
            color: item.isBanned ? const Color(0xFF22C55E) : const Color(0xFFEAB308),
            onTap: () async {
              if (item.isBanned) {
                await ApiService.unbanKey(item.id);
                _refreshData();
              } else {
                _showBanDialog(item);
              }
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
              await ApiService.deleteKey(item.id);
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
        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
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
      await ApiService.bulkKeyAction(bulkAction: action, ids: _selectedIds.toList());
      _refreshData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showClearAllConfirmDialog() {
    String targetTabAction = '';
    String title = '';

    if (_selectedTab == 'active') {
      targetTabAction = 'clear_active_keys';
      title = 'Clear All Active Keys';
    } else if (_selectedTab == 'banned') {
      targetTabAction = 'clear_banned_keys';
      title = 'Clear All Banned Keys';
    } else if (_selectedTab == 'expired') {
      targetTabAction = 'clear_expired_keys';
      title = 'Clear All Expired Keys';
    } else if (_selectedTab == 'deleted') {
      targetTabAction = 'clear_deleted_history';
      title = 'Purge Deleted Keys History';
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
              await ApiService.clearAllKeys(targetTabAction);
              _refreshData();
            },
            child: const Text('Confirm Clear All'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // DIALOGS (CREATE, BAN, RENEW)
  // ------------------------------------------------------------------

  void _showCreateKeyDialog() async {
    List<PackageItem> packages = [];
    try {
      packages = await ApiService.fetchPackages('active');
    } catch (_) {}

    int? selectedProject = packages.isNotEmpty ? packages.first.id : null;
    String keyType = 'dynamic';
    String prefixType = 'package';
    final customPrefixController = TextEditingController();
    final durationNumController = TextEditingController(text: '1');
    final quantityController = TextEditingController(text: '1'); // 🟢 เพิ่มช่องจำนวนสร้าง
    String durationUnit = 'day';
    int maxDevices = 1;
    DateTime selectedStaticDate = DateTime.now().add(const Duration(days: 1)); // 🟢 สำหรับ Static Key

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF232330),
          title: const Text('Create New Key', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (packages.isNotEmpty)
                  DropdownButtonFormField<int>(
                    value: selectedProject,
                    dropdownColor: const Color(0xFF232330),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Select Package', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                    items: packages.map((pkg) => DropdownMenuItem<int>(value: pkg.id, child: Text(pkg.name))).toList(),
                    onChanged: (val) => setDialogState(() => selectedProject = val),
                  ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: keyType,
                  dropdownColor: const Color(0xFF232330),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Key Type', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                  items: const [
                    DropdownMenuItem(value: 'dynamic', child: Text('Dynamic Key')),
                    DropdownMenuItem(value: 'static', child: Text('Static Key')),
                    DropdownMenuItem(value: 'lifetime', child: Text('Lifetime Key')),
                  ],
                  onChanged: (val) => setDialogState(() => keyType = val!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: prefixType,
                  dropdownColor: const Color(0xFF232330),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Prefix Type', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                  items: const [
                    DropdownMenuItem(value: 'package', child: Text('From Package Name')),
                    DropdownMenuItem(value: 'custom', child: Text('Custom Prefix')),
                  ],
                  onChanged: (val) => setDialogState(() => prefixType = val!),
                ),
                if (prefixType == 'custom') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: customPrefixController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Custom Prefix Value', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                ],

                // 🟢 กรณีเป็น Dynamic Key: เลือกตัวเลข และหน่วยเวลา (ชั่วโมง/วัน/สัปดาห์/เดือน/ปี)
                if (keyType == 'dynamic') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: durationNumController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Duration', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: durationUnit,
                          dropdownColor: const Color(0xFF232330),
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(value: 'hour', child: Text('Hour')),
                            DropdownMenuItem(value: 'day', child: Text('Day')),
                            DropdownMenuItem(value: 'week', child: Text('Week')),
                            DropdownMenuItem(value: 'month', child: Text('Month')),
                            DropdownMenuItem(value: 'year', child: Text('Year')),
                          ],
                          onChanged: (val) => setDialogState(() => durationUnit = val!),
                        ),
                      ),
                    ],
                  ),
                ],

                // 🟢 กรณีเป็น Static Key: แสดง UI ปุ่มเลือกวันเวลา (DatePicker + TimePicker)
                if (keyType == 'static') ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedStaticDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                      );
                      if (pickedDate != null && context.mounted) {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedStaticDate),
                        );
                        if (pickedTime != null) {
                          setDialogState(() {
                            selectedStaticDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF94A3B8)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Expire Date & Time', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('yyyy-MM-dd HH:mm').format(selectedStaticDate),
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Icon(Icons.calendar_month, color: Color(0xFF6366F1), size: 20),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: '1',
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Max Device Limit', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                        onChanged: (val) => maxDevices = int.tryParse(val) ?? 1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Quantity (Keys)', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
              onPressed: selectedProject == null
                  ? null
                  : () async {
                      bool success = await ApiService.createKey(
                        projectId: selectedProject!,
                        type: keyType,
                        maxDevices: maxDevices,
                        prefixType: prefixType,
                        quantity: int.tryParse(quantityController.text) ?? 1,
                        customPrefix: customPrefixController.text,
                        staticDate: keyType == 'static' ? DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedStaticDate) : null,
                        durationNum: int.tryParse(durationNumController.text) ?? 1,
                        durationUnit: durationUnit,
                      );
                      if (context.mounted) Navigator.pop(context);
                      if (success) _refreshData();
                    },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBanDialog(KeyItem item) {
    final reasonController = TextEditingController();
    final hoursController = TextEditingController(text: '24');
    String banType = 'permanent';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF232330),
          title: const Text('Lock / Ban Key', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: banType,
                dropdownColor: const Color(0xFF232330),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(labelText: 'Ban Type', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                items: const [
                  DropdownMenuItem(value: 'permanent', child: Text('Permanent')),
                  DropdownMenuItem(value: 'temp', child: Text('Temporary (Hours)')),
                ],
                onChanged: (val) => setDialogState(() => banType = val!),
              ),
              if (banType == 'temp') ...[
                const SizedBox(height: 10),
                TextField(
                  controller: hoursController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(labelText: 'Ban Hours', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(labelText: 'Reason', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () async {
                await ApiService.banKey(
                  keyId: item.id,
                  banType: banType,
                  banHours: int.tryParse(hoursController.text) ?? 24,
                  reason: reasonController.text,
                );
                if (context.mounted) Navigator.pop(context);
                _refreshData();
              },
              child: const Text('Confirm Ban'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenewDialog(KeyItem item) {
    int renewNum = 1;
    String renewUnit = 'day';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232330),
        title: const Text('Edit / Renew Key', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: '1',
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Duration', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                onChanged: (val) => renewNum = int.tryParse(val) ?? 1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: renewUnit,
                dropdownColor: const Color(0xFF232330),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: const [
                  DropdownMenuItem(value: 'hour', child: Text('Hour')),
                  DropdownMenuItem(value: 'day', child: Text('Day')),
                  DropdownMenuItem(value: 'week', child: Text('Week')),
                  DropdownMenuItem(value: 'month', child: Text('Month')),
                  DropdownMenuItem(value: 'year', child: Text('Year')),
                ],
                onChanged: (val) => renewUnit = val!,
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
            onPressed: () async {
              await ApiService.renewKey(
                keyId: item.id,
                renewNum: renewNum,
                renewUnit: renewUnit,
              );
              if (context.mounted) Navigator.pop(context);
              _refreshData();
            },
            child: const Text('Renew'),
          ),
        ],
      ),
    );
  }
}
