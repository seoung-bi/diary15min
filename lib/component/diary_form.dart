import 'dart:async';
import 'dart:io';
import 'package:diary15min/model/diary_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../const/colors.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DiaryFormScreen extends StatefulWidget {
  final DateTime selectedDate;

  const DiaryFormScreen({Key? key, required this.selectedDate}) : super(key: key);

  @override
  State<DiaryFormScreen> createState() => _DiaryFormScreenState();
}

class _DiaryFormScreenState extends State<DiaryFormScreen> {
  final GlobalKey<FormState> formKey = GlobalKey();
  final TextEditingController _controller = TextEditingController(); // 내용 입력용
  final TextEditingController _titleController = TextEditingController(); // 제목 입력용
  List<XFile> _images = [];
  String? content;
  String? title; // 제목 저장 변수
  Timer? _timer;
  int elapsedSeconds = 0;
  bool isTimerRunning = false;

  @override
  void dispose() {
    _timer?.cancel(); // 타이머 취소
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    setState(() {
      isTimerRunning = true;
      elapsedSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          elapsedSeconds++;
        });

        if (elapsedSeconds >= 900) {
          _timer?.cancel();
          if (content == null || content!.isEmpty) {
            _showEmptyContentAlert();
          } else {
            onSavePressed();
          }
        }
      }
    });
  }

  void _showEmptyContentAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("일기를 적어주세요"),
        content: Text("일기를 작성하지 않으셨습니다. 일기를 다시 작성해주세요."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();  // 다이얼로그 닫기
            },
            child: Text("확인"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _controller.clear();
                content = null;
                _titleController.clear(); // 제목도 초기화
                title = null;
              });
              _startTimer();
            },
            child: Text("다시 작성하기"),
          ),
        ],
      ),
    );
  }

  void onSavePressed() async {
    final now = DateTime.now();
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save(); // 폼을 저장하여 onSaved 호출

      // 제목을 controller.text로 직접 가져오기
      final title = _titleController.text;

      List<String> imageUrls = [];
      for (var image in _images) {
        File imageFile = File(image.path);

        final storageReference = FirebaseStorage.instance.ref().child('diary_images/$now');
        final uploadTask = storageReference.putFile(imageFile);

        await uploadTask.whenComplete(() async {
          imageUrls.add(await storageReference.getDownloadURL());
        });
      }

      final diary = DiaryModel(
        id: Uuid().v4(),
        title: title.isNotEmpty ? title : 'No Title', // title이 비어있으면 기본값 적용
        content: content ?? 'NO TEXT',
        date: widget.selectedDate,
        imageUrl: imageUrls.isNotEmpty ? imageUrls.join(',') : '',
        timerMin: elapsedSeconds ~/ 60,
        timerSec: elapsedSeconds % 60,
      );

      await FirebaseFirestore.instance
          .collection('diaries')
          .doc(diary.id)
          .set(diary.toJson());

      Navigator.of(context).pop();
    }
  }



  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles);
      });
    }
  }

  void _viewImage(XFile image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.file(File(image.path), fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 8.0,
              right: 8.0,
              child: IconButton(
                icon: Icon(Icons.delete, color: Colors.white),
                onPressed: () {
                  _deleteImage(image);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteImage(XFile image) {
    setState(() {
      _images.remove(image);
    });
    // 이미지 파일 삭제
    File(image.path).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_YELLOW_COLOR, // 배경색 변경 (예시: 연한 파란색)
      appBar: AppBar(
        backgroundColor: BLUE_COLOR, // 기존의 앱바 색상
        title: Text('${widget.selectedDate.year}-${widget.selectedDate.month}-${widget.selectedDate.day}'),
        actions: [
          if (isTimerRunning) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: Icon(Icons.save, color: YELLOW_COLOR, size: 30.0),
                onPressed: onSavePressed,
              ),
            ),
          ],
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            if (isTimerRunning) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _formatTime(900 - elapsedSeconds),
                  style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: PRIMARY_COLOR),
                ),
              ),
              // 제목 입력란 추가
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextFormField(
                  controller: _titleController,
                  style: TextStyle(color: PRIMARY_COLOR),

                  decoration: InputDecoration(
                    labelText: '제목을 입력하세요',
                    labelStyle: const TextStyle(color: PRIMARY_COLOR),
                    fillColor: WHITE_COLOR, // 테두리 안쪽 배경색
                    filled: true, // 배경색 활성화
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13.0), // 둥근 테두리 설정
                      borderSide: const BorderSide(
                        color: PRIMARY_COLOR, // 테두리 색상
                      ),
                    ),
                  ),

                  onSaved: (val) => title = val,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return '제목을 입력해주세요.';
                    }
                    return null;
                  },
                ),
              ),

              // 이미지 슬라이드 공간
              if (_images.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    height: 200.0, // 이미지 크기
                    child: PageView.builder(
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        final image = _images[index];
                        return GestureDetector(
                          onTap: () => _viewImage(image),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 8.0),
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: FileImage(File(image.path)),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(13.0),
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: WHITE_COLOR,
                      border: Border.all( // 테두리 설정
                        color: PRIMARY_COLOR, // 테두리 색상
                        width: 2.0, // 테두리 두께
                      ),
                      borderRadius: BorderRadius.circular(13.0),
                    ),
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _controller,
                              maxLines: null,
                              style: TextStyle(color: PRIMARY_COLOR),
                              decoration: const InputDecoration(
                                labelText: '내용을 입력하세요',
                                labelStyle: TextStyle(color: PRIMARY_COLOR),
                                border: InputBorder.none,
                              ),
                              onSaved: (val) => content = val,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return '내용을 입력해주세요.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(height: 120.0), // 위쪽에 여백 추가
                      // 이미지 추가
                      Image.asset(
                        'assets/img/form.png', // 이미지 경로
                        width: 230.0,  // 이미지 크기 조절
                        height: 230.0, // 이미지 크기 조절
                      ),
                      SizedBox(height: 50.0), // 이미지와 버튼 사이의 간격
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DARK_PINK_COLOR, // 버튼 색상
                          padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 40.0), // 버튼 크기 조절
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0), // 둥근 모서리
                            side: BorderSide(color: PRIMARY_COLOR, width: 3.0), // 테두리 색상과 두께
                          ),
                        ),
                        onPressed: _startTimer,
                        child: Text(
                          "          일 기  작 성  시 작          ",
                          style: TextStyle(
                            fontSize: 18.0, // 글자 크기
                            fontWeight: FontWeight.bold, // 글자 굵기
                            color: PRIMARY_COLOR, // 글자 색상
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )


            ],
          ],
        ),
      ),
      floatingActionButton: isTimerRunning
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: PRIMARY_COLOR,  // 테두리 색상
              width: 2.0,  // 테두리 두께
            ),
            borderRadius: BorderRadius.circular(18.0), // 모서리 둥글게
          ),
          child: FloatingActionButton(
            onPressed: _pickImages,
            backgroundColor: YELLOW_COLOR,  // 배경 색상 변경
            child: const Icon(Icons.image, color: PRIMARY_COLOR),
          ),
        ),
      )
          : null,
    );
  }
}
