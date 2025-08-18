package com.focusedai.service.grading;

import com.focusedai.dto.*;
import com.focusedai.model.grading.Grade;
import com.focusedai.service.execution.ExecutionService;
import com.focusedai.utils.UserContextExtractor;
import com.focusedai.exception.GradingException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class GradingService {

    @Autowired
    private ExecutionService executionService;

    @Autowired
    private FeedbackGenerator feedbackGenerator;

    @Autowired
    private UserContextExtractor userContextExtractor;

    // In-memory storage for demonstration (replace with database in production)
    private final Map<String, Grade> gradeStore = new ConcurrentHashMap<>();
    private final Map<String, Map<String, Object>> gradingCriteria = new ConcurrentHashMap<>();

    /**
     * Grade a single submission with automatic execution and analysis
     */
    public GradeDto gradeSubmission(GradingRequestDto request, String userContext) {
        try {
            System.out.println("📊 Starting grading for submission: " + request.getSubmissionId());
            
            // Convert grading request to execution request
            ExecutionRequestDto executionRequest = convertToExecutionRequest(request);
            
            // Execute the code
            ExecutionResultDto executionResult = executionService.executeCode(executionRequest, userContext);
            
            // Calculate grade based on execution result
            Grade grade = calculateGrade(request, executionResult, userContext);
            
            // Store the grade
            gradeStore.put(request.getSubmissionId(), grade);
            
            // Convert to DTO
            return convertToGradeDto(grade, executionResult);
            
        } catch (Exception e) {
            System.err.println("❌ Grading failed for submission " + request.getSubmissionId() + ": " + e.getMessage());
            throw new GradingException("Grading failed: " + e.getMessage(), e);
        }
    }

    /**
     * Grade multiple submissions in batch
     */
    public BatchGradingResultDto gradeBatch(Map<String, Object> batchRequest, String userContext) {
        try {
            System.out.println("📊 Starting batch grading");
            
            // Execute batch first
            BatchExecutionResultDto batchExecution = executionService.executeBatch(batchRequest, userContext);
            
            List<GradeDto> grades = new ArrayList<>();
            int successCount = 0;
            int failureCount = 0;
            
            // Grade each execution result
            for (ExecutionResultDto executionResult : batchExecution.getResults()) {
                try {
                    // Create a grading request from execution result
                    GradingRequestDto gradingRequest = createGradingRequestFromExecution(executionResult, batchRequest);
                    
                    // Calculate grade
                    Grade grade = calculateGrade(gradingRequest, executionResult, userContext);
                    gradeStore.put(executionResult.getSubmissionId(), grade);
                    
                    GradeDto gradeDto = convertToGradeDto(grade, executionResult);
                    grades.add(gradeDto);
                    
                    if (gradeDto.getError() == null) {
                        successCount++;
                    } else {
                        failureCount++;
                    }
                } catch (Exception e) {
                    System.err.println("❌ Failed to grade execution result: " + e.getMessage());
                    
                    GradeDto errorGrade = GradeDto.error("Grading failed: " + e.getMessage());
                    errorGrade.setSubmissionId(executionResult.getSubmissionId());
                    grades.add(errorGrade);
                    failureCount++;
                }
            }
            
            BatchGradingResultDto result = new BatchGradingResultDto();
            result.setSuccess(true);
            result.setGrades(grades);
            result.setTotalSubmissions(grades.size());
            result.setSuccessfulGrades(successCount);
            result.setFailedGrades(failureCount);
            result.setTimestamp(System.currentTimeMillis());
            
            System.out.println("✅ Batch grading completed: " + successCount + "/" + grades.size() + " successful");
            
            return result;
            
        } catch (Exception e) {
            System.err.println("❌ Batch grading failed: " + e.getMessage());
            throw new GradingException("Batch grading failed: " + e.getMessage(), e);
        }
    }

    /**
     * Get existing grade for a submission
     */
    public GradeDto getGrade(String submissionId, String userContext) {
        Grade grade = gradeStore.get(submissionId);
        if (grade != null) {
            return convertToGradeDto(grade, null);
        }
        return null;
    }

    /**
     * Get grading criteria for a language/strategy combination
     */
    public Map<String, Object> getGradingCriteria(String language, String strategy) {
        String key = language + (strategy != null ? "_" + strategy : "");
        return gradingCriteria.getOrDefault(key, getDefaultGradingCriteria(language, strategy));
    }

    /**
     * Update grading criteria
     */
    public void updateGradingCriteria(String language, Map<String, Object> criteria, String userContext) {
        // Validate user has permission to update criteria
        Map<String, Object> userInfo = userContextExtractor.extractUserInfo(userContext);
        String userRole = (String) userInfo.get("role");
        
        if (!"teacher".equals(userRole) && !"admin".equals(userRole)) {
            throw new GradingException("Insufficient permissions to update grading criteria");
        }
        
        String key = language;
        if (criteria.containsKey("strategy")) {
            key += "_" + criteria.get("strategy");
        }
        
        gradingCriteria.put(key, new HashMap<>(criteria));
        System.out.println("✅ Updated grading criteria for: " + key);
    }

    // ========== PRIVATE HELPER METHODS ==========

    private ExecutionRequestDto convertToExecutionRequest(GradingRequestDto request) {
        ExecutionRequestDto executionRequest = new ExecutionRequestDto();
        executionRequest.setLanguage(request.getLanguage());
        executionRequest.setFiles(request.getFiles());
        executionRequest.setTestInput(request.getTestInput());
        executionRequest.setExpectedOutput(request.getExpectedOutput());
        executionRequest.setSubmissionId(request.getSubmissionId());
        executionRequest.setAssignmentId(request.getAssignmentId());
        return executionRequest;
    }

    private GradingRequestDto createGradingRequestFromExecution(ExecutionResultDto executionResult, Map<String, Object> batchRequest) {
        GradingRequestDto dto = new GradingRequestDto();
        dto.setSubmissionId(executionResult.getSubmissionId());
        
        // Extract data from batch request
        @SuppressWarnings("unchecked")
        Map<String, Object> submissions = (Map<String, Object>) batchRequest.get("submissions");
        if (submissions != null) {
            @SuppressWarnings("unchecked")
            Map<String, Object> submissionData = (Map<String, Object>) submissions.get(executionResult.getSubmissionId());
            if (submissionData != null) {
                dto.setAssignmentId((String) submissionData.get("assignmentId"));
                dto.setLanguage((String) submissionData.getOrDefault("language", "java"));
                dto.setStudentId((String) submissionData.get("studentId"));
                dto.setStudentName((String) submissionData.get("studentName"));
                dto.setTestInput((String) submissionData.getOrDefault("input", ""));
                dto.setExpectedOutput((String) submissionData.getOrDefault("expectedOutput", ""));
                
                Object maxScore = submissionData.get("maxScore");
                if (maxScore instanceof Number) {
                    dto.setMaxScore(((Number) maxScore).doubleValue());
                } else {
                    dto.setMaxScore(100.0); // Default
                }
            }
        }
        
        return dto;
    }

    private Grade calculateGrade(GradingRequestDto request, ExecutionResultDto executionResult, String userContext) {
        Grade grade = new Grade();
        grade.setGradeId(UUID.randomUUID().toString());
        grade.setSubmissionId(request.getSubmissionId());
        grade.setMaxScore(request.getMaxScore());
        grade.setGradedBy("auto-grader");

        Map<String, Object> userInfo = userContextExtractor.extractUserInfo(userContext);
        if (userInfo.get("userId") != null) {
            grade.setGradedBy("auto-grader-" + userInfo.get("userId"));
        }

        if (!executionResult.isSuccess()) {
            // Execution failed
            grade.setScore(0.0);
            grade.setPercentage(0.0);
            grade.setLetterGrade("F");
            grade.setPassed(false);
            grade.setFeedback(feedbackGenerator.generateErrorFeedback(executionResult));
        } else {
            // Calculate score based on strategy and results
            double score = calculateScoreBasedOnStrategy(executionResult, request);
            grade.setScore(score);
            grade.setPercentage((score / request.getMaxScore()) * 100);
            grade.setLetterGrade(calculateLetterGrade(grade.getPercentage()));
            grade.setPassed(grade.getPercentage() >= 60.0); // 60% passing threshold
            grade.setFeedback(feedbackGenerator.generateFeedback(executionResult, request));
        }

        grade.setGradingStrategy(executionResult.getUsedStrategy());
        grade.setExecutionDetails(createExecutionDetails(executionResult));
        grade.setAnalysisDetails(executionResult.getCodeAnalysis());

        return grade;
    }

    private double calculateScoreBasedOnStrategy(ExecutionResultDto executionResult, GradingRequestDto request) {
        String strategy = executionResult.getUsedStrategy();
        double maxScore = request.getMaxScore();
        
        switch (strategy) {
            case "UNIT_TEST":
                return calculateUnitTestScore(executionResult, maxScore);
            case "METHOD_CALL":
                return calculateMethodCallScore(executionResult, maxScore);
            case "FILE_IO":
                return calculateFileIOScore(executionResult, maxScore);
            case "INTERACTIVE":
                return calculateInteractiveScore(executionResult, maxScore);
            case "STDIN_STDOUT":
            default:
                return calculateStandardScore(executionResult, maxScore);
        }
    }

    private double calculateStandardScore(ExecutionResultDto result, double maxScore) {
        if (result.isTestPassed()) {
            return maxScore; // Full score for exact match
        }
        
        // Partial score based on similarity
        double similarity = result.getOutputSimilarity();
        if (similarity >= 95) {
            return maxScore * 0.95; // 95% for near-perfect match
        } else if (similarity >= 85) {
            return maxScore * 0.85; // 85% for very close match
        } else if (similarity >= 70) {
            return maxScore * 0.70; // 70% for close match
        } else if (similarity >= 50) {
            return maxScore * 0.50; // 50% for partial match
        } else {
            return maxScore * 0.20; // 20% for execution success but wrong output
        }
    }

    private double calculateUnitTestScore(ExecutionResultDto result, double maxScore) {
        Map<String, Object> strategyResults = result.getStrategyResults();
        
        if (strategyResults != null) {
            Integer totalTests = (Integer) strategyResults.get("totalTests");
            Integer passedTests = (Integer) strategyResults.get("passedTests");
            
            if (totalTests != null && totalTests > 0) {
                double passRate = (double) (passedTests != null ? passedTests : 0) / totalTests;
                return maxScore * passRate;
            }
        }
        
        return result.isTestPassed() ? maxScore : 0.0;
    }

    private double calculateMethodCallScore(ExecutionResultDto result, double maxScore) {
        return calculateStandardScore(result, maxScore);
    }

    private double calculateFileIOScore(ExecutionResultDto result, double maxScore) {
        double baseScore = calculateStandardScore(result, maxScore);
        return Math.min(maxScore, baseScore * 1.05); // 5% bonus for file operations
    }

    private double calculateInteractiveScore(ExecutionResultDto result, double maxScore) {
        double similarity = result.getOutputSimilarity();
        if (similarity >= 75) { // Lower threshold for interactive
            return maxScore * 0.90; // 90% for good interactive match
        }
        return calculateStandardScore(result, maxScore) * 0.85; // Slight penalty for complexity
    }

    private String calculateLetterGrade(double percentage) {
        if (percentage >= 90) return "A";
        if (percentage >= 80) return "B";
        if (percentage >= 70) return "C";
        if (percentage >= 60) return "D";
        return "F";
    }

    private Map<String, Object> createExecutionDetails(ExecutionResultDto result) {
        Map<String, Object> details = new HashMap<>();
        details.put("executionTimeMs", result.getExecutionTimeMs());
        details.put("memoryUsedMb", result.getMemoryUsedMb());
        details.put("exitCode", result.getExitCode());
        details.put("outputSimilarity", result.getOutputSimilarity());
        details.put("testPassed", result.isTestPassed());
        details.put("usedStrategy", result.getUsedStrategy());
        details.put("detectedStrategy", result.getDetectedStrategy());
        return details;
    }

    private GradeDto convertToGradeDto(Grade grade, ExecutionResultDto executionResult) {
        GradeDto dto = new GradeDto();
        dto.setGradeId(grade.getGradeId());
        dto.setSubmissionId(grade.getSubmissionId());
        dto.setScore(grade.getScore());
        dto.setMaxScore(grade.getMaxScore());
        dto.setPercentage(grade.getPercentage());
        dto.setLetterGrade(grade.getLetterGrade());
        dto.setFeedback(grade.getFeedback());
        dto.setPassed(grade.isPassed());
        dto.setGradingStrategy(grade.getGradingStrategy());
        dto.setExecutionDetails(grade.getExecutionDetails());
        dto.setAnalysisDetails(grade.getAnalysisDetails());
        dto.setGradedAt(grade.getGradedAt());
        dto.setGradedBy(grade.getGradedBy());
        return dto;
    }

    private Map<String, Object> getDefaultGradingCriteria(String language, String strategy) {
        Map<String, Object> criteria = new HashMap<>();
        criteria.put("language", language);
        criteria.put("strategy", strategy);
        criteria.put("passingThreshold", 60.0);
        criteria.put("similarityWeight", 0.8);
        criteria.put("executionWeight", 0.2);
        criteria.put("timeoutPenalty", 0.1);
        criteria.put("memoryPenalty", 0.05);
        return criteria;
    }
}