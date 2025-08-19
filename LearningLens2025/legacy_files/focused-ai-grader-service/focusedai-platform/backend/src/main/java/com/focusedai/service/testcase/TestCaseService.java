package com.focusedai.service.testcase;

import com.focusedai.model.testcase.TestCase;
import com.focusedai.utils.UserContextExtractor;
import com.focusedai.exception.GradingException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class TestCaseService {

    @Autowired
    private UserContextExtractor userContextExtractor;

    // In-memory storage for demonstration (replace with database in production)
    private final Map<String, List<TestCase>> testCaseStore = new ConcurrentHashMap<>();

    /**
     * Create a new test case
     */
    public TestCase createTestCase(TestCase testCase, String userContext) {
        // Validate user context
        Map<String, Object> userInfo = userContextExtractor.extractUserInfo(userContext);
        validateTeacherPermission(userInfo);

        // Generate ID if not provided
        if (testCase.getId() == null) {
            testCase.setId(UUID.randomUUID().toString());
        }

        // Add to assignment's test cases
        List<TestCase> testCases = testCaseStore.computeIfAbsent(
            testCase.getAssignmentId(), k -> new ArrayList<>()
        );
        testCases.add(testCase);

        System.out.println("✅ Created test case: " + testCase.getName() + " for assignment: " + testCase.getAssignmentId());
        return testCase;
    }

    /**
     * Get all test cases for an assignment
     */
    public List<TestCase> getTestCases(String assignmentId, String userContext) {
        return testCaseStore.getOrDefault(assignmentId, new ArrayList<>());
    }

    /**
     * Update test cases for an assignment
     */
    public List<TestCase> updateTestCases(String assignmentId, List<TestCase> testCases, String userContext) {
        // Validate user context
        Map<String, Object> userInfo = userContextExtractor.extractUserInfo(userContext);
        validateTeacherPermission(userInfo);

        // Set assignment ID for all test cases
        testCases.forEach(testCase -> {
            testCase.setAssignmentId(assignmentId);
            if (testCase.getId() == null) {
                testCase.setId(UUID.randomUUID().toString());
            }
        });

        // Replace existing test cases
        testCaseStore.put(assignmentId, new ArrayList<>(testCases));

        System.out.println("✅ Updated " + testCases.size() + " test cases for assignment: " + assignmentId);
        return testCases;
    }

    /**
     * Delete all test cases for an assignment
     */
    public boolean deleteTestCases(String assignmentId, String userContext) {
        // Validate user context
        Map<String, Object> userInfo = userContextExtractor.extractUserInfo(userContext);
        validateTeacherPermission(userInfo);

        List<TestCase> removed = testCaseStore.remove(assignmentId);
        System.out.println("✅ Deleted test cases for assignment: " + assignmentId);
        return removed != null;
    }

    private void validateTeacherPermission(Map<String, Object> userInfo) {
        if (userInfo.get("error") != null || Boolean.TRUE.equals(userInfo.get("anonymous"))) {
            throw new GradingException("Authentication required for test case operations");
        }

        String userRole = (String) userInfo.get("role");
        if (!"teacher".equals(userRole) && !"admin".equals(userRole)) {
            throw new GradingException("Teacher permissions required for test case operations");
        }
    }
}