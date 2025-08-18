  package com.focused_ai.apis.google;

import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import com.focused_ai.models.google.GoogleCourseList;
import com.focused_ai.models.google.GoogleCourseWorkList;
import com.focused_ai.models.google.GoogleStudentList;
import com.focused_ai.models.google.GoogleStudentSubmissionList;
import com.focused_ai.models.google.GoogleTeacherList;
import com.focused_ai.models.google.GoogleUserProfile;

import reactor.core.publisher.Mono;

@Service
public class GoogleClassroomApi {
    private final WebClient webClient;
    private final String googleClassroomAPI = "https://classroom.googleapis.com";

    public GoogleClassroomApi() {
        this.webClient = WebClient.builder()
            .baseUrl(googleClassroomAPI)
            .defaultHeader("Content-Type", "application/json")
            .build();
    }

    public Mono<GoogleUserProfile> getUserProfile(String accessToken) {
        return webClient.get()
            .uri("/v1/userProfiles/me")
            .header("Authorization", "Bearer " + accessToken)
            .retrieve()
            .bodyToMono(GoogleUserProfile.class);
    }

    public Mono<GoogleCourseList> getCourses(String accessToken) {
        return webClient.get()
            .uri("/v1/courses")
            .header("Authorization", "Bearer " + accessToken)
            .retrieve()
            .bodyToMono(GoogleCourseList.class);
    }

    public Mono<GoogleTeacherList> getCourseTeachers(String courseId, String accessToken) {
        return webClient.get()
            .uri("/v1/courses/{courseId}/teachers", courseId)
            .header("Authorization", "Bearer " + accessToken)
            .retrieve()
            .bodyToMono(GoogleTeacherList.class);
    }

    public Mono<GoogleStudentList> getCourseStudents(String courseId, String accessToken) {
        return webClient.get()
            .uri("/v1/courses/{courseId}/students", courseId)
            .header("Authorization", "Bearer " + accessToken)
            .retrieve()
            .bodyToMono(GoogleStudentList.class);
    }

    public Mono<GoogleStudentSubmissionList> getStudentSubmissions(String courseId, String courseWorkId, String accessToken) {
    return webClient.get()
            .uri("/v1/courses/{courseId}/courseWork/{courseWorkId}/studentSubmissions", courseId, courseWorkId)
            .header("Authorization", "Bearer " + accessToken)
            .retrieve()
            .bodyToMono(GoogleStudentSubmissionList.class);
}

public Mono<GoogleCourseWorkList> getCourseWork(String courseId, String accessToken) {
    return webClient.get()
            .uri("/v1/courses/{courseId}/courseWork", courseId)
            .header("Authorization", "Bearer " + accessToken)
            .retrieve()
            .bodyToMono(GoogleCourseWorkList.class);
}

}
