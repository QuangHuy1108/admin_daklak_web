// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GlobalConfigImpl _$$GlobalConfigImplFromJson(Map<String, dynamic> json) =>
    _$GlobalConfigImpl(
      appName: json['appName'] as String? ?? 'DakLak Admin',
      logoUrl: json['logoUrl'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      contactEmail: json['contactEmail'] as String? ?? '',
      address: json['address'] as String? ?? '',
      termsUrl: json['termsUrl'] as String? ?? '',
      privacyUrl: json['privacyUrl'] as String? ?? '',
      refundUrl: json['refundUrl'] as String? ?? '',
    );

Map<String, dynamic> _$$GlobalConfigImplToJson(_$GlobalConfigImpl instance) =>
    <String, dynamic>{
      'appName': instance.appName,
      'logoUrl': instance.logoUrl,
      'contactPhone': instance.contactPhone,
      'contactEmail': instance.contactEmail,
      'address': instance.address,
      'termsUrl': instance.termsUrl,
      'privacyUrl': instance.privacyUrl,
      'refundUrl': instance.refundUrl,
    };
