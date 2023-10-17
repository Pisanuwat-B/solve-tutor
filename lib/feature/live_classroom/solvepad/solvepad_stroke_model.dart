import 'dart:ui';

class SolvepadStroke {
  Offset offset;
  Color color;
  double width;

  SolvepadStroke(this.offset, this.color, this.width);

  Map<String, dynamic> toJson() => {
        'offset': {'dx': offset.dx, 'dy': offset.dy},
        'color': color.value.toRadixString(16),
        'width': width,
      };

  SolvepadStroke.fromJson(Map<String, dynamic> json)
      : offset = Offset(json['offset']['dx'], json['offset']['dy']),
        color = Color(int.parse(json['color'], radix: 16)),
        width = json['width'];

  @override
  String toString() {
    return 'SolvepadStroke(offset: $offset, color: $color, width: $width)';
  }
}

class StrokeStamp {
  final Offset offset;
  final int timestamp;

  StrokeStamp(this.offset, this.timestamp);
}

class ScrollZoomStamp {
  final double x, y, scale;
  final int timestamp;

  ScrollZoomStamp(this.x, this.y, this.scale, this.timestamp);
}
