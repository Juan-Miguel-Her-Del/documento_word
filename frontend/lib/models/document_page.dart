// Una página del documento en la vista previa (tarea T302; spec 004; data-model.md de
// 004).
//
// Guarda la imagen de la página (copia de trabajo de 001), la original si se recortó
// (003) y el resultado de su reconocimiento, para no volver a enviarla [SC-402].

import 'picked_image.dart';
import 'recognition_result.dart';

/// Una página del documento: su imagen (y la original, si se recortó) y el texto
/// que se reconoció en ella.
///
/// Es inmutable: [withResult] y [withoutResult] devuelven una copia cambiada.
class DocumentPage {
  const DocumentPage(this.image, {this.original, this.result});

  /// Imagen que se ve y que se envía.
  final PickedImage image;

  /// La imagen tal como se eligió, si después se recortó o giró.
  final PickedImage? original;

  /// Resultado del reconocimiento; null si todavía no se reconoció o si la página cambió.
  final RecognitionResult? result;

  /// La misma página con su resultado (se conserva si otra página falla).
  DocumentPage withResult(RecognitionResult value) =>
      DocumentPage(image, original: original, result: value);

  /// La misma página sin resultado: cambió su imagen o su lugar [VP-H3-E3].
  DocumentPage withoutResult() => DocumentPage(image, original: original);
}
