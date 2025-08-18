import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


import '../../core/config/locator.dart';
import '../bloc/ip_bloc.dart';

class RealtimeIpWidget extends StatelessWidget {
  const RealtimeIpWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<IpBloc>(),
      child: BlocBuilder<IpBloc, IpState>(
        builder: (context, state) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10.r,
            children: [
              Icon(
                _getIconForState(state),
                color: _getColorForState(context, state),
              ),
              
              Text(
                _getTextForState(state),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w200,
                  color: _getColorForState(context, state),
                ),
              ),
              
              if (state is IpLoading)
                Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: SizedBox(
                    width: 12.w,
                    height: 12.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  IconData _getIconForState(IpState state) {
    if (state is IpLoaded) {
      return state.isVpnConnected 
          ? Icons.shield_rounded 
          : Icons.security_rounded;
    } else if (state is IpError) {
      return Icons.error_outline_rounded;
    }
    return Icons.security_rounded;
  }

  Color _getColorForState(BuildContext context, IpState state) {
    if (state is IpLoaded) {
      return state.isVpnConnected 
          ? Colors.green.withAlpha(200)
          : Theme.of(context).colorScheme.onSurface.withAlpha(200);
    } else if (state is IpError) {
      return Colors.red.withAlpha(200);
    }
    return Theme.of(context).colorScheme.onSurface.withAlpha(200);
  }

  String _getTextForState(IpState state) {
    if (state is IpLoaded) {
      final location = state.ipInfo.country != null 
          ? ' (${state.ipInfo.country})' 
          : '';
      final vpnStatus = state.isVpnConnected ? ' 🔒' : '';
      return 'Your IP: ${state.ipInfo.ip}$location$vpnStatus';
    } else if (state is IpError) {
      return 'IP: Failed to load';
    } else if (state is IpLoading) {
      return 'Getting your IP...';
    }
    return 'Your IP: Loading...';
  }
}
