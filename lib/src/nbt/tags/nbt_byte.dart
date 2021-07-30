import '../nbt_reader.dart';
import '../nbt_tags.dart';
import '../nbt_writer.dart';
import 'nbt_tag.dart';

/// Represents a single byte in a NBT file.
class NbtByte extends NbtTag {
  int _value;

  @override
  int get value => _value;

  /// Creates a [NbtByte] with given [parent].
  NbtByte({required String name, required int value})
      : _value = value,
        super(name, NbtTagType.TAG_BYTE);

  @override
  NbtByte readTag(NbtReader nbtReader, {bool withName = true}) {
    final name = withName ? nbtReader.readString() : 'None';
    final value = nbtReader.readByte();
    return this
      ..name = name
      .._value = value;
  }

  @override
  void writeTag(NbtWriter nbtWriter,
      {bool withName = true, bool withType = true}) {
    if (withType) nbtWriter.writeByte(nbtTagType.index);
    if (withName) {
      nbtWriter.writeString(name);
    }
    nbtWriter.writeByte(_value, signed: true);
  }
}
