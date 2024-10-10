import 'dart:typed_data';
import 'package:archive/archive.dart';

import '../nbt_compression.dart';

List<int> compress(NbtCompression compression, Uint8List data) {
  switch (compression) {
    case NbtCompression.gzip:
      return GZipEncoder().encode(data)!;
    case NbtCompression.zlib:
      return const ZLibEncoder().encode(data);
    case NbtCompression.none:
    case NbtCompression.unknown:
    default:
      return data;
  }
}

Uint8List decompress(NbtCompression compression, Uint8List data) {
  switch (compression) {
    case NbtCompression.gzip:
      return Uint8List.fromList(GZipDecoder().decodeBytes(data));
    case NbtCompression.zlib:
      return Uint8List.fromList(const ZLibDecoder().decodeBytes(data));
    case NbtCompression.unknown:
      throw Exception('Invalid NBT File.');
    case NbtCompression.none:
    default:
      // Don't need to do anything for no compression.
      return data;
  }
}
