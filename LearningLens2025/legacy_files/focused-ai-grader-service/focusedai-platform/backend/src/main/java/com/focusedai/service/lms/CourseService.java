package com.focusedai.service.lms;

import com.focusedai.dto.CourseDto;
import com.focusedai.dto.AssignmentDto;
import com.focusedai.service.lms.client.GoogleClassroomClient;
import com.focusedai.service.lms.client.MoodleClient;
import com.focusedai.utils.UserContextExtractor;
import com.focusedai.utils.JwtUtil;
import com.focusedai.exception.LmsException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class CourseService {

    @Autowired
    private UserContextExtractor userContextExtractor;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private GoogleClassroomClient googleClient;

    @Autowired
    private MoodleClient moodleClient;

    public List<CourseDto> getCoursesForUser(String userContext, String platform) {
        Map<String, Object> userInfo = userContextExtractor.extractUserInfo(userContext);
        
        if (Boolean.TRUE.equals(userInfo.get("anonymous"))) {
            return createFallbackCourses();
        }

        try {
            if (jwtUtil.isGoogleUser(userContext)) {
                return googleClient.getCourses(userInfo);
            } else if (jwtUtil.isMoodleUser(userContext)) {
                return moodleClient.getCourses(userInfo);
            } else {
                throw new LmsException("Unsupported LMS platform: " + userInfo.get("lms"));
            }
        } catch (Exception e) {
            System.err.println("❌ Failed to fetch courses from LMS: " + e.getMessage());
            return createFallbackCourses();
        }
    }

    public CourseDto getCourse(String courseId, String userContext) {
        Map<String, Object> userInfo = userContextExtractor.extractUserInfo(userContext);
        
        if (Boolean.TRUE.equals(userInfo.get("anonymous"))) {
            return createFallbackCourse(courseId);
        }

        try {
            if (jwtUtil.isGoogleUser(userContext)) {
                return googleClient.getCourse(courseId, userInfo);
            } else if (jwtUtil.isMoodleUser(userContext)) {
                return moodleClient.getCourse(courseId, userInfo);
            } else {
                throw new LmsException("Unsupported LMS platform");
            }
        } catch (Exception e) {
            System.err.println("❌ Failed to fetch course from LMS: " + e.getMessage());
            return createFallbackCourse(courseId);
        }
    }

    public List<AssignmentDto> getAssignmentsForCourse(String courseId, String userContext) {
        Map<String, Object> userInfo = userContextExtractor.extractUserInfo(userContext);
        
        if (Boolean.TRUE.equals(userInfo.get("anonymous"))) {
            return createFallbackAssignments(courseId);
        }

        try {
            if (jwtUtil.isGoogleUser(userContext)) {
                return googleClient.getAssignments(courseId, userInfo);
            } else if (jwtUtil.isMoodleUser(userContext)) {
                return moodleClient.getAssignments(courseId, userInfo);
            } else {
                throw new LmsException("Unsupported LMS platform");
            }
        } catch (Exception e) {
            System.err.println("❌ Failed to fetch assignments from LMS: " + e.getMessage());
            return createFallbackAssignments(courseId);
        }
    }

    // Fallback methods for when LMS is unavailable
    private List<CourseDto> createFallbackCourses() {
        return List.of(
            createCourse("cs101-fallback", "CS 101 - Introduction to Programming", "classroom"),
            createCourse("cs102-fallback", "CS 102 - Data Structures", "classroom"),
            createCourse("cs201-fallback", "CS 201 - Object-Oriented Programming", "classroom")
        );
    }

    private CourseDto createFallbackCourse(String courseId) {
        return createCourse(courseId, "Programming Course", "classroom");
    }

    private CourseDto createCourse(String id, String name, String platform) {
        CourseDto course = new CourseDto(id, name, platform);
        course.setDescription("Computer Science programming course with automated grading");
        course.setInstructor("Course Instructor");
        course.setEnrollmentCount(25);
        return course;
    }

    private List<AssignmentDto> createFallbackAssignments(String courseId) {
        return List.of(
            createAssignment("hello-world-" + courseId, courseId, "Hello World Program", "java"),
            createAssignment("calculator-" + courseId, courseId, "Simple Calculator", "java"),
            createAssignment("array-ops-" + courseId, courseId, "Array Operations", "java")
        );
    }

    private AssignmentDto createAssignment(String id, String courseId, String name, String language) {
        AssignmentDto assignment = new AssignmentDto();
        assignment.setId(id);
        assignment.setCourseId(courseId);
        assignment.setName(name);
        assignment.setLanguage(language);
        assignment.setMaxScore(100.0);
        assignment.setDescription("Programming assignment with automated testing");
        return assignment;
    }
}