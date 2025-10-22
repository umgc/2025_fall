import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/theme/app_theme.dart';
import 'package:camera/camera.dart';

class VideoWidget extends StatefulWidget{
  ///TODO: Figure out what a key is in this context and add it.
  const VideoWidget({super.key});
  @override
  State<VideoWidget> createState() => VideoWidgetState();
}

class VideoWidgetState extends State<VideoWidget>
{
  late CameraController controller;
  late Future<void> controllerFuture;

  @override
  void initState() {
    super.initState();

    //controller = CameraController(widget.camera, ResolutionPreset.medium);
    controllerFuture = controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return  Container(
      alignment: Alignment.center,
      height: 50,
      width: 50,
      child: Text("This is the Video Widget"),
    );
  }

}