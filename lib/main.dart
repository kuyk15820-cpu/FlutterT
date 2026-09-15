import 'flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Key Manager',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121318),
      ),
      home: const Test2Page(),
    );
  }
}

class Test2Page extends StatefulWidget {
  const Test2Page({super.key});

  @override
  State<Test2Page> createState() => _Test2PageState();
}

class _Test2PageState extends State<Test2Page> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121318),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121318),
        elevation: 0,
        title: const Text(
          'Keys',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: const [
          // Item 1: Active Status (Collapsed)
          KeyCardCollapsed(
            keyName: 'baontq-day-xAmDKWLT7Rdfk7YD',
            duration: '30 day',
            statusText: 'ACTIVE',
            statusColor: Color(0xFF53B552),
          ),
          SizedBox(height: 12),

          // Item 2: Pending Status (Expanded)
          KeyCardExpanded(
            keyName: 'baontq23-hour-ubKEmd2aZnDLIxTx',
            duration: '1 hour',
            statusText: 'PENDING',
            statusColor: Color(0xFF4A90E2),
            packageText: '@😁😁😁😁, Testing 3, APIServer framework test',
            activated: '0/1',
            resetCount: '0',
            source: 'group',
            createdAt: '04/04/2026 02:17',
            expiryText: 'Not Activated',
            expiryColor: Color(0xFFD97724),
          ),
          SizedBox(height: 12),

          // Item 3: Pending Status (Collapsed)
          KeyCardCollapsed(
            keyName: 'baontq23-hour-ZCWBVPUB2Hi8W...',
            duration: '1 hour',
            statusText: 'PENDING',
            statusColor: Color(0xFF4A90E2),
          ),
          SizedBox(height: 12),

          // Item 4: Expired Status (Collapsed)
          KeyCardCollapsed(
            keyName: 'baontq-day-yWKSKUNFpC3WuaEj',
            duration: '30 day',
            statusText: 'EXPIRED',
            statusColor: Color(0xFFE55644),
          ),
          SizedBox(height: 80), // Space for bottom bar
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E2028),
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4A90E2),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.key),
            label: 'Keys',
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Collapsed Card Widget
// -----------------------------------------------------------------------------
class KeyCardCollapsed extends StatelessWidget {
  final String keyName;
  final String duration;
  final String statusText;
  final Color statusColor;

  const KeyCardCollapsed({
    super.key,
    required this.keyName,
    required this.duration,
    required this.statusText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF232530),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  keyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StatusChip(text: statusText, color: statusColor),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Expanded Card Widget
// -----------------------------------------------------------------------------
class KeyCardExpanded extends StatelessWidget {
  final String keyName;
  final String duration;
  final String statusText;
  final Color statusColor;
  final String packageText;
  final String activated;
  final String resetCount;
  final String source;
  final String createdAt;
  final String expiryText;
  final Color expiryColor;

  const KeyCardExpanded({
    super.key,
    required this.keyName,
    required this.duration,
    required this.statusText,
    required this.statusColor,
    required this.packageText,
    required this.activated,
    required this.resetCount,
    required this.source,
    required this.createdAt,
    required this.expiryText,
    required this.expiryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF232530),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      keyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusChip(text: statusText, color: statusColor),
            ],
          ),
          const SizedBox(height: 16),

          // Detail Section
          _buildDetailRow('Package', packageText),
          const SizedBox(height: 8),
          _buildDetailRow('Activated', activated),
          const SizedBox(height: 8),
          _buildDetailRow('Reset Count', resetCount),
          const SizedBox(height: 8),
          _buildDetailRow('Source', source),
          const SizedBox(height: 8),
          _buildDetailRow('Created At', createdAt),
          const SizedBox(height: 8),
          _buildDetailRow('Expiry', expiryText, valueColor: expiryColor),
          const SizedBox(height: 20),

          // Action Buttons Row
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.copy_rounded,
                  label: 'Copy',
                  color: const Color(0xFF4A90E2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: const Color(0xFF4A90E2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Reset',
                  color: const Color(0xFF4A90E2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.lock_outline,
                  label: 'Lock',
                  color: const Color(0xFFE55644),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color valueColor = Colors.grey}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor == Colors.grey ? Colors.white70 : valueColor,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Status Chip Component
// -----------------------------------------------------------------------------
class StatusChip extends StatelessWidget {
  final String text;
  final Color color;

  const StatusChip({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
