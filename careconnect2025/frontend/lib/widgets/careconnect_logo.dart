import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CareConnectLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final bool useSVG;

  const CareConnectLogo({
    super.key,
    this.width,
    this.height,
    this.color,
    this.useSVG = false, // Default to PNG to avoid SVG issues
  });

  @override
  Widget build(BuildContext context) {
    if (useSVG) {
      return SvgPicture.asset(
        'assets/images/CareConnectLogo_fixed.svg',
        width: width,
        height: height,
        colorFilter: color != null 
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        // Hide unwanted elements by clipping
        clipBehavior: Clip.antiAlias,
      );
    } else {
      return Image.asset(
        'assets/images/CareConnectLogo_PNG.png',
        width: width,
        height: height,
        color: color,
        fit: BoxFit.contain,
      );
    }
  }
}

class CareConnectLogoIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const CareConnectLogoIcon({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CareConnectLogo(
      width: size,
      height: size,
      color: color,
      useSVG: true,
    );
  }
}
