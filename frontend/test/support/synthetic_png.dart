// Generador de imágenes PNG sintéticas para las pruebas (constitución §6: las muestras
// DEBEN ser sintéticas). Crea en memoria un PNG real en escala de grises, todo blanco,
// del tamaño pedido; no se usa ninguna foto ni documento real.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// PNG válido de [width] × [height] píxeles, todo blanco.
Uint8List syntheticPng(int width, int height) {
  // Cada fila: un byte de «filtro» (0) seguido de los píxeles (255 = blanco).
  final rows = BytesBuilder();
  for (var y = 0; y < height; y++) {
    rows
      ..addByte(0)
      ..add(List.filled(width, 255));
  }
  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // 8 bits por píxel
    ..setUint8(9, 0); // escala de grises
  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // firma PNG
    ..._chunk('IHDR', header.buffer.asUint8List()),
    ..._chunk('IDAT', zlib.encode(rows.takeBytes())),
    ..._chunk('IEND', const []),
  ]);
}

/// Bloque PNG: longitud + tipo + datos + CRC32 de (tipo + datos).
List<int> _chunk(String type, List<int> data) {
  final typeBytes = ascii.encode(type);
  final length = ByteData(4)..setUint32(0, data.length);
  final crc = ByteData(4)..setUint32(0, _crc32([...typeBytes, ...data]));
  return [
    ...length.buffer.asUint8List(),
    ...typeBytes,
    ...data,
    ...crc.buffer.asUint8List(),
  ];
}

/// Suma de verificación CRC32 que exige el formato PNG.
int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}
