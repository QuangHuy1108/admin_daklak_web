import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_config.freezed.dart';
part 'notification_config.g.dart';

@freezed
class NotificationConfig with _$NotificationConfig {
  const factory NotificationConfig({
    @Default(true) bool enableEmailNotifications,
    @Default(true) bool enableSMSNotifications,
    @Default(true) bool enablePushNotifications,
    @Default({}) Map<String, String> emailTemplates,
    @Default({}) Map<String, String> smsTemplates,
    @Default(NotificationTriggerRules()) NotificationTriggerRules triggerRules,
  }) = _NotificationConfig;

  factory NotificationConfig.fromJson(Map<String, dynamic> json) =>
      _$NotificationConfigFromJson(json);
}

@freezed
class NotificationTriggerRules with _$NotificationTriggerRules {
  const factory NotificationTriggerRules({
    @Default(true) bool notifyOnNewOrder,
    @Default(true) bool notifyOnLowStock,
    @Default(true) bool notifyOnSystemError,
    @Default(true) bool notifyOnNewExpertAppointment,
  }) = _NotificationTriggerRules;

  factory NotificationTriggerRules.fromJson(Map<String, dynamic> json) =>
      _$NotificationTriggerRulesFromJson(json);
}
