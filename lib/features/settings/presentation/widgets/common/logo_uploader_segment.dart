import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:admin_daklak_web/core/constants/app_colors.dart';

class LogoUploaderSegment extends StatefulWidget {
  final String? initialLogoUrl;
  final String appInitial;
  final Function(Uint8List?) onLogoChanged;

  const LogoUploaderSegment({
    super.key,
    this.initialLogoUrl,
    required this.appInitial,
    required this.onLogoChanged,
  });

  @override
  State<LogoUploaderSegment> createState() => _LogoUploaderSegmentState();
}

class _LogoUploaderSegmentState extends State<LogoUploaderSegment> {
  Uint8List? _previewData;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _previewData = bytes);
      widget.onLogoChanged(bytes);
    }
  }

  void _removeImage() {
    setState(() => _previewData = null);
    widget.onLogoChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Logo thương hiệu',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid, // Dash effect would require custom painter or package
            ),
          ),
          child: Row(
            children: [
              // Logo Preview
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _previewData != null
                      ? Image.memory(_previewData!, fit: BoxFit.cover)
                      : widget.initialLogoUrl != null && widget.initialLogoUrl!.isNotEmpty
                          ? Image.network(widget.initialLogoUrl!, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                widget.appInitial,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary.withOpacity(0.5),
                                ),
                              ),
                            ),
                ),
              ),
              const SizedBox(width: 24),
              // Controls
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Định dạng khuyên dùng: PNG, SVG (Tối đa 2MB)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceVariant,
                            foregroundColor: AppColors.textHeading,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Thay đổi', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: _removeImage,
                          child: const Text(
                            'Gỡ bỏ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
