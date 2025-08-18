package com.focused_ai.services;

import com.focused_ai.apis.google.GoogleClassroomApi;
import com.focused_ai.mappers.CourseMapper;
import com.focused_ai.mappers.UserMapper;
import com.focused_ai.models.google.*;
import com.focused_ai.models.domain.*;

import lombok.RequiredArgsConstructor;
import reactor.core.publisher.Mono;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
public class GoogleClassroomService {

    private final Map<String, GoogleTokenData> googleTokenCache = new ConcurrentHashMap<>();

    private static class GoogleTokenData {
        private String accessToken;
        private String refreshToken;
        private long expiryTime; // epoch milliseconds

        public GoogleTokenData(String accessToken, String refreshToken, long expiresInSeconds) {
            this.accessToken = accessToken;
            this.refreshToken = refreshToken;
            this.expiryTime = System.currentTimeMillis() + (expiresInSeconds * 1000);
        }

        public boolean isExpired() {
            return System.currentTimeMillis() >= expiryTime;
        }

        public boolean willExpireSoon() {
            // Consider token expiring soon if it has less than 5 minutes left
            return (expiryTime - System.currentTimeMillis()) < (5 * 60 * 1000);
        }
    }

    @Value("${GOOGLE_CLIENT_ID}")
    private String googleClientId;

    @Value("${GOOGLE_CLIENT_SECRET}")
    private String googleClientSecret;

    private final WebClient webClient = WebClient.create();

    private final GoogleClassroomApi apiClient;

    @Autowired
    private CourseMapper courseMapper;

    @Autowired
    private UserMapper userMapper;

    private Map<String, String> exchangeAuthCode(String serverAuthCode) {
        try {
            // First, get raw response as string for debugging
            Map<String, Object> response = webClient.post()
                    .uri("https://oauth2.googleapis.com/token")
                    .header("Content-Type", "application/x-www-form-urlencoded")
                    .bodyValue(
                            "code=" + serverAuthCode +
                                    "&client_id=" + googleClientId +
                                    "&client_secret=" + googleClientSecret +
                                    "&redirect_uri=postmessage" +
                                    "&grant_type=authorization_code")
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();

            return Map.of(
                    "access_token", (String) response.get("access_token"),
                    "refresh_token", (String) response.get("refresh_token"),
                    "expires_in", String.valueOf(response.get("expires_in")));
        } catch (Exception e) {
            throw new RuntimeException("Failed to exchange auth code: " + e.getMessage());
        }
    }

    // Might get back to this, for now the user is logged out when their session
    // expires
    // private GoogleTokenData refreshToken(String refreshToken) {
    // try {
    // Map<String, Object> response = webClient.post()
    // .uri("https://oauth2.googleapis.com/token")
    // .header("Content-Type", "application/x-www-form-urlencoded")
    // .bodyValue(
    // "refresh_token=" + refreshToken +
    // "&client_id=" + googleClientId +
    // "&client_secret=" + googleClientSecret +
    // "&grant_type=refresh_token")
    // .retrieve()
    // .bodyToMono(Map.class)
    // .block();

    // long expiresIn = Long.parseLong(String.valueOf(response.get("expires_in")));
    // return new GoogleTokenData(
    // (String) response.get("access_token"),
    // refreshToken, // refresh token remains the same
    // expiresIn);
    // } catch (Exception e) {
    // throw new RuntimeException("Failed to refresh token: " + e.getMessage());
    // }
    // }

    // Modify the storeAccessToken method
    public void storeGoogleTokenData(String userId, GoogleTokenData tokenData) {
        googleTokenCache.put(userId, tokenData);
    }

    public Map<String, String> googleAuthenticate(String serverAuthCode, String userId) {
        Map<String, String> tokenResponse = exchangeAuthCode(serverAuthCode);
        String accessToken = tokenResponse.get("access_token");
        String refreshToken = tokenResponse.get("refresh_token");
        long expiresIn = Long.parseLong(tokenResponse.get("expires_in"));

        GoogleTokenData tokenData = new GoogleTokenData(accessToken, refreshToken, expiresIn);
        System.out.println("we got the access token: " + accessToken);
        String role = googleAuthorize(accessToken).block();
        System.out.println("we got the role " + role);

        storeGoogleTokenData(userId, tokenData);

        return Map.of(
                "role", role);
    }

    // public Mono<String> googleAuthorize(String accessToken) {
    // return apiClient.getUserProfile(accessToken)
    // .flatMap(userProfile -> {
    // return apiClient.getCourses(accessToken)
    // .flatMap(courseList -> {
    // if (courseList.getCourses() == null || courseList.getCourses().isEmpty()) {
    // return Mono.just("unknown");
    // }

    // String firstCourseId =
    // String.valueOf(courseList.getCourses().get(0).getId());

    // return apiClient.getCourseTeachers(firstCourseId, accessToken)
    // .flatMap(teacherList -> {
    // boolean isTeacher = teacherList.getTeachers().stream()
    // .anyMatch(
    // teacher -> teacher.getUserId().equals(userProfile.getId()));

    // if (isTeacher) {
    // return Mono.just("teacher");
    // }

    // return apiClient.getCourseStudents(firstCourseId, accessToken)
    // .map(studentList -> {
    // return studentList.getStudents().stream()
    // .anyMatch(student -> student.getUserId()
    // .equals(userProfile.getId()))
    // ? "student"
    // : "unknown";
    // });
    // });
    // });
    // });
    // }

    public Mono<String> googleAuthorize(String accessToken) {
        return apiClient.getUserProfile(accessToken)
                .flatMap(googleUserProfile -> {
                    UserProfile userProfile = userMapper.fromGoogle(googleUserProfile);
                    return determineUserRole(userProfile, accessToken);
                });
    }

    private Mono<String> determineUserRole(UserProfile userProfile, String accessToken) {
        return apiClient.getCourses(accessToken)
                .flatMap(googleCourseList -> {
                    CourseList courseList = courseMapper.fromGoogle(googleCourseList);

                    if (courseList.getCourses() == null || courseList.getCourses().isEmpty()) {
                        return Mono.just("unknown");
                    }

                    String firstCourseId = courseList.getCourses().get(0).getId();
                    return checkUserRoleInCourse(userProfile, firstCourseId, accessToken);
                });
    }

    private Mono<String> checkUserRoleInCourse(UserProfile userProfile, String courseId, String accessToken) {
        return apiClient.getCourseTeachers(courseId, accessToken)
                .flatMap(googleTeacherList -> {
                    TeacherList teacherList = userMapper.fromGoogle(googleTeacherList);

                    boolean isTeacher = teacherList.getTeachers().stream()
                            .anyMatch(teacher -> teacher.getUserId().equals(userProfile.getId()));

                    if (isTeacher) {
                        return Mono.just("teacher");
                    }

                    return apiClient.getCourseStudents(courseId, accessToken)
                            .map(googleStudentList -> {
                                StudentList studentList = userMapper.fromGoogle(googleStudentList);
                                boolean isStudent = studentList.getStudents().stream()
                                        .anyMatch(student -> student.getUserId().equals(userProfile.getId()));
                                return isStudent ? "student" : "unknown";
                            });
                });
    }

    public CourseList getCourses(String userId) {
        GoogleTokenData tokenData = googleTokenCache.get(userId);
        if (tokenData == null || tokenData.isExpired()) {
            throw new RuntimeException("No valid token found for user: " + userId);
        }

        GoogleCourseList googleCourseList = apiClient.getCourses(tokenData.accessToken).block();
        return courseMapper.fromGoogle(googleCourseList);
    }

    public StudentList getStudentsInCourse(String userId) {
    GoogleTokenData tokenData = googleTokenCache.get(userId);
    if (tokenData == null || tokenData.isExpired()) {
        throw new RuntimeException("No valid token found for user: " + userId);
    }

    GoogleStudentList googleStudentList = apiClient.getCourseStudents(userId, tokenData.accessToken).block();
    return userMapper.fromGoogle(googleStudentList);
}

public List<GoogleStudentSubmission> getStudentSubmissions(String userId, String courseId, String courseWorkId) {
    GoogleTokenData tokenData = googleTokenCache.get(userId);
    if (tokenData == null || tokenData.isExpired()) {
        throw new RuntimeException("No valid token found for user: " + userId);
    }

    GoogleStudentSubmissionList submissionList = apiClient
            .getStudentSubmissions(courseId, courseWorkId, tokenData.accessToken)
            .block();

    return submissionList != null && submissionList.getStudentSubmissions() != null
            ? submissionList.getStudentSubmissions()
            : List.of();
}

public List<GoogleCourseWork> getCourseWorkList(String userId, String courseId) {
    GoogleTokenData tokenData = googleTokenCache.get(userId);
    if (tokenData == null || tokenData.isExpired()) {
        throw new RuntimeException("No valid token for user: " + userId);
    }

    GoogleCourseWorkList courseWorkList = apiClient.getCourseWork(courseId, tokenData.accessToken).block();
    return courseWorkList != null ? courseWorkList.getCourseWork() : List.of();
}

public List<Grade> fetchQuizGrades(String userId, String courseId) {
    GoogleTokenData tokenData = googleTokenCache.get(userId);
    if (tokenData == null || tokenData.isExpired()) {
        throw new RuntimeException("No valid token found for user: " + userId);
    }

    String accessToken = tokenData.accessToken;

    GoogleCourseWorkList courseworkList = apiClient.getCourseWork(courseId, accessToken).block();
    if (courseworkList == null || courseworkList.getCourseWork() == null) {
        return List.of(); // no coursework
    }

    List<Grade> grades = new ArrayList<>();

    for (GoogleCourseWork work : courseworkList.getCourseWork()) {
        String workType = work.getWorkType();
        String title = work.getTitle();
        String courseWorkId = work.getId();

        // Only consider quizzes or coursework that looks like a quiz
        if (!"MULTIPLE_CHOICE_QUESTION".equals(workType) &&
            (title == null || !title.toLowerCase().contains("quiz"))) {
            continue;
        }

        GoogleStudentSubmissionList submissions =
                apiClient.getStudentSubmissions(courseId, courseWorkId, accessToken).block();

        if (submissions == null || submissions.getStudentSubmissions() == null) {
            continue;
        }

        for (GoogleStudentSubmission sub : submissions.getStudentSubmissions()) {
            if (sub.getAssignedGrade() != null && sub.getUserId() != null) {
                Grade grade = new Grade();
                grade.setStudentId(sub.getUserId());
                grade.setAssignmentTitle(title != null ? title : "Quiz");
                grade.setGrade(sub.getAssignedGrade().doubleValue());
                grades.add(grade);
            }
        }
    }

    return grades;
}



} 