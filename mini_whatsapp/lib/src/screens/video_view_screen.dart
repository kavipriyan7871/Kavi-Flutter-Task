import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoViewScreen extends StatefulWidget {
  final String videoUrl;

  const VideoViewScreen({super.key, required this.videoUrl});

  @override
  State<VideoViewScreen> createState() => _VideoViewScreenState();
}

class _VideoViewScreenState extends State<VideoViewScreen> {
  late VideoPlayerController videoController;
  ChewieController? chewieController;

  @override
  void initState() {
    super.initState();
    videoController = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        chewieController = ChewieController(
          videoPlayerController: videoController,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          allowPlaybackSpeedChanging: true,
        );
        setState(() {});
      });
  }

  @override
  void dispose() {
    videoController.dispose();
    chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: chewieController != null
            ? Chewie(controller: chewieController!)
            : const CircularProgressIndicator(),
      ),
    );
  }
}
