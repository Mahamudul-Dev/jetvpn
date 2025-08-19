import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(
              FontAwesomeIcons.crown,
              size: 100.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pro Subscription',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        Text(
                          'Limited Offer!',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),

                  // Features
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            const Gap(5),
                            Text(
                              'More Countries',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            const Gap(5),
                            Text(
                              'More Speed',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            const Gap(5),
                            Text(
                              'More Streaming',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Plans
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            ListTile(
                              tileColor: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              title: Text(
                                'Monthly Plan',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              subtitle: Text(
                                '\$1.99/month',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              trailing: Text(
                                'Save 20%',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),

                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(10.r),
                                    bottomLeft: Radius.circular(10.r),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                child: Text(
                                  'Recommended',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Gap(10),

                        ListTile(
                          tileColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          title: Text(
                            'Yearly Plan',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            '\$12.99/month',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          trailing: Text(
                            'Save 20%',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),

                        const Gap(10),

                        ListTile(
                          tileColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          title: Text(
                            'Weekly Plan',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            '\$5.99/month',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          trailing: Text(
                            'Save 20%',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Gap(30.h),

                  // declaration
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Subscription auto renews until cancelled. \nCancel anytime on ${Platform.isIOS ? 'App Store' : 'Google Play Store'}.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Gap(20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
