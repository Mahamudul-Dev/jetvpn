import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routes/app_router.dart';

class AppDrawerWidget extends StatelessWidget {
  const AppDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      
      children: [
        DrawerHeader(child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device: 19731987491', style: Theme.of(context).textTheme.titleSmall,),
            Text('Free Plan', style: Theme.of(context).textTheme.labelMedium,),

          ],
        ),),

        ListTile(
          titleTextStyle: Theme.of(context).textTheme.labelMedium,
          title: Text('Account'), onTap: (){}, leading: Icon(FontAwesomeIcons.user),
        ),
        ListTile(
          titleTextStyle: Theme.of(context).textTheme.labelMedium,
          title: Text('Rate App'), onTap: (){}, leading: Icon(FontAwesomeIcons.star),
        ),
        ListTile(
          titleTextStyle: Theme.of(context).textTheme.labelMedium,
          title: Text('Share'), onTap: (){}, leading: Icon(FontAwesomeIcons.star),
        ),
        ListTile(
          titleTextStyle: Theme.of(context).textTheme.labelMedium,title: Text('Terms & Conditions'), onTap: (){
          context.pushNamed(AppRoutes.webview.name, extra: '${AppConfig.baseUrl}/terms-and-conditions');
        }, leading: Icon(Icons.gavel),),
        ListTile(
          titleTextStyle: Theme.of(context).textTheme.labelMedium,title: Text('Privacy Policy'), onTap: (){
          context.pushNamed(AppRoutes.webview.name, extra: '${AppConfig.baseUrl}/privacy-policy');
        }, leading: Icon(Icons.privacy_tip),),

      ]);
  }
}
