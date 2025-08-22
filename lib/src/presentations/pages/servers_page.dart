import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jetvpn/src/core/routes/app_router.dart';
import 'package:jetvpn/src/data/datasources/vpn_datasource.dart';
import 'package:jetvpn/src/presentations/bloc/vpn_bloc.dart';

import '../../core/config/app_config.dart';
import '../../core/config/locator.dart';
import '../../core/utils/assets_helper.dart';

class ServersPage extends StatefulWidget {
  const ServersPage({super.key});

  @override
  State<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Servers'),
      ),
      body: BlocBuilder<VpnBloc, VpnState>(builder: (context, state){
        if(state is VpnLoaded){
          return ListView.builder(
            itemCount: state.availableConfigs.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Badge(
                  backgroundColor: Colors.transparent,
                  label: state.availableConfigs[index].isPro! ? Icon(FontAwesomeIcons.crown, color: Colors.amber): null,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    height: 40.r,
                    width: 40.r,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,

                    ),
                    child: state.availableConfigs[index].icon != null ? CachedNetworkImage(imageUrl: AppConfig.storagePath + state.availableConfigs[index].icon!, fit: BoxFit.cover, ) : SvgPicture.asset(AssetsHelper.imagePlaceholder),
                  ),
                ),
                title: Text('${state.availableConfigs[index].city ?? 'Unknown'}, ${state.availableConfigs[index].country ?? 'Unknown'}'),
                subtitle: Text(state.availableConfigs[index].isPro! ? 'Premium' : 'Free', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,),),
                trailing: state.availableConfigs[index].serverAddress == null ? null : FutureBuilder(future: getIt<VpnDataSource>().getV2RayServerDelay(state.availableConfigs[index].serverAddress!), builder: (context, asyncSnapshot){
                  if(asyncSnapshot.connectionState == ConnectionState.done && asyncSnapshot.hasData){
                    return Text('${asyncSnapshot.data!/100} ms');
                  } else if(asyncSnapshot.connectionState == ConnectionState.waiting){
                    return const CircularProgressIndicator();
                  } else {
                    return const Text('N/A');
                  }
                }),
                titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w100,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                ),

                onTap: (){
                  context.read<VpnBloc>().add(VpnSelectConfigEvent(state.availableConfigs[index]));
                  context.goNamed(AppRoutes.home.name);
                },
              );
            },
          );
        } else if(state is VpnLoading){
          return const Center(child: CircularProgressIndicator(),);
        } else {
          return Center(child: Text('No servers found', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),);
        }
      }),
    );
  }
}
