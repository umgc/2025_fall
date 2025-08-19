package com.focused_ai.controllers;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.focused_ai.models.domain.CourseList;
import com.focused_ai.models.domain.Grade;
import com.focused_ai.models.domain.StudentList;
import com.focused_ai.models.google.GoogleCourseWork;
import com.focused_ai.models.google.GoogleStudentSubmission;
import com.focused_ai.services.GoogleClassroomService;
import com.focused_ai.utils.JwtUtil;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/google")
@RequiredArgsConstructor
public class GoogleController {
    private final GoogleClassroomService googleService;
    private final JwtUtil jwtUtil;


    @GetMapping("/courses")
    public ResponseEntity<CourseList> getCourses(
        @RequestHeader("Authorization") String token
    ) {
        String userId = jwtUtil.extractUserId(token.substring(7));
        return ResponseEntity.ok(googleService.getCourses(userId));
    }

    @GetMapping("/courses/{courseId}/students")
public ResponseEntity<StudentList> getStudentsInCourse(
    @RequestHeader("Authorization") String token,
    @PathVariable String name,
    @PathVariable Double grade
) {
    String userId = jwtUtil.extractUserId(token.substring(7));
    return ResponseEntity.ok(googleService.getStudentsInCourse(userId));
}

@GetMapping("/courses/{courseId}/courseWork/{courseWorkId}/submissions")
public ResponseEntity<List<GoogleStudentSubmission>> getSubmissions(
        @RequestHeader("Authorization") String token,
        @PathVariable String courseId,
        @PathVariable String courseWorkId
) {
    String userId = jwtUtil.extractUserId(token.substring(7));
    return ResponseEntity.ok(googleService.getStudentSubmissions(userId, courseId, courseWorkId));
}

@GetMapping("/courses/{courseId}/courseWork")
public ResponseEntity<List<GoogleCourseWork>> getCourseWork(
    @RequestHeader("Authorization") String token,
    @PathVariable String courseId
) {
    String userId = jwtUtil.extractUserId(token.substring(7));
    return ResponseEntity.ok(googleService.getCourseWorkList(userId, courseId));
}

@GetMapping("/courses/{courseId}/grades")
public ResponseEntity<List<Grade>> getQuizGrades(
        @RequestHeader("Authorization") String token,
        @PathVariable String courseId
) {
    String userId = jwtUtil.extractUserId(token.substring(7));
    List<Grade> grades = googleService.fetchQuizGrades(userId, courseId);
    return ResponseEntity.ok(grades);
}
}