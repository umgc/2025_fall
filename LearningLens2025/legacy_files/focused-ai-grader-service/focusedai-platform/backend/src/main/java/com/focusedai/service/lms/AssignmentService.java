package com.focusedai.service.lms;

import com.focusedai.dto.AssignmentDto;
import com.focusedai.dto.SubmissionDto;
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
public class AssignmentService {

    @Autowired
    private UserContextExtractor userContextExtractor;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private GoogleClassroomClient googleClient;

    @Autowired
    private MoodleClient moodleClient;

    public AssignmentDto getAssignment(String assignmentId, String userContext) {
        Map<String, Object> userInfo = userContextExtractor.extractUserInfo(userContext);
        
        if (Boolean.TRUE.equals(userInfo.get("anonymous"))) {
            return createFallbackAssignment(assignmentId);
        }

        try {
            if (jwtUtil.isGoogleUser(userContext)) {
                return googleClient.getAssignment(assignmentId, userInfo);
            } else if (jwtUtil.isMoodleUser(userContext)) {
                return moodleClient.getAssignment(assignmentId, userInfo);
            } else {
                throw new LmsException("Unsupported LMS platform");
            }
        } catch (Exception e) {
            System.err.println("❌ Failed to fetch assignment from LMS: " + e.getMessage());
            return createFallbackAssignment(assignmentId);
        }
    }

    public List<SubmissionDto> getSubmissions(String assignmentId, String userContext) {
        Map<String, Object> userInfo = userContextExtractor.extractUserInfo(userContext);
        
        if (Boolean.TRUE.equals(userInfo.get("anonymous"))) {
            return createFallbackSubmissions(assignmentId);
        }

        try {
            if (jwtUtil.isGoogleUser(userContext)) {
                return googleClient.getSubmissions(assignmentId, userInfo);
            } else if (jwtUtil.isMoodleUser(userContext)) {
                return moodleClient.getSubmissions(assignmentId, userInfo);
            } else {
                throw new LmsException("Unsupported LMS platform");
            }
        } catch (Exception e) {
            System.err.println("❌ Failed to fetch submissions from LMS: " + e.getMessage());
            return createFallbackSubmissions(assignmentId);
        }
    }

    private AssignmentDto createFallbackAssignment(String assignmentId) {
        AssignmentDto assignment = new AssignmentDto();
        assignment.setId(assignmentId);
        assignment.setName("Programming Assignment");
        assignment.setDescription("Complete the programming task as described");
        assignment.setLanguage("java");
        assignment.setMaxScore(100.0);
        return assignment;
    }

    private List<SubmissionDto> createFallbackSubmissions(String assignmentId) {
        return List.of(
            createSubmission("sub1-" + assignmentId, assignmentId, "Alice Johnson"),
            createSubmission("sub2-" + assignmentId, assignmentId, "Bob Smith"),
            createSubmission("sub3-" + assignmentId, assignmentId, "Carol Davis")
        );
    }

    private SubmissionDto createSubmission(String id, String assignmentId, String studentName) {
        SubmissionDto submission = new SubmissionDto();
        submission.setId(id);
        submission.setAssignmentId(assignmentId);
        submission.setStudentName(studentName);
        submission.setStudentId("student-" + id);
        submission.setStatus("submitted");
        return submission;
    }
}