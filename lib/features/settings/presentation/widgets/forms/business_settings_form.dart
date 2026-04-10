import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/settings_provider.dart';
import '../common/config_card.dart';

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
        Text(
          'Cấu hình Kinh doanh',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Quản lý các quy tắc vận hành cho đơn hàng, kho bãi, chuyên gia và khuyến mãi.'),
        const SizedBox(height: 32),

        ConfigCard(
          title: 'Đơn hàng & Thanh toán',
          icon: Icons.shopping_basket,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: config.orders.vatPercent.toString(),
                    decoration: const InputDecoration(
                      labelText: 'VAT (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final parsed = double.tryParse(val) ?? 0.0;
                      provider.updateBusiness(config.copyWith(
                        orders: config.orders.copyWith(vatPercent: parsed),
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextFormField(
                    initialValue: config.orders.shippingFeeFlat.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Phí vận chuyển cố định (VND)',
                      border: OutlineInputBorder(),
                    ),
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
            const SizedBox(height: 20),
            TextFormField(
              initialValue: config.orders.autoCancelHours.toString(),
              decoration: const InputDecoration(
                labelText: 'Thời gian tự động hủy đơn chưa thanh toán (Giờ)',
                border: OutlineInputBorder(),
                helperText: 'Hệ thống sẽ tự động hủy đơn nếu khách hàng không thanh toán sau khoảng thời gian này.',
              ),
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

        const SizedBox(height: 24),

        ConfigCard(
          title: 'Sản phẩm & Warehouse',
          icon: Icons.inventory_2,
          children: [
            TextFormField(
              initialValue: config.products.lowStockThreshold.toString(),
              decoration: const InputDecoration(
                labelText: 'Ngưỡng báo động tồn kho thấp (Số lượng)',
                border: OutlineInputBorder(),
                helperText: 'Hệ thống sẽ gửi thông báo khi số lượng sản phẩm thấp hơn mức này.',
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final parsed = int.tryParse(val) ?? 0;
                provider.updateBusiness(config.copyWith(
                  products: config.products.copyWith(lowStockThreshold: parsed),
                ));
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: config.products.priceUpdateFrequencyHours.toString(),
              decoration: const InputDecoration(
                labelText: 'Tần suất cập nhật giá thị trường (Giờ)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final parsed = int.tryParse(val) ?? 0;
                provider.updateBusiness(config.copyWith(
                  products: config.products.copyWith(priceUpdateFrequencyHours: parsed),
                ));
              },
            ),
          ],
        ),

        const SizedBox(height: 24),

        ConfigCard(
          title: 'Quản lý Chuyên gia',
          icon: Icons.person_search,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: config.experts.defaultStartWorkTime,
                    decoration: const InputDecoration(
                      labelText: 'Giờ bắt đầu làm việc',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    onChanged: (val) => provider.updateBusiness(config.copyWith(
                      experts: config.experts.copyWith(defaultStartWorkTime: val),
                    )),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextFormField(
                    initialValue: config.experts.defaultEndWorkTime,
                    decoration: const InputDecoration(
                      labelText: 'Giờ kết thúc làm việc',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer_off),
                    ),
                    onChanged: (val) => provider.updateBusiness(config.copyWith(
                      experts: config.experts.copyWith(defaultEndWorkTime: val),
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: config.experts.sessionDurationMinutes.toString(),
              decoration: const InputDecoration(
                labelText: 'Thời lượng mặc định một phiên tư vấn (Phút)',
                border: OutlineInputBorder(),
              ),
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

        const SizedBox(height: 24),

        ConfigCard(
          title: 'Khuyến mãi & Vouchers',
          icon: Icons.confirmation_number,
          children: [
            TextFormField(
              initialValue: config.promotions.maxVouchersPerUser.toString(),
              decoration: const InputDecoration(
                labelText: 'Số lượng voucher tối đa mỗi người dùng',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final parsed = int.tryParse(val) ?? 0;
                provider.updateBusiness(config.copyWith(
                  promotions: config.promotions.copyWith(maxVouchersPerUser: parsed),
                ));
              },
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Cho phép cộng dồn Voucher'),
              subtitle: const Text('Người dùng có thể áp dụng nhiều voucher cho một đơn hàng.'),
              value: config.promotions.allowStackingVouchers,
              onChanged: (val) {
                provider.updateBusiness(config.copyWith(
                  promotions: config.promotions.copyWith(allowStackingVouchers: val),
                ));
              },
            ),
          ],
        ),
      ],
    );
  }
}
