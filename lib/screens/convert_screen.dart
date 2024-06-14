import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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

  Future<void> _downloadFile(String videoId) async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(videoId);
      final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
      final audioStream = _youtubeExplode.videos.streamsClient.get(audioStreamInfo);

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${_video?.title ?? 'audio'}.mp3';
      final file = File(filePath);
      final output = file.openWrite(mode: FileMode.writeOnlyAppend);

      await audioStream.pipe(output);
      await output.flush();
      await output.close();

      // Check if file exists
      final fileExists = await file.exists();
      if (fileExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File downloaded to: $filePath')),
        );
      } else {
        print('File does not exist at: $filePath');
      }
    } catch (e) {
      print('Error downloading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Convert Screen')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter YouTube Video URL',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchVideoDetails,
              child: const Text('Fetch Video Details'),
            ),
            const SizedBox(height: 16),
            if (_isLoading) const CircularProgressIndicator(),
            if (_video != null) ...[
              Image.network(_video!.thumbnails.highResUrl),
              Text(_video!.title),
              ElevatedButton(
                onPressed: _isDownloading
                    ? null
                    : () => _downloadFile(_video!.id.value),
                child: _isDownloading
                    ? const CircularProgressIndicator()
                    : const Text('Download MP3'),
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
