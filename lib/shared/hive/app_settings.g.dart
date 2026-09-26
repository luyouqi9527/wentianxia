// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

/// 2.0.0 起：本文件在手写基础上加了**向后兼容读取**。
///
/// 1.x 写进 Hive 的记录只有字段 0~3；2.0.0 新增了 `glassMode(4)` 与
/// `lastSeenVersion(5)`。如果直接 `fields[4] as GlassMode`，老用户升级后
/// 读到旧记录会抛 `type 'Null' is not a subtype of type 'GlassMode'`，
/// 导致启动崩溃。因此这里对缺失字段一律给默认值。
class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 1;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      apiKey: fields[0] as String? ?? '',
      selectedCategories: (fields[1] as List?)?.cast<String>(),
      isFirstLaunch: fields[2] as bool? ?? false,
      onboardingCompletedAt: fields[3] as DateTime?,
      // 老版本记录里没有这两个字段 → 回落到 2.0.0 默认值
      glassMode: GlassMode.fromName((fields[4] as String?)),
      lastSeenVersion: fields[5] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.apiKey)
      ..writeByte(1)
      ..write(obj.selectedCategories)
      ..writeByte(2)
      ..write(obj.isFirstLaunch)
      ..writeByte(3)
      ..write(obj.onboardingCompletedAt)
      ..writeByte(4)
      // 枚举按名字存字符串：跨版本最稳（增删枚举值也不会破坏老数据）
      ..write(obj.glassMode.name)
      ..writeByte(5)
      ..write(obj.lastSeenVersion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
