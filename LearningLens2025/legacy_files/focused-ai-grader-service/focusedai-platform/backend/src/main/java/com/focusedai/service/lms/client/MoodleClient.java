package com.focusedai.service.lms.client;

import com.focusedai.dto.CourseDto;
import com.focusedai.dto.AssignmentDto;
import com.focusedai.dto.SubmissionDto;
import com.focusedai.exception.LmsException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpEntity;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;

import java.util.List;
import java.util.ArrayList;
import java.util.Map;

@Service
public class MoodleClient {

    @Autowired
    private RestTemplate restTemplate;

    public List<CourseDto> getCourses(Map<String, Object> userInfo) {
        try {
            String moodleDomain = (String) userInfo.get("moodleDomain");
            String webServiceToken = (String) userInfo.get("webServiceToken");
            
            if (moodleDomain == null || webServiceToken == null) {
                throw new LmsException("Moodle credentials not found");
            }

            String url = moodleDomain + "/webservice/rest/server.php";
            
            MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
            params.add("wstoken", webServiceToken);
            params.add("wsfunction", "core_enrol_get_users_courses");
            params.add("moodlewsrestformat", "json");
            params.add("userid", (String) userInfo.get("userId"));

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            HttpEntity<MultiValueMap<String, String>> entity = new HttpEntity<>(params, headers);

            ResponseEntity<List> response = restTemplate.postForEntity(url, entity, List.class);
            
            List<CourseDto> courses = new ArrayList<>();
            List<Map<String, Object>> coursesData = response.getBody();
            
            if (coursesData != null) {
                for (Map<String, Object> courseData : coursesData) {
                    CourseDto course = convertMoodleCourseToCourseDto(courseData);
                    courses.add(course);
                }
            }

            return courses;
            
        } catch (Exception e) {
            throw new LmsException("Failed to fetch courses from Moodle: " + e.getMessage(), e);
        }
    }

    public CourseDto getCourse(String courseId, Map<String, Object> userInfo) {
        try {
            String moodleDomain = (String) userInfo.get("moodleDomain");
            String webServiceToken = (String) userInfo.get("webServiceToken");
            
            String url = moodleDomain + "/webservice/rest/server.php";
            
            MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
            params.add("wstoken", webServiceToken);
            params.add("wsfunction", "core_course_get_courses");
            params.add("moodlewsrestformat", "json");
            params.add("options[ids][0]", courseId);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            HttpEntity<MultiValueMap<String, String>> entity = new HttpEntity<>(params, headers);

            ResponseEntity<List> response = restTemplate.postForEntity(url, entity, List.class);
            
            List<Map<String, Object>> coursesData = response.getBody();
            if (coursesData != null && !coursesData.isEmpty()) {
                return convertMoodleCourseToCourseDto(coursesData.get(0));
            }
            
            throw new LmsException("Course not found: " + courseId);
            
        } catch (Exception e) {
            throw new LmsException("Failed to fetch course from Moodle: " + e.getMessage(), e);
        }
    }

    public List<AssignmentDto> getAssignments(String courseId, Map<String, Object> userInfo) {
        try {
            String moodleDomain = (String) userInfo.get("moodleDomain");
            String webServiceToken = (String) userInfo.get("webServiceToken");
            
            String url = moodleDomain + "/webservice/rest/server.php";
            
            MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
            params.add("wstoken", webServiceToken);
            params.add("wsfunction", "mod_assign_get_assignments");
            params.add("moodlewsrestformat", "json");
            params.add("courseids[0]", courseId);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            HttpEntity<MultiValueMap<String, String>> entity = new HttpEntity<>(params, headers);

            ResponseEntity<Map> response = restTemplate.postForEntity(url, entity, Map.class);
            
            List<AssignmentDto> assignments = new ArrayList<>();
            Map<String, Object> responseBody = response.getBody();
            
            if (responseBody != null && responseBody.get("courses") != null) {
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> courses = (List<Map<String, Object>>) responseBody.get("courses");
                
                if (!courses.isEmpty()) {
                    @SuppressWarnings("unchecked")
                    List<Map<String, Object>> assignmentsData = (List<Map<String, Object>>) courses.get(0).get("assignments");
                    
                    if (assignmentsData != null) {
                        for (Map<String, Object> assignmentData : assignmentsData) {
                            AssignmentDto assignment = convertMoodleAssignmentToAssignmentDto(assignmentData, courseId);
                            assignments.add(assignment);
                        }
                    }
                }
            }

            return assignments;
            
        } catch (Exception e) {
            throw new LmsException("Failed to fetch assignments from Moodle: " + e.getMessage(), e);
        }
    }

    public AssignmentDto getAssignment(String assignmentId, Map<String, Object> userInfo) {
        // Extract courseId from assignmentId or use a different approach
        String courseId = extractCourseIdFromAssignmentId(assignmentId);
        
        List<AssignmentDto> assignments = getAssignments(courseId, userInfo);
        return assignments.stream()
            .filter(a -> a.getId().equals(assignmentId))
            .findFirst()
            .orElseThrow(() -> new LmsException("Assignment not found: " + assignmentId));
    }

    public List<SubmissionDto> getSubmissions(String assignmentId, Map<String, Object> userInfo) {
        try {
            String moodleDomain = (String) userInfo.get("moodleDomain");
            String webServiceToken = (String) userInfo.get("webServiceToken");
            
            String url = moodleDomain + "/webservice/rest/server.php";
            
            MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
            params.add("wstoken", webServiceToken);
            params.add("wsfunction", "mod_assign_get_submissions");
            params.add("moodlewsrestformat", "json");
            params.add("assignmentids[0]", assignmentId);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            HttpEntity<MultiValueMap<String, String>> entity = new HttpEntity<>(params, headers);

            ResponseEntity<Map> response = restTemplate.postForEntity(url, entity, Map.class);
            
            List<SubmissionDto> submissions = new ArrayList<>();
            Map<String, Object> responseBody = response.getBody();
            
            if (responseBody != null && responseBody.get("assignments") != null) {
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> assignments = (List<Map<String, Object>>) responseBody.get("assignments");
                
                if (!assignments.isEmpty()) {
                    @SuppressWarnings("unchecked")
                    List<Map<String, Object>> submissionsData = (List<Map<String, Object>>) assignments.get(0).get("submissions");
                    
                    if (submissionsData != null) {
                        for (Map<String, Object> submissionData : submissionsData) {
                            SubmissionDto submission = convertMoodleSubmissionToSubmissionDto(submissionData);
                            submissions.add(submission);
                        }
                    }
                }
            }

            return submissions;
            
        } catch (Exception e) {
            throw new LmsException("Failed to fetch submissions from Moodle: " + e.getMessage(), e);
        }
    }

    // Helper methods to convert Moodle API responses to DTOs
    private CourseDto convertMoodleCourseToCourseDto(Map<String, Object> courseData) {
        CourseDto course = new CourseDto();
        course.setId(String.valueOf(courseData.get("id")));
        course.setLmsId(String.valueOf(courseData.get("id")));
        course.setName((String) courseData.get("fullname"));
        course.setDescription((String) courseData.get("summary"));
        course.setPlatform("moodle");
        course.setInstructor("Instructor"); // Moodle doesn't provide this directly
        course.setEnrollmentCount(0); // Would need separate API call
        return course;
    }

    private AssignmentDto convertMoodleAssignmentToAssignmentDto(Map<String, Object> assignmentData, String courseId) {
        AssignmentDto assignment = new AssignmentDto();
        assignment.setId(String.valueOf(assignmentData.get("id")));
        assignment.setLmsId(String.valueOf(assignmentData.get("id")));
        assignment.setCourseId(courseId);
        assignment.setName((String) assignmentData.get("name"));
        assignment.setDescription((String) assignmentData.get("intro"));
        assignment.setLanguage("java"); // Default, could be parsed from description
        assignment.setMaxScore(100.0); // Default
        return assignment;
    }

    private SubmissionDto convertMoodleSubmissionToSubmissionDto(Map<String, Object> submissionData) {
        SubmissionDto submission = new SubmissionDto();
        submission.setId(String.valueOf(submissionData.get("id")));
        submission.setLmsId(String.valueOf(submissionData.get("id")));
        submission.setStudentId(String.valueOf(submissionData.get("userid")));
        submission.setStudentName("Student " + submission.getStudentId()); // Fallback
        submission.setStatus("submitted");
        return submission;
    }

    private String extractCourseIdFromAssignmentId(String assignmentId) {
        // Simplified - in reality you'd maintain proper relationships
        return "default-course-id";
    }
}