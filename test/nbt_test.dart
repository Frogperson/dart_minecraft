import 'dart:io';
import 'dart:typed_data';

import 'package:dart_minecraft/dart_nbt.dart';
import 'package:dart_minecraft/src/exceptions/nbt_exception.dart';
import 'package:test/test.dart';

class NbtFile {
  File file;

  NbtCompound? root;

  NbtCompression? nbtCompression;

  NbtFile.fromPath(String path) : file = File(path) {
    if (!file.existsSync()) file.createSync();
  }

  Future<void> readFile({Endian endian = Endian.big}) async {
    var reader = NbtReader.fromFile(file.path);
    reader.setEndianness = endian;
    reader.read();
    root = reader.root;
    nbtCompression = reader.nbtCompression;
  }

  Future<void> writeFile(
      {File? file,
      NbtCompression nbtCompression = NbtCompression.none,
      Endian endian = Endian.big}) async {
    if (file != null) this.file = file;
    if (root == null) return;
    var writer = NbtWriter(nbtCompression: nbtCompression);
    writer.setEndianness = endian;
    await writer.writeFile(this.file.path, root!);
  }
}

void main() {
  group('Read files and check for values', () {
    test('Read servers.dat', () async {
      NbtFile nbtFile;
      try {
        nbtFile = NbtFile.fromPath('./test/servers.dat');
        // As we have not yet called [readFile], the root node should be null.
        expect(nbtFile.root, isNull);
        await nbtFile.readFile();
      } on NbtException {
        return;
      }
      final root = nbtFile.root;
      expect(root, isNotNull);

      /// The root tag should always be a Compound for Java Edition NBT.
      expect(root!.nbtTagType, equals(NbtTagType.TAG_COMPOUND));

      /// As we're checking the servers.dat file, the root compound only
      /// has a single child, a TAG_List with the name 'servers'.
      expect(root.getChildrenByName('servers').length, equals(1));
    });

    test('Read bigtest.nbt', () async {
      // bigtest.nbt is GZIP compressed and is therefore a special test file.
      // You can get bigtest.nbt from https://raw.github.com/Dav1dde/nbd/master/test/bigtest.nbt.
      NbtFile nbtFile;
      try {
        nbtFile = NbtFile.fromPath('./test/bigtest.nbt');
        await nbtFile.readFile();
      } on NbtException {
        return;
      }
      final root = nbtFile.root;
      expect(root, isNotNull);

      expect(root!.getChildrenByName('stringTest').first.value,
          equals('HELLO WORLD THIS IS A TEST STRING ÅÄÖ!'));

      final nbtByteArray = root
          .getChildrenByName(
              'byteArrayTest (the first 1000 values of (n*n*255+n*7)%100, starting with n=0 (0, 62, 34, 16, 8, ...))')
          .first as NbtByteArray;

      expect(nbtByteArray.length, equals(1000));
    });

    test('Read level.dat', () async {
      // level.dat is simply any main minecraft world file.
      final NbtFile nbtFile;
      try {
        nbtFile = NbtFile.fromPath('./test/level.dat');
        await nbtFile.readFile();
      } on NbtException {
        return;
      }
      final root = nbtFile.root;
      expect(root, isNotNull);

      final list = (root!.children.first as NbtList)
          .where((val) => val.nbtTagType == NbtTagType.TAG_STRING);

      // We'll check that there should be at max 3 TAG_Strings in the list.
      // These strings are named "generatorName", "WanderingTraderId" and "LevelName".
      expect(list.length, inInclusiveRange(1, 3));
    });

    test('Read NaN double value', () async {
      // Player-nan-value.dat is a NBT file with a TAG_Double with a NaN (Not a Number).
      // This checks if the parser can detect this issue and handles the value accordingly.
      final NbtFile nbtFile;
      try {
        nbtFile = NbtFile.fromPath('./test/NaN-value.nbt');
        await nbtFile.readFile();
      } on NbtException {
        return;
      }

      expect(nbtFile.root, isNotNull);

      // 'Pos' is a NbtList, where the second entry is a NaN. Check if that
      // value exists there and if it is NaN.
      // TAG_List(Pos): 3 entries {[TAG_Double(None): 0.0, TAG_Double(None): NaN, TAG_Double(None): 0.0]}
      final fallDistance = nbtFile.root!.getChildrenByName('Pos').first;

      // [fallDistance] should be a NbtList<NbtDouble>, but as NbtList<T> can be
      // anything, we will only check if it is NbtList<NbtTag>.
      expect(fallDistance, isA<NbtList<NbtTag>>());

      // The second child should be a NbtDouble and have a NaN value.
      expect((fallDistance as NbtList<NbtTag>).children[1].value, isNaN);
    });
  });

  group('Rewrite files and check if they remain the same.', () {
    Future<bool> compareFiles(String file, String file2) async {
      final nbtFile1 = NbtFile.fromPath(file);
      await nbtFile1.readFile();
      final nbtFile2 = NbtFile.fromPath(file2);
      await nbtFile2.readFile();
      return nbtFile1.root == nbtFile2.root;
    }

    test('Rewrite servers.dat', () async {
      try {
        final nbtFile = NbtFile.fromPath('./test/servers.dat');
        await nbtFile.readFile();

        await nbtFile.writeFile(
            file: File('./test/servers2.dat'),
            nbtCompression: nbtFile.nbtCompression ?? NbtCompression.none);

        expect(await compareFiles('./test/servers.dat', './test/servers2.dat'),
            isTrue);
      } on NbtException {
        return;
      }
    });

    test('Rewrite bigtest.dat', () async {
      try {
        var nbtFile = NbtFile.fromPath('./test/bigtest.nbt');
        await nbtFile.readFile();

        await nbtFile.writeFile(
            file: File('./test/bigtest2.nbt'),
            nbtCompression: nbtFile.nbtCompression ?? NbtCompression.none);

        expect(await compareFiles('./test/bigtest.nbt', './test/bigtest2.nbt'),
            isTrue);
      } on NbtException {
        return;
      }
    });

    test('Rewrite level.dat', () async {
      try {
        final nbtFile = NbtFile.fromPath('./test/level.dat');
        await nbtFile.readFile();

        await nbtFile.writeFile(
            file: File('./test/level2.dat'),
            nbtCompression: nbtFile.nbtCompression ?? NbtCompression.none);

        expect(await compareFiles('./test/level.dat', './test/level2.dat'),
            isTrue);
      } on NbtException {
        return;
      }
    });
  });

  test('Write test.nbt', () async {
    try {
      final nbtFile = NbtFile.fromPath('./test/test.nbt');
      nbtFile.root = NbtCompound(
        name: 'rootCompound',
        children: <NbtTag>[
          NbtInt(
            name: 'intTest',
            value: 5430834,
          ),
          NbtString(name: 'stringTest', value: 'This is a String test!'),
        ],
      );

      // Write the data to the file.
      await nbtFile.writeFile(nbtCompression: NbtCompression.gzip);

      // Re-read the file from disk.
      await nbtFile.readFile();

      expect(nbtFile.root, isNotNull);
      expect(nbtFile.root!.children[0].value, equals(5430834));
      expect(nbtFile.root!.children[1].value, equals('This is a String test!'));
    } on NbtException {
      return;
    }
  });

  test('Write/read with proper endianness', () async {
    try {
      final file = NbtFile.fromPath('./test/endianness_test.nbt');
      file.root = NbtCompound(
        name: 'root',
        children: <NbtTag>[
          NbtLong(name: 'int', value: BigInt.from( 0xFFFF)), // This should be the first byte.
        ],
      );
      await file.writeFile(
          endian: Endian.little, nbtCompression: NbtCompression.none);

      // Now we try and read that integer again. With big Endian, we'd likely get
      // a RangeError somewhere in the code.
      file.root = null;
      await file.readFile(endian: Endian.little);
      expect(file.root?.children[0].value, equals(BigInt.from(0xFFFF)));
    } on NbtException {
      return;
    }
  });
}
