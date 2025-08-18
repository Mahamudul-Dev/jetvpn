import 'package:equatable/equatable.dart';

class VpnConfig extends Equatable {
  final int? id;
  final String? name;
  final String? icon;
  final String? serverAddress;
  final String? username;
  final String? password;
  final String? protocol;
  final String? config;
  final bool? isPro;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VpnConfig({
    this.id,
    this.name,
    this.icon,
    this.serverAddress,
    this.username,
    this.password,
    this.protocol,
    this.config,
    this.isPro,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, icon, serverAddress, username, password, protocol, config, isPro, createdAt, updatedAt];

}
