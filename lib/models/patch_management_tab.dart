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

  // Patches State
  List<PatchItem> _patchesList = [];
  bool _isLoadingPatches = false;

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
          borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Patch & Game Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGamesTab(),
          _buildPatchesTab(),
        ],
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

    return Column(
      children: [
        // Action Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('เพิ่มเกมใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showGameDialog(),
              ),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.power_settings_new, size: 16),
                label: const Text('เปิดหมด', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.greenAccent,
                  side: const BorderSide(color: Colors.greenAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _toggleAllGames(true),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.power_off, size: 16),
                label: const Text('ปิดหมด', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _toggleAllGames(false),
              ),
            ],
          ),
        ),

        // List View with Expandable Cards
        Expanded(
          child: _gamesList.isEmpty
              ? const Center(child: Text('ไม่มีข้อมูล Target Game', style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _gamesList.length,
                  itemBuilder: (context, index) {
                    final game = _gamesList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(10),
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
                              game.active ? Icons.check : Icons.block,
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
                          trailing: Switch(
                            value: game.active,
                            activeColor: Colors.blueAccent,
                            onChanged: (_) => _toggleGame(game.bundleID),
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                color: Color(0xFF161616),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow('ชื่อเกม:', game.name),
                                  const SizedBox(height: 6),
                                  _buildDetailRow('Bundle ID:', game.bundleID),
                                  const SizedBox(height: 6),
                                  _buildDetailRow('สถานะ:', game.active ? 'เปิดใช้งาน (Active)' : 'ปิดใช้งาน (Disabled)'),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('แก้ไข'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.blueAccent,
                                          side: const BorderSide(color: Colors.blueAccent),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        onPressed: () => _showGameDialog(game: game),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.delete, size: 16),
                                        label: const Text('ลบ'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.redAccent,
                                          side: const BorderSide(color: Colors.redAccent),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        onPressed: () => _deleteGame(game.bundleID),
                                      ),
                                    ],
                                  ),
                                ],
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

    return Column(
      children: [
        // Action Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('เพิ่ม Patch ใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showPatchDialog(),
              ),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.power_settings_new, size: 16),
                label: const Text('เปิดหมด', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.greenAccent,
                  side: const BorderSide(color: Colors.greenAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _toggleAllPatches(true),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.power_off, size: 16),
                label: const Text('ปิดหมด', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _toggleAllPatches(false),
              ),
            ],
          ),
        ),

        // List View with Expandable Cards
        Expanded(
          child: _patchesList.isEmpty
              ? const Center(child: Text('ไม่มีข้อมูล Patch ในระบบ', style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _patchesList.length,
                  itemBuilder: (context, index) {
                    final patch = _patchesList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(10),
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
                          trailing: Switch(
                            value: patch.active,
                            activeColor: Colors.blueAccent,
                            onChanged: (_) => _togglePatch(patch.id),
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                color: Color(0xFF161616),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow('Patch ID:', patch.id),
                                  const SizedBox(height: 6),
                                  _buildDetailRow('ชื่อ Patch:', patch.title),
                                  const SizedBox(height: 6),
                                  _buildDetailRow('หมวดหมู่:', patch.category.isEmpty ? '-' : patch.category),
                                  const SizedBox(height: 6),
                                  _buildDetailRow('Target Bundle:', patch.bundleID.isEmpty ? 'รองรับทุกเกม (All Games)' : patch.bundleID),
                                  const SizedBox(height: 6),
                                  _buildDetailRow('สถานะ:', patch.active ? 'เปิดใช้งาน (Active)' : 'ปิดใช้งาน (Disabled)'),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('แก้ไข Patch'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.blueAccent,
                                          side: const BorderSide(color: Colors.blueAccent),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        onPressed: () => _showPatchDialog(patch: patch),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.delete, size: 16),
                                        label: const Text('ลบ Patch'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.redAccent,
                                          side: const BorderSide(color: Colors.redAccent),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        onPressed: () => _deletePatch(patch.id),
                                      ),
                                    ],
                                  ),
                                ],
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
