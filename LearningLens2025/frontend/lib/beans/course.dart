import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/learning_lens_interface.dart';
import 'package:learninglens_app/beans/quiz.dart';

class Course implements LearningLensInterface {
  int id;
  String shortName;
  String fullName;
  DateTime startdate;
  DateTime enddate;
  String courseId;
  String? teacherFolderId;
  String? subject;

  List<Quiz>? get quizzes => _quizzes;
  List<Assignment>? get essays => _essays;

  List<Quiz>? _quizzes;
  List<Assignment>? _essays;
  int? quizTopicId;
  int? essayTopicId;

  Course(this.id, this.shortName, this.courseId, this.fullName, this.startdate,
      this.enddate,
      {this.teacherFolderId, this.subject});

  Course.empty()
      : id = 0,
        shortName = '',
        courseId = '',
        fullName = '',
        startdate = DateTime.now(),
        enddate = DateTime.now(),
        teacherFolderId = '',
        subject = null,
        _quizzes = null,
        _essays = null;

  static String dateFormatted(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Course fromMoodleJson(Map<String, dynamic> json) {
    return Course(
      json['id'],
      json['shortname'] ?? '',
      json['idnumber'] ?? '',
      json['fullname'] ?? '',
      DateTime.fromMillisecondsSinceEpoch(json['startdate'] * 1000),
      DateTime.fromMillisecondsSinceEpoch(json['enddate'] * 1000),
      subject: json['subject'] ?? 'General',
    );
  }

  @override
  Course fromGoogleJson(Map<String, dynamic> json) {
    // TODO: Figure out an end date.
    dynamic teacherFolder = json['teacherFolder'];

    print(json);
    return Course(
      int.parse(json['id']),
      json['name'],
      json['section'],
      json['name'],
      DateTime.parse(json['creationTime']),
      DateTime.parse(json['updateTime']).add(Duration(days: 180)),
      // teacherFolder is null if the logged in user is a student
      teacherFolderId: teacherFolder != null ? teacherFolder['id'] : '',
    );
  }

  @override
  String toString() {
    return "$shortName ($fullName) $id";
  }

  Future<void> refreshQuizzes() async {
    _quizzes =
        await LmsFactory.getLmsService().getQuizzes(id, topicId: quizTopicId);
  }

  Future<void> refreshEssays() async {
    _essays =
        await LmsFactory.getLmsService().getEssays(id, topicId: essayTopicId);
  }
}
