import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common/custom_admin_input.dart';
import '../../auth/logic/user_provider.dart';
import '../../settings/presentation/widgets/common/config_card.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final TextEditingController _emailController = TextEditingController(); // read-only

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isSavingProfile = false;
  bool _isUploadingAvatar = false;
  bool _isChangingPassword = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final userProvider = context.read<UserProvider>();
    _nameController.text = userProvider.displayName ?? '';
    _phoneController.text = userProvider.phoneNumber ?? '';
    _emailController.text = userProvider.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);
    
    try {
      await context.read<UserProvider>().updateAdminProfile(
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      _showSnackBar('Profile updated successfully');
    } catch (e) {
      _showSnackBar('Error updating profile: $e', isError: true);
    } finally {
      setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _uploadAvatar() async {
    try {
      final user = context.read<UserProvider>();
      
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isUploadingAvatar = true);

      final Uint8List imageBytes = await image.readAsBytes();
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars/admins/admin_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await storageRef.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await user.updateAdminProfile(photoURL: downloadUrl);
      
      _showSnackBar('Avatar updated successfully');
    } catch (e) {
      _showSnackBar('Error uploading avatar: $e', isError: true);
    } finally {
      setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty || 
        _newPasswordController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('Please fill all password fields', isError: true);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('New passwords do not match', isError: true);
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
      _showSnackBar('Password changed successfully');
    } catch (e) {
      _showSnackBar('Error changing password: ${e.toString().split(']').last.trim()}', isError: true);
    } finally {
      setState(() => _isChangingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Account',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your profile information and security settings.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Profile Info & Avatar
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      ConfigCard(
                        title: 'Personal Information',
                        subtitle: 'Update your photo and personal details.',
                        children: [
                          Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        shape: BoxShape.circle,
                                        image: userProvider.photoURL != null
                                            ? DecorationImage(
                                                image: NetworkImage(userProvider.photoURL!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: userProvider.photoURL == null
                                          ? const Icon(Icons.person, size: 40, color: AppColors.textMuted)
                                          : null,
                                    ),
                                    if (_isUploadingAvatar)
                                      const Positioned.fill(
                                        child: CircularProgressIndicator(color: AppColors.primary),
                                      ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: InkWell(
                                        onTap: _isUploadingAvatar ? null : _uploadAvatar,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              CustomAdminInput(
                                label: 'Email Address',
                                hintText: 'admin@domain.com',
                                prefixIcon: Icons.email_outlined,
                                initialValue: _emailController.text,
                                // Email is disabled for change through basic UI without extensive reauth setup usually
                                // Using CustomAdminInput requires an onChanged or we use a separate widget if disabled.
                                // We'll just pass onChanged arbitrarily but not save it. 
                                // To make it read-only, we should ideally use standard TextFormField or just show it as text
                              ),
                              const SizedBox(height: 16),
                              CustomAdminInput(
                                label: 'Display Name',
                                hintText: 'Enter your full name',
                                prefixIcon: Icons.badge_outlined,
                                initialValue: _nameController.text,
                                onChanged: (val) => _nameController.text = val,
                              ),
                              const SizedBox(height: 16),
                              CustomAdminInput(
                                label: 'Phone Number',
                                hintText: 'Enter your phone number',
                                prefixIcon: Icons.phone_outlined,
                                initialValue: _phoneController.text,
                                onChanged: (val) => _phoneController.text = val,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _isSavingProfile ? null : _updateProfile,
                                    icon: _isSavingProfile 
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(Icons.save, size: 18),
                                    label: Text(
                                      _isSavingProfile ? 'Saving...' : 'Save Profile',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ], // Close children array
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 24),

                // Right Column: Security (Password)
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      ConfigCard(
                        title: 'Security',
                        subtitle: 'Change your password.',
                        children: [
                          Form(
                          key: _passwordFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomAdminInput(
                                label: 'Current Password',
                                hintText: 'Enter current password',
                                prefixIcon: Icons.lock_outline,
                                onChanged: (val) => _currentPasswordController.text = val,
                              ),
                              const SizedBox(height: 16),
                              CustomAdminInput(
                                label: 'New Password',
                                hintText: 'Enter new password',
                                prefixIcon: Icons.lock_reset,
                                onChanged: (val) => _newPasswordController.text = val,
                              ),
                              const SizedBox(height: 16),
                              CustomAdminInput(
                                label: 'Confirm New Password',
                                hintText: 'Confirm your new password',
                                prefixIcon: Icons.done_all,
                                onChanged: (val) => _confirmPasswordController.text = val,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isChangingPassword ? null : _changePassword,
                                  icon: _isChangingPassword 
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.security, size: 18),
                                  label: Text(
                                    _isChangingPassword ? 'Updating...' : 'Update Password',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.background,
                                    foregroundColor: AppColors.textHeading,
                                    side: const BorderSide(color: AppColors.border),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ), // Closes Form
                        ], // Closes children
                      ), // Closes ConfigCard
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}
