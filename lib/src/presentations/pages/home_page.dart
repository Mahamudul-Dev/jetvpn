import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:jetvpn/src/core/routes/app_router.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/assets_helper.dart';
import '../bloc/vpn_bloc.dart';
import '../widgets/widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VpnBloc>().add(VpnInitializeEvent());
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppConfig.appName), actions: [
        IconButton(onPressed: () => context.pushNamed(AppRoutes.subscriptions.name), icon: Icon(FontAwesomeIcons.crown),)
      ],),

      drawer: AppDrawerWidget(),

      body: Stack(
        children: [
          // background map
          SvgPicture.asset(AssetsHelper.map, fit: BoxFit.cover),

          BlocConsumer<VpnBloc, VpnState>(
            listener: (context, state){
              if(state is VpnError){
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onErrorContainer),),
                    backgroundColor: Theme.of(context).colorScheme.errorContainer,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              if(state is VpnInitial || state is VpnLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if(state is VpnError) {
                return ErrorViewWidget(
                  message: state.message,
                );
              } else if(state is VpnLoaded) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 20.r,
                    children: [
                      // your ip address
                      RealtimeIpWidget(),

                      // vpn connect/disconnect button
                      VpnConnectionToggleButtonWidget(vpnStatus: state.vpnStatus, selectedConfig: state.selectedConfig, onConnect: (){

                        if(state.selectedConfig?.serverAddress == null){
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Server not live', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onErrorContainer),),
                              backgroundColor: Theme.of(context).colorScheme.errorContainer,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          context.read<VpnBloc>().add(VpnConnectEvent(state.selectedConfig!.serverAddress!));
                        }
                      }, onDisconnect: (){
                        context.read<VpnBloc>().add(VpnDisconnectEvent());
                      }),


                      // connection state and duration
                      ConnectionStateWidget(
                        connectionStatus: state.vpnStatus,
                      ),

                      // speed
                      RealtimeSpeedWidget( vpnStatus: state.vpnStatus),

                      // connected country
                      CountryTile(
                        name: state.selectedConfig?.name ?? 'Unknown',
                        flag: state.selectedConfig?.icon,
                        onTap: () {
                          context.pushNamed(AppRoutes.servers.name);
                        },
                      ),
                    ],
                  ),
                );
              } else {
                return SizedBox.shrink();
              }

            },
          ),
        ],
      ),
    );
  }
}
