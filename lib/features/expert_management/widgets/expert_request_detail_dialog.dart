import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import '../../../core/constants/app_colors.dart';
import '../models/expert_verification_request_model.dart';
import '../services/expert_verification_service.dart';

class ExpertRequestDetailDialog extends StatefulWidget {
  final ExpertVerificationRequestModel request;
  final VoidCallback onProcessed;

  const ExpertRequestDetailDialog({
    super.key,
    required this.request,
    required this.onProcessed,
  });

  @override
  State<ExpertRequestDetailDialog> createState() =>
      _ExpertRequestDetailDialogState();
}

class _ExpertRequestDetailDialogState extends State<ExpertRequestDetailDialog> {
  final ExpertVerificationService _service = ExpertVerificationService();
  bool _isProcessing = false;

  Future<void> _handleAction(bool isApproved) async {
    setState(() => _isProcessing = true);
    try {
      await _service.processRequest(
        requestId: widget.request.id,
        userId: widget.request.userId,
        isApproved: isApproved,
      );
      
      if (mounted) {
        _showSuccess(isApproved);
        widget.onProcessed();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccess(bool isApproved) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isApproved ? 'Đã duyệt chuyên gia thành công' : 'Đã từ chối yêu cầu'),
        backgroundColor: isApproved ? Colors.green[700] : Colors.red[700],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi: $message'), backgroundColor: Colors.red),
    );
  }

  void _openUrl(String url) {
    html.window.open(url, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 650,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          children: [
            // Header
            _buildHeader(),
            const Divider(height: 1),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Thông tin cá nhân'),
                    const SizedBox(height: 16),
                    _buildInfoGrid(),
                    
                    const SizedBox(height: 32),
                    _buildSectionHeader('Tiểu sử & Kinh nghiệm'),
                    const SizedBox(height: 12),
                    _buildBioCard(),
                    
                    const SizedBox(height: 32),
                    _buildSectionHeader('Tài liệu minh chứng'),
                    const SizedBox(height: 12),
                    _buildEvidenceGrid(),
                  ],
                ),
              ),
            ),
            
            const Divider(height: 1),
            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Hồ sơ xác minh chuyên gia',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Wrap(
      spacing: 40,
      runSpacing: 16,
      children: [
        _buildInfoItem('Họ tên', widget.request.fullName, width: 250),
        _buildInfoItem('Số điện thoại', widget.request.phone, width: 250),
        _buildInfoItem('Chuyên môn', widget.request.expertise, width: 250),
        _buildInfoItem('Cơ quan', widget.request.workplace, width: 250),
        _buildInfoItem('Trình độ', widget.request.education, width: 250),
        _buildInfoItem('Kỹ năng', widget.request.skills, width: 250),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, {double? width}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildBioCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        widget.request.bio.isEmpty ? 'Không có thông tin giới thiệu.' : widget.request.bio,
        style: const TextStyle(height: 1.5, fontSize: 14),
      ),
    );
  }

  Widget _buildEvidenceGrid() {
    if (widget.request.evidenceDocuments.isEmpty) {
      return const Text('Không có tài liệu đính kèm', style: TextStyle(fontStyle: FontStyle.italic));
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.request.evidenceDocuments.map((url) => _buildEvidenceCard(url)).toList(),
    );
  }

  Widget _buildEvidenceCard(String url) {
    final bool isImage = url.toLowerCase().contains(RegExp(r'\.(jpg|jpeg|png|webp|gif|svg)'));

    return InkWell(
      onTap: () => _openUrl(url),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 140,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: isImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                ),
              )
            : const Icon(Icons.description, size: 32, color: Colors.blueGrey),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isProcessing ? null : () => _handleAction(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: const Text('TỪ CHỐI DUYỆT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isProcessing ? null : () => _handleAction(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isProcessing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('CHẤP THUẬN CHUYÊN GIA', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
