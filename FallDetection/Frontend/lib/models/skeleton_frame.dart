class SkeletonKeypoint {
  final double x;
  final double y;

  SkeletonKeypoint(this.x, this.y);

  factory SkeletonKeypoint.fromJson(Map<String, dynamic> json) {
    return SkeletonKeypoint(
      (json['x'] ?? 0.0).toDouble(),
      (json['y'] ?? 0.0).toDouble(),
    );
  }

  factory SkeletonKeypoint.fromList(List<dynamic> list) {
    if (list.length >= 2) {
      return SkeletonKeypoint(
        (list[0] ?? 0.0).toDouble(),
        (list[1] ?? 0.0).toDouble(),
      );
    }
    return SkeletonKeypoint(0.0, 0.0);
  }
}

class SkeletonFrame {
  final List<List<SkeletonKeypoint>> people;

  SkeletonFrame(this.people);

  factory SkeletonFrame.fromJson(Map<String, dynamic> json) {
    List<List<SkeletonKeypoint>> peopleList = [];
    
    if (json['people'] != null) {
      for (var person in json['people']) {
        List<SkeletonKeypoint> keypoints = [];
        if (person is List) {
          for (var kp in person) {
            if (kp is List && kp.length >= 2) {
              keypoints.add(SkeletonKeypoint.fromList(kp));
            } else if (kp is Map) {
              keypoints.add(SkeletonKeypoint.fromJson(kp as Map<String, dynamic>));
            }
          }
        }
        if (keypoints.isNotEmpty) {
          peopleList.add(keypoints);
        }
      }
    }
    
    return SkeletonFrame(peopleList);
  }
}