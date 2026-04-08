import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_daklak_web/core/constants/app_colors.dart';

// --- KPI Card with Drill-down Effect ---

class ReportKPICard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final String trend;
  final bool isPositive;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const ReportKPICard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.trend,
    required this.isPositive,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<ReportKPICard> createState() => _ReportKPICardState();
}

class _ReportKPICardState extends State<ReportKPICard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? widget.iconColor.withOpacity(0.3) : AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.04),
                blurRadius: _isHovered ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 24),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isPositive ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.trend,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.isPositive ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                widget.value,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- AI System Health Card (Fallback %) ---

class AIHealthCard extends StatefulWidget {
  final double fallbackPercent;
  final int totalQuestions;

  const AIHealthCard({
    super.key,
    required this.fallbackPercent,
    required this.totalQuestions,
  });

  @override
  State<AIHealthCard> createState() => _AIHealthCardState();
}

class _AIHealthCardState extends State<AIHealthCard> {
  bool _isHovered = false;

  Color get _healthColor {
    if (widget.fallbackPercent < 5) return Colors.green;
    if (widget.fallbackPercent <= 15) return Colors.orange;
    return Colors.red;
  }

  String get _statusText {
    if (widget.fallbackPercent < 5) return "Operating Optimally";
    if (widget.fallbackPercent <= 15) return "Needs Training";
    return "System Overwhelmed";
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () => context.go('/ai-logs'),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? _healthColor : _healthColor.withOpacity(0.3), 
              width: _isHovered ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _healthColor.withOpacity(_isHovered ? 0.15 : 0.05),
                blurRadius: _isHovered ? 25 : 15,
                offset: Offset(0, _isHovered ? 8 : 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "AI System Health",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeading,
                    ),
                  ),
                  Icon(Icons.psychology, color: _healthColor),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${widget.fallbackPercent.toStringAsFixed(1)}%",
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _healthColor,
                          ),
                        ),
                        Text(
                          "Fallback Rate",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _statusText,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _healthColor,
                          ),
                        ),
                        Text(
                          "Status",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.fallbackPercent / 100,
                  backgroundColor: _healthColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(_healthColor),
                  minHeight: 8,
                ),
              ),
              if (_isHovered) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "View Detailed Logs",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _healthColor,
                      ),
                    ),
                    const Icon(Icons.arrow_right_alt, size: 16),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- Ranking List Widget ---

class RankingList extends StatefulWidget {
  final String title;
  final List<dynamic> items;
  final bool isCurrency;

  const RankingList({
    super.key,
    required this.title,
    required this.items,
    this.isCurrency = false,
  });

  @override
  State<RankingList> createState() => _RankingListState();
}

class _RankingListState extends State<RankingList> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () => context.go('/ai-logs'),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? AppColors.primary : Colors.transparent,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.04),
                blurRadius: _isHovered ? 20 : 10,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeading,
                    ),
                  ),
                  if (_isHovered)
                    const Icon(Icons.launch, size: 16, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 16),
              ...widget.items.asMap().entries.map((entry) {
                int idx = entry.key;
                var data = entry.value;
                String name = data['name'] ?? data['query'] ?? '--';
                dynamic val = data['quantitySold'] ?? data['hits'] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: idx == 0 ? Colors.amber[100] : AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "${idx + 1}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: idx == 0 ? Colors.amber[900] : AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textHeading,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        widget.isCurrency ? "$val đ" : "$val",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (widget.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "Chưa có đủ dữ liệu thống kê",
                      style: GoogleFonts.inter(color: AppColors.textMuted),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
