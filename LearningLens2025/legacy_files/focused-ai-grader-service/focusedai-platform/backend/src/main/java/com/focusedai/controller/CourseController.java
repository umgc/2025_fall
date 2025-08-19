package com.focusedai.controller;

import com.focusedai.service.lms.CourseService;
import com.focusedai.dto.CourseDto;
import com.focusedai.dto.AssignmentDto;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/courses")
public class CourseController {

    @Autowired
    private CourseService courseService;

    @GetMapping
    public ResponseEntity<List<CourseDto>> getCourses(
            @RequestHeader(value = "Authorization", required = false) String userContext,
            @RequestParam(required = false) String platform) {
        
        List<CourseDto> courses = courseService.getCoursesForUser(userContext, platform);
        return ResponseEntity.ok(courses);
    }

    @GetMapping("/{courseId}")
    public ResponseEntity<CourseDto> getCourse(
            @PathVariable String courseId,
            @RequestHeader(value = "Authorization", required = false) String userContext) {
        
        CourseDto course = courseService.getCourse(courseId, userContext);
        return ResponseEntity.ok(course);
    }

    @GetMapping("/{courseId}/assignments")
    public ResponseEntity<List<AssignmentDto>> getCourseAssignments(
            @PathVariable String courseId,
            @RequestHeader(value = "Authorization", required = false) String userContext) {
        
        List<AssignmentDto> assignments = courseService.getAssignmentsForCourse(courseId, userContext);
        return ResponseEntity.ok(assignments);
    }
}