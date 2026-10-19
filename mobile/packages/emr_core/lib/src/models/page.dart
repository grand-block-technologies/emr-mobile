import 'package:json_annotation/json_annotation.dart';

part 'page.g.dart';

/// Server page envelope. `totalElements` may be null, so page with [hasNext].
@JsonSerializable(genericArgumentFactories: true, createToJson: false)
class ApiPage<T> {
  const ApiPage({required this.content, this.page = 0, this.size = 0, this.hasNext = false, this.totalElements});

  factory ApiPage.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) =>
      _$ApiPageFromJson(json, fromJsonT);

  @JsonKey(defaultValue: [])
  final List<T> content;
  @JsonKey(defaultValue: 0)
  final int page;
  @JsonKey(defaultValue: 0)
  final int size;
  @JsonKey(defaultValue: false)
  final bool hasNext;
  final int? totalElements;
}
