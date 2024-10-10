import 'dart:typed_data';

import 'compression/compression.dart';

/// The compression of a [NbtFile].
/// Implementation of detecting the compression can be found
/// at [NbtFileReader#detectCompression].
enum NbtCompression {
  /// The file does not have any compression.
  none,

  /// Gzip compressed files usually start with 1F.
  gzip,

  /// Zlib compressed files usually start with 78.
  zlib,

  /// There was an error reading the compression.
  unknown,
}

extension CompressionFunctionExtension on NbtCompression {
  /// Compress the given [data].
  List<int> compressData(Uint8List data) => compress(this, data);

  /// Decompress the given [data].
  Uint8List decompressData(Uint8List data) => decompress(this, data);
}
