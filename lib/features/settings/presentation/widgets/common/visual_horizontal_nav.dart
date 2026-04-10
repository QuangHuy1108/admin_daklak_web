import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../data/models/settings_group.dart';
import 'visual_nav_card.dart';
import 'package:admin_daklak_web/core/constants/app_colors.dart';

class VisualHorizontalNav extends StatefulWidget {
  final List<SettingsGroup> groups;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const VisualHorizontalNav({
    super.key,
    required this.groups,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<VisualHorizontalNav> createState() => _VisualHorizontalNavState();
}

class _VisualHorizontalNavState extends State<VisualHorizontalNav> {
  late final ScrollController _scrollController;
  final double _cardWidth = 200.0; // Compact chip width
  
  static const int _infiniteCount = 10000;
  Timer? _snapTimer;
  bool _isManualScrolling = false;
  Timer? _manualScrollResetTimer;

  @override
  void initState() {
    super.initState();
    final virtualStartIndex = (_infiniteCount ~/ 2) - ((_infiniteCount ~/ 2) % widget.groups.length) + widget.selectedIndex;
    _scrollController = ScrollController(
      initialScrollOffset: virtualStartIndex * _cardWidth,
    );
  }

  void _scrollToIndex(int targetRealIndex, {bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final int currentVirtual = (_scrollController.offset / _cardWidth).round();
    final int currentReal = currentVirtual % widget.groups.length;
    
    int diff = targetRealIndex - currentReal;
    if (diff > widget.groups.length / 2) diff -= widget.groups.length;
    if (diff < -widget.groups.length / 2) diff += widget.groups.length;
    
    final int targetVirtual = currentVirtual + diff;
    final double targetOffset = targetVirtual * _cardWidth;
    
    if (animate) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }
  }

  @override
  void didUpdateWidget(VisualHorizontalNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex && !_isManualScrolling) {
      _scrollToIndex(widget.selectedIndex);
    }
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _scrollController.hasClients) {
      _isManualScrolling = true;
      _manualScrollResetTimer?.cancel();

      final double newOffset = _scrollController.offset + event.scrollDelta.dy;
      _scrollController.jumpTo(newOffset.clamp(0.0, _scrollController.position.maxScrollExtent));
      
      _debounceSnapping();
      
      _manualScrollResetTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _isManualScrolling = false);
      });
    }
  }

  void _debounceSnapping() {
    _snapTimer?.cancel();
    _snapTimer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      final int nearestVirtual = (_scrollController.offset / _cardWidth).round();
      final int realIndex = nearestVirtual % widget.groups.length;
      
      if (realIndex != widget.selectedIndex) {
        widget.onSelected(realIndex);
      }
      
      _scrollToIndex(realIndex);
    });
  }

  @override
  void dispose() {
    _snapTimer?.cancel();
    _manualScrollResetTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72, // Reduced height for compact chips
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Listener(
        onPointerSignal: _handlePointerSignal,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemExtent: _cardWidth, 
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _infiniteCount,
          itemBuilder: (context, index) {
            final realIndex = index % widget.groups.length;
            final group = widget.groups[realIndex];
            final isSelected = widget.selectedIndex == realIndex;

            return VisualNavCard(
              title: group.title,
              icon: group.icon,
              isSelected: isSelected,
              onTap: () {
                widget.onSelected(realIndex);
                _scrollToIndex(realIndex);
              },
            );
          },
        ),
      ),
    );
  }
}
