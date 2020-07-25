import 'dart:math';

import 'package:flutter/material.dart';

class SmoothPageIndicator extends AnimatedWidget {
  /// a PageView controller to listen for page offset updates
  final PageController controller;

  /// Holds effect configuration to be used in the [IndicatorPainter]
  final IndicatorEffect effect;

  /// The number of children in [PageView]
  final int count;

  /// If [textDirection] is [TextDirection.rtl], page offset will be reversed
  final TextDirection textDirection;

  SmoothPageIndicator({
    @required this.controller,
    @required this.count,
    this.textDirection,
    this.effect = const WormEffect(),
    Key key,
  })  : assert(controller != null),
        assert(effect != null),
        assert(count != null),
        super(listenable: controller, key: key);

  @override
  Widget build(BuildContext context) {
    // if textDirection is not provided use the nearest directionality up the widgets tree;
    final isRTL =
        (textDirection ?? Directionality.of(context)) == TextDirection.rtl;
    return CustomPaint(
      // different effects have different sizes
      // so we calculate size based on the provided effect
      size: effect.calculateSize(count),
      // rebuild the painter with the new offset every time it updates
      painter: effect.buildPainter(
        count,
        _currentPage,
        isRTL,
      ),
    );
  }

  double get _currentPage {
    try {
      return controller.page ?? controller.initialPage.toDouble();
    } catch (Exception) {
      return controller.initialPage.toDouble();
    }
  }
}

/// Painters

abstract class IndicatorPainter extends CustomPainter {
  /// The raw offset from the [PageController].page
  ///
  /// This is called raw because it's used to resolve
  /// the final [offset] based on [isRTL] property
  final double _rawOffset;

  /// This holds the directional offset
  final double offset;

  // The count of pages
  final int count;

  // The provided effect is passed to this super class
  // to make some calculations and paint still dots
  final IndicatorEffect _effect;

  // Inactive dot paint or base paint in one-color effects.
  final Paint dotPaint;

  // The Radius of all dots
  final Radius dotRadius;

  IndicatorPainter(
    this._rawOffset,
    this.count,
    this._effect,
    bool _isRTL,
  )   : assert(_isRTL != null),
        dotRadius = Radius.circular(_effect.radius),
        dotPaint = Paint()
          ..color = _effect.dotColor
          ..style = _effect.paintStyle
          ..strokeWidth = _effect.strokeWidth,
        offset = _isRTL ? (count - 1) - _rawOffset : _rawOffset;

  // The distance between dot lefts
  double get distance => _effect.dotWidth + _effect.spacing;

  @override
  void paint(Canvas canvas, Size size) {
    // Paint still dots if the sub class calls super
    for (int i = 0; i < count; i++) {
      final xPos = (i * distance);
      final yPos = size.height / 2;
      final bounds = Rect.fromLTRB(xPos, yPos - _effect.dotHeight / 2,
          xPos + _effect.dotWidth, yPos + _effect.dotHeight / 2);
      RRect rect = RRect.fromRectAndRadius(bounds, dotRadius);
      canvas.drawRRect(rect, dotPaint);
    }
  }

  @override
  bool shouldRepaint(IndicatorPainter oldDelegate) {
    // only repaint if the raw offset changes
    return oldDelegate._rawOffset != _rawOffset;
  }
}

class WormPainter extends IndicatorPainter {
  final WormEffect effect;

  WormPainter({
    @required this.effect,
    @required int count,
    @required double offset,
    @required bool isRTL,
  }) : super(offset, count, effect, isRTL);

  @override
  void paint(Canvas canvas, Size size) {
    // paint still dots
    super.paint(canvas, size);
    final activeDotPaint = Paint()..color = effect.activeDotColor;
    final dotOffset = offset - offset.toInt();
    final worm = _calcBounds(offset.floor(), dotOffset * 2);
    canvas.drawRRect(worm, activeDotPaint);
  }

  RRect _calcBounds(num i, double dotOffset) {
    final xPos = (i * distance);
    final yPos = (effect.dotHeight) / 2;
    double left = xPos;
    double right = xPos +
        effect.dotWidth +
        (dotOffset * (effect.dotWidth + effect.spacing));
    if (dotOffset > 1) {
      right = xPos + effect.dotWidth + (1 * (effect.dotWidth + effect.spacing));
      left = xPos + ((effect.spacing + effect.dotWidth) * (dotOffset - 1));
    }
    return RRect.fromLTRBR(
      left,
      yPos - effect.dotHeight / 2,
      right,
      yPos + effect.dotHeight / 2,
      dotRadius,
    );
  }
}

class SwapPainter extends IndicatorPainter {
  final SwapEffect effect;

  SwapPainter({
    @required double offset,
    @required this.effect,
    @required int count,
    @required bool isRTL,
  }) : super(offset, count, effect, isRTL);

  @override
  void paint(Canvas canvas, Size size) {
    final int current = offset.floor();
    final dotOffset = offset - offset.floor();
    final activePaint = Paint()..color = effect.activeDotColor;
    for (int i = count - 1; i >= 0; i--) {
      double posOffset = i.toDouble();
      Paint paint = dotPaint;

      if (i == current) {
        paint = activePaint;
        posOffset = offset;
      } else if (i - 1 == current) {
        posOffset = i - dotOffset;
      }

      final xPos =
          effect.spacing / 2 + (posOffset * (effect.dotWidth + effect.spacing));
      final yPos = (effect.dotHeight) / 2;
      final rRect = RRect.fromLTRBR(xPos, yPos - effect.dotHeight / 2,
          xPos + effect.dotWidth, yPos + effect.dotHeight / 2, dotRadius);

      canvas.drawRRect(rRect, paint);
    }
  }
}

class SlidePainter extends IndicatorPainter {
  final SlideEffect effect;

  SlidePainter({
    @required this.effect,
    @required int count,
    @required double offset,
    @required bool isRTL,
  }) : super(offset, count, effect, isRTL);

  @override
  void paint(Canvas canvas, Size size) {
    // paint still dots
    super.paint(canvas, size);

    final activePaint = Paint()..color = effect.activeDotColor;
    final xPos = effect.strokeWidth / 2 + (offset * distance);
    final yPos = size.height / 2;
    final rRect = RRect.fromLTRBR(
      xPos,
      yPos - effect.dotHeight / 2,
      xPos + effect.dotWidth,
      yPos + effect.dotHeight / 2,
      dotRadius,
    );

    canvas.drawRRect(rRect, activePaint);
  }
}

class ScrollingDotsWithFixedCenterPainter extends IndicatorPainter {
  final ScrollingDotsEffect effect;

  ScrollingDotsWithFixedCenterPainter({
    @required this.effect,
    @required int count,
    @required double offset,
    @required bool isRTL,
  }) : super(offset, count, effect, isRTL);

  @override
  void paint(Canvas canvas, Size size) {
    final int current = offset.floor();
    final dotOffset = offset - current;
    final dotPaint = Paint()
      ..strokeWidth = effect.strokeWidth
      ..style = effect.paintStyle;

    for (int index = 0; index < count; index++) {
      Color color = effect.dotColor;
      if (index == current) {
        color = Color.lerp(effect.activeDotColor, effect.dotColor, dotOffset);
      } else if (index - 1 == current) {
        color =
            Color.lerp(effect.activeDotColor, effect.dotColor, 1 - dotOffset);
      }

      double scale = 1.0;
      final smallDotScale = 0.66;
      final revDotOffset = 1 - dotOffset;
      final centerAnchor = (effect.maxVisibleDots - 1) / 2;

      if (count > effect.maxVisibleDots) {
        if (index >= current - centerAnchor &&
            index <= current + (centerAnchor + 1)) {
          if (index == (current + centerAnchor)) {
            scale = smallDotScale + ((1 - smallDotScale) * dotOffset);
          } else if (index == current - (centerAnchor - 1)) {
            scale = 1 - (1 - smallDotScale) * dotOffset;
          } else if (index == current - centerAnchor) {
            scale = (smallDotScale * revDotOffset);
          } else if (index == current + (centerAnchor + 1)) {
            scale = (smallDotScale * dotOffset);
          }
        } else {
          continue;
        }
      }

      final rRect = _calcBounds(
        size.height,
        size.width / 2 - (offset * (effect.dotWidth + effect.spacing)),
        index,
        scale,
      );

      canvas.drawRRect(rRect, dotPaint..color = color);
    }

    final rRect =
        _calcBounds(size.height, size.width / 2, 0, effect.activeDotScale);
    canvas.drawRRect(
        rRect,
        Paint()
          ..color = effect.activeDotColor
          ..strokeWidth = effect.activeStrokeWidth
          ..style = PaintingStyle.stroke);
  }

  RRect _calcBounds(double canvasHeight, double startingPoint, num i,
      [double scale = 1.0]) {
    final scaledWidth = effect.dotWidth * scale;
    final scaledHeight = effect.dotHeight * scale;

    final xPos = startingPoint + (effect.dotWidth + effect.spacing) * i;
    final yPos = canvasHeight / 2;
    return RRect.fromLTRBR(
      xPos - scaledWidth / 2,
      yPos - scaledHeight / 2,
      xPos + scaledWidth / 2,
      yPos + scaledHeight / 2,
      dotRadius * scale,
    );
  }
}

class ScrollingDotsPainter extends IndicatorPainter {
  final ScrollingDotsEffect effect;

  ScrollingDotsPainter({
    @required this.effect,
    @required int count,
    @required double offset,
    @required bool isRTL,
  }) : super(offset, count, effect, isRTL);

  @override
  void paint(Canvas canvas, Size size) {
    final current = super.offset.floor();
    final switchPoint = (effect.maxVisibleDots / 2).floor();
    final firstVisibleDot =
        (current < switchPoint || count - 1 < effect.maxVisibleDots)
            ? 0
            : min(current - switchPoint, count - effect.maxVisibleDots);
    final lastVisibleDot =
        min(firstVisibleDot + effect.maxVisibleDots, count - 1);
    final inPreScrollRange = current < switchPoint;
    final inAfterScrollRange = current >= (count - 1) - switchPoint;
    final willStartScrolling = (current + 1) == switchPoint + 1;
    final willStopScrolling = current + 1 == (count - 1) - switchPoint;

    final dotOffset = offset - offset.toInt();
    final dotPaint = Paint()
      ..strokeWidth = effect.strokeWidth
      ..style = effect.paintStyle;

    final drawingAnchor = (inPreScrollRange || inAfterScrollRange)
        ? -(firstVisibleDot * distance)
        : -((offset - switchPoint) * distance);

    final smallDotScale = 0.66;
    final activeScale = effect.activeDotScale - 1.0;
    for (int index = firstVisibleDot; index <= lastVisibleDot; index++) {
      Color color = effect.dotColor;

      double scale = 1.0;

      if (index == current) {
        color = Color.lerp(effect.activeDotColor, effect.dotColor, dotOffset);
        scale = effect.activeDotScale - (activeScale * dotOffset);
      } else if (index - 1 == current) {
        color = Color.lerp(effect.dotColor, effect.activeDotColor, dotOffset);
        scale = 1.0 + (activeScale * dotOffset);
      } else if (count - 1 < effect.maxVisibleDots) {
        scale = 1.0;
      } else if (index == firstVisibleDot) {
        if (willStartScrolling) {
          scale = (1.0 * (1.0 - dotOffset));
        } else if (inAfterScrollRange) {
          scale = smallDotScale;
        } else if (!inPreScrollRange) {
          scale = smallDotScale * (1.0 - dotOffset);
        }
      } else if (index == firstVisibleDot + 1 &&
          !(inPreScrollRange || inAfterScrollRange)) {
        scale = 1.0 - (dotOffset * (1.0 - smallDotScale));
      } else if (index == lastVisibleDot - 1.0) {
        if (inPreScrollRange) {
          scale = smallDotScale;
        } else if (!inAfterScrollRange) {
          scale = smallDotScale + ((1.0 - smallDotScale) * dotOffset);
        }
      } else if (index == lastVisibleDot) {
        if (inPreScrollRange) {
          scale = 0.0;
        } else if (willStopScrolling) {
          scale = dotOffset;
        } else if (!inAfterScrollRange) {
          scale = smallDotScale * dotOffset;
        }
      }

      final scaledWidth = (effect.dotWidth * scale);
      final scaledHeight = effect.dotHeight * scale;
      final yPos = size.height / 2;
      final xPos = effect.dotWidth / 2 + drawingAnchor + (index * distance);

      final rRect = RRect.fromLTRBR(
        xPos - scaledWidth / 2 + effect.spacing / 2,
        yPos - scaledHeight / 2,
        xPos + scaledWidth / 2 + effect.spacing / 2,
        yPos + scaledHeight / 2,
        dotRadius * scale,
      );

      canvas.drawRRect(rRect, dotPaint..color = color);
    }
  }
}

class ScalePainter extends IndicatorPainter {
  final ScaleEffect effect;

  ScalePainter({
    @required double offset,
    @required this.effect,
    @required int count,
    @required bool isRTL,
  }) : super(offset, count, effect, isRTL);

  @override
  void paint(Canvas canvas, Size size) {
    final int current = offset.floor();
    final activePaint = Paint()
      ..color = effect.dotColor
      ..style = effect.activePaintStyle
      ..strokeWidth = effect.activeStrokeWidth;

    final dotOffset = offset - current;
    final activeScale = effect.scale - 1.0;

    for (int index = 0; index < count; index++) {
      canvas.drawRRect(_calcBounds(size.height, index), dotPaint);
      Color color = effect.dotColor;
      double scale = 0.0;
      if (index == current) {
        scale = effect.scale - (activeScale * dotOffset);
        color = Color.lerp(effect.activeDotColor, effect.dotColor, dotOffset);
      } else if (index - 1 == current) {
        scale = 1.0 + (activeScale * dotOffset);
        color =
            Color.lerp(effect.activeDotColor, effect.dotColor, 1.0 - dotOffset);
      }
      canvas.drawRRect(
          _calcBounds(size.height, index, scale), activePaint..color = color);
    }
  }

  RRect _calcBounds(double canvasHeight, num offset, [double scale = 1.0]) {
    final width = effect.dotWidth * scale;
    final height = effect.dotHeight * scale;
    final startingPoint = effect.dotWidth * effect.scale;
    final xPos = startingPoint / 2 -
        width / 2 +
        (offset * (effect.dotWidth + effect.spacing));
    final yPos = canvasHeight / 2;
    return RRect.fromLTRBR(xPos, yPos - height / 2, xPos + width,
        yPos + height / 2, dotRadius * scale);
  }
}

class JumpingDotPainter extends IndicatorPainter {
  final JumpingDotEffect effect;

  JumpingDotPainter({
    @required this.effect,
    @required int count,
    @required double offset,
    @required bool isRTL,
  }) : super(offset, count, effect, isRTL);

  @override
  void paint(Canvas canvas, Size size) {
    // paint still dots
    super.paint(canvas, size);
    final activeDotPainter = Paint()..color = effect.activeDotColor;
    final dotOffset = offset - offset.toInt();
    double scale = 1.0;
    if (dotOffset < .5) {
      scale = dotOffset * effect.elevation;
    } else {
      scale = (1 - dotOffset) * effect.elevation;
    }

    final xPos = (offset * (effect.dotWidth + effect.spacing));
    final yPos = (effect.dotHeight) / 2;
    final height = effect.dotHeight + scale;
    final width = effect.dotWidth + scale;
    final scaleRatio = width / effect.dotWidth;
    final rRect = RRect.fromLTRBR(xPos, yPos - height / 2, xPos + width,
        yPos + height / 2, dotRadius * scaleRatio);

    canvas.drawRRect(rRect, activeDotPainter);
  }
}

class ExpandingDotsPainter extends IndicatorPainter {
  final ExpandingDotsEffect effect;

  ExpandingDotsPainter({
    @required double offset,
    @required this.effect,
    @required int count,
    @required bool isRTL,
  }) : super(offset, count, effect, isRTL);

  @override
  void paint(Canvas canvas, Size size) {
    final int current = offset.floor();
    double drawingOffset = -effect.spacing;
    final dotOffset = offset - current;

    for (int i = 0; i < count; i++) {
      Color color = effect.dotColor;
      final activeDotWidth = effect.dotWidth * effect.expansionFactor;
      final expansion =
          (dotOffset / 2 * ((activeDotWidth - effect.dotWidth) / .5));
      final xPos = drawingOffset + effect.spacing;
      double width = effect.dotWidth;
      if (i == current) {
        color = Color.lerp(effect.activeDotColor, effect.dotColor, dotOffset);
        width = activeDotWidth - expansion;
      } else if (i - 1 == current) {
        width = effect.dotWidth + expansion;
        color =
            Color.lerp(effect.activeDotColor, effect.dotColor, 1.0 - dotOffset);
      }
      final yPos = size.height / 2;
      final rRect = RRect.fromLTRBR(
        xPos,
        yPos - effect.dotHeight / 2,
        xPos + width,
        yPos + effect.dotHeight / 2,
        dotRadius,
      );
      drawingOffset = rRect.right;
      canvas.drawRRect(rRect, dotPaint..color = color);
    }
  }
}

class TransitionPainter extends IndicatorPainter {
  final ColorTransitionEffect effect;

  TransitionPainter({
    @required this.effect,
    @required int count,
    @required double offset,
    @required bool isRTL,
  }) : super(offset, count, effect, isRTL);

  @override
  void paint(Canvas canvas, Size size) {
    final int current = offset.floor();
    final dotPaint = Paint()
      ..strokeWidth = effect.strokeWidth
      ..style = effect.paintStyle;

    final dotOffset = offset - current;
    for (int i = 0; i < count; i++) {
      Color color = effect.dotColor;
      if (i == current) {
        color = Color.lerp(effect.activeDotColor, effect.dotColor, dotOffset);
      } else if (i - 1 == current) {
        color =
            Color.lerp(effect.activeDotColor, effect.dotColor, 1.0 - dotOffset);
      }

      final xPos = (i * distance);
      final yPos = size.height / 2;
      final rRect = RRect.fromLTRBR(
        xPos,
        yPos - effect.dotHeight / 2,
        xPos + effect.dotWidth,
        yPos + effect.dotHeight / 2,
        dotRadius,
      );

      canvas.drawRRect(rRect, dotPaint..color = color);
    }
  }
}

/// Effects

abstract class IndicatorEffect {
  // Singe dot width
  final double dotWidth;

  // Singe dot height
  final double dotHeight;

  // The horizontal space between dots
  final double spacing;

  // Single dot radius
  final double radius;

  // Inactive dots color or all dots in some effects
  final Color dotColor;

  // The active dot color
  final Color activeDotColor;

  // Inactive dots paint style (fill|stroke) defaults to fill.
  final PaintingStyle paintStyle;

  /// This is ignored if [paintStyle] is PaintStyle.fill
  final double strokeWidth;

  const IndicatorEffect({
    @required this.strokeWidth,
    @required this.dotWidth,
    @required this.dotHeight,
    @required this.spacing,
    @required this.radius,
    @required this.dotColor,
    @required this.paintStyle,
    @required this.activeDotColor,
  })  : assert(radius != null),
        assert(dotColor != null || paintStyle != null || strokeWidth != null),
        assert(activeDotColor != null),
        assert(dotWidth != null),
        assert(dotHeight != null),
        assert(spacing != null),
        assert(dotWidth >= 0 &&
            dotHeight >= 0 &&
            spacing >= 0 &&
            strokeWidth >= 0);

  // Builds a new painter every time the page offset changes
  IndicatorPainter buildPainter(int count, double offset, bool isRTL);

  /// Calculates the size of canvas based on dots count, size and spacing
  /// Other effects can override this function to calculate their own size
  Size calculateSize(int count) {
    return Size(dotWidth * count + (spacing * (count - 1)), dotHeight);
  }
}

class WormEffect extends IndicatorEffect {
  const WormEffect({
    double offset,
    double dotWidth = 16.0,
    double dotHeight = 16.0,
    double spacing = 8.0,
    double radius = 16,
    Color dotColor = Colors.grey,
    Color activeDotColor = Colors.indigo,
    double strokeWidth = 1.0,
    PaintingStyle paintStyle = PaintingStyle.fill,
  })  : assert(activeDotColor != null),
        super(
          dotWidth: dotWidth,
          dotHeight: dotHeight,
          spacing: spacing,
          radius: radius,
          strokeWidth: strokeWidth,
          paintStyle: paintStyle,
          dotColor: dotColor,
          activeDotColor: activeDotColor,
        );

  @override
  IndicatorPainter buildPainter(int count, double offset, bool isRTL) {
    return WormPainter(
        count: count, offset: offset, effect: this, isRTL: isRTL);
  }
}

class SwapEffect extends IndicatorEffect {
  const SwapEffect({
    Color activeDotColor = Colors.indigo,
    double offset,
    double dotWidth = 16.0,
    double dotHeight = 16.0,
    double spacing = 8.0,
    double radius = 16,
    Color dotColor = Colors.grey,
    double strokeWidth = 1.0,
    PaintingStyle paintStyle = PaintingStyle.fill,
  })  : assert(activeDotColor != null),
        super(
          dotWidth: dotWidth,
          dotHeight: dotHeight,
          spacing: spacing,
          radius: radius,
          strokeWidth: strokeWidth,
          paintStyle: paintStyle,
          dotColor: dotColor,
          activeDotColor: activeDotColor,
        );

  @override
  IndicatorPainter buildPainter(int count, double offset, bool isRTL) {
    return SwapPainter(
        count: count, offset: offset, effect: this, isRTL: isRTL);
  }
}

class SlideEffect extends IndicatorEffect {
  const SlideEffect({
    Color activeDotColor = Colors.indigo,
    double offset,
    double dotWidth = 16.0,
    double dotHeight = 16.0,
    double spacing = 8.0,
    double radius = 16,
    Color dotColor = Colors.grey,
    double strokeWidth = 1.0,
    PaintingStyle paintStyle = PaintingStyle.fill,
  })  : assert(activeDotColor != null),
        super(
            dotWidth: dotWidth,
            dotHeight: dotHeight,
            spacing: spacing,
            radius: radius,
            strokeWidth: strokeWidth,
            paintStyle: paintStyle,
            dotColor: dotColor,
            activeDotColor: activeDotColor);

  @override
  IndicatorPainter buildPainter(int count, double offset, bool isRTL) {
    return SlidePainter(
        count: count, offset: offset, effect: this, isRTL: isRTL);
  }
}

class ScrollingDotsEffect extends IndicatorEffect {
  /// The active dot strokeWidth
  /// this's ignored if [fixedCenter] is false
  final double activeStrokeWidth;

  /// [activeDotScale] is multiplied by [dotWidth] to resolve
  /// active dot scaling
  final double activeDotScale;

  /// The max number of dots to display at a time
  /// if count is <= [maxVisibleDots] [maxVisibleDots] = count
  /// must be an odd number that's >= 5
  final int maxVisibleDots;

  // if True the old center dot style will be used
  final bool fixedCenter;

  const ScrollingDotsEffect({
    this.activeStrokeWidth = 1.5,
    this.activeDotScale = 1.3,
    this.maxVisibleDots = 5,
    this.fixedCenter = false,
    double offset,
    double dotWidth = 16.0,
    double dotHeight = 16.0,
    double spacing = 8.0,
    double radius = 16,
    Color dotColor = Colors.grey,
    Color activeDotColor = Colors.indigo,
    double strokeWidth = 1.0,
    PaintingStyle paintStyle = PaintingStyle.fill,
  })  : assert(activeStrokeWidth != null),
        assert(fixedCenter != null),
        assert(activeDotScale != null),
        assert(activeDotScale >= 0.0),
        assert(maxVisibleDots >= 5 && maxVisibleDots % 2 != 0),
        super(
          dotWidth: dotWidth,
          dotHeight: dotHeight,
          spacing: spacing,
          radius: radius,
          strokeWidth: strokeWidth,
          paintStyle: paintStyle,
          dotColor: dotColor,
          activeDotColor: activeDotColor,
        );

  @override
  Size calculateSize(int count) {
    // Add the scaled dot width to our size calculation
    double width = (dotWidth + spacing) * (min(count, maxVisibleDots));
    if (fixedCenter && count <= maxVisibleDots) {
      width = ((count * 2) - 1) * (dotWidth + spacing);
    }
    return Size(width, dotHeight * activeDotScale);
  }

  @override
  IndicatorPainter buildPainter(int count, double offset, bool isRTL) {
    if (fixedCenter) {
      return ScrollingDotsWithFixedCenterPainter(
          count: count, offset: offset, effect: this, isRTL: isRTL);
    } else {
      return ScrollingDotsPainter(
          count: count, offset: offset, effect: this, isRTL: isRTL);
    }
  }
}

class ScaleEffect extends IndicatorEffect {
  // Inactive dots paint style (fill|stroke) defaults to fill.
  final PaintingStyle activePaintStyle;

  /// This is ignored if [activePaintStyle] is PaintStyle.fill
  final double activeStrokeWidth;

  /// [scale] is multiplied by [dotWidth] to resolve
  /// active dot scaling
  final double scale;

  const ScaleEffect({
    Color activeDotColor = Colors.indigo,
    this.activePaintStyle = PaintingStyle.fill,
    this.scale = 0.3,
    this.activeStrokeWidth = 1.0,
    double offset,
    double dotWidth = 16.0,
    double dotHeight = 16.0,
    double spacing = 16.0,
    double radius = 16,
    Color dotColor = Colors.grey,
    double strokeWidth = 1.0,
    PaintingStyle paintStyle = PaintingStyle.fill,
  })  : assert(activePaintStyle != null),
        assert(scale != null),
        assert(activeStrokeWidth != null),
        super(
          dotWidth: dotWidth,
          dotHeight: dotHeight,
          spacing: spacing,
          radius: radius,
          strokeWidth: strokeWidth,
          paintStyle: paintStyle,
          dotColor: dotColor,
          activeDotColor: activeDotColor,
        );

  @override
  Size calculateSize(int count) {
    // Add the scaled dot width to our size calculation
    final scaledWidth = (dotWidth + (dotWidth * scale)) - dotWidth;
    return Size((dotWidth * count) + (spacing * (count - 1)) + scaledWidth,
        (dotHeight + scaledWidth));
  }

  @override
  IndicatorPainter buildPainter(int count, double offset, bool isRTL) {
    return ScalePainter(
        count: count, offset: offset, effect: this, isRTL: isRTL);
  }
}

class JumpingDotEffect extends IndicatorEffect {
  // Defines how high the dot will jump
  final double elevation;

  const JumpingDotEffect({
    Color activeDotColor = Colors.indigo,
    this.elevation = 15.0,
    double offset,
    double dotWidth = 16.0,
    double dotHeight = 16.0,
    double spacing = 8.0,
    double radius = 16,
    Color dotColor = Colors.grey,
    double strokeWidth = 1.0,
    PaintingStyle paintStyle = PaintingStyle.fill,
  })  : assert(activeDotColor != null),
        assert(elevation != null),
        super(
            dotWidth: dotWidth,
            dotHeight: dotHeight,
            spacing: spacing,
            radius: radius,
            strokeWidth: strokeWidth,
            paintStyle: paintStyle,
            dotColor: dotColor,
            activeDotColor: activeDotColor);

  @override
  IndicatorPainter buildPainter(int count, double offset, bool isRTL) {
    return JumpingDotPainter(
        count: count, offset: offset, effect: this, isRTL: isRTL);
  }
}

class ExpandingDotsEffect extends IndicatorEffect {
  /// [expansionFactor] is multiplied by [dotWidth] to resolve
  /// the width of the expanded dot.
  final double expansionFactor;

  const ExpandingDotsEffect({
    this.expansionFactor = 3,
    double offset,
    double dotWidth = 16.0,
    double dotHeight = 16.0,
    double spacing = 8.0,
    double radius = 16.0,
    Color activeDotColor = Colors.indigo,
    Color dotColor = Colors.grey,
    double strokeWidth = 1.0,
    PaintingStyle paintStyle = PaintingStyle.fill,
  })  : assert(expansionFactor != null),
        assert(expansionFactor > 1),
        super(
            dotWidth: dotWidth,
            dotHeight: dotHeight,
            spacing: spacing,
            radius: radius,
            strokeWidth: strokeWidth,
            paintStyle: paintStyle,
            dotColor: dotColor,
            activeDotColor: activeDotColor);

  @override
  Size calculateSize(int count) {
    // Add the expanded dot width to our size calculation
    return Size(
        ((dotWidth + spacing) * (count - 1)) + (expansionFactor * dotWidth),
        dotHeight);
  }

  @override
  IndicatorPainter buildPainter(int count, double offset, bool isRTL) {
    return ExpandingDotsPainter(
        count: count, offset: offset, effect: this, isRTL: isRTL);
  }
}

class ColorTransitionEffect extends IndicatorEffect {
  // The active dot strokeWidth
  final double activeStrokeWidth;

  const ColorTransitionEffect({
    this.activeStrokeWidth = 1.5,
    double offset,
    double dotWidth = 16.0,
    double dotHeight = 16.0,
    double spacing = 8.0,
    double radius = 16,
    Color dotColor = Colors.grey,
    Color activeDotColor = Colors.indigo,
    double strokeWidth = 1.0,
    PaintingStyle paintStyle = PaintingStyle.fill,
  })  : assert(activeDotColor != null),
        assert(activeStrokeWidth != null),
        super(
            dotWidth: dotWidth,
            dotHeight: dotHeight,
            spacing: spacing,
            radius: radius,
            strokeWidth: strokeWidth,
            paintStyle: paintStyle,
            dotColor: dotColor,
            activeDotColor: activeDotColor);

  @override
  IndicatorPainter buildPainter(int count, double offset, bool isRTL) {
    return TransitionPainter(
        count: count, offset: offset, effect: this, isRTL: isRTL);
  }
}
