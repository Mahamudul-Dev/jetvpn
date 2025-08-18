import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';

import '../../domain/entities/vpn_status.dart';

class RippleWidget extends StatefulWidget {
  final Widget? child;
  final V2RayStatus status;
  final bool isRippleEnabled;
  const RippleWidget({super.key, this.child, this.isRippleEnabled = true, required this.status});

  @override
  State<RippleWidget> createState() => _RippleWidgetState();
}

class _RippleWidgetState extends State<RippleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<double> _listOfRadius = [100.r, 130.r, 160.r, 190.r, 220.r];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: !widget.isRippleEnabled ? widget.child :
      AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              ..._listOfRadius.map((radius) {
                final double effectiveRadius =
                    radius * (1 + _animation.value) / 2;
                return FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        _listOfRadius.indexOf(radius) / _listOfRadius.length,
                        1.0,
                        curve: Curves.easeIn,
                      ),
                    ),
                  ),
                  child: Container(
                    width: effectiveRadius,
                    height: effectiveRadius,
                    decoration: BoxDecoration(
                      color: (widget.status.state == 'DISCONNECTING' || widget.status.state == 'CONNECTING' ? Colors.amber : Colors.green).withAlpha(50),
                      // Theme.of(context)
                      //     .colorScheme
                      //     .primaryContainer
                      //     .withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
              if (widget.child != null) widget.child!,
            ],
          );
        },
      ),
    );
  }
}
