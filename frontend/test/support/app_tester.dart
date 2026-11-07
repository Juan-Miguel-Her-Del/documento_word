// Ayudas para las pruebas de pantallas (tareas T026, T128 y T135).
//
// - Pantalla del tamaño de un teléfono (411 × 914 puntos).
// - [SC-207] Preferencia de accesibilidad «quitar animaciones» activada: es la misma que
//   respeta la app, así las animaciones decorativas en bucle no impiden que la prueba
//   espere a que todo termine (pumpAndSettle).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/app.dart';

import 'fakes.dart';

/// Abre la app completa con las dependencias falsas del arnés.
Future<void> pumpHandTextApp(WidgetTester tester, TestHarness h) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);

  // Como main.dart: los ajustes se leen antes de mostrar la app (spec 006: ahí está
  // si los consejos ya se vieron).
  await h.settings.load();
  await tester.pumpWidget(
    HandTextApp(
      auth: h.auth,
      settings: h.settings,
      lock: h.lock,
      createDocumentController: h.buildController,
    ),
  );
  await tester.pumpAndSettle();
}

/// Carga Poppins, la letra real de la app. Sin esto, las pruebas usan una letra de
/// prueba más ancha y las medidas del texto no son las del teléfono (spec 006).
Future<void> loadPoppins(WidgetTester tester) => tester.runAsync(() async {
  final loader = FontLoader('Poppins');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
});

/// Desplaza la lista hasta que [text] se construya y se vea (las listas solo
/// construyen lo visible; spec 009 agregó una opción arriba en el inicio).
Future<void> scrollToText(WidgetTester tester, String text) async {
  if (find.text(text).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(find.text(text).first);
  await tester.pumpAndSettle();
}

/// Desplaza la pantalla hasta un texto visible, lo toca y espera.
Future<void> tapText(WidgetTester tester, String text) async {
  if (find.text(text).evaluate().isEmpty) {
    // Las listas solo construyen lo visible: con la letra grande (spec 006), el
    // texto puede estar más abajo y todavía no existir.
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  final finder = find.text(text).first;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Escribe en el campo de texto cuya etiqueta es [label].
Future<void> enterField(WidgetTester tester, String label, String value) async {
  final field = find.widgetWithText(TextField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}
