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
        title: Text(game == null ? 'เพิ่ม Target Game' : 'แก้ไข Target Game'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'ชื่อเกม (Game Name)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bundleController,
              decoration: const InputDecoration(labelText: 'Bundle ID'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
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
            child: const Text('บันทึก'),
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
      builder: (ctx) => StatefulWidget(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(patch == null ? 'เพิ่ม Patch ใหม่' : 'แก้ไข Patch'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAlignment.start,
              children: [
                TextField(
                  controller: idController,
                  enabled: patch == null, // ห้ามแก้ ID เมื่อแก้ไข
                  decoration: const InputDecoration(
                    labelText: 'Patch ID (เช่น anti_recoil_v1)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'ชื่อ Patch (Title)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'หมวดหมู่ (Category)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bundleController,
                  decoration: const InputDecoration(labelText: 'Target Bundle ID'),
                ),
                const SizedBox(height: 16),
                const Text('ไฟล์ Patch (.c4):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedFile != null
                            ? selectedFile!.path.split('/').last
                            : 'ยังไม่ได้เลือกไฟล์',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.attach_file, size: 16),
                      label: const Text('เลือกไฟล์'),
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles();
                        if (result != null && result.files.single.path != null) {
                          setDialogState(() {
                            selectedFile = File(result.files.single.path!);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
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
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================================
  // HELPER UI
  // ==================================================================
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patch & Game Manager'),
        bottom: TabBar(
          controller: _tabController,
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
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.black12,
          child: Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('เพิ่มเกมใหม่'),
                onPressed: () => _showGameDialog(),
              ),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.power_settings_new),
                label: const Text('เปิดทั้งหมด'),
                onPressed: () => _toggleAllGames(true),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.power_off),
                label: const Text('ปิดทั้งหมด'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _toggleAllGames(false),
              ),
            ],
          ),
        ),
        Expanded(
          child: _gamesList.isEmpty
              ? const Center(child: Text('ไม่มีข้อมูล Target Game'))
              : ListView.builder(
                  itemCount: _gamesList.length,
                  itemBuilder: (context, index) {
                    final game = _gamesList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              game.active ? Colors.green : Colors.grey,
                          child: Icon(
                            game.active ? Icons.check : Icons.block,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(game.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(game.bundleID),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: game.active,
                              onChanged: (_) => _toggleGame(game.bundleID),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showGameDialog(game: game),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteGame(game.bundleID),
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
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.black12,
          child: Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('เพิ่ม Patch ใหม่'),
                onPressed: () => _showPatchDialog(),
              ),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.power_settings_new),
                label: const Text('เปิดทั้งหมด'),
                onPressed: () => _toggleAllPatches(true),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.power_off),
                label: const Text('ปิดทั้งหมด'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _toggleAllPatches(false),
              ),
            ],
          ),
        ),
        Expanded(
          child: _patchesList.isEmpty
              ? const Center(child: Text('ไม่มีข้อมูล Patch ในระบบ'))
              : ListView.builder(
                  itemCount: _patchesList.length,
                  itemBuilder: (context, index) {
                    final patch = _patchesList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              patch.active ? Colors.blue : Colors.grey,
                          child: Text(
                            patch.category.isNotEmpty
                                ? patch.category[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(patch.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'ID: ${patch.id}\nBundle: ${patch.bundleID.isEmpty ? "All Games" : patch.bundleID}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: patch.active,
                              onChanged: (_) => _togglePatch(patch.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showPatchDialog(patch: patch),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePatch(patch.id),
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
