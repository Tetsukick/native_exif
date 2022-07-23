import 'dart:async';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Exif {
  static const MethodChannel _channel = MethodChannel('native_exif');

  final int _id;
  bool active = true;

  Exif(int id) : _id = id;

  /// Parse the exif metadata from an image located at [path].
  static Future<Exif> fromPath(String path) async {
    final int id = await _channel.invokeMethod('initPath', path);

    return Exif(id);
  }

  /// Get an Exif attribute from the interface. Can be one of the Exif constants
  /// See https://exiftool.org/TagNames/EXIF.html for all available tags.
  /// Returns `null` when the given [tag] was not found.
  Future<T?> getAttribute<T>(String tag) async {
    if (active == false) {
      throw StateError('Exif interface is already closed.');
    }

    final T? result = await _channel.invokeMethod<T>('getAttribute', {
      'id': _id,
      'tag': tag,
    });

    return result;
  }

  Future<Map<String, Object>?> getAttributes() async {
    if (active == false) {
      throw StateError('Exif interface is already closed.');
    }

    final result = await _channel.invokeMethod<Map>('getAttributes', {
      'id': _id,
    });

    if (result != null) {
      return Map<String, Object>.from(result);
    }

    return null;
  }

  Future<void> writeAttribute<T>(String tag, T value) async {
    if (active == false) {
      throw StateError('Exif interface is already closed.');
    }

    await _channel.invokeMethod('setAttribute', {
      'id': _id,
      'tag': tag,
      'value': value,
    });

    return;
  }

  Future<void> writeAttributes(Map<String, Object> values) async {
    if (active == false) {
      throw StateError('Exif interface is already closed.');
    }

    await _channel.invokeMethod('setAttributes', {
      'id': _id,
      'values': values,
    });

    return;
  }

  /// Convenient function to read out the "DateTimeOriginal" tag from the interface.
  /// Returns `null` when no date tag was found in the image metadata.
  Future<DateTime?> getOriginalDate() async {
    final dateString = await getAttribute<String>('DateTimeOriginal');

    if (dateString == null) {
      return null;
    }

    final dateFormat = DateFormat("yyyy:MM:dd HH:mm:ss");

    try {
      return dateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Close the exif interface to keep memory clean
  Future<void> close() async {
    await _channel.invokeMethod('close', {'id': _id});
    active = false;
  }
}
