import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final Set<String> _expandedRows = {}; // เก็บ ID (String) ของแถวที่คลี่ออก

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

  void _toggleRow(String id) {
    setState(() {
      if (_expandedRows.contains(id)) {
        _expandedRows.remove(id);
      } else {
        _expandedRows.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13111C),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Title & Refresh Button
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
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Search & Tab Filter
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildTabSelector(),
              const SizedBox(height: 16),

              // 3. Collapsible Data Table
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFF272535))),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 32),
                          Expanded(
                            child: Text(
                              'Key Code',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          ),
                          Text(
                            'Expiration',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    // Table Rows
                    FutureBuilder<List<KeyItem>>(
                      future: _keysFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CupertinoActivityIndicator(radius: 12)),
                          );
                        } else if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                'No keys found in this category.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
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
                          return const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                'No matching key found.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredKeys.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFF272535)),
                          itemBuilder: (context, index) {
                            final item = filteredKeys[index];
                            final itemIdString = item.id.toString();
                            final isExpanded = _expandedRows.contains(itemIdString);

                            return Column(
                              children: [
                                // Main Row
                                InkWell(
                                  onTap: () => _toggleRow(itemIdString),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: isExpanded ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isExpanded ? Icons.remove : Icons.add,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            item.tokenCode,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildBadge(
                                          item.type == 'lifetime'
                                              ? 'Lifetime'
                                              : (item.expireDate ?? 'Pending'),
                                          item.type == 'lifetime' ? const Color(0xFF22C55E) : const Color(0xFFEAB308),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Expanded Row Details
                                if (isExpanded)
                                  Container(
                                    color: const Color(0xFF13111C),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        _buildDetailRow(
                                          'Project',
                                          _buildBadge(item.projectName, const Color(0xFFA855F7)),
                                        ),
                                        _buildDetailRow(
                                          'Key Token',
                                          Row(
                                            children: [
                                              Expanded(
                                                child: SelectableText(
                                                  item.tokenCode,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: 'monospace',
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  Clipboard.setData(ClipboardData(text: item.tokenCode));
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Copied Key to Clipboard')),
                                                  );
                                                },
                                                child: const Icon(Icons.copy, size: 16, color: Color(0xFF3B82F6)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _buildDetailRow(
                                          'Devices Bound',
                                          Text(
                                            '${item.usedDevices} / ${item.maxDevices}',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                        if (item.devices.isNotEmpty)
                                          _buildDetailRow(
                                            'Device List',
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: item.devices
                                                  .map((uuid) => Text('• $uuid', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)))
                                                  .toList(),
                                            ),
                                          ),
                                        if (item.isBanned)
                                          _buildDetailRow(
                                            'Ban Reason',
                                            Text(
                                              item.banReason ?? 'No reason provided',
                                              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        const Divider(color: Color(0xFF272535)),
                                        const SizedBox(height: 8),

                                        // Action Buttons
                                        _buildDetailRow(
                                          'Actions',
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: [
                                              if (_selectedTab == 'active') ...[
                                                _buildActionButton('Reset', Icons.refresh, const Color(0xFF3B82F6), () async {
                                                  await ApiService.resetDevice(item.id);
                                                  _refreshData();
                                                }),
                                                _buildActionButton('Ban', Icons.block, const Color(0xFFEF4444), () {
                                                  _showBanDialog(item);
                                                }),
                                                if (item.type != 'lifetime')
                                                  _buildActionButton('Renew', Icons.calendar_today, const Color(0xFF22C55E), () {
                                                    _showRenewDialog(item);
                                                  }),
                                              ],
                                              if (_selectedTab == 'banned') ...[
                                                _buildActionButton('Unban', Icons.lock_open, const Color(0xFF22C55E), () async {
                                                  await ApiService.unbanKey(item.id);
                                                  _refreshData();
                                                }),
                                              ],
                                              _buildActionButton('Del', Icons.delete, const Color(0xFFEF4444), () async {
                                                await ApiService.deleteKey(item.id);
                                                _refreshData();
                                              }),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // HELPER WIDGETS
  // ------------------------------------------------------------------

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: const InputDecoration(
          hintText: 'Search Key or Project...',
          hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Color(0xFF64748B), size: 18),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
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
                  fontSize: 11,
                ),
              ),
              selected: isSelected,
              selectedColor: activeColor.withOpacity(0.25),
              backgroundColor: const Color(0xFF1E1B2E),
              side: BorderSide(
                color: isSelected ? activeColor : Colors.white.withOpacity(0.05),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTab = tab['id'] as String;
                    _expandedRows.clear();
                  });
                  _refreshData();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailRow(String label, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: content)),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      icon: Icon(icon, size: 12),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Ban Key', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: banType,
              dropdownColor: const Color(0xFF1E1B2E),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Ban Type', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
              items: const [
                DropdownMenuItem(value: 'permanent', child: Text('Permanent')),
                DropdownMenuItem(value: 'temp', child: Text('Temporary (Hours)')),
              ],
              onChanged: (val) => banType = val!,
            ),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
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
        backgroundColor: const Color(0xFF1E1B2E),
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
                dropdownColor: const Color(0xFF1E1B2E),
                style: const TextStyle(color: Colors.white, fontSize: 13),
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
