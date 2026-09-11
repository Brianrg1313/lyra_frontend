import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
// The mouse wheel arrives as a pointer signal, and that is not exported by
// `material.dart`: without this there are no `PointerSignalEvent` or the scroll
// event that is watched below.
import 'package:flutter/gestures.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';

/// Crops an image before uploading it: it chooses which part of it is shown
/// and with how much zoom, and what comes out is that square and nothing else.
///
/// It is cropped **here and not on the other side** because the framing is a
/// decision of whoever uploads the photo, not of the server: a landscape photo
/// forced into a square leaves out half the image, and which half is precisely
/// what the backend cannot guess. What is sent already comes resolved, so the
/// business sees exactly the logo that is going to stand before uploading.
///
/// The frame **is** the crop: what is seen is what is saved. There is no
/// movable window over a still image but the reverse —the image moves under a
/// fixed window—, which is how any camera frames and does not force hitting a
/// rectangle with the mouse.
///
/// It opens centered and filling the frame (never with empty borders), so
/// accepting without touching anything already gives a reasonable crop: the
/// adjustment is for the one who needs it, not a procedure for the one who
/// does not.
///
/// Returns the crop bytes in PNG through [Navigator.pop], or nothing if it is
/// closed without accepting. It uploads nothing and does not know what the
/// image is for: that is for whoever opens it.
class CropImageModal extends StatefulWidget {
  const CropImageModal({super.key, required this.bytes, this.output = 512});

  /// The image as it was chosen, untouched.
  final Uint8List bytes;

  /// Maximum side of the crop, in pixels. Nothing is enlarged to reach it: a
  /// small logo comes out small, which is preferable to coming out blurry.
  final int output;

  @override
  State<CropImageModal> createState() => _CropImageModalState();
}

class _CropImageModalState extends State<CropImageModal> {
  /// Side of the frame on screen. It is fixed and not a fraction of the
  /// width: the modal is measured by its content (`IntrinsicWidth`), so asking
  /// how much width there is to decide how much to use is a loop that does
  /// not close.
  static double get _frame => AppSize.picture * 5;

  /// How much can be zoomed over what already fills the frame. Four times is
  /// keeping a quarter of the image side: more than that is already cropping a
  /// detail that is going to be uploaded blurry.
  static const double _maxZoom = 4;

  ui.Image? _image;

  /// Zoom over [_cover]. At 1 the image barely fills the frame, which is the
  /// minimum: below that empty background would appear inside the crop.
  double _zoom = 1;

  /// With how much zoom the current gesture started. The gesture reports how
  /// much the fingers opened **since it began**, not since the last notice, so
  /// without this each event would start from zero.
  double _startZoom = 1;

  /// Top-left corner of the image inside the frame. It is negative or zero:
  /// what is seen is a window over something bigger.
  Offset _offset = Offset.zero;

  /// How much the image has to be enlarged to fill the frame. It comes from
  /// its proportions, so it is calculated only once, when it finishes decoding.
  double _cover = 1;

  final _loading = ValueNotifier<bool>(false);

  /// Real scale at which it is drawn: the one that fills the frame times the
  /// chosen zoom.
  double get _scale => _cover * _zoom;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void dispose() {
    _image?.dispose();
    _loading.dispose();
    super.dispose();
  }

  /// Decodes the chosen bytes. An image that cannot be decoded is not an
  /// image: the modal closes and whoever opened it lets it be known, because
  /// it is the one that knows which photo it was talking about.
  Future<void> _decode() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      final frame = await codec.getNextFrame();

      if (!mounted) {
        frame.image.dispose();
        return;
      }

      setState(() {
        _image = frame.image;
        _cover = math.max(
          _frame / frame.image.width,
          _frame / frame.image.height
        );
        // Centered: the overflow that does not fit in the frame is split
        // evenly between the two sides.
        _offset = Offset(
          (_frame - frame.image.width * _cover) / 2,
          (_frame - frame.image.height * _cover) / 2
        );
      });
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _frame,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _viewport(context),
        SizedBox(height: AppSize.spaceXS),
        TextSmall(
          S.of(context).image_crop_hint,
          lines: 2,
          textAlign: TextAlign.center,
          color: ThemeColor.of(context).text.secondary
        ),
        SizedBox(height: AppSize.spaceS),
        _ZoomBar(
          value: (_zoom - 1) / (_maxZoom - 1),
          width: _frame,
          onChanged: _zoomBar
        ),
        SizedBox(height: AppSize.spaceM),
        Button(
          title: S.of(context).save,
          loading: _loading,
          action: _submit
        )
      ]
    )
  );

  /// The frame: the image below and, on top, everything that moves it.
  Widget _viewport(BuildContext context) {
    final image = _image;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSize.corner),
      child: Container(
        width: _frame,
        height: _frame,
        color: ThemeColor.of(context).background,
        child: image == null
          ? const Center(child: Loading())
          // The mouse wheel is the only way to zoom without fingers, so it is
          // listened apart: Flutter gestures do not report it.
          : Listener(
            onPointerSignal: _wheel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (_) => _startZoom = _zoom,
              onScaleUpdate: _drag,
              child: Stack(children: [
                Positioned(
                  left: _offset.dx,
                  top: _offset.dy,
                  child: RawImage(
                    image: image,
                    width: image.width * _scale,
                    height: image.height * _scale,
                    filterQuality: FilterQuality.medium
                  )
                )
              ])
            )
          )
      )
    );
  }

  /// A drag or a pinch gesture, which for Flutter are the same: one with one
  /// finger and the other with two.
  void _drag(ScaleUpdateDetails details) => _move(
    zoom: _startZoom * details.scale,
    focus: details.localFocalPoint,
    delta: details.focalPointDelta
  );

  void _wheel(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    // Exponential and not a sum: zooming two notches from far away has to feel
    // the same as zooming them from close by.
    _move(
      zoom: _zoom * math.exp(-event.scrollDelta.dy / 250),
      focus: event.localPosition
    );
  }

  void _zoomBar(double value) => _move(
    zoom: 1 + value * (_maxZoom - 1),
    focus: Offset(_frame / 2, _frame / 2)
  );

  /// Moves the image: brings it to [zoom] keeping still what is under
  /// [focus], and shifts it by [delta].
  ///
  /// The fixed point is the gesture's and not the center of the frame because
  /// that is what is expected from a zoom: it zooms **over what is being
  /// looked at**, not over the middle of the photo, which would force going
  /// over it again after every zoom.
  void _move({required double zoom, required Offset focus, Offset? delta}) {
    final image = _image;
    if (image == null) return;

    final previous = _scale;

    setState(() {
      _zoom = zoom.clamp(1.0, _maxZoom);

      final moved = focus - (focus - _offset) * (_scale / previous);

      _offset = _inside(moved + (delta ?? Offset.zero), image);
    });
  }

  /// Leaves the image covering the whole frame: dragging it beyond its edge
  /// would leave empty background inside the crop, which is a transparent
  /// corner in the logo.
  Offset _inside(Offset offset, ui.Image image) {
    final width = image.width * _scale;
    final height = image.height * _scale;

    return Offset(
      offset.dx.clamp(math.min(_frame - width, 0.0), 0.0),
      offset.dy.clamp(math.min(_frame - height, 0.0), 0.0)
    );
  }

  /// Draws what is seen in the frame and returns it in PNG.
  ///
  /// It comes out in PNG and not in the original format because what is saved
  /// is no longer the file that was chosen but a crop: there are no bytes to
  /// keep. The backend re-encodes it the same way (to WebP, without
  /// metadata), so sending it compressed with loss would be compressing the
  /// same image twice.
  Future<void> _submit() async {
    final image = _image;
    if (image == null || _loading.value) return;

    _loading.value = true;

    final bytes = await _crop(image);

    if (!mounted) return;

    _loading.value = false;

    if (bytes == null) {
      FloatFlag.of(context).error(message: S.of(context).image_crop_failed);
      return;
    }

    Navigator.pop(context, bytes);
  }

  Future<Uint8List?> _crop(ui.Image image) async {
    // The frame, measured over the image: what is seen divided by how much it
    // was enlarged to see it.
    final source = Rect.fromLTWH(
      -_offset.dx / _scale,
      -_offset.dy / _scale,
      _frame / _scale,
      _frame / _scale
    );

    // It is never enlarged: a 200 px logo comes out at 200 px. Stretching it
    // to the maximum adds not a single detail, only weight.
    final side = math.max(1, math.min(widget.output, source.width.round()));

    try {
      final recorder = ui.PictureRecorder();

      Canvas(recorder).drawImageRect(
        image,
        source,
        Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()),
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.medium
      );

      final picture = recorder.endRecording();
      final rendered = await picture.toImage(side, side);

      picture.dispose();

      final data = await rendered.toByteData(format: ui.ImageByteFormat.png);

      rendered.dispose();

      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}

/// The bar used to zoom the image.
///
/// It exists besides the wheel and the pinch because it is the only one of the
/// three that **is seen**: without it, whoever does not know the wheel zooms
/// can only move the photo, and half the crop escapes them.
///
/// It measures a fixed width, the frame's: it lives inside a modal that is
/// measured by its content, and asking how much width is available there has
/// no answer.
class _ZoomBar extends StatelessWidget {
  const _ZoomBar({
    required this.value,
    required this.width,
    required this.onChanged
  });

  /// How much zoom there is, from 0 (the minimum) to 1 (the maximum).
  final double value;

  final double width;
  final void Function(double value) onChanged;

  /// Side of the thumb. From the height of the text: it is what is grabbed
  /// with the mouse, and smaller than that is not easy to hit.
  static double get _grip => AppSize.text * 1.4;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    // The thumb travels the slot left by its own diameter, so it does not
    // come out at the ends of the track.
    final span = math.max(width - _grip, 1.0);

    void pick(Offset position) =>
      onChanged(((position.dx - (_grip / 2)) / span).clamp(0.0, 1.0));

    return SizedBox(
      width: width,
      height: _grip,
      child: GestureDetector(
        onTapDown: (details) => pick(details.localPosition),
        onPanStart: (details) => pick(details.localPosition),
        onPanUpdate: (details) => pick(details.localPosition),
        child: Stack(children: [
          Positioned.fill(child: Center(child: Container(
            height: AppSize.gap / 2,
            decoration: BoxDecoration(
              color: scheme.line,
              borderRadius: BorderRadius.circular(AppSize.gap)
            )
          ))),
          Positioned(
            top: 0,
            left: value.clamp(0.0, 1.0) * span,
            child: Container(
              width: _grip,
              height: _grip,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle
              )
            )
          )
        ])
      )
    );
  }
}