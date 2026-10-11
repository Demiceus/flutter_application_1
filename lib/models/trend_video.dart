class TrendVideo {
  final String videoId;
  final String title;
  final String description;
  final String channelTitle;
  final DateTime publishedAt;
  final String thumbnail;
  final int viewCount;
  final int likeCount;

  const TrendVideo({
    required this.videoId,
    required this.title,
    required this.description,
    required this.channelTitle,
    required this.publishedAt,
    required this.thumbnail,
    required this.viewCount,
    required this.likeCount,
  });

  factory TrendVideo.fromJson(
    Map<String, dynamic> json,
  ) {
    return TrendVideo(
      videoId: json['videoId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled video',
      description:
          json['description']?.toString() ?? '',
      channelTitle:
          json['channelTitle']?.toString() ?? '',
      publishedAt: _parseDateTime(
        json['publishedAt'],
      ),
      thumbnail:
          json['thumbnail']?.toString() ?? '',
      viewCount: _parseInt(
        json['viewCount'],
      ),
      likeCount: _parseInt(
        json['likeCount'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'description': description,
      'channelTitle': channelTitle,
      'publishedAt':
          publishedAt.toIso8601String(),
      'thumbnail': thumbnail,
      'viewCount': viewCount,
      'likeCount': likeCount,
    };
  }

  static DateTime _parseDateTime(
    dynamic value,
  ) {
    if (value is String) {
      final DateTime? parsed =
          DateTime.tryParse(value);

      if (parsed != null) {
        return parsed;
      }
    }

    return DateTime.now();
  }

  static int _parseInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }
}


// ==========================================================
// TREND SIGNAL
// ==========================================================

class TrendSignal {
  final String name;
  final String description;
  final int evidenceCount;

  const TrendSignal({
    required this.name,
    required this.description,
    required this.evidenceCount,
  });

  factory TrendSignal.fromJson(
    Map<String, dynamic> json,
  ) {
    return TrendSignal(
      name: json['name']?.toString() ??
          'Unknown trend',
      description:
          json['description']?.toString() ?? '',
      evidenceCount:
          _parseInt(json['evidenceCount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'evidenceCount': evidenceCount,
    };
  }

  static int _parseInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }
}


// ==========================================================
// TREND DATA
// ==========================================================

class TrendData {
  final List<TrendSignal> trendSignals;
  final List<TrendVideo> videos;

  const TrendData({
    required this.trendSignals,
    required this.videos,
  });

  factory TrendData.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic rawSignals =
        json['trendSignals'];

    final dynamic rawVideos =
        json['videos'];

    final List<TrendSignal> signals = [];

    if (rawSignals is List) {
      for (final dynamic item in rawSignals) {
        if (item is Map<String, dynamic>) {
          signals.add(
            TrendSignal.fromJson(item),
          );
        }
      }
    }

    final List<TrendVideo> videos = [];

    if (rawVideos is List) {
      for (final dynamic item in rawVideos) {
        if (item is Map<String, dynamic>) {
          videos.add(
            TrendVideo.fromJson(item),
          );
        }
      }
    }

    return TrendData(
      trendSignals: signals,
      videos: videos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trendSignals': trendSignals
          .map(
            (signal) => signal.toJson(),
          )
          .toList(),
      'videos': videos
          .map(
            (video) => video.toJson(),
          )
          .toList(),
    };
  }
}