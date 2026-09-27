import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/model.dart';
import '../services/api_service.dart';

// 🟢 Helper Function สำหรับแปลงเวลา ISO String เป็นเวลาภาษาไทย
String formatThaiTimeAgo(String? isoDateTimeString) {
  if (isoDateTimeString == null || isoDateTimeString.isEmpty) {
    return '-';
  }
  try {
    final dateTime = DateTime.parse(isoDateTimeString).toLocal();
    return timeago.format(dateTime, locale: 'th');
  } catch (e) {
    return isoDateTimeString;
  }
}

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

  // Filter Status State: 'all', 'active', 'disabled'
  String _selectedFilterStatus = 'all';

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

  // 🟢 แสดง Bottom Sheet สำหรับ เพิ่ม/แก้ไข Target Game
  void _showGameBottomSheet({TargetGame? game}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: game?.name ?? '');
    final bundleController = TextEditingController(text: game?.bundleID ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 12,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        game == null ? 'เพิ่ม Target Game' : 'แก้ไข Target Game',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFormTextField(
                        controller: nameController,
                        label: 'ชื่อเกม (Game Name)',
                        hint: 'เช่น Free Fire',
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อเกม' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildFormTextField(
                        controller: bundleController,
                        label: 'Bundle ID',
                        hint: 'เช่น com.dts.freefireth',
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'กรุณากรอก Bundle ID' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setSheetState(() => isSaving = true);
                                  try {
                                    await ApiService.addOrUpdateGame(
                                      gameName: nameController.text.trim(),
                                      bundleID: bundleController.text.trim(),
                                    );
                                    if (mounted) Navigator.pop(ctx);
                                    _showSnackBar('บันทึกข้อมูลเกมสำเร็จ');
                                    _loadGames();
                                  } catch (e) {
                                    setSheetState(() => isSaving = false);
                                    _showSnackBar('บันทึกไม่สำเร็จ: $e', isError: true);
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'บันทึกข้อมูล',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

  // 🟢 แสดง Bottom Sheet สำหรับ เพิ่ม/แก้ไข Patch
  void _showPatchBottomSheet({PatchItem? patch}) {
    final formKey = GlobalKey<FormState>();
    final idController = TextEditingController(text: patch?.id ?? '');
    final titleController = TextEditingController(text: patch?.title ?? '');
    final categoryController =
        TextEditingController(text: patch?.category ?? 'General');
    final bundleController = TextEditingController(text: patch?.bundleID ?? '');

    File? selectedFile;
    String? selectedFileName;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 12,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        patch == null ? 'เพิ่ม Patch ใหม่' : 'แก้ไข Patch',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFormTextField(
                        controller: idController,
                        label: 'Patch ID',
                        hint: 'เช่น anti_recoil_v1',
                        enabled: patch == null,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'กรุณากรอก Patch ID' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildFormTextField(
                        controller: titleController,
                        label: 'ชื่อ Patch (Title)',
                        hint: 'เช่น No Recoil High Accuracy',
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อ Patch' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildFormTextField(
                        controller: categoryController,
                        label: 'หมวดหมู่ (Category)',
                        hint: 'เช่น Weapon, ESP, General',
                      ),
                      const SizedBox(height: 12),
                      _buildFormTextField(
                        controller: bundleController,
                        label: 'Target Bundle ID',
                        hint: 'เว้นว่างไว้เพื่อใช้งานทุกเกม',
                      ),
                      const SizedBox(height: 12),

                      // 🟢 File Picker Section รูปแบบ Card สไตล์ admin_tab
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'อัปโหลดไฟล์ Patch (.c4)',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles();
                              if (result != null &&
                                  result.files.single.path != null) {
                                setSheetState(() {
                                  selectedFile = File(result.files.single.path!);
                                  selectedFileName = result.files.single.name;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.upload_file, color: Colors.blueAccent),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      selectedFileName ?? 'เลือกไฟล์ Patch (.c4)...',
                                      style: TextStyle(
                                        color: selectedFileName != null
                                            ? Colors.white
                                            : Colors.white38,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Browse',
                                      style: TextStyle(
                                          color: Colors.blueAccent, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setSheetState(() => isSaving = true);
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
                                    if (mounted) Navigator.pop(ctx);
                                    _loadPatches();
                                  } catch (e) {
                                    setSheetState(() => isSaving = false);
                                    _showSnackBar('บันทึก Patch ไม่สำเร็จ: $e', isError: true);
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'บันทึกข้อมูล',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🟢 แสดง Filters UI Bottom Sheet สำหรับเลือกกรองสถานะ
  void _showFilterBottomSheet() {
    String tempFilter = _selectedFilterStatus;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Status (สถานะการใช้งาน)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildFilterChip(
                        label: 'ทั้งหมด (All)',
                        value: 'all',
                        selectedValue: tempFilter,
                        onSelected: (val) => setSheetState(() => tempFilter = val),
                      ),
                      _buildFilterChip(
                        label: 'ใช้งานได้ (Active)',
                        value: 'active',
                        selectedValue: tempFilter,
                        onSelected: (val) => setSheetState(() => tempFilter = val),
                      ),
                      _buildFilterChip(
                        label: 'ปิดปรับปรุง (Disabled)',
                        value: 'disabled',
                        selectedValue: tempFilter,
                        onSelected: (val) => setSheetState(() => tempFilter = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            setSheetState(() => tempFilter = 'all');
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedFilterStatus = tempFilter;
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    final bool isSelected = value == selectedValue;
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.2)
              : const Color(0xFF121212),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blueAccent : Colors.white60,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
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

  // 🟢 Form TextField สไตล์ admin_tab.dart
  Widget _buildFormTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? sublabel,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        if (sublabel != null)
          Text(sublabel, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: enabled ? const Color(0xFF1E1E1E) : Colors.white10,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  Widget _buildDetailRowRight(String label, String valueText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 13, fontWeight: FontWeight.normal),
          ),
          Flexible(
            child: Text(
              valueText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

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
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildStandardTabBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
        tabs: const [
          Tab(text: 'Target Games'),
          Tab(text: 'Patches Catalog'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Patch & Game Manager',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search,
                color: Colors.white),
            tooltip: _showSearch ? 'ซ่อนการค้นหา' : 'แสดงการค้นหา',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
              });
            },
          ),
          // 🟢 ปุ่ม Filters บน AppBar
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            tooltip: 'ตัวกรอง (Filters)',
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip:
                _tabController.index == 0 ? 'เพิ่ม Target Game' : 'เพิ่ม Patch ใหม่',
            onPressed: () {
              if (_tabController.index == 0) {
                _showGameBottomSheet();
              } else {
                _showPatchBottomSheet();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.white),
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
            icon: const Icon(Icons.power_settings_new, color: Colors.white),
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
            icon: const Icon(Icons.refresh, color: Colors.white),
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

    final filteredGames = _gamesList.where((g) {
      final query = _gameSearchQuery.toLowerCase();
      final matchesSearch = g.name.toLowerCase().contains(query) ||
          g.bundleID.toLowerCase().contains(query);

      bool matchesFilter = true;
      if (_selectedFilterStatus == 'active') {
        matchesFilter = g.active;
      } else if (_selectedFilterStatus == 'disabled') {
        matchesFilter = !g.active;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Column(
            children: [
              _buildStandardTabBar(),
              if (_showSearch) ...[
                const SizedBox(height: 8),
                TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (val) => setState(() => _gameSearchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'ค้นหา Target Game หรือ Bundle ID...',
                    hintStyle:
                        const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white54, size: 20),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: filteredGames.isEmpty
              ? const Center(
                  child: Text('ไม่พบข้อมูล Target Game',
                      style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                  itemCount: filteredGames.length,
                  itemBuilder: (context, index) {
                    final game = filteredGames[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          iconColor: Colors.white,
                          collapsedIconColor: Colors.white54,
                          leading: CircleAvatar(
                            radius: 15,
                            backgroundColor: game.active
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            child: Text(
                              '#${index + 1}',
                              style: TextStyle(
                                color:
                                    game.active ? Colors.greenAccent : Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            game.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'อัปเดตเมื่อ: ${formatThaiTimeAgo(game.updatedAt)}',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                          trailing: _buildStatusCapsule(
                            game.active,
                            onTap: () => _toggleGame(game.bundleID),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF141414),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailRowRight('ชื่อเกม:', game.name),
                                        _buildDetailRowRight(
                                            'Bundle ID:', game.bundleID),
                                        _buildDetailRowRight(
                                          'สถานะ:',
                                          game.active
                                              ? 'เปิดใช้งาน'
                                              : 'ปิดใช้งาน',
                                        ),
                                        _buildDetailRowRight(
                                          'อัปเดตเมื่อ:',
                                          formatThaiTimeAgo(game.updatedAt),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      _buildCapsuleActionButton(
                                        icon: Icons.edit_outlined,
                                        label: 'แก้ไข',
                                        color: Colors.blueAccent,
                                        onPressed: () =>
                                            _showGameBottomSheet(game: game),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildCapsuleActionButton(
                                        icon: Icons.delete_outline,
                                        label: 'ลบ',
                                        color: Colors.redAccent,
                                        onPressed: () =>
                                            _deleteGame(game.bundleID),
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
      final matchesSearch = p.title.toLowerCase().contains(query) ||
          p.id.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.bundleID.toLowerCase().contains(query);

      bool matchesFilter = true;
      if (_selectedFilterStatus == 'active') {
        matchesFilter = p.active;
      } else if (_selectedFilterStatus == 'disabled') {
        matchesFilter = !p.active;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Column(
            children: [
              _buildStandardTabBar(),
              if (_showSearch) ...[
                const SizedBox(height: 8),
                TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (val) => setState(() => _patchSearchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'ค้นหา Patch ID, ชื่อ, หมวดหมู่ หรือ Bundle ID...',
                    hintStyle:
                        const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white54, size: 20),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: filteredPatches.isEmpty
              ? const Center(
                  child: Text('ไม่พบข้อมูล Patch ในระบบ',
                      style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                  itemCount: filteredPatches.length,
                  itemBuilder: (context, index) {
                    final patch = filteredPatches[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          iconColor: Colors.white,
                          collapsedIconColor: Colors.white54,
                          leading: CircleAvatar(
                            radius: 15,
                            backgroundColor: patch.active
                                ? Colors.blueAccent.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            child: Text(
                              '#${patch.id}',
                              style: TextStyle(
                                color:
                                    patch.active ? Colors.blueAccent : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          title: Text(
                            patch.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'อัปเดตเมื่อ: ${formatThaiTimeAgo(patch.updatedAt)}',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                          trailing: _buildStatusCapsule(
                            patch.active,
                            onTap: () => _togglePatch(patch.id),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF141414),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailRowRight(
                                            'ID:', #patch.id),
                                        _buildDetailRowRight(
                                            'ชื่อ:', patch.title),
                                        _buildDetailRowRight(
                                            'หมวดหมู่:',
                                            patch.category.isEmpty
                                                ? 'General'
                                                : patch.category),
                                        _buildDetailRowRight(
                                            'เป้าหมาย:',
                                            patch.bundleID.isEmpty
                                                ? 'All Games (ทุกเกม)'
                                                : patch.bundleID),
                                        _buildDetailRowRight(
                                            'อัปเดตเมื่อ:',
                                            formatThaiTimeAgo(patch.updatedAt)),
                                        _buildDetailRowRight(
                                          'สถานะ:',
                                          patch.active
                                              ? 'ใช้งานอยู่'
                                              : 'ปิดปรับปรุง',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      _buildCapsuleActionButton(
                                        icon: Icons.edit_outlined,
                                        label: 'แก้ไขแพทช์',
                                        color: Colors.blueAccent,
                                        onPressed: () =>
                                            _showPatchBottomSheet(patch: patch),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildCapsuleActionButton(
                                        icon: Icons.delete_outline,
                                        label: 'ลบแพทช์',
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
