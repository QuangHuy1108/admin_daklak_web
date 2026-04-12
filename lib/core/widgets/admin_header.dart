import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/auth/logic/user_provider.dart';
import '../../features/notifications/services/notification_service.dart';
import '../../features/notifications/models/notification_model.dart';
import '../../features/notifications/widgets/notification_dropdown.dart';
import '../services/search_service.dart';
import 'search_overlay.dart';

class AdminHeader extends StatefulWidget implements PreferredSizeWidget {
  const AdminHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<AdminHeader> createState() => _AdminHeaderState();
}

class _AdminHeaderState extends State<AdminHeader> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final LayerLink _layerLink = LayerLink();
  
  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  final SearchService _searchService = SearchService();
  
  bool _isSearching = false;
  List<SearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus && _searchController.text.isNotEmpty) {
        _showOverlay();
      } else if (!_searchFocus.hasFocus) {
        // Need a slight delay to allow taps on the overlay to register
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) _hideOverlay();
        });
      }
    });

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _hideOverlay();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      _showOverlay();
      setState(() => _isSearching = true);
      _overlayEntry?.markNeedsBuild();

      final results = await _searchService.searchGlobal(query);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
        _overlayEntry?.markNeedsBuild();
      }
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 400,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 50),
            child: SearchOverlay(
              isLoading: _isSearching,
              results: _searchResults,
              onClose: () {
                _hideOverlay();
                _searchFocus.unfocus();
                _searchController.clear();
              },
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width <= 768;
    final userProvider = Provider.of<UserProvider>(context);

    // Get real user data
    final displayName = userProvider.displayName ?? 'Admin';
    final email = userProvider.email ?? 'admin@farmvista.com';
    final photoURL = userProvider.photoURL;

    return Container(
      height: 64, 
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // ── Feature 2: Search Bar ──────────────────────────────
          if (!isMobile)
            Expanded(
              flex: 5,
              child: CompositedTransformTarget(
                link: _layerLink,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          decoration: InputDecoration(
                            hintText: 'Search orders, users, or experts...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textBody,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const Spacer(flex: 3),

          // ── Feature 3: Actions Group ───────────────────────────
          StreamBuilder<List<AdminNotification>>(
            stream: NotificationService.getUnreadNotificationsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('🚨 [AdminHeader] StreamBuilder Error: ${snapshot.error}');
              }
              final unreadList = snapshot.data ?? [];
              final unreadCount = unreadList.length;

              return Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.bug_report_outlined, color: Colors.grey.shade400, size: 18),
                    onPressed: () async {
                      try {
                        await NotificationService.sendTestNotification();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã gửi thông báo thử nghiệm thành công!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi khi gửi thông báo: $e')),
                          );
                        }
                      }
                    },
                    tooltip: 'Gửi Test Notification',
                  ),
                  const SizedBox(width: 8),

                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: PopupMenuButton<void>(
                          padding: EdgeInsets.zero,
                          tooltip: 'Thông báo',
                          offset: const Offset(0, 50),
                          icon: Icon(
                            unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                            color: unreadCount > 0 ? AppColors.primary : AppColors.textHeading,
                            size: 20,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          itemBuilder: (context) => [
                            PopupMenuItem<void>(
                              enabled: false,
                              padding: EdgeInsets.zero,
                              child: NotificationDropdown(
                                notifications: unreadList,
                                onAction: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(width: 20),
          Container(height: 24, width: 1, color: Colors.grey.shade300),
          const SizedBox(width: 20),

          // Profile item
          PopupMenuButton<String>(
            offset: const Offset(0, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('My Account'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                await AuthService().logout();
                if (context.mounted) context.go('/login');
              } else if (value == 'settings') {
                context.go('/settings');
              } else if (value == 'profile') {
                context.go('/profile');
              }
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                  child: photoURL == null
                      ? const Icon(Icons.person, size: 16, color: AppColors.textMuted)
                      : null,
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHeading,
                        ),
                      ),
                      Text(
                        email.length > 20 ? '${email.substring(0, 17)}...' : email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
