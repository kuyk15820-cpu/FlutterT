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
      backgroundColor: const Color(0xFF13111C),
      body: CustomScrollView(
        slivers: [
          // Header & Tab Selection
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Key Management',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: _refreshData,
                        icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8)),
                        tooltip: 'Refresh',
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildTabSelector(),
                ],
              ),
            ),
          ),

          // Key List View
          FutureBuilder<List<KeyItem>>(
            future: _keysFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator(radius: 14)),
                );
              } else if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: CupertinoColors.systemRed),
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No keys found in this category.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                );
              }

              final filteredKeys = snapshot.data!.where((item) {
                final query = _searchQuery.toLowerCase();
                return item.tokenCode.toLowerCase().contains(query) ||
                    item.projectName.toLowerCase().contains(query);
              }).toList();

              if (filteredKeys.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No matching key found.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildKeyCard(filteredKeys[index]),
                    childCount: filteredKeys.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // UI WIDGETS
  // ------------------------------------------------------------------

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF272535),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Search Key or Project...',
          hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Color(0xFF64748B), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    final tabs = [
      {'id': 'active', 'label': 'Active', 'color': const Color(0xFF22C55E)},
      {'id': 'banned', 'label': 'Banned', 'color': const Color(0xFFEF4444)},
      {'id': 'expired', 'label': 'Expired', 'color': const Color(0xFFEAB308)},
      {'id': 'deleted', 'label': 'Deleted', 'color': const Color(0xFF94A3B8)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedTab == tab['id'];
          final activeColor = tab['color'] as Color;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                tab['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              selectedColor: activeColor.withOpacity(0.3),
              backgroundColor: const Color(0xFF272535),
              side: BorderSide(
                color: isSelected ? activeColor : Colors.white.withOpacity(0.05),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTab = tab['id'] as String);
                  _refreshData();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyCard(KeyItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF272535),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: const Color(0xFF94A3B8),
        collapsedIconColor: const Color(0xFF64748B),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.tokenCode,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.copy, size: 14, color: Color(0xFF3B82F6)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: item.tokenCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied Key to Clipboard')),
                );
              },
            ),
          ],
        ),
        subtitle: Row(
          children: [
            _buildBadge(item.projectName, const Color(0xFFA855F7)),
            const SizedBox(width: 6),
            _buildBadge(
              item.type == 'lifetime'
                  ? '∞ Lifetime'
                  : (item.expireDate ?? 'Pending'),
              item.type == 'lifetime' ? const Color(0xFF22C55E) : const Color(0xFFEAB308),
            ),
          ],
        ),
        children: [
          const Divider(color: Color(0xFF334155), height: 20),
          _buildInfoRow('Devices Bound:', '${item.usedDevices} / ${item.maxDevices}'),
          if (item.devices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 4, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.devices
                    .map((uuid) => Text(
                          '• $uuid',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ))
                    .toList(),
              ),
            ),
          if (item.isBanned) ...[
            _buildInfoRow('Ban Reason:', item.banReason ?? 'No reason provided'),
          ],
          const SizedBox(height: 12),
          _buildActionButtons(item),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(KeyItem item) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_selectedTab == 'active') ...[
          _buildActionButton('Reset Device', FontAwesomeIcons.rotateLeft, const Color(0xFF3B82F6), () async {
            await ApiService.resetDevice(item.id);
            _refreshData();
          }),
          _buildActionButton('Ban Key', FontAwesomeIcons.ban, const Color(0xFFEF4444), () {
            _showBanDialog(item);
          }),
          if (item.type != 'lifetime')
            _buildActionButton('Renew', FontAwesomeIcons.calendarPlus, const Color(0xFF22C55E), () {
              _showRenewDialog(item);
            }),
        ],
        if (_selectedTab == 'banned') ...[
          _buildActionButton('Unban', FontAwesomeIcons.lockOpen, const Color(0xFF22C55E), () async {
            await ApiService.unbanKey(item.id);
            _refreshData();
          }),
        ],
        _buildActionButton('Delete', FontAwesomeIcons.trashCan, const Color(0xFFEF4444), () async {
          await ApiService.deleteKey(item.id);
          _refreshData();
        }),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 10, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // DIALOGS
  // ------------------------------------------------------------------

  void _showBanDialog(KeyItem item) {
    final reasonController = TextEditingController();
    String banType = 'permanent';
    int banHours = 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF272535),
        title: const Text('Ban Key', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: banType,
              dropdownColor: const Color(0xFF272535),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(labelText: 'Ban Type', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
              items: const [
                DropdownMenuItem(value: 'permanent', child: Text('Permanent')),
                DropdownMenuItem(value: 'temp', child: Text('Temporary (Hours)')),
              ],
              onChanged: (val) => banType = val!,
            ),
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
                banHours: banHours,
                reason: reasonController.text,
              );
              if (mounted) Navigator.pop(context);
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
        backgroundColor: const Color(0xFF272535),
        title: const Text('Renew Key', style: TextStyle(color: Colors.white, fontSize: 16)),
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
                dropdownColor: const Color(0xFF272535),
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
              if (mounted) Navigator.pop(context);
              _refreshData();
            },
            child: const Text('Renew'),
          ),
        ],
      ),
    );
  }
}
