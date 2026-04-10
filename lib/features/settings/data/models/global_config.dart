import 'package:freezed_annotation/freezed_annotation.dart';

part 'global_config.freezed.dart';
part 'global_config.g.dart';

@freezed
class GlobalConfig with _$GlobalConfig {
  const factory GlobalConfig({
    @Default('DakLak Admin') String appName,
    @Default('') String logoUrl,
    @Default('') String contactPhone,
    @Default('') String contactEmail,
    @Default('') String address,
    @Default('') String termsUrl,
    @Default('') String privacyUrl,
    @Default('') String refundUrl,
  }) = _GlobalConfig;

  factory GlobalConfig.fromJson(Map<String, dynamic> json) =>
      _$GlobalConfigFromJson(json);
}
