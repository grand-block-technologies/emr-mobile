// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiPage<T> _$ApiPageFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => ApiPage<T>(
  content: (json['content'] as List<dynamic>?)?.map(fromJsonT).toList() ?? [],
  page: (json['page'] as num?)?.toInt() ?? 0,
  size: (json['size'] as num?)?.toInt() ?? 0,
  hasNext: json['hasNext'] as bool? ?? false,
  totalElements: (json['totalElements'] as num?)?.toInt(),
);
