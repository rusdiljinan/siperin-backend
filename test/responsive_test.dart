import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/utils/responsive.dart';

void main() {
  Future<double> readScale(WidgetTester tester, double width) async {
    double scale = 0;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: Builder(
          builder: (context) {
            scale = Responsive.textScaleFactor(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return scale;
  }

  testWidgets('uses compact typography on mobile', (tester) async {
    expect(await readScale(tester, 360), 0.88);
    expect(Responsive.isMobile(tester.element(find.byType(SizedBox))), isTrue);
  });

  testWidgets('uses intermediate typography on tablet', (tester) async {
    expect(await readScale(tester, 768), 0.98);
    expect(Responsive.isTablet(tester.element(find.byType(SizedBox))), isTrue);
  });

  testWidgets('keeps desktop typography at the base scale', (tester) async {
    expect(await readScale(tester, 1280), 1);
    expect(Responsive.isDesktop(tester.element(find.byType(SizedBox))), isTrue);
  });
}
