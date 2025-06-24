import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_vault/models/video.dart';
import 'package:media_vault/screens/convert_screen.dart';
import 'package:media_vault/screens/download_screen.dart';
import 'package:media_vault/youtube_data_api.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SearchScreenContent(),
    const ConvertScreen(),
    const DownloadScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Convert',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: 'Download',
          ),
        ],
      ),
    );
  }
}

class SearchScreenContent extends StatefulWidget {
  const SearchScreenContent({super.key});

  @override
  _SearchScreenContentState createState() => _SearchScreenContentState();
}

class _SearchScreenContentState extends State<SearchScreenContent> {
  final YoutubeDataApi _youtubeDataApi = YoutubeDataApi();
  final TextEditingController _controller = TextEditingController();
  List<Video> _videos = [];
  bool _isLoading = false;

  void _searchVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      const apiKey = 'AIzaSyAEcsjbv7bmgIkrYAwCpLghxDNXuvu8zjQ';
      final query = _controller.text;
      final videos =
          await _youtubeDataApi.fetchSearchVideo(query, apiKey, maxResults: 69);
      setState(() {
        _videos = videos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch search results')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(
                    left: 30, right: 30, top: 30, bottom: 20),
                child: Container(
                  color: Colors.white,
                  child: TextField(
                    autocorrect: true,
                    textAlign: TextAlign.justify,
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Search for YouTube Videos here...",
                      hintStyle: TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
              ElevatedButton.icon(
              onPressed: _searchVideos,
              icon: Icon(Icons.search),
              label: Text('search'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
              const SizedBox(height: 18),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _videos.length,
                        itemBuilder: (context, index) {
                          final video = _videos[index];
                          return ListTile(
                            leading: video.thumbnailUrl != null
                                ? Image.network(
                                    video.thumbnailUrl!,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.broken_image);
                                    },
                                  )
                                : const Icon(Icons.broken_image),
                            title: Text(video.title ?? 'No title',maxLines: 1,
                              overflow: TextOverflow.ellipsis,),
                            subtitle:
                                Text(video.channelName ?? 'No channel name',maxLines: 1,
                                  overflow: TextOverflow.ellipsis,),
                            onTap: () {
                              String vidUrl = "https://youtu.be/${video.id}";
                              print('Video URL: $vidUrl');
                              Clipboard.setData(ClipboardData(text: vidUrl ?? ''));
                            },
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
