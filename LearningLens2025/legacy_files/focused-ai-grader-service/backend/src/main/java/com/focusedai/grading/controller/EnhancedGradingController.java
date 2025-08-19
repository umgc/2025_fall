package com.focusedai.grading.controller;

import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.multipart.MultipartFile;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.time.LocalDateTime;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "http://localhost:3000")
public class EnhancedGradingController {

    // In-memory storage (in production, use database)
    private final Map<String, Map<String, Object>> courses = new ConcurrentHashMap<>();
    private final Map<String, Map<String, Object>> assignments = new ConcurrentHashMap<>();
    private final Map<String, Map<String, Object>> submissions = new ConcurrentHashMap<>();
    private final Map<String, Map<String, Object>> grades = new ConcurrentHashMap<>();

    public EnhancedGradingController() {
        // Initialize with some mock courses
        initializeMockData();
    }

    private void initializeMockData() {
        // Mock courses
        courses.put("CS101", Map.of(
            "id", "CS101",
            "name", "Introduction to Computer Science",
            "description", "Basic programming concepts"
        ));
        courses.put("CS201", Map.of(
            "id", "CS201", 
            "name", "Data Structures and Algorithms",
            "description", "Advanced programming concepts"
        ));
        courses.put("CS301", Map.of(
            "id", "CS301",
            "name", "Software Engineering",
            "description", "Software development practices"
        ));
    }

    @GetMapping("/")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("🎓 Enhanced Teacher Grading System API - Ready for integrated grading!");
    }
    
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> status() {
        Map<String, Object> status = new HashMap<>();
        status.put("service", "Enhanced Teacher Code Grading System");
        status.put("architecture", "🚀 Integrated Code Editor with Grading");
        status.put("features", Arrays.asList(
            "📚 Course-based assignment management",
            "👨‍🎓 Student submission tracking", 
            "🧪 Automated test case execution",
            "📝 Integrated code editor",
            "💯 Real-time grading and feedback",
            "📊 Grade management and export"
        ));
        status.put("supportedLanguages", Arrays.asList("java", "python", "javascript", "cpp"));
        status.put("ready", "✅ Ready for integrated grading workflow");
        
        return ResponseEntity.ok(status);
    }

    // === COURSE MANAGEMENT ===
    
    @GetMapping("/courses")
    public ResponseEntity<List<Map<String, Object>>> getCourses() {
        System.out.println("📋 Retrieving all courses. Count: " + courses.size());
        return ResponseEntity.ok(new ArrayList<>(courses.values()));
    }
    
    @GetMapping("/courses/{courseId}")
    public ResponseEntity<?> getCourse(@PathVariable String courseId) {
        Map<String, Object> course = courses.get(courseId);
        if (course != null) {
            System.out.println("📄 Retrieved course: " + course.get("name"));
            return ResponseEntity.ok(course);
        } else {
            System.out.println("❌ Course not found: " + courseId);
            return ResponseEntity.notFound().build();
        }
    }

    // === ASSIGNMENT MANAGEMENT ===
    
    @PostMapping("/courses/{courseId}/assignments")
    public ResponseEntity<?> createAssignment(
            @PathVariable String courseId,
            @RequestBody Map<String, Object> assignmentData) {
        try {
            System.out.println("📝 Creating assignment for course " + courseId + ": " + assignmentData.get("name"));
            
            // Verify course exists
            if (!courses.containsKey(courseId)) {
                return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "error", "Course not found: " + courseId
                ));
            }
            
            // Generate ID if not provided
            if (!assignmentData.containsKey("id") || assignmentData.get("id") == null) {
                assignmentData.put("id", UUID.randomUUID().toString());
            }
            
            // Add course and metadata
            assignmentData.put("courseId", courseId);
            assignmentData.put("createdAt", LocalDateTime.now().toString());
            
            // Calculate max score from test cases
            List<Map<String, Object>> testCases = (List<Map<String, Object>>) assignmentData.get("testCases");
            if (testCases != null && !testCases.isEmpty()) {
                int maxScore = testCases.stream()
                    .mapToInt(tc -> {
                        Object points = tc.get("points");
                        if (points instanceof Integer) {
                            return (Integer) points;
                        } else if (points instanceof String) {
                            try {
                                return Integer.parseInt((String) points);
                            } catch (NumberFormatException e) {
                                return 1;
                            }
                        }
                        return 1;
                    })
                    .sum();
                assignmentData.put("maxScore", maxScore);
            } else {
                assignmentData.put("maxScore", 0);
            }
            
            // Store assignment
            String assignmentId = (String) assignmentData.get("id");
            assignments.put(assignmentId, assignmentData);
            
            System.out.println("✅ Assignment created successfully with ID: " + assignmentId);
            
            return ResponseEntity.ok(Map.of(
                "success", true,
                "assignment", assignmentData,
                "message", "Assignment created successfully"
            ));
        } catch (Exception e) {
            System.err.println("❌ Error creating assignment: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "error", "Failed to create assignment: " + e.getMessage()
            ));
        }
    }
    
    @GetMapping("/courses/{courseId}/assignments")
    public ResponseEntity<List<Map<String, Object>>> getAssignmentsByCourse(@PathVariable String courseId) {
        System.out.println("📋 Retrieving assignments for course: " + courseId);
        
        List<Map<String, Object>> courseAssignments = assignments.values().stream()
            .filter(assignment -> courseId.equals(assignment.get("courseId")))
            .collect(ArrayList::new, ArrayList::add, ArrayList::addAll);
            
        return ResponseEntity.ok(courseAssignments);
    }
    
    @GetMapping("/assignments")
    public ResponseEntity<List<Map<String, Object>>> getAllAssignments() {
        System.out.println("📋 Retrieving all assignments. Count: " + assignments.size());
        return ResponseEntity.ok(new ArrayList<>(assignments.values()));
    }
    
    @GetMapping("/assignments/{id}")
    public ResponseEntity<?> getAssignment(@PathVariable String id) {
        Map<String, Object> assignment = assignments.get(id);
        if (assignment != null) {
            System.out.println("📄 Retrieved assignment: " + assignment.get("name"));
            return ResponseEntity.ok(assignment);
        } else {
            System.out.println("❌ Assignment not found: " + id);
            return ResponseEntity.notFound().build();
        }
    }
    
    @DeleteMapping("/assignments/{id}")
    public ResponseEntity<?> deleteAssignment(@PathVariable String id) {
        Map<String, Object> removed = assignments.remove(id);
        if (removed != null) {
            System.out.println("🗑️ Deleted assignment: " + removed.get("name"));
            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Assignment deleted successfully"
            ));
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // === SUBMISSION MANAGEMENT ===
    
    @GetMapping("/assignments/{assignmentId}/submissions")
    public ResponseEntity<List<Map<String, Object>>> getSubmissionsByAssignment(@PathVariable String assignmentId) {
        System.out.println("📋 Retrieving submissions for assignment: " + assignmentId);
        
        List<Map<String, Object>> assignmentSubmissions = submissions.values().stream()
            .filter(submission -> assignmentId.equals(submission.get("assignmentId")))
            .collect(ArrayList::new, ArrayList::add, ArrayList::addAll);
            
        return ResponseEntity.ok(assignmentSubmissions);
    }
    
    @PostMapping("/assignments/{assignmentId}/submissions")
    public ResponseEntity<?> uploadSubmissions(
            @PathVariable String assignmentId,
            @RequestBody Map<String, Object> requestData) {
        try {
            System.out.println("📤 Uploading submissions for assignment: " + assignmentId);
            
            // Verify assignment exists
            if (!assignments.containsKey(assignmentId)) {
                return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "error", "Assignment not found: " + assignmentId
                ));
            }
            
            List<Map<String, Object>> submissionList = (List<Map<String, Object>>) requestData.get("submissions");
            List<String> submissionIds = new ArrayList<>();
            
            for (Map<String, Object> submissionData : submissionList) {
                String submissionId = UUID.randomUUID().toString();
                submissionData.put("id", submissionId);
                submissionData.put("assignmentId", assignmentId);
                submissionData.put("uploadedAt", LocalDateTime.now().toString());
                submissionData.put("status", "uploaded");
                
                submissions.put(submissionId, submissionData);
                submissionIds.add(submissionId);
            }
            
            System.out.println("✅ Uploaded " + submissionIds.size() + " submissions");
            
            return ResponseEntity.ok(Map.of(
                "success", true,
                "submissionIds", submissionIds,
                "message", "Submissions uploaded successfully"
            ));
        } catch (Exception e) {
            System.err.println("❌ Error uploading submissions: " + e.getMessage());
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "error", "Failed to upload submissions: " + e.getMessage()
            ));
        }
    }

    // === GRADING MANAGEMENT ===
    
    @PostMapping("/submissions/{submissionId}/grade")
    public ResponseEntity<?> gradeSubmission(
            @PathVariable String submissionId,
            @RequestBody Map<String, Object> gradeData) {
        try {
            System.out.println("📊 Grading submission: " + submissionId);
            
            // Verify submission exists
            if (!submissions.containsKey(submissionId)) {
                return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "error", "Submission not found: " + submissionId
                ));
            }
            
            String gradeId = UUID.randomUUID().toString();
            gradeData.put("id", gradeId);
            gradeData.put("submissionId", submissionId);
            gradeData.put("gradedAt", LocalDateTime.now().toString());
            gradeData.put("gradedBy", "teacher"); // In production, get from authentication
            
            grades.put(gradeId, gradeData);
            
            // Update submission status
            Map<String, Object> submission = submissions.get(submissionId);
            submission.put("status", "graded");
            submission.put("gradeId", gradeId);
            
            System.out.println("✅ Grade saved for submission: " + submissionId);
            
            return ResponseEntity.ok(Map.of(
                "success", true,
                "grade", gradeData,
                "message", "Grade saved successfully"
            ));
        } catch (Exception e) {
            System.err.println("❌ Error grading submission: " + e.getMessage());
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "error", "Failed to grade submission: " + e.getMessage()
            ));
        }
    }
    
    @GetMapping("/submissions/{submissionId}/grade")
    public ResponseEntity<?> getGrade(@PathVariable String submissionId) {
        Map<String, Object> submission = submissions.get(submissionId);
        if (submission == null) {
            return ResponseEntity.notFound().build();
        }
        
        String gradeId = (String) submission.get("gradeId");
        if (gradeId == null) {
            return ResponseEntity.ok(Map.of(
                "graded", false,
                "message", "Submission not yet graded"
            ));
        }
        
        Map<String, Object> grade = grades.get(gradeId);
        return ResponseEntity.ok(Map.of(
            "graded", true,
            "grade", grade
        ));
    }
    
    @PostMapping("/assignments/{assignmentId}/grade-all")
    public ResponseEntity<?> gradeAllSubmissions(
            @PathVariable String assignmentId,
            @RequestBody Map<String, Object> requestData) {
        try {
            System.out.println("📊 Starting batch grading for assignment: " + assignmentId);
            
            // Get all ungraded submissions for this assignment
            List<Map<String, Object>> ungradedSubmissions = submissions.values().stream()
                .filter(submission -> assignmentId.equals(submission.get("assignmentId")))
                .filter(submission -> !"graded".equals(submission.get("status")))
                .collect(ArrayList::new, ArrayList::add, ArrayList::addAll);
            
            String batchId = UUID.randomUUID().toString();
            int gradedCount = 0;
            
            // Mock grading process
            for (Map<String, Object> submission : ungradedSubmissions) {
                String submissionId = (String) submission.get("id");
                
                // Create mock grade
                Map<String, Object> gradeData = new HashMap<>();
                gradeData.put("score", 75 + (Math.random() * 25)); // Random score 75-100
                gradeData.put("feedback", "Automatically graded submission");
                gradeData.put("batchId", batchId);
                
                String gradeId = UUID.randomUUID().toString();
                gradeData.put("id", gradeId);
                gradeData.put("submissionId", submissionId);
                gradeData.put("gradedAt", LocalDateTime.now().toString());
                gradeData.put("gradedBy", "system");
                
                grades.put(gradeId, gradeData);
                
                // Update submission
                submission.put("status", "graded");
                submission.put("gradeId", gradeId);
                
                gradedCount++;
            }
            
            System.out.println("✅ Batch grading completed. Graded " + gradedCount + " submissions");
            
            return ResponseEntity.ok(Map.of(
                "success", true,
                "batchId", batchId,
                "gradedCount", gradedCount,
                "message", "Batch grading completed successfully"
            ));
        } catch (Exception e) {
            System.err.println("❌ Error in batch grading: " + e.getMessage());
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "error", "Failed to complete batch grading: " + e.getMessage()
            ));
        }
    }

    // === TEST FILE MANAGEMENT ===
    
    @PostMapping("/assignments/{assignmentId}/test-files")
    public ResponseEntity<?> uploadTestFiles(
            @PathVariable String assignmentId,
            @RequestParam(value = "inputFile", required = false) MultipartFile inputFile,
            @RequestParam(value = "outputFile", required = false) MultipartFile outputFile) {
        try {
            System.out.println("📁 Uploading test files for assignment: " + assignmentId);
            
            // Verify assignment exists
            if (!assignments.containsKey(assignmentId)) {
                return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "error", "Assignment not found: " + assignmentId
                ));
            }
            
            Map<String, Object> assignment = assignments.get(assignmentId);
            Map<String, String> testFiles = new HashMap<>();
            
            if (inputFile != null && !inputFile.isEmpty()) {
                // In production, save to file system or cloud storage
                testFiles.put("inputFile", inputFile.getOriginalFilename());
                System.out.println("📄 Input file uploaded: " + inputFile.getOriginalFilename());
            }
            
            if (outputFile != null && !outputFile.isEmpty()) {
                // In production, save to file system or cloud storage
                testFiles.put("outputFile", outputFile.getOriginalFilename());
                System.out.println("📄 Output file uploaded: " + outputFile.getOriginalFilename());
            }
            
            assignment.put("testFiles", testFiles);
            
            return ResponseEntity.ok(Map.of(
                "success", true,
                "testFiles", testFiles,
                "message", "Test files uploaded successfully"
            ));
        } catch (Exception e) {
            System.err.println("❌ Error uploading test files: " + e.getMessage());
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "error", "Failed to upload test files: " + e.getMessage()
            ));
        }
    }

    // === UTILITY ENDPOINTS ===
    
    @GetMapping("/assignments/count")
    public ResponseEntity<Map<String, Object>> getAssignmentCount() {
        return ResponseEntity.ok(Map.of(
            "count", assignments.size(),
            "assignments", assignments.keySet()
        ));
    }
    
    @GetMapping("/submissions/count")
    public ResponseEntity<Map<String, Object>> getSubmissionCount() {
        return ResponseEntity.ok(Map.of(
            "count", submissions.size(),
            "submissions", submissions.keySet()
        ));
    }
    
    @GetMapping("/grades/count")
    public ResponseEntity<Map<String, Object>> getGradeCount() {
        return ResponseEntity.ok(Map.of(
            "count", grades.size(),
            "grades", grades.keySet()
        ));
    }
}