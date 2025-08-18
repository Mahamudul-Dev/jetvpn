import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jetvpn/src/core/config/app_config.dart';

import '../../core/utils/assets_helper.dart';

class CountryTile extends StatelessWidget {
  final String name;
  final String? flag;
  final String? city;
  final VoidCallback? onTap;
  const CountryTile({super.key, required this.name, this.flag, this.city, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).colorScheme.secondaryContainer.withAlpha(200),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),

      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 10.r),
      leading: Container(
        clipBehavior: Clip.antiAlias,
        height: 50.r,
        width: 50.r,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,

        ),
        child: flag != null ? SvgPicture.network(AppConfig.storagePath + flag!, fit: BoxFit.cover, ) : SvgPicture.asset(AssetsHelper.imagePlaceholder),
      ),
      title: Text(
        name,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w100,
          fontFamily: GoogleFonts.montserrat().fontFamily,
        ),
      ),
      subtitle: city == null ? null : Text(city!, style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,),
      ),

      trailing: IconButton(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(
            Theme.of(context).colorScheme.surfaceContainer.withAlpha(200),
          ),
        ),
        onPressed: onTap, icon: Icon(Icons.arrow_forward_ios_rounded, color: Theme.of(context).colorScheme.onSurface,),),
    );
  }
}
