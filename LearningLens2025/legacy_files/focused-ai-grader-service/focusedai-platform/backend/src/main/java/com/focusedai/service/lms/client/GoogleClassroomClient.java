package com.focusedai.service.lms.client;

import com.focusedai.dto.CourseDto;
import com.focusedai.dto.AssignmentDto;
import com.focusedai.dto.SubmissionDto;
import com.focusedai.model.execution.CodeFile;
import com.focusedai.exception.LmsException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;

import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Service
public class GoogleClassroomClient {

    @Autowired
    private RestTemplate restTemplate;

    private static final String CLASSROOM_API_BASE = "https://classroom.googleapis.com/v1";

    public List<CourseDto> getCourses(Map<String, Object> userInfo) {
        try {
            String accessToken = (String) userInfo.get("googleAccessToken");
            if (accessToken == null) {
                throw new LmsException("Google access token not found");
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            HttpEntity<?> entity = new HttpEntity<>(headers);

            String url = CLASSROOM_API_BASE + "/courses?teacherId=me&courseStates=ACTIVE";
            
            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.GET, entity, Map.class
            );

            List<CourseDto> courses = new ArrayList<>();
            Map<String, Object> responseBody = response.getBody();
            
            if (responseBody != null && responseBody.get("courses") != null) {
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> coursesData = (List<Map<String, Object>>) responseBody.get("courses");
                
                for (Map<String, Object> courseData : coursesData) {
                    CourseDto course = convertGoogleCourseToCourseDto(courseData);
                    courses.add(course);
                }
            }

            return courses;
            
        } catch (Exception e) {
            throw new LmsException("Failed to fetch courses from Google Classroom: " + e.getMessage(), e);
        }
    }

    public CourseDto getCourse(String courseId, Map<String, Object> userInfo) {
        try {
            String accessToken = (String) userInfo.get("googleAccessToken");
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            HttpEntity<?> entity = new HttpEntity<>(headers);

            String url = CLASSROOM_API_BASE + "/courses/" + courseId;
            
            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.GET, entity, Map.class
            );

            Map<String, Object> courseData = response.getBody();
            return convertGoogleCourseToCourseDto(courseData);
            
        } catch (Exception e) {
            throw new LmsException("Failed to fetch course from Google Classroom: " + e.getMessage(), e);
        }
    }

    public List<AssignmentDto> getAssignments(String courseId, Map<String, Object> userInfo) {
        try {
            String accessToken = (String) userInfo.get("googleAccessToken");
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            HttpEntity<?> entity = new HttpEntity<>(headers);

            String url = CLASSROOM_API_BASE + "/courses/" + courseId + "/courseWork";
            
            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.GET, entity, Map.class
            );

            List<AssignmentDto> assignments = new ArrayList<>();
            Map<String, Object> responseBody = response.getBody();
            
            if (responseBody != null && responseBody.get("courseWork") != null) {
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> courseWorkData = (List<Map<String, Object>>) responseBody.get("courseWork");
                
                for (Map<String, Object> workData : courseWorkData) {
                    AssignmentDto assignment = convertGoogleCourseWorkToAssignmentDto(workData, courseId);
                    assignments.add(assignment);
                }
            }

            return assignments;
            
        } catch (Exception e) {
            throw new LmsException("Failed to fetch assignments from Google Classroom: " + e.getMessage(), e);
        }
    }

    public AssignmentDto getAssignment(String assignmentId, Map<String, Object> userInfo) {
        // For simplicity, this extracts courseId from assignmentId
        // In real implementation, you'd need to track course-assignment relationships
        String courseId = extractCourseIdFromAssignmentId(assignmentId);
        
        List<AssignmentDto> assignments = getAssignments(courseId, userInfo);
        return assignments.stream()
            .filter(a -> a.getId().equals(assignmentId))
            .findFirst()
            .orElseThrow(() -> new LmsException("Assignment not found: " + assignmentId));
    }

    public List<SubmissionDto> getSubmissions(String assignmentId, Map<String, Object> userInfo) {
        try {
            String accessToken = (String) userInfo.get("googleAccessToken");
            String courseId = extractCourseIdFromAssignmentId(assignmentId);
            
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            HttpEntity<?> entity = new HttpEntity<>(headers);

            String url = CLASSROOM_API_BASE + "/courses/" + courseId + "/courseWork/" + assignmentId + "/studentSubmissions";
            
            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.GET, entity, Map.class
            );

            List<SubmissionDto> submissions = new ArrayList<>();
            Map<String, Object> responseBody = response.getBody();
            
            if (responseBody != null && responseBody.get("studentSubmissions") != null) {
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> submissionsData = (List<Map<String, Object>>) responseBody.get("studentSubmissions");
                
                for (Map<String, Object> submissionData : submissionsData) {
                    SubmissionDto submission = convertGoogleSubmissionToSubmissionDto(submissionData);
                    submissions.add(submission);
                }
            }

            return submissions;
            
        } catch (Exception e) {
            throw new LmsException("Failed to fetch submissions from Google Classroom: " + e.getMessage(), e);
        }
    }

    // Helper methods to convert Google API responses to DTOs
    private CourseDto convertGoogleCourseToCourseDto(Map<String, Object> courseData) {
        CourseDto course = new CourseDto();
        course.setId((String) courseData.get("id"));
        course.setLmsId((String) courseData.get("id"));
        course.setName((String) courseData.get("name"));
        course.setDescription((String) courseData.get("description"));
        course.setPlatform("google");
        
        @SuppressWarnings("unchecked")
        Map<String, Object> teacher = (Map<String, Object>) courseData.get("teacher");
        if (teacher != null) {
            course.setInstructor((String) teacher.get("name"));
        }
        
        course.setEnrollmentCount(0); // Google Classroom doesn't provide this directly
        course.setCreatedAt(LocalDateTime.now()); // Use current time as fallback
        
        return course;
    }

    private AssignmentDto convertGoogleCourseWorkToAssignmentDto(Map<String, Object> workData, String courseId) {
        AssignmentDto assignment = new AssignmentDto();
        assignment.setId((String) workData.get("id"));
        assignment.setLmsId((String) workData.get("id"));
        assignment.setCourseId(courseId);
        assignment.setName((String) workData.get("title"));
        assignment.setDescription((String) workData.get("description"));
        assignment.setLanguage("java"); // Default, could be parsed from description
        assignment.setMaxScore(100.0); // Default, Google Classroom uses points differently
        
        // Parse due date if available
        @SuppressWarnings("unchecked")
        Map<String, Object> dueDate = (Map<String, Object>) workData.get("dueDate");
        if (dueDate != null) {
            // Convert Google's date format to LocalDateTime
            assignment.setDueDate(LocalDateTime.now().plusDays(7)); // Fallback
        }
        
        return assignment;
    }

    private SubmissionDto convertGoogleSubmissionToSubmissionDto(Map<String, Object> submissionData) {
        SubmissionDto submission = new SubmissionDto();
        submission.setId((String) submissionData.get("id"));
        submission.setLmsId((String) submissionData.get("id"));
        submission.setAssignmentId((String) submissionData.get("courseWorkId"));
        submission.setStudentId((String) submissionData.get("userId"));
        
        // Get student name from submission data
        submission.setStudentName("Student " + submission.getStudentId()); // Fallback
        
        submission.setStatus("submitted");
        submission.setSubmittedAt(LocalDateTime.now()); // Fallback
        
        // Parse attachments as code files
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> attachments = (List<Map<String, Object>>) submissionData.get("assignmentSubmission");
        if (attachments != null) {
            List<CodeFile> files = parseGoogleAttachments(attachments);
            submission.setFiles(files);
        }
        
        return submission;
    }

    private List<CodeFile> parseGoogleAttachments(List<Map<String, Object>> attachments) {
        List<CodeFile> files = new ArrayList<>();
        
        for (Map<String, Object> attachment : attachments) {
            // This is simplified - in reality you'd need to download file content
            // from Google Drive API using the attachment details
            CodeFile file = new CodeFile();
            file.setFilename("submission.java"); // Default
            file.setContent("// Code content would be downloaded from Google Drive");
            file.setLanguage("java");
            files.add(file);
        }
        
        return files;
    }

    private String extractCourseIdFromAssignmentId(String assignmentId) {
        // This is a simplification - in reality you'd need to maintain
        // a mapping or parse the ID structure
        return "default-course-id";
    }
}