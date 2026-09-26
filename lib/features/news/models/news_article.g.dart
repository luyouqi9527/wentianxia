// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_article.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NewsArticleAdapter extends TypeAdapter<NewsArticle> {
  @override
  final int typeId = 2;

  @override
  NewsArticle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NewsArticle(
      id: fields[0] as String?,
      title: fields[1] as String,
      author: fields[2] as String,
      publishedAt: fields[3] as String,
      thumbnailUrl: fields[4] as String,
      imageUrl2: fields[5] as String,
      imageUrl3: fields[6] as String,
      url: fields[7] as String,
      category: fields[8] as String,
      summary: fields[9] as String,
      favoritedAt: fields[11] as DateTime?,
      hiveKey: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, NewsArticle obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.publishedAt)
      ..writeByte(4)
      ..write(obj.thumbnailUrl)
      ..writeByte(5)
      ..write(obj.imageUrl2)
      ..writeByte(6)
      ..write(obj.imageUrl3)
      ..writeByte(7)
      ..write(obj.url)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.summary)
      ..writeByte(11)
      ..write(obj.favoritedAt)
      ..writeByte(12)
      ..write(obj.hiveKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewsArticleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NewsArticleImpl _$$NewsArticleImplFromJson(Map<String, dynamic> json) =>
    _$NewsArticleImpl(
      id: json['id'] as String?,
      title: json['title'] as String,
      author: json['author_name'] as String? ?? '',
      publishedAt: json['date'] as String? ?? '',
      thumbnailUrl: json['thumbnail_pic_s'] as String? ?? '',
      imageUrl2: json['thumbnail_pic_s02'] as String? ?? '',
      imageUrl3: json['thumbnail_pic_s03'] as String? ?? '',
      url: json['url'] as String? ?? '',
      category: json['category'] as String? ?? 'top',
      summary: json['description'] as String? ?? '',
      favoritedAt: json['favoritedAt'] == null
          ? null
          : DateTime.parse(json['favoritedAt'] as String),
    );

Map<String, dynamic> _$$NewsArticleImplToJson(_$NewsArticleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'author_name': instance.author,
      'date': instance.publishedAt,
      'thumbnail_pic_s': instance.thumbnailUrl,
      'thumbnail_pic_s02': instance.imageUrl2,
      'thumbnail_pic_s03': instance.imageUrl3,
      'url': instance.url,
      'category': instance.category,
      'description': instance.summary,
      'favoritedAt': instance.favoritedAt?.toIso8601String(),
    };
