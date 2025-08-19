import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';

class RealtimeSpeedWidget extends StatelessWidget {
  final V2RayStatus vpnStatus;
  const RealtimeSpeedWidget({super.key, required this.vpnStatus});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // upload
        Row(
          children: [
            Icon(
              Icons.upload,
              color: Colors.amber,
            ),
            Text(
              "${vpnStatus.uploadSpeed / 1000} Mbit/s",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),


        // upload
        Row(
          children: [
            Icon(
              Icons.download,
              color: Colors.green,
            ),
            Text(
              "${vpnStatus.downloadSpeed / 1000} Mbit/s",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        )
      ],
    );
  }
}
