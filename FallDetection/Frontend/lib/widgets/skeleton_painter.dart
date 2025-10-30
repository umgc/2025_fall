// lib/widgets/skeleton_painter.dart
import 'package:flutter/material.dart';
import '../models/skeleton_frame.dart';

class SkeletonPainter extends CustomPainter {
  final SkeletonFrame? frame;
  
  // OpenPose 18-keypoint skeleton connections
  // 0: Nose, 1: Neck
  // 2-4: Right arm (RShoulder, RElbow, RWrist)
  // 5-7: Left arm (LShoulder, LElbow, LWrist)
  // 8-10: Right leg (RHip, RKnee, RAnkle)
  // 11-13: Left leg (LHip, LKnee, LAnkle)
  // 14-15: Eyes (REye, LEye)
  // 16-17: Ears (REar, LEar)
  static const List<List<int>> connections = [
    // Face
    [0, 1],                   // nose to neck
    [0, 14], [0, 15],         // nose to eyes
    [14, 16], [15, 17],       // eyes to ears
    
    // Upper body
    [1, 2], [1, 5],           // neck to shoulders
    [2, 3], [3, 4],           // right arm
    [5, 6], [6, 7],           // left arm
    
    // Torso
    [1, 8], [1, 11],          // neck to hips
    [8, 11],                  // hips
    
    // Lower body
    [8, 9], [9, 10],          // right leg
    [11, 12], [12, 13],       // left leg
  ];

  SkeletonPainter(this.frame);

  @override
  void paint(Canvas canvas, Size size) {
    if (frame == null || frame!.people.isEmpty) {
      return;
    }

    final linePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (var person in frame!.people) {
      // Coordinates are already normalized 0.0-1.0 from AltumView
      // Just multiply by canvas dimensions
      
      // Draw connections
      for (var connection in connections) {
        if (connection[0] >= person.length || connection[1] >= person.length) {
          continue; // Skip invalid connections
        }
        
        final p1 = person[connection[0]];
        final p2 = person[connection[1]];
        
        // Skip if either keypoint is missing (0, 0)
        if (p1.x == 0 && p1.y == 0) continue;
        if (p2.x == 0 && p2.y == 0) continue;
        
        // Convert normalized coordinates (0-1) to canvas pixels
        final x1 = p1.x * size.width;
        final y1 = p1.y * size.height;
        final x2 = p2.x * size.width;
        final y2 = p2.y * size.height;
        
        canvas.drawLine(
          Offset(x1, y1),
          Offset(x2, y2),
          linePaint,
        );
      }

      // Draw keypoints
      for (var keypoint in person) {
        // Skip missing keypoints (0, 0)
        if (keypoint.x == 0 && keypoint.y == 0) continue;
        
        // Convert normalized coordinates (0-1) to canvas pixels
        final x = keypoint.x * size.width;
        final y = keypoint.y * size.height;
        
        canvas.drawCircle(Offset(x, y), 6, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(SkeletonPainter oldDelegate) => true;
}