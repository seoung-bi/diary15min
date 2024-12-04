class DiaryModel {
  final String id; // Firestore 문서 ID
  final String content; // 일기 내용
  final String title; // 일기 제목
  final String imageUrl; // 이미지 URL
  final DateTime date; // 일기 생성일
  final int timerMin; // 타이머 분
  final int timerSec; // 타이머 초

  DiaryModel({
    required this.id,
    required this.content,
    required this.title, // 제목 필드 추가
    required this.imageUrl,
    required this.date,
    required this.timerMin,
    required this.timerSec,
  });

  // ➊ JSON으로부터 DiaryModel을 생성하는 생성자
  DiaryModel.fromJson({
    required Map<String, dynamic> json,
  })  : id = json['id'],
        content = json['content'],
        title = json['title'], // 제목 추가
        imageUrl = json['imageUrl'],
        date = DateTime.parse(json['date']),
        timerMin = json['timerMin'],
        timerSec = json['timerSec'];

  // ➋ DiaryModel을 다시 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'title': title, // 제목 추가
      'imageUrl': imageUrl,
      'date':
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}',
      'timerMin': timerMin,
      'timerSec': timerSec,
    };
  }

  // ➌ DiaryModel 복사 및 특정 필드 변경
  DiaryModel copyWith({
    String? id,
    String? content,
    String? title, // 제목 복사 가능하도록 추가
    String? imageUrl,
    DateTime? date,
    int? timerMin,
    int? timerSec,
  }) {
    return DiaryModel(
      id: id ?? this.id,
      content: content ?? this.content,
      title: title ?? this.title, // 제목 추가
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      timerMin: timerMin ?? this.timerMin,
      timerSec: timerSec ?? this.timerSec,
    );
  }
}