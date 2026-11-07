// Un documento del historial (tarea T602; spec 007, módulo 1; data-model.md de 007).
//
// Guarda el texto del último guardado correcto, sus formatos y la hora. No guarda la
// imagen ni el archivo Word o PDF (Non-Goal).
// Spec 010 (tarea T905): el nombre dado por la persona (renamed) y la búsqueda sin
// tildes ni mayúsculas (research.md de 010, R3 y R4).

import 'export_format.dart';

/// Un documento de «Mis documentos»: su título, el texto del último guardado, los
/// formatos en que se guardó y cuándo.
///
/// Cada cuenta tiene su propio historial en el teléfono (FileHistoryStore).
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.title,
    required this.text,
    required this.formats,
    required this.savedAt,
    this.renamed = false,
  });

  /// Se asigna en el primer guardado y no cambia (research.md de 007, R3).
  final String id;

  /// Primera línea con texto, hasta 60 caracteres (historyTitleFor).
  final String title;

  /// Texto del último guardado correcto.
  final String text;

  /// Formatos en que se guardó, sin repetir.
  final Set<ExportFormat> formats;

  /// Hora del último guardado correcto.
  final DateTime savedAt;

  /// Spec 010: true si la persona le dio el título en Mis documentos; volver a
  /// guardar lo conserva [OR-H3-E4].
  final bool renamed;

  /// [OR-H3-E3] La misma entrada con el título que eligió la persona.
  HistoryEntry renamedTo(String newTitle) => HistoryEntry(
    id: id,
    title: newTitle,
    text: text,
    formats: formats,
    savedAt: savedAt,
    renamed: true,
  );

  /// [OR-H3-E1] [SC-1003] ¿El título o el texto contienen [query]? Sin importar
  /// mayúsculas ni tildes; una búsqueda vacía coincide con todo.
  bool matchesQuery(String query) {
    final wanted = foldForSearch(query.trim());
    if (wanted.isEmpty) return true;
    return foldForSearch(title).contains(wanted) ||
        foldForSearch(text).contains(wanted);
  }

  /// Cantidad de palabras (se calcula; no se guarda).
  int get wordCount {
    final trimmed = text.trim();
    return trimmed.isEmpty ? 0 : trimmed.split(RegExp(r'\s+')).length;
  }
}

/// Spec 010: minúsculas y sin tildes, para comparar al buscar: «CÉLULA» → «celula».
String foldForSearch(String value) {
  const accented = 'áàäâãåéèëêíìïîóòöôõúùüûñç';
  const plain = 'aaaaaaeeeeiiiiooooouuuunc';
  final buffer = StringBuffer();
  for (final character in value.toLowerCase().split('')) {
    final index = accented.indexOf(character);
    buffer.write(index < 0 ? character : plain[index]);
  }
  return buffer.toString();
}

/// [HD-H1-E1] Título de un documento: la primera línea con texto, sin espacios a los
/// lados, hasta [maxLength] caracteres y con «…» si se corta (R5). Se cuenta por
/// caracteres Unicode, así una tilde o un emoji nunca quedan partidos.
String historyTitleFor(String text, {int maxLength = 60}) {
  final line = text
      .split('\n')
      .map((line) => line.trim())
      .firstWhere((line) => line.isNotEmpty, orElse: () => '');
  final characters = line.runes.toList();
  if (characters.length <= maxLength) return line;
  return '${String.fromCharCodes(characters.take(maxLength - 1)).trimRight()}…';
}
