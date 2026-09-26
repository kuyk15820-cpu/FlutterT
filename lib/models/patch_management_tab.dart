import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/model.dart';
import '../services/api_service.dart';

class PatchManagementScreen extends StatefulWidget {
  const PatchManagementScreen({Key? key}) : super(key: key);

  @override
  State<PatchManagementScreen> createState() => _PatchManagementScreenState();
}

class _PatchManagementScreenState extends State<PatchManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Games State
  List<TargetGame> _gamesList = [];
  bool _isLoadingGames = false;
  String _gameSearchQuery = '';

  // Patches State
  List<PatchItem> _patchesList = [];
  bool _isLoadingPatches = false;
  String _patchSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    _loadGames();
    _loadPatches();
  }

  // ==================================================================
  // GAMES LOGIC
  // ==================================================================
  Future<void> _loadGames() async {
    setState(() => _isLoadingGames = true);
    try {
      final games = await ApiService.fetchGames();
      setState(() => _gamesList = games);
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการโหลดเกม: $e', isError: true);
    } finally {
      setState(() => _isLoadingGames = false);
    }
  }

  Future<void> _toggleGame(String bundleID) async {
    try {
      await ApiService.toggleGameStatus(bundleID);
      _loadGames();
    } catch (e) {
      _showSnackBar('เปลี่ยนสถานะเกมไม่สำเร็จ: $e', isError: true);
    }
  }

  Future<void> _toggleAllGames(bool status) async {
    try {
      await ApiService.toggleAllGamesStatus(status);
      _loadGames();
    } catch (e) {
      _showSnackBar('เปลี่ยนสถานะเกมทั้งหมดไม่สำเร็จ: $e', isError: true);
    }
  }

  Future<void> _deleteGame(String bundleID) async {
    try {
      await ApiService.deleteGame(bundleID);
      _showSnackBar('ลบเกมเรียบร้อย');
      _loadGames();
    } catch (e) {
      _showSnackBar('ลบเกมไม่สำเร็จ: $e', isError: true);
    }
  }

  void _showGameDialog({TargetGame? game}) {
    final nameController = TextEditingController(text: game?.name ?? '');
    final bundleController = TextEditingController(text: game?.bundleID ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white10),
        ),
        title: Text(
          game == null ? 'เพิ่ม Target Game' : 'แก้ไข Target Game',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(
              controller: nameController,
              label: 'ชื่อเกม (Game Name)',
              hint: 'เช่น Free Fire',
            ),
            const SizedBox(height: 12),
            _buildDialogTextField(
              controller: bundleController,
              label: 'Bundle ID',
              hint: 'เช่น com.dts.freefireth',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  bundleController.text.trim().isEmpty) {
                _showSnackBar('กรุณากรอกข้อมูลให้ครบถ้วน', isError: true);
                return;
              }
              Navigator.pop(ctx);
              try {
                await ApiService.addOrUpdateGame(
                  gameName: nameController.text.trim(),
                  bundleID: bundleController.text.trim(),
                );
                _showSnackBar('บันทึกข้อมูลเกมสำเร็จ');
                _loadGames();
              } catch (e) {
                _showSnackBar('บันทึกไม่สำเร็จ: $e', isError: true);
              }
            },
            child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // PATCHES LOGIC
  // ==================================================================
  Future<void> _loadPatches() async {
    setState(() => _isLoadingPatches = true);
    try {
      final patches = await ApiService.fetchPatches();
      setState(() => _patchesList = patches);
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการโหลด Patch: $e', isError: true);
    } finally {
      setState(() => _isLoadingPatches = false);
    }
  }

  Future<void> _togglePatch(String id) async {
    try {
      await ApiService.togglePatchStatus(id);
      _loadPatches();
    } catch (e) {
      _showSnackBar('เปลี่ยนสถานะ Patch ไม่สำเร็จ: $e', isError: true);
    }
  }

  Future<void> _toggleAllPatches(bool status) async {
    try {
      await ApiService.toggleAllPatchesStatus(status);
      _loadPatches();
    } catch (e) {
      _showSnackBar('เปลี่ยนสถานะ Patch ทั้งหมดไม่สำเร็จ: $e', isError: true);
    }
  }

  Future<void> _deletePatch(String id) async {
    try {
      await ApiService.deletePatch(id);
      _showSnackBar('ลบ Patch เรียบร้อย');
      _loadPatches();
    } catch (e) {
      _showSnackBar('ลบ Patch ไม่สำเร็จ: $e', isError: true);
    }
  }

  void _showPatchDialog({PatchItem? patch}) {
    final idController = TextEditingController(text: patch?.id ?? '');
    final titleController = TextEditingController(text: patch?.title ?? '');
    final categoryController =
        TextEditingController(text: patch?.category ?? 'General');
    final bundleController = TextEditingController(text: patch?.bundleID ?? '');
    File? selectedFile;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white10),
          ),
          title: Text(
            patch == null ? 'เพิ่ม Patch ใหม่' : 'แก้ไข Patch',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogTextField(
                  controller: idController,
                  label: 'Patch ID',
                  hint: 'เช่น anti_recoil_v1',
                  enabled: patch == null,
                ),
                const SizedBox(height: 12),
                _buildDialogTextField(
                  controller: titleController,
                  label: 'ชื่อ Patch (Title)',
                  hint: 'เช่น No Recoil High Accuracy',
                ),
                const SizedBox(height: 12),
                _buildDialogTextField(
                  controller: categoryController,
                  label: 'หมวดหมู่ (Category)',
                  hint: 'เช่น Weapon, ESP, General',
                ),
                const SizedBox(height: 12),
                _buildDialogTextField(
                  controller: bundleController,
                  label: 'Target Bundle ID',
                  hint: 'เว้นว่างไว้เพื่อใช้งานทุกเกม',
                ),
                const SizedBox(height: 16),
                const Text('ไฟล์ Patch (.c4):',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles();
                    if (result != null && result.files.single.path != null) {
                      setDialogState(() {
                        selectedFile = File(result.files.single.path!);
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedFile != null
                                ? selectedFile!.path.split('/').last
                                : 'ยังไม่ได้เลือกไฟล์',
                            style: TextStyle(
                              color: selectedFile != null ? Colors.white : Colors.white38,
                              fontSize: 13,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Text(
                          'Browse',
                          style: TextStyle(color: Colors.blueAccent.shade100, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (idController.text.trim().isEmpty ||
                    titleController.text.trim().isEmpty) {
                  _showSnackBar('กรุณากรอก ID และ Title', isError: true);
                  return;
                }
                Navigator.pop(ctx);
                try {
                  if (patch == null) {
                    await ApiService.addPatch(
                      id: idController.text.trim(),
                      title: titleController.text.trim(),
                      category: categoryController.text.trim(),
                      bundleID: bundleController.text.trim(),
                      applyFile: selectedFile,
                    );
                    _showSnackBar('เพิ่ม Patch สำเร็จ');
                  } else {
                    await ApiService.updatePatch(
                      id: idController.text.trim(),
                      title: titleController.text.trim(),
                      category: categoryController.text.trim(),
                      bundleID: bundleController.text.trim(),
                      applyFile: selectedFile,
                    );
                    _showSnackBar('อัปเดต Patch สำเร็จ');
                  }
                  _loadPatches();
                } catch (e) {
                  _showSnackBar('บันทึก Patch ไม่สำเร็จ: $e', isError: true);
                }
              },
              child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================================
  // HELPER UI COMPONENTS
  // ==================================================================
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
            filled: true,
            fillColor: enabled ? const Color(0xFF121212) : Colors.white10,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
      ],
    );
  }

  // Capsule สถานะ (ACTIVE / DISABLED)
  Widget _buildStatusCapsule(bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.greenAccent.withOpacity(0.15)
              : Colors.redAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Colors.greenAccent.withOpacity(0.4)
                : Colors.redAccent.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isActive ? 'ACTIVE' : 'DISABLED',
              style: TextStyle(
                color: isActive ? Colors.greenAccent : Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Capsule หมวดหมู่ / Tag
  Widget _buildCategoryCapsule(String label, {Color color = Colors.blueAccent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Widget แสดงข้อมูลแบบจัดชิดขวา
  Widget _buildDetailRowRight(String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: valueWidget,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Patch & Game Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.greenAccent),
            tooltip: 'เปิดทั้งหมด',
            onPressed: () {
              if (_tabController.index == 0) {
                _toggleAllGames(true);
              } else {
                _toggleAllPatches(true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
            tooltip: 'ปิดทั้งหมด',
            onPressed: () {
              if (_tabController.index == 0) {
                _toggleAllGames(false);
              } else {
                _toggleAllPatches(false);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.sports_esports), text: 'Target Games'),
            Tab(icon: Icon(Icons.extension), text: 'Patches Catalog'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGamesTab(),
          _buildPatchesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'เพิ่ม Target Game' : 'เพิ่ม Patch ใหม่',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          if (_tabController.index == 0) {
            _showGameDialog();
          } else {
            _showPatchDialog();
          }
        },
      ),
    );
  }

  // ==================================================================
  // TAB 1: TARGET GAMES UI
  // ==================================================================
  Widget _buildGamesTab() {
    if (_isLoadingGames) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredGames = _gamesList.where((g) {
      final query = _gameSearchQuery.toLowerCase();
      return g.name.toLowerCase().contains(query) ||
          g.bundleID.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onChanged: (val) => setState(() => _gameSearchQuery = val),
            decoration: InputDecoration(
              hintText: 'ค้นหา Target Game หรือ Bundle ID...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
            ),
          ),
        ),

        // List View with Expandable Cards
        Expanded(
          child: filteredGames.isEmpty
              ? const Center(child: Text('ไม่พบข้อมูล Target Game', style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                  itemCount: filteredGames.length,
                  itemBuilder: (context, index) {
                    final game = filteredGames[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          iconColor: Colors.blueAccent,
                          collapsedIconColor: Colors.white54,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: game.active
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            child: Icon(
                              game.active ? Icons.sports_esports : Icons.block,
                              color: game.active ? Colors.greenAccent : Colors.grey,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            game.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            game.bundleID,
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                          trailing: _buildStatusCapsule(
                            game.active,
                            onTap: () => _toggleGame(game.bundleID),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF161616),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRowRight(
                                      'ชื่อเกม:',
                                      Text(
                                        game.name,
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                    _buildDetailRowRight(
                                      'Bundle ID:',
                                      Text(
                                        game.bundleID,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                    _buildDetailRowRight(
                                      'สถานะ:',
                                      _buildStatusCapsule(
                                        game.active,
                                        onTap: () => _toggleGame(game.bundleID),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.edit, size: 15),
                                          label: const Text('แก้ไข', style: TextStyle(fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.blueAccent,
                                            side: const BorderSide(color: Colors.blueAccent),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () => _showGameDialog(game: game),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.delete, size: 15),
                                          label: const Text('ลบ', style: TextStyle(fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                            side: const BorderSide(color: Colors.redAccent),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () => _deleteGame(game.bundleID),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==================================================================
  // TAB 2: PATCHES CATALOG UI
  // ==================================================================
  Widget _buildPatchesTab() {
    if (_isLoadingPatches) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredPatches = _patchesList.where((p) {
      final query = _patchSearchQuery.toLowerCase();
      return p.title.toLowerCase().contains(query) ||
          p.id.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.bundleID.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onChanged: (val) => setState(() => _patchSearchQuery = val),
            decoration: InputDecoration(
              hintText: 'ค้นหา Patch ID, ชื่อ, หมวดหมู่ หรือ Bundle ID...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
            ),
          ),
        ),

        // List View with Expandable Cards
        Expanded(
          child: filteredPatches.isEmpty
              ? const Center(child: Text('ไม่พบข้อมูล Patch ในระบบ', style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                  itemCount: filteredPatches.length,
                  itemBuilder: (context, index) {
                    final patch = filteredPatches[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          iconColor: Colors.blueAccent,
                          collapsedIconColor: Colors.white54,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: patch.active
                                ? Colors.blueAccent.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            child: Text(
                              patch.category.isNotEmpty
                                  ? patch.category[0].toUpperCase()
                                  : 'P',
                              style: TextStyle(
                                color: patch.active ? Colors.blueAccent : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            patch.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'ID: ${patch.id}',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                          trailing: _buildStatusCapsule(
                            patch.active,
                            onTap: () => _togglePatch(patch.id),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF161616),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRowRight(
                                      'Patch ID:',
                                      Text(
                                        patch.id,
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                    _buildDetailRowRight(
                                      'ชื่อ Patch:',
                                      Text(
                                        patch.title,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                    _buildDetailRowRight(
                                      'หมวดหมู่:',
                                      _buildCategoryCapsule(
                                        patch.category.isEmpty ? 'General' : patch.category,
                                        color: Colors.purpleAccent,
                                      ),
                                    ),
                                    _buildDetailRowRight(
                                      'Target Bundle:',
                                      patch.bundleID.isEmpty
                                          ? _buildCategoryCapsule('All Games', color: Colors.orangeAccent)
                                          : Text(
                                              patch.bundleID,
                                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                                              textAlign: TextAlign.end,
                                            ),
                                    ),
                                    _buildDetailRowRight(
                                      'สถานะ:',
                                      _buildStatusCapsule(
                                        patch.active,
                                        onTap: () => _togglePatch(patch.id),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.edit, size: 15),
                                          label: const Text('แก้ไข Patch', style: TextStyle(fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.blueAccent,
                                            side: const BorderSide(color: Colors.blueAccent),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () => _showPatchDialog(patch: patch),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.delete, size: 15),
                                          label: const Text('ลบ Patch', style: TextStyle(fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                            side: const BorderSide(color: Colors.redAccent),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () => _deletePatch(patch.id),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
