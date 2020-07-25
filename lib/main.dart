import 'package:flutter/material.dart';
import 'package:indicatorish/dots_page_indicator.dart';
import 'package:indicatorish/scale.dart' as scale;

void main() {
  runApp(HomePage());
}

final double sizeBoxCardHeight = scale.value(300);
final double borderRadius = scale.value(16);
final double horizontalInset = scale.value(10);
final double verticalInset = scale.value(4);
final double cardContainerHeight = scale.value(280);
final double sizedBoxBelowCards = scale.value(16);

/*final double sizedBoxBelowCards = scale.value(280);
final double sizeBoxCardHeight = scale.value(300);
final double sizeBoxCardHeight = scale.value(300);*/

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final controller = PageController(viewportFraction: 0.8);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey.shade300,
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text('dots Indicator with cards'),
        ),
        body: Center(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                /// creates card
                /// Will create a diff widget for it
                SizedBox(
                  height: sizeBoxCardHeight,
                  child: PageView(
                    pageSnapping: true,
                    controller: controller,
                    children: List.generate(
                        6,
                        (_) => Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(borderRadius)),
                              margin: EdgeInsets.symmetric(
                                  horizontal: horizontalInset,
                                  vertical: verticalInset),
                              child: Container(height: cardContainerHeight),
                            )),
                  ),
                ),
                SizedBox(height: sizedBoxBelowCards),
                SmoothPageIndicator(
                  controller: controller,
                  count: 6,
                  effect: JumpingDotEffect(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text("slide Dots "),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text("Scrolling Dots "),
                ),
                SmoothPageIndicator(
                    controller: controller,
                    count: 6,
                    effect: ScrollingDotsEffect(
                      activeStrokeWidth: 2.6,
                      activeDotScale: .4,
                      radius: 8,
                      spacing: 10,
                    )),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text("Scale"),
                ),
                Container(
                  child: SmoothPageIndicator(
                    controller: controller,
                    count: 6,
                    effect: ScaleEffect(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
