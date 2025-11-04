class SkeletonStreamConfig {
  final String mqttUsername;
  final String mqttPassword;
  final String wssUrl;
  final int groupId;
  final String serialNumber;
  final int streamToken;
  final String publishTopic;
  final String subscribeTopic;

  SkeletonStreamConfig({
    required this.mqttUsername,
    required this.mqttPassword,
    required this.wssUrl,
    required this.groupId,
    required this.serialNumber,
    required this.streamToken,
    required this.publishTopic,
    required this.subscribeTopic,
  });

  factory SkeletonStreamConfig.fromJson(Map<String, dynamic> json) {
    return SkeletonStreamConfig(
      mqttUsername: json['mqttUsername'],
      mqttPassword: json['mqttPassword'],
      wssUrl: json['wssUrl'],
      groupId: json['groupId'],
      serialNumber: json['serialNumber'],
      streamToken: json['streamToken'],
      publishTopic: json['publishTopic'],
      subscribeTopic: json['subscribeTopic'],
    );
  }
}
