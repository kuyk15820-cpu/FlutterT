import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/model.dart';
import '../services/api_service.dart';

class AppVersionAdminScreen extends StatefulWidget {
  const AppVersionAdminScreen({Key? key}) : super(key: key);

  @override
  State<AppVersionAdminScreen> createState() => _AppVersionAdminScreenState();
}

class _AppVersionAdminScreenState extends State<AppVersionAdminScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _bundleIDController = TextEditingController();
  final _appNameController = TextEditingController();
  final _latestVersionController = TextEditingController();
  final _allowedVersionsController = TextEditingController();
  final _releaseNotesController = TextEditingController();

  File? _selectedFile;
  String? _selectedFileName;
  String? _currentDownloadUrl;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersionData();
  }

  @override
  void dispose() {
    _bundleIDController.dispose();
    _appNameController.dispose();
    _latestVersionController.dispose();
    _allowedVersionsController.dispose();
    _releaseNotesController.dispose();
    super.dispose();
  }

  /// ดึงข้อมูลเวอร์ชันปัจจุบันจากเซิร์ฟเวอร์
  Future<void> _loadCurrentVersionData() async {
    setState(() => _isLoading = true);
    try {
      final config = await ApiService.fetchAppVersion();
      _bundleIDController.text = config.bundleID;
      _appNameController.text = config.appName;
      _latestVersionController.text = config.latestVersion;
      _allowedVersionsController.text = config.allowedVersions.join(', ');
      _releaseNotesController.text = config.releaseNotes;
      _currentDownloadUrl = config.downloadUrl;
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// เลือกไฟล์ .ipa จากตัวเครื่อง
  Future<void> _pickIpaFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ipa'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
      });
    }
  }

  /// ส่งข้อมูลไปอัปเดตบนเซิร์ฟเวอร์
  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    // ถ้าไม่มีไฟล์เก่า และยังไม่ได้เลือกไฟล์ใหม่
    if ((_currentDownloadUrl == null || _currentDownloadUrl!.isEmpty) && _selectedFile == null) {
      _showSnackBar('กรุณาเลือกไฟล์ .ipa ก่อนทำการบันทึก', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final allowedList = _allowedVersionsController.text
          .split(',')
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .toList();

      final success = await ApiService.updateAppVersion(
        bundleID: _bundleIDController.text.trim(),
        appName: _appNameController.text.trim(),
        latestVersion: _latestVersionController.text.trim(),
        allowedVersions: allowedList,
        releaseNotes: _releaseNotesController.text.trim(),
        downloadUrl: _currentDownloadUrl,
        ipaFile: _selectedFile,
      );

      if (success) {
        _showSnackBar('บันทึกและประกาศอัปเดตเรียบร้อยแล้ว');
        _selectedFile = null;
        _selectedFileName = null;
        _loadCurrentVersionData(); // โหลดข้อมูลใหม่เพื่ออัปเดต URL ล่าสุด
      }
    } catch (e) {
      _showSnackBar('บันทึกข้อมูลไม่สำเร็จ: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('App Version Manager'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadCurrentVersionData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Current Status Card
                    _buildCurrentStatusCard(),
                    const SizedBox(height: 20),

                    // 2. Form Title
                    const Text(
                      'จัดการเวอร์ชันและข้อมูลแอป',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Form Inputs
                    _buildTextField(
                      controller: _bundleIDController,
                      label: 'Bundle ID เป้าหมาย',
                      hint: 'เช่น com.dts.freefireth',
                      validator: (v) => v == null || v.isEmpty ? 'กรุณากรอก Bundle ID' : null,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _appNameController,
                      label: 'ชื่อแอป (App Name)',
                      hint: 'เช่น FXTool',
                      validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกชื่อแอป' : null,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _latestVersionController,
                      label: 'เวอร์ชันล่าสุด (Latest Version)',
                      hint: 'เช่น 1.0.1',
                      validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกเวอร์ชันล่าสุด' : null,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _allowedVersionsController,
                      label: 'เวอร์ชันที่อนุญาตให้ใช้งาน (คั่นด้วย ,)',
                      hint: 'เช่น 1.0.0, 1.0.1',
                      sublabel: '* ถ้า User แก้ Info.plist หรือเวอร์ชันไม่ตรงในนี้ จะถูกบังคับอัปเดตทันที',
                      validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกเวอร์ชันที่อนุญาต' : null,
                    ),
                    const SizedBox(height: 12),

                    // 4. File Picker Section
                    _buildFilePickerSection(),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _releaseNotesController,
                      label: 'รายละเอียดอัปเดต (Release Notes)',
                      hint: 'รายละเอียดการอัปเดต...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // 5. Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isSaving ? null : _submitData,
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'บันทึกและประกาศอัปเดต',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'สถานะปัจจุบัน: ${_appNameController.text} (${_bundleIDController.text})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'เวอร์ชันล่าสุด: ${_latestVersionController.text}',
            style: const TextStyle(color: Colors.white70),
          ),
          if (_currentDownloadUrl != null && _currentDownloadUrl!.isNotEmpty) ...[
            const SizedBox(height: 6),
            SelectableText(
              'ไฟล์ปัจจุบัน: $_currentDownloadUrl',
              style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? sublabel,
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
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  Widget _buildFilePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('อัปโหลดไฟล์แอป (.ipa)', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const Text('* ระบบจะสร้าง URL ดาวน์โหลดและบันทึกลง JSON ให้อัตโนมัติ',
            style: TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickIpaFile,
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
                    _selectedFileName ?? 'เลือกไฟล์ .ipa...',
                    style: TextStyle(
                      color: _selectedFileName != null ? Colors.white : Colors.white38,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Browse', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
