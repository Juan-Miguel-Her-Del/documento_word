// Guardado del archivo con el diálogo del sistema (tarea T039; research.md, R6).
//
// Usa el diálogo «Guardar como» de Android (Storage Access Framework) a través de
// file_picker. El usuario elige carpeta y nombre. Android no reemplaza un archivo
// existente sin intervención del usuario (Historia 1, escenario 11). No se necesitan
// permisos de almacenamiento.
//
// Resultados posibles: guardado, cancelado (no es éxito ni error) o fallo
// (AppFailure saveFailed). Spec, módulo 4: un fallo nunca se anuncia como éxito.

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/app_failure.dart';

/// Resultado de intentar guardar.
sealed class SaveOutcome {
  const SaveOutcome();
}

/// El archivo quedó guardado donde el usuario eligió.
class SaveCompleted extends SaveOutcome {
  const SaveCompleted();
}

/// El usuario cerró el diálogo sin guardar.
class SaveCancelled extends SaveOutcome {
  const SaveCancelled();
}

/// Lo que el controlador necesita para guardar. Las pruebas usan una versión falsa.
abstract interface class FileSaver {
  Future<SaveOutcome> save({
    required Uint8List bytes,
    required String fileName,
  });
}

class SystemFileSaver implements FileSaver {
  const SystemFileSaver({required this.dialogTitle});

  /// Título del diálogo en el idioma actual (spec 008: se lee al abrirlo, desde
  /// AppStrings.current; research.md de 008, R3).
  final String Function() dialogTitle;

  @override
  Future<SaveOutcome> save({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final savedPath = await FilePicker.saveFile(
        dialogTitle: dialogTitle(),
        fileName: fileName,
        bytes: bytes,
      );
      return savedPath == null ? const SaveCancelled() : const SaveCompleted();
    } on Exception {
      throw const AppFailure(FailureKind.saveFailed);
    }
  }
}
