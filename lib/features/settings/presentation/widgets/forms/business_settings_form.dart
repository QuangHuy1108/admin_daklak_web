import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/settings_provider.dart';
import '../common/config_card.dart';
import '../common/settings_form_header.dart';
import '../common/settings_form_footer.dart';
import 'package:admin_daklak_web/core/widgets/common/custom_admin_input.dart';
import 'package:admin_daklak_web/core/constants/app_colors.dart';

class BusinessSettingsForm extends StatelessWidget {
  const BusinessSettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final config = provider.business;

    if (config == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Premium Header
        SettingsFormHeader(
          title: 'Cấu hình Kinh doanh',
          subtitle: 'Quản lý các quy tắc vận hành cho đơn hàng, kho bãi, chuyên gia và khuyến mãi.',
          isLoading: provider.isLoading,
          onSave: () => provider.saveBusiness(),
        ),

        // 2. Orders & Payments
        ConfigCard(
          title: 'Đơn hàng & Thanh toán',
          icon: Icons.shopping_bag_rounded,
          iconCircleColor: const Color(0xFFE8F5E9),
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomAdminInput(
                    label: 'VAT (%)',
                    initialValue: config.orders.vatPercent.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final parsed = double.tryParse(val) ?? 0.0;
                      provider.updateBusiness(config.copyWith(
                        orders: config.orders.copyWith(vatPercent: parsed),
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: CustomAdminInput(
                    label: 'Phí vận chuyển cố định (VND)',
                    initialValue: config.orders.shippingFeeFlat.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final parsed = double.tryParse(val) ?? 0.0;
                      provider.updateBusiness(config.copyWith(
                        orders: config.orders.copyWith(shippingFeeFlat: parsed),
                      ));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            CustomAdminInput(
              label: 'Thời gian tự động hủy đơn (Giờ)',
              initialValue: config.orders.autoCancelHours.toString(),
              helperText: 'Hủy đơn nếu khách không thanh toán sau khoảng thời gian này.',
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final parsed = int.tryParse(val) ?? 0;
                provider.updateBusiness(config.copyWith(
                  orders: config.orders.copyWith(autoCancelHours: parsed),
                ));
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 3. Products & Warehouse
        ConfigCard(
          title: 'Sản phẩm & Warehouse',
          icon: Icons.inventory_2_rounded,
          iconCircleColor: const Color(0xFFE3F2FD),
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomAdminInput(
                    label: 'Ngưỡng báo động tồn kho thấp',
                    initialValue: config.products.lowStockThreshold.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final parsed = int.tryParse(val) ?? 0;
                      provider.updateBusiness(config.copyWith(
                        products: config.products.copyWith(lowStockThreshold: parsed),
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: CustomAdminInput(
                    label: 'Tần suất cập nhật giá (Giờ)',
                    initialValue: config.products.priceUpdateFrequencyHours.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final parsed = int.tryParse(val) ?? 0;
                      provider.updateBusiness(config.copyWith(
                        products: config.products.copyWith(priceUpdateFrequencyHours: parsed),
                      ));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 4. Expert Management
        ConfigCard(
          title: 'Quản lý Chuyên gia',
          icon: Icons.psychology_rounded,
          iconCircleColor: const Color(0xFFF3E5F5),
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomAdminInput(
                    label: 'Giờ bắt đầu làm việc',
                    initialValue: config.experts.defaultStartWorkTime,
                    prefixIcon: Icons.access_time_filled_rounded,
                    onChanged: (val) => provider.updateBusiness(config.copyWith(
                      experts: config.experts.copyWith(defaultStartWorkTime: val),
                    )),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: CustomAdminInput(
                    label: 'Giờ kết thúc làm việc',
                    initialValue: config.experts.defaultEndWorkTime,
                    prefixIcon: Icons.timer_off_rounded,
                    onChanged: (val) => provider.updateBusiness(config.copyWith(
                      experts: config.experts.copyWith(defaultEndWorkTime: val),
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            CustomAdminInput(
              label: 'Thời lượng một phiên (Phút)',
              initialValue: config.experts.sessionDurationMinutes.toString(),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final parsed = int.tryParse(val) ?? 0;
                provider.updateBusiness(config.copyWith(
                  experts: config.experts.copyWith(sessionDurationMinutes: parsed),
                ));
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 5. Promotions & Vouchers
        ConfigCard(
          title: 'Khuyến mãi & Vouchers',
          icon: Icons.confirmation_number_rounded,
          iconCircleColor: const Color(0xFFFFF3E0),
          children: [
            CustomAdminInput(
              label: 'Số lượng voucher tối đa / user',
              initialValue: config.promotions.maxVouchersPerUser.toString(),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final parsed = int.tryParse(val) ?? 0;
                provider.updateBusiness(config.copyWith(
                  promotions: config.promotions.copyWith(maxVouchersPerUser: parsed),
                ));
              },
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text('Cho phép cộng dồn Voucher', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Người dùng có thể áp dụng nhiều voucher cho một đơn hàng.', style: TextStyle(fontSize: 12)),
                value: config.promotions.allowStackingVouchers,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  provider.updateBusiness(config.copyWith(
                    promotions: config.promotions.copyWith(allowStackingVouchers: val),
                  ));
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),

        // 6. Premium Footer
        SettingsFormFooter(
          isLoading: provider.isLoading,
          onSave: () => provider.saveBusiness(),
          onDiscard: () => provider.discardChanges(),
        ),
      ],
    );
  }
}
