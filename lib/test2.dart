import 'package:flutter/material.dart';

class KeyData {
  final int id;
  final String expirationDate;
  final String status;
  final String keyType;
  final String key;

  KeyData({
    required this.id,
    required this.expirationDate,
    required this.status,
    required this.keyType,
    required this.key,
  });
}

class CollapsibleTablePage extends StatefulWidget {
  const CollapsibleTablePage({super.key});

  @override
  State<CollapsibleTablePage> createState() => _CollapsibleTablePageState();
}

class _CollapsibleTablePageState extends State<CollapsibleTablePage> {
  final Set<int> _expandedRows = {2};

  final List<KeyData> _items = [
    KeyData(id: 1, expirationDate: '30 day', status: 'Pending', keyType: 'Admin Key', key: 'baontq-6zy89tfsbdhvi01a'),
    KeyData(id: 2, expirationDate: '30 day', status: 'Pending', keyType: 'Admin Key', key: 'baontq-6zy89tfsbdhvi01c'),
    KeyData(id: 3, expirationDate: '30 day', status: 'Pending', keyType: 'Admin Key', key: 'baontq-6zy89tfsbdhvi01d'),
    KeyData(id: 4, expirationDate: '30 day', status: 'Pending', keyType: 'Admin Key', key: 'baontq-6zy89tfsbdhvi01e'),
  ];

  void _toggleRow(int id) {
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Collapsible Table'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Table Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        'Expiration date',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ),
                    Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              // 2. Table Rows
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final isExpanded = _expandedRows.contains(item.id);

                  return Column(
                    children: [
                      InkWell(
                        onTap: () => _toggleRow(item.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _toggleRow(item.id),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isExpanded ? const Color(0xFFDC2626) : const Color(0xFF4F46E5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isExpanded ? Icons.remove : Icons.add,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('${item.id}', style: const TextStyle(fontWeight: FontWeight.w500)),
                              const Spacer(),
                              Text(item.expirationDate, style: const TextStyle(color: Colors.black87)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF08A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.status,
                                  style: const TextStyle(color: Color(0xFF854D0E), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          color: const Color(0xFFF8FAFC),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildDetailRow('Key type', Text(item.keyType, style: const TextStyle(fontWeight: FontWeight.w600))),
                              _buildDetailRow('Key', SelectableText(item.key, style: const TextStyle(fontFamily: 'monospace'))),
                              _buildDetailRow('Reset', OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.refresh, size: 14), label: const Text('Reset'))),
                              _buildDetailRow('Edit', OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 14), label: const Text('Edit'))),
                              _buildDetailRow('Date', OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.calendar_month, size: 14), label: const Text('Update date'))),
                              _buildDetailRow('Del', OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.delete, size: 14, color: Colors.red), label: const Text('Delete', style: TextStyle(color: Colors.red)))),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: content)),
        ],
      ),
    );
  }
}
