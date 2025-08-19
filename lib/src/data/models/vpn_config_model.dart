import '../../domain/entities/vpn_config.dart';

class VpnConfigModel extends VpnConfig {
  const VpnConfigModel({
    super.id,
    super.country,
    super.remark,
    super.city,
    super.icon,
    super.serverAddress,
    super.username,
    super.password,
    super.protocol,
    super.config,
    super.isPro,
    super.createdAt,
    super.updatedAt,
  });


  factory VpnConfigModel.fromJson(Map<String, dynamic> json) {
    return VpnConfigModel(
      id: json['id'],
      country: json['name'],
      remark: json['remark'],
      city: json['city'],
      icon: json['icon'],
      serverAddress: json['server_address'],
      username: json['username'],
      password: json['password'],
      protocol: json['protocol'],
      config: json['config'],
      isPro: json['is_pro'],
      createdAt: DateTime.parse(json['created_at']) ,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  factory VpnConfigModel.fromEntity(VpnConfig entity) {
    return VpnConfigModel(
      id: entity.id,
      country: entity.country,
      remark: entity.remark,
      city: entity.city,
      icon: entity.icon,
      serverAddress: entity.serverAddress,
      username: entity.username,
      password: entity.password,
      protocol: entity.protocol,
      config: entity.config,
      isPro: entity.isPro,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'country': country,
      'remark': remark,
      'city': city,
      'icon': icon,
      'server_address': serverAddress,
      'username': username,
      'password': password,
      'protocol': protocol,
      'config': config,
      'isPro': isPro,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
