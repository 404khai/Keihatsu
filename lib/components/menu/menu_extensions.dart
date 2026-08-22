import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';

extension NumX on num {
  Widget get gap => Gap(toDouble());

  SliverGap get gapSliver => SliverGap(toDouble());
}
