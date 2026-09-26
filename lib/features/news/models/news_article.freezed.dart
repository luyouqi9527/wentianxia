// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'news_article.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NewsArticle _$NewsArticleFromJson(Map<String, dynamic> json) {
  return _NewsArticle.fromJson(json);
}

/// @nodoc
mixin _$NewsArticle {
  /// 稳定主键：优先使用原文 url 的哈希，保证同一条新闻不会重复收藏。
  @HiveField(0)
  String? get id => throw _privateConstructorUsedError;
  @HiveField(1)
  @JsonKey(name: 'title')
  String get title => throw _privateConstructorUsedError;
  @HiveField(2)
  @JsonKey(name: 'author_name')
  String get author => throw _privateConstructorUsedError;
  @HiveField(3)
  @JsonKey(name: 'date')
  String get publishedAt => throw _privateConstructorUsedError;
  @HiveField(4)
  @JsonKey(name: 'thumbnail_pic_s')
  String get thumbnailUrl => throw _privateConstructorUsedError;
  @HiveField(5)
  @JsonKey(name: 'thumbnail_pic_s02')
  String get imageUrl2 => throw _privateConstructorUsedError;
  @HiveField(6)
  @JsonKey(name: 'thumbnail_pic_s03')
  String get imageUrl3 => throw _privateConstructorUsedError;
  @HiveField(7)
  @JsonKey(name: 'url')
  String get url => throw _privateConstructorUsedError;
  @HiveField(8)
  @JsonKey(name: 'category')
  String get category => throw _privateConstructorUsedError;
  @HiveField(9)
  @JsonKey(name: 'description')
  String get summary => throw _privateConstructorUsedError;

  /// 收藏时间（null 表示未收藏）。
  @HiveField(11)
  DateTime? get favoritedAt => throw _privateConstructorUsedError;

  /// 收藏记录在 Hive Box 中的 key（Freezed 生成 copyWith 时会带上该参数）。
  @HiveField(12)
  @JsonKey(includeFromJson: false, includeToJson: false)
  int? get hiveKey => throw _privateConstructorUsedError;

  /// Serializes this NewsArticle to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NewsArticle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NewsArticleCopyWith<NewsArticle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NewsArticleCopyWith<$Res> {
  factory $NewsArticleCopyWith(
          NewsArticle value, $Res Function(NewsArticle) then) =
      _$NewsArticleCopyWithImpl<$Res, NewsArticle>;
  @useResult
  $Res call(
      {@HiveField(0) String? id,
      @HiveField(1) @JsonKey(name: 'title') String title,
      @HiveField(2) @JsonKey(name: 'author_name') String author,
      @HiveField(3) @JsonKey(name: 'date') String publishedAt,
      @HiveField(4) @JsonKey(name: 'thumbnail_pic_s') String thumbnailUrl,
      @HiveField(5) @JsonKey(name: 'thumbnail_pic_s02') String imageUrl2,
      @HiveField(6) @JsonKey(name: 'thumbnail_pic_s03') String imageUrl3,
      @HiveField(7) @JsonKey(name: 'url') String url,
      @HiveField(8) @JsonKey(name: 'category') String category,
      @HiveField(9) @JsonKey(name: 'description') String summary,
      @HiveField(11) DateTime? favoritedAt,
      @HiveField(12)
      @JsonKey(includeFromJson: false, includeToJson: false)
      int? hiveKey});
}

/// @nodoc
class _$NewsArticleCopyWithImpl<$Res, $Val extends NewsArticle>
    implements $NewsArticleCopyWith<$Res> {
  _$NewsArticleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NewsArticle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? title = null,
    Object? author = null,
    Object? publishedAt = null,
    Object? thumbnailUrl = null,
    Object? imageUrl2 = null,
    Object? imageUrl3 = null,
    Object? url = null,
    Object? category = null,
    Object? summary = null,
    Object? favoritedAt = freezed,
    Object? hiveKey = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      publishedAt: null == publishedAt
          ? _value.publishedAt
          : publishedAt // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailUrl: null == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl2: null == imageUrl2
          ? _value.imageUrl2
          : imageUrl2 // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl3: null == imageUrl3
          ? _value.imageUrl3
          : imageUrl3 // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String,
      favoritedAt: freezed == favoritedAt
          ? _value.favoritedAt
          : favoritedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      hiveKey: freezed == hiveKey
          ? _value.hiveKey
          : hiveKey // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NewsArticleImplCopyWith<$Res>
    implements $NewsArticleCopyWith<$Res> {
  factory _$$NewsArticleImplCopyWith(
          _$NewsArticleImpl value, $Res Function(_$NewsArticleImpl) then) =
      __$$NewsArticleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String? id,
      @HiveField(1) @JsonKey(name: 'title') String title,
      @HiveField(2) @JsonKey(name: 'author_name') String author,
      @HiveField(3) @JsonKey(name: 'date') String publishedAt,
      @HiveField(4) @JsonKey(name: 'thumbnail_pic_s') String thumbnailUrl,
      @HiveField(5) @JsonKey(name: 'thumbnail_pic_s02') String imageUrl2,
      @HiveField(6) @JsonKey(name: 'thumbnail_pic_s03') String imageUrl3,
      @HiveField(7) @JsonKey(name: 'url') String url,
      @HiveField(8) @JsonKey(name: 'category') String category,
      @HiveField(9) @JsonKey(name: 'description') String summary,
      @HiveField(11) DateTime? favoritedAt,
      @HiveField(12)
      @JsonKey(includeFromJson: false, includeToJson: false)
      int? hiveKey});
}

/// @nodoc
class __$$NewsArticleImplCopyWithImpl<$Res>
    extends _$NewsArticleCopyWithImpl<$Res, _$NewsArticleImpl>
    implements _$$NewsArticleImplCopyWith<$Res> {
  __$$NewsArticleImplCopyWithImpl(
      _$NewsArticleImpl _value, $Res Function(_$NewsArticleImpl) _then)
      : super(_value, _then);

  /// Create a copy of NewsArticle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? title = null,
    Object? author = null,
    Object? publishedAt = null,
    Object? thumbnailUrl = null,
    Object? imageUrl2 = null,
    Object? imageUrl3 = null,
    Object? url = null,
    Object? category = null,
    Object? summary = null,
    Object? favoritedAt = freezed,
    Object? hiveKey = freezed,
  }) {
    return _then(_$NewsArticleImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      publishedAt: null == publishedAt
          ? _value.publishedAt
          : publishedAt // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailUrl: null == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl2: null == imageUrl2
          ? _value.imageUrl2
          : imageUrl2 // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl3: null == imageUrl3
          ? _value.imageUrl3
          : imageUrl3 // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String,
      favoritedAt: freezed == favoritedAt
          ? _value.favoritedAt
          : favoritedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      hiveKey: freezed == hiveKey
          ? _value.hiveKey
          : hiveKey // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NewsArticleImpl extends _NewsArticle {
  const _$NewsArticleImpl(
      {@HiveField(0) this.id,
      @HiveField(1) @JsonKey(name: 'title') required this.title,
      @HiveField(2) @JsonKey(name: 'author_name') this.author = '',
      @HiveField(3) @JsonKey(name: 'date') this.publishedAt = '',
      @HiveField(4) @JsonKey(name: 'thumbnail_pic_s') this.thumbnailUrl = '',
      @HiveField(5) @JsonKey(name: 'thumbnail_pic_s02') this.imageUrl2 = '',
      @HiveField(6) @JsonKey(name: 'thumbnail_pic_s03') this.imageUrl3 = '',
      @HiveField(7) @JsonKey(name: 'url') this.url = '',
      @HiveField(8) @JsonKey(name: 'category') this.category = 'top',
      @HiveField(9) @JsonKey(name: 'description') this.summary = '',
      @HiveField(11) this.favoritedAt,
      @HiveField(12)
      @JsonKey(includeFromJson: false, includeToJson: false)
      this.hiveKey})
      : super._();

  factory _$NewsArticleImpl.fromJson(Map<String, dynamic> json) =>
      _$$NewsArticleImplFromJson(json);

  /// 稳定主键：优先使用原文 url 的哈希，保证同一条新闻不会重复收藏。
  @override
  @HiveField(0)
  final String? id;
  @override
  @HiveField(1)
  @JsonKey(name: 'title')
  final String title;
  @override
  @HiveField(2)
  @JsonKey(name: 'author_name')
  final String author;
  @override
  @HiveField(3)
  @JsonKey(name: 'date')
  final String publishedAt;
  @override
  @HiveField(4)
  @JsonKey(name: 'thumbnail_pic_s')
  final String thumbnailUrl;
  @override
  @HiveField(5)
  @JsonKey(name: 'thumbnail_pic_s02')
  final String imageUrl2;
  @override
  @HiveField(6)
  @JsonKey(name: 'thumbnail_pic_s03')
  final String imageUrl3;
  @override
  @HiveField(7)
  @JsonKey(name: 'url')
  final String url;
  @override
  @HiveField(8)
  @JsonKey(name: 'category')
  final String category;
  @override
  @HiveField(9)
  @JsonKey(name: 'description')
  final String summary;

  /// 收藏时间（null 表示未收藏）。
  @override
  @HiveField(11)
  final DateTime? favoritedAt;

  /// 收藏记录在 Hive Box 中的 key（Freezed 生成 copyWith 时会带上该参数）。
  @override
  @HiveField(12)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final int? hiveKey;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NewsArticleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.publishedAt, publishedAt) ||
                other.publishedAt == publishedAt) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.imageUrl2, imageUrl2) ||
                other.imageUrl2 == imageUrl2) &&
            (identical(other.imageUrl3, imageUrl3) ||
                other.imageUrl3 == imageUrl3) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.favoritedAt, favoritedAt) ||
                other.favoritedAt == favoritedAt) &&
            (identical(other.hiveKey, hiveKey) || other.hiveKey == hiveKey));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      author,
      publishedAt,
      thumbnailUrl,
      imageUrl2,
      imageUrl3,
      url,
      category,
      summary,
      favoritedAt,
      hiveKey);

  /// Create a copy of NewsArticle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NewsArticleImplCopyWith<_$NewsArticleImpl> get copyWith =>
      __$$NewsArticleImplCopyWithImpl<_$NewsArticleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NewsArticleImplToJson(
      this,
    );
  }
}

abstract class _NewsArticle extends NewsArticle {
  const factory _NewsArticle(
      {@HiveField(0) final String? id,
      @HiveField(1) @JsonKey(name: 'title') required final String title,
      @HiveField(2) @JsonKey(name: 'author_name') final String author,
      @HiveField(3) @JsonKey(name: 'date') final String publishedAt,
      @HiveField(4) @JsonKey(name: 'thumbnail_pic_s') final String thumbnailUrl,
      @HiveField(5) @JsonKey(name: 'thumbnail_pic_s02') final String imageUrl2,
      @HiveField(6) @JsonKey(name: 'thumbnail_pic_s03') final String imageUrl3,
      @HiveField(7) @JsonKey(name: 'url') final String url,
      @HiveField(8) @JsonKey(name: 'category') final String category,
      @HiveField(9) @JsonKey(name: 'description') final String summary,
      @HiveField(11) final DateTime? favoritedAt,
      @HiveField(12)
      @JsonKey(includeFromJson: false, includeToJson: false)
      final int? hiveKey}) = _$NewsArticleImpl;
  const _NewsArticle._() : super._();

  factory _NewsArticle.fromJson(Map<String, dynamic> json) =
      _$NewsArticleImpl.fromJson;

  /// 稳定主键：优先使用原文 url 的哈希，保证同一条新闻不会重复收藏。
  @override
  @HiveField(0)
  String? get id;
  @override
  @HiveField(1)
  @JsonKey(name: 'title')
  String get title;
  @override
  @HiveField(2)
  @JsonKey(name: 'author_name')
  String get author;
  @override
  @HiveField(3)
  @JsonKey(name: 'date')
  String get publishedAt;
  @override
  @HiveField(4)
  @JsonKey(name: 'thumbnail_pic_s')
  String get thumbnailUrl;
  @override
  @HiveField(5)
  @JsonKey(name: 'thumbnail_pic_s02')
  String get imageUrl2;
  @override
  @HiveField(6)
  @JsonKey(name: 'thumbnail_pic_s03')
  String get imageUrl3;
  @override
  @HiveField(7)
  @JsonKey(name: 'url')
  String get url;
  @override
  @HiveField(8)
  @JsonKey(name: 'category')
  String get category;
  @override
  @HiveField(9)
  @JsonKey(name: 'description')
  String get summary;

  /// 收藏时间（null 表示未收藏）。
  @override
  @HiveField(11)
  DateTime? get favoritedAt;

  /// 收藏记录在 Hive Box 中的 key（Freezed 生成 copyWith 时会带上该参数）。
  @override
  @HiveField(12)
  @JsonKey(includeFromJson: false, includeToJson: false)
  int? get hiveKey;

  /// Create a copy of NewsArticle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NewsArticleImplCopyWith<_$NewsArticleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
