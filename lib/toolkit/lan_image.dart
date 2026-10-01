import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

// SERVICES
import 'package:app/toolkit/settings/initial_builder.dart' show lanService;

/// The image behind [url], wherever it lives: a master's file (`lyra-file:` addresses, which
/// `CdnService` gives in `local` mode) comes over the master's channel, anything else from the
/// network. Screens draw `Image(image: mediaImage(url))` and never know the mode.
ImageProvider mediaImage(String url) => LanFileImage.parse(url) ?? NetworkImage(url);

/// A file of the master (`protocol-v1.md` §6), downloaded with this session over the pinned
/// channel: `Image.network` can't, since the master's certificate chains to the installation CA
/// and the request needs the session's token.
///
/// Equal ids and sizes are one image to Flutter's cache, so a list scrolled back and forth
/// downloads each photo once.
@immutable
class LanFileImage extends ImageProvider<LanFileImage> {
  const LanFileImage(this.id, {this.size});

  final String id;

  /// The thumbnail's width, or null for the original.
  final int? size;

  static const scheme = "lyra-file:";

  /// The address `CdnService` gives for [id] on a master.
  static String address(String id, {int? width}) => width == null ? "$scheme$id" : "$scheme$id@$width";

  /// The image an [address] names, or null when [url] isn't one.
  static LanFileImage? parse(String url) {
    if (!url.startsWith(scheme)) return null;

    final rest = url.substring(scheme.length);
    final at = rest.lastIndexOf("@");
    if (at == -1) return LanFileImage(rest);

    return LanFileImage(rest.substring(0, at), size: int.tryParse(rest.substring(at + 1)));
  }

  @override
  Future<LanFileImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(LanFileImage key, ImageDecoderCallback decode) =>
    MultiFrameImageStreamCompleter(codec: _load(key, decode), scale: 1);

  static Future<ui.Codec> _load(LanFileImage key, ImageDecoderCallback decode) async {
    final bytes = await lanService.download(key.id, size: key.size);

    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) => other is LanFileImage && other.id == id && other.size == size;

  @override
  int get hashCode => Object.hash(id, size);

  @override
  String toString() => "LanFileImage($id, size: $size)";
}
