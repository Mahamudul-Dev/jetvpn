import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ionicons/ionicons.dart';
import 'package:jetvpn/src/domain/entities/vpn_config.dart';

import '../../../main.dart';
import 'ripple_widget.dart';


class VpnConnectionToggleButtonWidget extends StatelessWidget {
  final V2RayStatus vpnStatus;
  final VpnConfig? selectedConfig;
  final void Function() onConnect;
  final VoidCallback onDisconnect;
  const VpnConnectionToggleButtonWidget({super.key, required this.vpnStatus, this.selectedConfig, required this.onConnect, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200.r,
      width: 200.r,
      child: Center(
        child: RippleWidget(
          status: vpnStatus,
          isRippleEnabled: vpnStatus.state == 'CONNECTED' || vpnStatus.state == 'CONNECTING' || vpnStatus.state == 'DISCONNECTING',
          child: SizedBox(
            width: 120.r,
            height: 120.r,
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll<Color>(
                  Theme.of(
                    context,
                  ).colorScheme.surfaceContainer,
                ),
                shape:
                WidgetStatePropertyAll<
                    RoundedRectangleBorder
                >(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      100.0,
                    ),
                    side: BorderSide(
                      color: vpnStatus.state == 'CONNECTING' || vpnStatus.state == 'DISCONNECTING' ? Colors.amber : vpnStatus.state == 'CONNECTED' ? Colors.green : Colors.red,
                      width: 3.0,
                    ),
                  ),
                ),
              ),
              onPressed: _handleConnectToggle,
              child: Icon(
                vpnStatus.state == 'CONNECTING' || vpnStatus.state == 'DISCONNECTING' ? FontAwesomeIcons.lock : Ionicons.lock_open,
                color:  vpnStatus.state == 'CONNECTING' || vpnStatus.state == 'DISCONNECTING' ? Colors.amber : vpnStatus.state == 'CONNECTED' ? Colors.green : Colors.red,
                size: 30.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }


  _handleConnectToggle() {
    logger.d('tapped vpn connection toggle button, vpnStatus: $vpnStatus, selectedConfigFileName: ${selectedConfig?.country}',);
    if(vpnStatus.state == 'CONNECTING' || vpnStatus.state == 'DISCONNECTING'){
      return;
    }

    if(vpnStatus.state == 'CONNECTED'){
      onDisconnect();
    } else {
      if(selectedConfig != null){
        onConnect();
      }
    }
  }
}
