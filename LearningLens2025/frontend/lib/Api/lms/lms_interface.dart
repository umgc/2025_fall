import 'dart:io';

import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/grade.dart';
import 'package:learninglens_app/beans/moodle_rubric.dart';
import 'package:learninglens_app/beans/override.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/quiz_override';
import 'package:learninglens_app/beans/quiz_type.dart';
import 'package:learninglens_app/beans/submission.dart';
import 'package:learninglens_app/beans/submission_status.dart';
import 'package:learninglens_app/beans/submission_with_grade.dart';

enum UserRole { teacher, student }

// Singleton interface class for API access.
abstract class LmsInterface {
  late String serverUrl;

  // User info
  late String apiURL;
  String? userName;
  String? firstName;
  String? lastName;
  String? siteName;
  String? fullName;
  String? profileImage;
  List<Course>? courses;
  UserRole? role;
  List<Override>? overrides;

  // Authentication/Login methods
  Future<void> login(String username, String password, String baseURL);
  bool isLoggedIn();
  Future<UserRole> getUserRole();
  Future<bool> isUserTeacher(List<Course> moodleCourses);
  void logout();
  void resetLMSUserInfo();

  // Course methods
  Future<List<Course>> getCourses();
  Future<List<Course>> getUserCourses();
  Future<List<Participant>> getCourseParticipants(String courseId);

  // Quiz methods
  Future<void> importQuiz(String courseid, String quizXml);
  Future<List<Quiz>> getQuizzes(int? courseID, {int? topicId});
  Future<int?> createQuiz(String courseid, String quizname, String quizintro,
      String sectionid, String timeopen, String timeclose);
  Future<String> addRandomQuestions(
      String categoryid, String quizid, String numquestions);
  Future<int?> importQuizQuestions(String courseid, String quizXml);
  Future<List<QuestionType>> getQuestionsFromQuiz(int quizId);

  // Assignment methods
  Future<List<Assignment>> getEssays(int? courseID, {int? topicId});
  Future<Map<String, dynamic>?> createAssignment(
      String courseid,
      String sectionid,
      String assignmentName,
      String startdate,
      String enddate,
      String rubricJson,
      String description);
  Future<int?> getContextId(int assignmentId, String courseId);

  // Submission and grading methods
  Future<List<Submission>> getAssignmentSubmissions(int assignmentId);
  Future<List<SubmissionWithGrade>> getSubmissionsWithGrades(int assignmentId);
  Future<SubmissionStatus?> getSubmissionStatus(int assignmentId, int userId);
  Future<List<Grade>> getAssignmentGrades(int assignmentId);
  Future<bool> setRubricGrades(int assignmentId, int userId, String jsonGrades);
  Future<List<dynamic>> getRubricGrades(int assignmentId, int userid);
  Grade? findGradeForUser(List<Grade> grades, int userId);

  // Rubric methods
  Future<MoodleRubric?> getRubric(String assignmentid);

  // Analytics
  Future<List<Participant>> getQuizGradesForParticipants(
      String courseId, int quizId);
  Future<dynamic> getQuizStatsForStudent(String quizId, int userId);
  Future<List<Participant>> getEssayGradesForParticipants(
      String courseId, int essayId);

  // Sumbit Essay Draft
  Future<int> uploadFileToDraft({
    required File file,
    required int contextId,
  });
  Future<void> appendFileToDraft({
    required File file,
    required int contextId,
    required int draftItemId,
  });
  Future<void> saveAssignmentSubmissionOnlineText({
    required int assignId,
    required String text,
    int format = 1,
    int? draftItemId,
  });

  Future<void> saveAssignmentSubmissionFiles({
    required int assignId,
    required int draftItemId,
  });

  Future<void> refreshOverrides();

  Future<void> submitAssignmentForGrading({
    required int assignId,
    bool acceptSubmissionStatement,
  });
  Future<Map<String, dynamic>> getSubmissionStatusRaw({
    required int assignId,
    int? forUserId,
  }) {
    throw UnimplementedError();
  }

  Future<List<Map<String, dynamic>>> getSubmissionAttachments(
      {required int assignId}) {
    throw UnimplementedError();
  }

  Future<QuizOverride> addQuizOverride(
      {required int quizId,
      int? userId,
      int? groupId,
      int? timeOpen,
      int? timeClose,
      int? timeLimit,
      int? attempts,
      String? password,
      int? courseId});

  Future<String> addEssayOverride(
      {required int assignid,
      int? userId,
      int? groupId,
      int? allowsubmissionsfromdate,
      int? dueDate,
      int? cutoffDate,
      int? timelimit,
      int? sortorder,
      int? courseId});
}
