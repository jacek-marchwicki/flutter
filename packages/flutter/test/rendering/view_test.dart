// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

class MockWindowPadding implements WindowPadding {
  const MockWindowPadding({ this.left = 0.0, this.top = 0.0, this.right = 0.0, this.bottom = 0.0 });
  @override final double left;
  @override final double top;
  @override final double right;
  @override final double bottom;
}

void main() {
  group('RenderView', () {
    test('accounts for device pixel ratio in paintBounds', () {
      layout(RenderAspectRatio(aspectRatio: 1.0));
      pumpFrame();
      final Size logicalSize = renderer.renderView.configuration.size;
      final double devicePixelRatio = renderer.renderView.configuration.devicePixelRatio;
      final Size physicalSize = logicalSize * devicePixelRatio;
      expect(renderer.renderView.paintBounds, Offset.zero & physicalSize);
    });
  });
  
  group('asdf', () {

    RenderView _buildRenderView({RenderBox child, ui.Window window}) {
      final double devicePixelRatio = window.devicePixelRatio;
      final configuration = ViewConfiguration(
        size: window.physicalSize / devicePixelRatio,
        devicePixelRatio: devicePixelRatio,
      );
      return RenderView(child: child, configuration: configuration, window: window);
    }

    test('asdf', () {
      final window = TestWindow(window: ui.window)
        ..viewPaddingTestValue = MockWindowPadding(top: 25*2.0, bottom: 54*2.0)
        ..paddingTestValue = MockWindowPadding(top: 25*2.0, bottom: 54*2.0)
        ..devicePixelRatioTestValue = 2.0
        ..physicalSizeTestValue = Size(
          480.0*2,
          960.0*2);

      final double devicePixelRatio = window.devicePixelRatio;
      final configuration = ViewConfiguration(
        size: window.physicalSize / devicePixelRatio,
        devicePixelRatio: devicePixelRatio,
      );
      final box = RenderAnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent,));

      final child = RenderPositionedBox(
        alignment: Alignment.topCenter,
        child: RenderConstrainedBox(
          additionalConstraints: BoxConstraints.tightFor(height: 100.0),
          child: box,
        ),
      );
      final x = _buildRenderView(child: child, window: window);
      renderer.renderView = x;
      pumpFrame();

      expect(SystemChrome.latestStyle.systemNavigationBarColor, Colors.transparent);
    });
  });
}
