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

  // Search Toggle State
  bool _showSearch = false;

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
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
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

  // Widget แสดงข้อมูลแบบจัดชิดขวา (Text ปกติ สมดุล)
  Widget _buildDetailRowRight(String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
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

  // Action Buttons แบบ Capsule ทรงแคปซูล
  Widget _buildCapsuleActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 14, color: color),
      label: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.6), width: 1),
        shape: const StadiumBorder(), // รูปทรงแคปซูล
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Patch & Game Manager', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search, color: Colors.white70),
            tooltip: _showSearch ? 'ซ่อนการค้นหา' : 'แสดงการค้นหา',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
            tooltip: _tabController.index == 0 ? 'เพิ่ม Target Game' : 'เพิ่ม Patch ใหม่',
            onPressed: () {
              if (_tabController.index == 0) {
                _showGameDialog();
              } else {
                _showPatchDialog();
              }
            },
          ),
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
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadAllData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.blueAccent.withOpacity(0.25),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                ),
                labelColor: Colors.blueAccent,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.sports_esports, size: 18), text: 'Target Games'),
                  Tab(icon: Icon(Icons.extension, size: 18), text: 'Patches Catalog'),
                ],
              ),
            ),
          ),
        ),
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

    final filteredGames = _gamesList.where((g) {
      final query = _gameSearchQuery.toLowerCase();
      return g.name.toLowerCase().contains(query) ||
          g.bundleID.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // Search Bar (เปิด/ปิด ได้จาก AppBar)
        if (_showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
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

        // List View with Main Card Table & Sub Card
        Expanded(
          child: filteredGames.isEmpty
              ? const Center(child: Text('ไม่พบข้อมูล Target Game', style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: filteredGames.length,
                  itemBuilder: (context, index) {
                    final game = filteredGames[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                              child: Column(
                                children: [
                                  // Card ย่อยแสดงข้อมูล
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF141414),
                                      borderRadius: BorderRadius.circular(10),
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
                                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace'),
                                            textAlign: TextAlign.end,
                                          ),
                                        ),
                                        _buildDetailRowRight(
                                          'สถานะการทำงาน:',
                                          _buildStatusCapsule(
                                            game.active,
                                            onTap: () => _toggleGame(game.bundleID),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Action Buttons แบบ Capsule อยู่นอก Card ย่อย
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      _buildCapsuleActionButton(
                                        icon: Icons.edit_outlined,
                                        label: 'แก้ไข',
                                        color: Colors.blueAccent,
                                        onPressed: () => _showGameDialog(game: game),
                                      ),
                                      const SizedBox(width: 10),
                                      _buildCapsuleActionButton(
                                        icon: Icons.delete_outline,
                                        label: 'ลบ',
                                        color: Colors.redAccent,
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

    final filteredPatches = _patchesList.where((p) {
      final query = _patchSearchQuery.toLowerCase();
      return p.title.toLowerCase().contains(query) ||
          p.id.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.bundleID.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // Search Bar (เปิด/ปิด ได้จาก AppBar)
        if (_showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
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

        // List View with Main Card Table & Sub Card
        Expanded(
          child: filteredPatches.isEmpty
              ? const Center(child: Text('ไม่พบข้อมูล Patch ในระบบ', style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: filteredPatches.length,
                  itemBuilder: (context, index) {
                    final patch = filteredPatches[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                              child: Column(
                                children: [
                                  // Card ย่อยแสดงข้อมูล (ใช้ Text ปกติ ID Patch Text)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF141414),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailRowRight(
                                          'Patch ID:',
                                          Text(
                                            patch.id,
                                            style: const TextStyle(
                                              color: Colors.lightBlueAccent,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'monospace',
                                            ),
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
                                          Text(
                                            patch.category.isEmpty ? 'General' : patch.category,
                                            style: const TextStyle(
                                              color: Colors.purpleAccent,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.end,
                                          ),
                                        ),
                                        _buildDetailRowRight(
                                          'Target Bundle:',
                                          Text(
                                            patch.bundleID.isEmpty ? 'All Games (ทุกเกม)' : patch.bundleID,
                                            style: TextStyle(
                                              color: patch.bundleID.isEmpty ? Colors.orangeAccent : Colors.white70,
                                              fontSize: 13,
                                              fontFamily: patch.bundleID.isEmpty ? null : 'monospace',
                                            ),
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
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Action Buttons แบบ Capsule อยู่นอก Card ย่อย
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      _buildCapsuleActionButton(
                                        icon: Icons.edit_outlined,
                                        label: 'แก้ไข Patch',
                                        color: Colors.blueAccent,
                                        onPressed: () => _showPatchDialog(patch: patch),
                                      ),
                                      const SizedBox(width: 10),
                                      _buildCapsuleActionButton(
                                        icon: Icons.delete_outline,
                                        label: 'ลบ Patch',
                                        color: Colors.redAccent,
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
}
