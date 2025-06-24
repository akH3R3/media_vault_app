import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'play_screen.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  _DownloadScreenState createState() => _DownloadScreenState();
}

const String apiKey = 'AIzaSyDN86d06XpcdFxapGQiMV8Hbv8wmIeTvAc';

class _DownloadScreenState extends State<DownloadScreen> {
  List<FileSystemEntity> _mediaFiles = [];
  String summary = '';
  String _transcribedText = "";
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadDownloadedMedia();
  }

  Future<void> _loadDownloadedMedia() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();

    setState(() {
      _mediaFiles = files.where((file) {
        return file.path.endsWith('.mp3');
      }).toList();
    });
  }

  void _playMedia(FileSystemEntity file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayScreen(file: file),
      ),
    );
  }

  void shareFile(String filePath) {
    SharePlus.instance.share(
      ShareParams(files: [XFile(filePath)], text: 'Check out this file!'),
    );
  }

  void showVideoOptions(BuildContext context, String filePath) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  shareFile(filePath);
                },
              ),
              ListTile(
                leading: const Icon(Icons.summarize),
                title: const Text('Summarize'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadAudio(File(filePath));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> summarizeText(String input) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
    final content = [Content.text('Summarize this:\n$input')];

    try {
      final response = await model.generateContent(content);
      setState(() {
        summary = response.text ?? 'No response';
      });
    } catch (e) {
      setState(() {
        summary = 'Error: $e';
      });
    }
  }

  Future<void> _pickAndUploadAudio(File file) async {

      File audioFile = file;
      String fileName = path.basename(audioFile.path);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.29.48:8000/transcribe'), // replace with IP if on physical device
      );

      request.files.add(await http.MultipartFile.fromPath('file', audioFile.path, filename: fileName));

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final decoded = jsonDecode(responseData);

        setState(() {
          _transcribedText = decoded["text"] ?? "No text returned.";
        });
      } else {
        setState(() {
          _transcribedText = "Failed to transcribe. Status code: ${response.statusCode}";
        });
      }
    await summarizeText('Summarize this: $_transcribedText');
    print('🌟');
    print(summary);
    _convertTextToSpeech(summary,fileName);
  }

  Future<void> _convertTextToSpeech(String textToConvert, String name) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.29.48:8000/speak'), // Use your actual backend IP
    );

    request.fields['text'] = textToConvert;

    var response = await request.send();

    if (response.statusCode == 200) {
      final bytes = await response.stream.toBytes();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/summarized_$name.mp3');
      await file.writeAsBytes(bytes);
      print('❤️');
      print(file);

      await player.play(DeviceFileSource(file.path));
    } else {
      print("TTS failed: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _mediaFiles.isEmpty
          ? const Center(child: Text('No downloaded media found'))
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.greenAccent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: ListView.builder(
                    itemCount: _mediaFiles.length,
                    itemBuilder: (context, index) {
                      final file = _mediaFiles[index];
                      return ListTile(
                        leading: Icon(file.path.endsWith('.mp4')
                            ? Icons.video_library
                            : Icons.audiotrack),
                        trailing: IconButton(onPressed: (){
                          showVideoOptions(context,file.path);
                        }, icon: Icon(Icons.more_vert)),
                        title: Text(file.path.split('/').last, maxLines: 2, overflow: TextOverflow.ellipsis,),
                        onTap: () => _playMedia(file),
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }
}
