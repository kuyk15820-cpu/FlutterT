import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/key_model.dart';
import '../services/api_service.dart';

class KeyTab extends StatefulWidget {
  const KeyTab({super.key});

  @override
  State<KeyTab> createState() => _KeyTabState();
}

class _KeyTabState extends State<KeyTab> {
  String _selectedTab = 'active'; // 'active', 'banned', 'expired', 'deleted'
  late Future<List<KeyItem>> _keysFuture;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _keysFuture = ApiService.fetchKeys(_selectedTab);
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
            Expanded(
              child: FutureBuilder<List<KeyItem>>(
                future: _keysFuture,
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
                        'No keys found.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    );
                  }

                  final filteredKeys = snapshot.data!.where((item) {
                    final query = _searchQuery.toLowerCase();
                    return item.tokenCode.toLowerCase().contains(query) ||
                        item.projectName.toLowerCase().contains(query);
                  }).toList();

                  if (filteredKeys.isEmpty) {
                    return const Center(
                      child: Text(
                        'No matching key found.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filteredKeys.length,
                    itemBuilder: (context, index) =>
                        _buildKeyCard(filteredKeys[index]),
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
  // APP BAR & HEADER
  // ------------------------------------------------------------------

  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Keys',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 24),
                onPressed: _showCreateKeyDialog,
                tooltip: 'Create Key',
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
                    child: Text(
                      '🟢 Active Keys',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'banned',
                    child: Text(
                      '🚫 Banned Keys',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'expired',
                    child: Text(
                      '🟡 Expired Keys',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'deleted',
                    child: Text(
                      '🔴 Deleted Keys',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
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

  // ------------------------------------------------------------------
  // KEY CARD ITEM
  // ------------------------------------------------------------------

  Widget _buildKeyCard(KeyItem item) {
    String statusText = 'PENDING';
    Color badgeColor = const Color(0xFF3B82F6); // Blue

    if (item.isBanned) {
      statusText = 'BANNED';
      badgeColor = const Color(0xFFEF4444);
    } else if (_selectedTab == 'expired') {
      statusText = 'EXPIRED';
      badgeColor = const Color(0xFFEF4444);
    } else if (item.usedDevices > 0) {
      statusText = 'ACTIVE';
      badgeColor = const Color(0xFF22C55E);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF232330),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.tokenCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
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
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Color(0xFF94A3B8),
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.type == 'lifetime'
                        ? '∞ Lifetime'
                        : '${item.duration > 0 ? (item.duration / 24).toStringAsFixed(0) : 0} day',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            const SizedBox(height: 8),
            _buildDetailRow('Package', item.projectName),
            _buildDetailRow('Activated', item.usedDevices > 0 ? 'Yes' : 'No'),
            _buildDetailRow(
              'Reset Count',
              '${item.usedDevices}/${item.maxDevices}',
            ),
            _buildDetailRow('Expiry', item.expireDate ?? 'Not Activated'),
            if (item.isBanned)
              _buildDetailRow('Ban Reason', item.banReason ?? 'None'),
            const SizedBox(height: 16),
            _buildCardActionButtons(item),
          ],
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
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardActionButtons(KeyItem item) {
    return Row(
      children: [
        Expanded(
          child: _buildSmallButton(
            label: 'Copy',
            icon: Icons.copy,
            color: const Color(0xFF3B82F6),
            onTap: () {
              Clipboard.setData(ClipboardData(text: item.tokenCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied Key to Clipboard')),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        if (item.type != 'lifetime' && !item.isBanned) ...[
          Expanded(
            child: _buildSmallButton(
              label: 'Edit',
              icon: Icons.edit,
              color: const Color(0xFF6366F1),
              onTap: () => _showRenewDialog(item),
            ),
          ),
          const SizedBox(width: 8),
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
        const SizedBox(width: 8),
        Expanded(
          child: _buildSmallButton(
            label: item.isBanned ? 'Unlock' : 'Lock',
            icon: item.isBanned ? Icons.lock_open : Icons.lock,
            color: const Color(0xFFEF4444),
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
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // DIALOGS (CREATE, BAN, RENEW)
  // ------------------------------------------------------------------

  void _showCreateKeyDialog() {
    int selectedProject = 1;
    String keyType = 'dynamic';
    String prefixType = 'package';
    final customPrefixController = TextEditingController();
    final durationNumController = TextEditingController(text: '1');
    String durationUnit = 'day';
    int maxDevices = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF232330),
          title: const Text(
            'Create New Key',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: keyType,
                  dropdownColor: const Color(0xFF232330),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Key Type',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'dynamic',
                      child: Text('Dynamic Key'),
                    ),
                    DropdownMenuItem(
                      value: 'static',
                      child: Text('Static Key'),
                    ),
                    DropdownMenuItem(
                      value: 'lifetime',
                      child: Text('Lifetime Key'),
                    ),
                  ],
                  onChanged: (val) => setDialogState(() => keyType = val!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: prefixType,
                  dropdownColor: const Color(0xFF232330),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Prefix Type',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'package',
                      child: Text('From Package Name'),
                    ),
                    DropdownMenuItem(
                      value: 'custom',
                      child: Text('Custom Prefix'),
                    ),
                  ],
                  onChanged: (val) => setDialogState(() => prefixType = val!),
                ),
                if (prefixType == 'custom') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: customPrefixController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Custom Prefix Value',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
                if (keyType == 'dynamic') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: durationNumController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Duration',
                            labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: durationUnit,
                          dropdownColor: const Color(0xFF232330),
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(
                              value: 'hour',
                              child: Text('Hour'),
                            ),
                            DropdownMenuItem(value: 'day', child: Text('Day')),
                            DropdownMenuItem(
                              value: 'week',
                              child: Text('Week'),
                            ),
                            DropdownMenuItem(
                              value: 'month',
                              child: Text('Month'),
                            ),
                          ],
                          onChanged: (val) =>
                              setDialogState(() => durationUnit = val!),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              onPressed: () async {
                bool success = await ApiService.createKey(
                  projectId: selectedProject,
                  type: keyType,
                  maxDevices: maxDevices,
                  prefixType: prefixType,
                  customPrefix: customPrefixController.text,
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
    String banType = 'permanent';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232330),
        title: const Text(
          'Lock / Ban Key',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: banType,
              dropdownColor: const Color(0xFF232330),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Ban Type',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'permanent',
                  child: Text('Permanent'),
                ),
                DropdownMenuItem(
                  value: 'temp',
                  child: Text('Temporary (Hours)'),
                ),
              ],
              onChanged: (val) => banType = val!,
            ),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Reason',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () async {
              await ApiService.banKey(
                keyId: item.id,
                banType: banType,
                reason: reasonController.text,
              );
              if (context.mounted) Navigator.pop(context);
              _refreshData();
            },
            child: const Text('Confirm Ban'),
          ),
        ],
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
        title: const Text(
          'Edit / Renew Key',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: '1',
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                ),
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
                ],
                onChanged: (val) => renewUnit = val!,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
            ),
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
