import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';

import '../../domain/entities/vpn_status.dart';

class ConnectionStateWidget extends StatelessWidget {
  final V2RayStatus connectionStatus;

  const ConnectionStateWidget({super.key, required this.connectionStatus});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          connectionStatus.state,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),

        Text(
          connectionStatus.duration,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
