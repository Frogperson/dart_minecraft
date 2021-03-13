import 'dart:collection';

import 'package:collection/collection.dart';

import '../nbt_tags.dart';
import 'nbt_tag.dart';

/// The base of any array or list nbt tag. Uses the [ListMixin]
/// to inherit all methods and properties of a [List].
// ignore: prefer_mixin
abstract class NbtArray<T> extends NbtTag with ListMixin<T> {
  /// The list of children this array has. All functions implemented with
  /// [ListMixin] are referencing of of this [List].
  List<T> children = <T>[];

  /// Creates a base NbtArray with [parent] and [nbtTagType].
  NbtArray(String name, NbtTagType nbtTagType) : super(name, nbtTagType);

  @override
  List<T> get value => children;

  @override
  int get length => children.length;

  @override
  set length(int length) => children.length = length;

  @override
  T operator [](int index) => children[index];

  @override
  void operator []=(int index, T value) {
    children[index] = value;
  }

  @override
  void add(T element) {
    children.add(element);
  }

  @override
  String toString() {
    return '${nbtTagType.asString()}($name): ${children.length} entries {$value}';
  }

  @override
  bool operator ==(o) {
    if (!(o is NbtArray)) return false;
    if (!(name == o.name)) return false;
    return const ListEquality().equals(children, o.children);
  }

  @override
  int get hashCode => value.hashCode;
}
