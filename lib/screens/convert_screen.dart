import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class ConvertScreen extends StatefulWidget {
  const ConvertScreen({super.key});

  @override
  _ConvertScreenState createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  final TextEditingController _controller = TextEditingController();
  Video? _video;
  bool _isLoading = false;
  bool _isDownloading = false;
  final YoutubeExplode _youtubeExplode = YoutubeExplode();

  Future<void> _fetchVideoDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = _controller.text.trim();
      final videoId = _extractVideoId(url);
      if (videoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid YouTube URL')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final video = await _youtubeExplode.videos.get(VideoId(videoId));
      setState(() {
        _video = video;
      });
    } catch (e) {
      print('Failed to fetch video details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch video details')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> requestStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted ||
        await Permission.storage.isGranted) return true;

    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  Future<void> downloadMp3FromNode(String videoUrl) async {
    try {
      final uri = Uri.parse("http://192.168.29.48:3000/download");
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"url": videoUrl}),
      );

      if (response.statusCode == 200) {
        // 📁 Save to app-private directory (no permission needed)
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/${_video?.title}.mp3';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        print("✅ Audio saved to: $filePath");

        final hasPermission = await requestStoragePermission();
        if (!hasPermission) {
          print("❌ Storage permission not granted");
          return;
        }

        final dir1 = Directory('/storage/emulated/0/Download');
        String? formattedTitle = _video?.title.replaceAll(' ', '');
        formattedTitle = formattedTitle?.replaceAll(',', '');
        formattedTitle = formattedTitle?.replaceAll('|', '');
        formattedTitle = formattedTitle?.replaceAll('-', '');
        formattedTitle = formattedTitle?.replaceAll('.', '');
        formattedTitle = formattedTitle?.replaceAll(':', '');
        final filePath1 = '${dir1.path}/${formattedTitle}.mp3';
        final file1 = File(filePath1);
        await file1.writeAsBytes(response.bodyBytes);
        print("✅ File saved to: $filePath1");
      } else {
        print("❌ Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Download error: $e");
    }
  }

  String? _extractVideoId(String url) {
    final uri = Uri.parse(url);
    if (uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v'];
    } else if (uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.greenAccent, Colors.cyanAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 40),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter YouTube Video URL',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                FocusScope.of(context).unfocus();
                _fetchVideoDetails();
              },
              icon: Icon(Icons.search),
              label: Text('search'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading) const CircularProgressIndicator(),
            if (_video != null) ...[
              Image.network(_video!.thumbnails.highResUrl),
              Text(_video!.title),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isDownloading
                    ? null
                    : () => downloadMp3FromNode(_controller.text.trim()),
                child: _isDownloading
                    ? const CircularProgressIndicator()
                    : const Text('Download in MP3'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _youtubeExplode.close();
    super.dispose();
  }
}
