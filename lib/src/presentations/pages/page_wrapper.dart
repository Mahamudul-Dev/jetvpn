import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/locator.dart';
import '../bloc/vpn_bloc.dart';
import '../widgets/widgets.dart';

class PageWrapper extends StatelessWidget {
  final Widget child;

  const PageWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VpnBloc>.value(
      value: getIt<VpnBloc>(),
      child: Scaffold(
          body: BlocListener<VpnBloc, VpnState>(
            listener: (context, state) {
              if (state is VpnError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: SafeArea(child: child),
          ),
          bottomNavigationBar: AppNavigationBar()
      ),
    );
  }
}
