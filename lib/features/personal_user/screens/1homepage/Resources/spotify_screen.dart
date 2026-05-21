import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:shimmer/shimmer.dart';

class SpotifyPlayerScreen extends StatefulWidget {
  final String playlistId;

  const SpotifyPlayerScreen({super.key, required this.playlistId});

  @override
  State<SpotifyPlayerScreen> createState() => _SpotifyPlayerScreenState();
}

class _SpotifyPlayerScreenState extends State<SpotifyPlayerScreen> with SingleTickerProviderStateMixin {
  late final WebViewController _webviewController;
  bool _isLoading = true;
  bool _isPlaying = false;
  int _currentTrackIndex = 0;
  
  // Rotation animation for the Vinyl/Album art
  late AnimationController _rotationController;

  // Curated list of high-quality relaxation YouTube tracks
  final List<RelaxTrack> _tracks = [
    RelaxTrack(
      id: 'UfcAVejsrTI',
      title: 'Weightless (Scientific Calm)',
      artist: 'Marconi Union',
      category: 'Anxiety Relief',
      imageUrl: 'https://images.unsplash.com/photo-1518241353330-0f7941c2d9b5?q=80&w=300&auto=format&fit=crop',
    ),
    RelaxTrack(
      id: 'tNkZsSP7560',
      title: 'Zen Flute Meditation',
      artist: 'Traditional Flutes',
      category: 'Mindfulness',
      imageUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=300&auto=format&fit=crop',
    ),
    RelaxTrack(
      id: 'mPZkdNFkNps',
      title: 'Soft Rain & Thunderstorm',
      artist: 'Nature Soundscapes',
      category: 'Deep Sleep',
      imageUrl: 'https://images.unsplash.com/photo-1534274988757-a28bf1a57c17?q=80&w=300&auto=format&fit=crop',
    ),
    RelaxTrack(
      id: '5qap5aO4i9A',
      title: 'Calming Ambient Lofi',
      artist: 'Study & Rest Beats',
      category: 'ADHD & Focus',
      imageUrl: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?q=80&w=300&auto=format&fit=crop',
    ),
    RelaxTrack(
      id: 'Q5dU6serXkg',
      title: 'Tibetan Singing Bowls',
      artist: 'Frequency Healing',
      category: 'Grounding',
      imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=300&auto=format&fit=crop',
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    // Determine initial track based on incoming playlistId
    if (widget.playlistId == '48HRfQBhsPP0Wm07AUpfHA') {
      _currentTrackIndex = 1; // Zen Flute for Depression
    } else if (widget.playlistId == '3n9e5pXW7kb3SDgvaxgvnL') {
      _currentTrackIndex = 2; // Nature Rain for Self Harm
    } else {
      _currentTrackIndex = 0; // Weightless for Anxiety (default)
    }

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _webviewController = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setOnConsoleMessage((JavaScriptConsoleMessage consoleMessage) {
        debugPrint('== SPOTIFY WEBVIEW JS == ${consoleMessage.level.name}: ${consoleMessage.message}');
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            debugPrint('== SPOTIFY WEBVIEW ERROR ==: ${error.description} (code: ${error.errorCode})');
          },
          onPageFinished: (_) {
            debugPrint('== SPOTIFY WEBVIEW PAGE FINISHED ==');
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('== SPOTIFY WEBVIEW CHANNEL MESSAGE ==: ${message.message}');
          try {
            final Map<String, dynamic> data = jsonDecode(message.message);
            final String? event = data['event'];
            if (event == 'ready') {
              setState(() {
                _isLoading = false;
                _isPlaying = true;
                _rotationController.repeat();
              });
            } else if (event == 'stateChange') {
              final int? state = data['state'];
              if (state == 1) { // PLAYING
                setState(() {
                  _isLoading = false;
                  _isPlaying = true;
                  _rotationController.repeat();
                });
              } else if (state == 2 || state == 0) { // PAUSED or ENDED
                setState(() {
                  _isPlaying = false;
                  _rotationController.stop();
                });
              }
            } else if (event == 'error') {
              setState(() {
                _isLoading = false;
              });
            }
          } catch (e) {
            debugPrint('== Error parsing channel message ==: $e');
          }
        },
      );

    if (_webviewController.platform is AndroidWebViewController) {
      (_webviewController.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    final initialHtml = _buildPlayerHtml(_tracks[_currentTrackIndex].id);
    _webviewController.loadHtmlString(initialHtml, baseUrl: 'https://www.youtube-nocookie.com');
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  String _buildPlayerHtml(String initialVideoId) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    body, html { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background-color: #000; }
    #player { width: 100%; height: 100%; border: none; }
  </style>
</head>
<body>
  <div id="player"></div>
  <script>
    var tag = document.createElement('script');
    tag.src = "https://www.youtube.com/iframe_api";
    var firstScriptTag = document.getElementsByTagName('script')[0];
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

    var player;
    var currentVideoId = '$initialVideoId';
    var isReady = false;

    function onYouTubeIframeAPIReady() {
      console.log("YT API Loading...");
      player = new YT.Player('player', {
        height: '100%',
        width: '100%',
        videoId: currentVideoId,
        host: 'https://www.youtube-nocookie.com',
        playerVars: {
          'playsinline': 1,
          'autoplay': 1,
          'controls': 0,
          'rel': 0,
          'showinfo': 0,
          'mute': 0,
          'loop': 1,
          'origin': 'https://www.youtube-nocookie.com',
          'playlist': currentVideoId
        },
        events: {
          'onReady': onPlayerReady,
          'onStateChange': onPlayerStateChange,
          'onError': onPlayerError
        }
      });
    }

    function onPlayerReady(event) {
      console.log("Player Ready");
      isReady = true;
      if (window.FlutterChannel) {
        window.FlutterChannel.postMessage(JSON.stringify({event: 'ready'}));
      }
      
      // Auto-play attempt
      event.target.playVideo();
      
      // Safety check: if autoplay is blocked, mute, play, and unmute
      setTimeout(function() {
        if (player.getPlayerState() !== 1) {
          console.log("Autoplay blocked. Retrying with mute-unmute cycle...");
          player.mute();
          player.playVideo();
          setTimeout(function() {
            player.unMute();
            player.playVideo();
            console.log("Unmuted playback active.");
          }, 300);
        }
      }, 500);
    }

    function onPlayerStateChange(event) {
      console.log("Player State Change: " + event.data);
      if (event.data === YT.PlayerState.ENDED) {
        player.playVideo(); // Loop support
      }
      if (window.FlutterChannel) {
        window.FlutterChannel.postMessage(JSON.stringify({event: 'stateChange', state: event.data}));
      }
    }

    function onPlayerError(event) {
      console.error("Player Error: " + event.data);
      if (window.FlutterChannel) {
        window.FlutterChannel.postMessage(JSON.stringify({event: 'error', error: event.data}));
      }
    }

    function playVideo() {
      console.log("Play commanded");
      if (player) {
        player.playVideo();
        setTimeout(function() {
          if (player.getPlayerState() !== 1) {
            console.log("Play failed. Running mute-unmute bypass...");
            player.mute();
            player.playVideo();
            setTimeout(function() {
              player.unMute();
              player.playVideo();
            }, 300);
          }
        }, 300);
      }
    }

    function pauseVideo() {
      console.log("Pause commanded");
      if (player) {
        player.pauseVideo();
      }
    }

    function loadVideo(videoId) {
      console.log("Loading Video: " + videoId);
      currentVideoId = videoId;
      if (player) {
        player.loadVideoById({
          videoId: videoId,
          suggestedQuality: 'small'
        });
        // Wait and ensure it plays
        setTimeout(playVideo, 300);
      }
    }
  </script>
</body>
</html>
''';
  }

  void _loadTrack(int index, {required bool autoPlay}) {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentTrackIndex = index;
      _isLoading = true;
      _isPlaying = autoPlay;
    });

    if (autoPlay) {
      _rotationController.repeat();
      _webviewController.runJavaScript('loadVideo("${_tracks[index].id}");');
    } else {
      _rotationController.stop();
      _webviewController.runJavaScript('loadVideo("${_tracks[index].id}"); pauseVideo();');
    }
  }

  void _togglePlay() {
    HapticFeedback.mediumImpact();
    if (_isPlaying) {
      _webviewController.runJavaScript('pauseVideo();');
      setState(() {
        _isPlaying = false;
        _rotationController.stop();
      });
    } else {
      _webviewController.runJavaScript('playVideo();');
      setState(() {
        _isPlaying = true;
        _rotationController.repeat();
      });
    }
  }

  void _playNext() {
    final nextIndex = (_currentTrackIndex + 1) % _tracks.length;
    _loadTrack(nextIndex, autoPlay: true);
  }

  void _playPrev() {
    final prevIndex = _currentTrackIndex == 0 ? _tracks.length - 1 : _currentTrackIndex - 1;
    _loadTrack(prevIndex, autoPlay: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTrack = _tracks[_currentTrackIndex];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        elevation: 0,
        title: const Text('Relaxation Music'),
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Covered onscreen WebView for streaming
          Positioned(
            left: 50,
            top: 50,
            width: 200,
            height: 200,
            child: WebViewWidget(controller: _webviewController),
          ),
          
          Positioned.fill(
            child: Container(
              color: isDark ? AppColors.darkBackground : AppColors.background,
              child: Column(
                children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      
                      // Rotating Disk / Album Art
                      Center(
                        child: RotationTransition(
                          turns: _rotationController,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer black record border
                              Container(
                                width: 230,
                                height: 230,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                              ),
                              // Grooves representation
                              Container(
                                width: 210,
                                height: 210,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white12, width: 2),
                                ),
                              ),
                              Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white10, width: 2),
                                ),
                              ),
                              // Album Center Art
                              ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  color: isDark ? AppColors.darkSurface : AppColors.white,
                                  child: Image.network(
                                    currentTrack.imageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return Shimmer.fromColors(
                                        baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
                                        highlightColor: isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight,
                                        child: Container(color: Colors.white),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      CupertinoIcons.music_note,
                                      size: 40,
                                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              // Center Hole
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? AppColors.darkBackground : AppColors.background,
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Track Info
                      Text(
                        currentTrack.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currentTrack.artist,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          currentTrack.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Custom controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              CupertinoIcons.backward_fill,
                              size: 28,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                            onPressed: _playPrev,
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: _togglePlay,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            icon: Icon(
                              CupertinoIcons.forward_fill,
                              size: 28,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                            onPressed: _playNext,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Track list header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'UP NEXT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Scrollable track list
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _tracks.length,
                        itemBuilder: (context, index) {
                          final track = _tracks[index];
                          final isSelected = index == _currentTrackIndex;
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: InkWell(
                              onTap: () => _loadTrack(index, autoPlay: true),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? AppColors.darkPrimaryLight.withValues(alpha: 0.5) : AppColors.primaryLight.withValues(alpha: 0.5))
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.3)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: Image.network(
                                          track.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: isDark ? AppColors.darkSurface : AppColors.primaryLight,
                                            child: const Icon(CupertinoIcons.music_note, size: 20),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            track.title,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              color: isSelected
                                                  ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                                                  : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            track.artist,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected && _isPlaying)
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                        ),
                                      )
                                    else
                                      Icon(
                                        CupertinoIcons.play_circle,
                                        size: 20,
                                        color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
                ],
              ),
            ),
          ),
          
          // Shimmer loading overlay for track loading state
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: isDark ? AppColors.darkBackground.withValues(alpha: 0.8) : AppColors.background.withValues(alpha: 0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Connecting safe stream...',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RelaxTrack {
  final String id;
  final String title;
  final String artist;
  final String category;
  final String imageUrl;

  RelaxTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.category,
    required this.imageUrl,
  });
}
