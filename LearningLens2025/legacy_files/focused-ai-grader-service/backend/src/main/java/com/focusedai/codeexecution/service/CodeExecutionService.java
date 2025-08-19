// backend/src/main/java/com/focusedai/codeexecution/service/CodeExecutionService.java

package com.focusedai.codeexecution.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.focusedai.codeexecution.model.CodeExecutionRequest;
import com.focusedai.codeexecution.model.CodeExecutionResult;
import com.focusedai.codeexecution.model.CodeFile;
import com.focusedai.codeexecution.model.BatchExecutionRequest;
import com.focusedai.codeexecution.model.BatchExecutionResult;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Duration;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
public class CodeExecutionService {

    @Value("${lambda.python.url:}")
    private String pythonLambdaUrl;

    @Value("${lambda.javascript.url:}")
    private String javascriptLambdaUrl;

    @Value("${lambda.java.url:}")
    private String javaLambdaUrl;

    @Value("${lambda.cpp.url:}")
    private String cppLambdaUrl;

    @Value("${lambda.timeout.seconds:90}")
    private int timeoutSeconds;

    @Value("${lambda.batch.timeout.seconds:300}")
    private int batchTimeoutSeconds;

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    public CodeExecutionService() {
        this.webClient = WebClient.builder()
                .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(10 * 1024 * 1024))
                .build();
        this.objectMapper = new ObjectMapper();
    }

    /**
     * 🆕 NEW: Execute code with optional test input (ENHANCED VERSION)
     */
    public CodeExecutionResult executeCode(String language, CodeExecutionRequest request) {
        String lambdaUrl = getLambdaUrlForLanguage(language);
        
        if (lambdaUrl == null || lambdaUrl.isEmpty()) {
            return createErrorResult("Lambda URL not configured for language: " + language, language);
        }

        try {
            System.out.println("🚀 Executing " + language + " code via Lambda");
            
            // 🆕 ENHANCED: Build request with input support
            Map<String, Object> lambdaRequest = new HashMap<>();
            lambdaRequest.put("files", request.getFiles());
            lambdaRequest.put("mainClassName", request.getMainClassName());
            lambdaRequest.put("language", language);
            lambdaRequest.put("source", "focusedai-grading-system");
            lambdaRequest.put("platform", request.getPlatform());
            
            // 🆕 NEW: Include test input if provided
            if (request.getInput() != null) {
                lambdaRequest.put("input", request.getInput());
                System.out.println("📥 Including test input: " + 
                    (request.getInput().length() > 50 ? 
                        request.getInput().substring(0, 50) + "..." : 
                        request.getInput()));
            }

            String response = webClient.post()
                    .uri(lambdaUrl)
                    .header("Content-Type", "application/json")
                    .bodyValue(lambdaRequest)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(timeoutSeconds))
                    .block();

            Map<String, Object> lambdaResponse = objectMapper.readValue(response, Map.class);
            
            CodeExecutionResult result = new CodeExecutionResult();
            result.setSuccess((Boolean) lambdaResponse.getOrDefault("success", false));
            result.setOutput((String) lambdaResponse.getOrDefault("output", ""));
            result.setError((String) lambdaResponse.getOrDefault("error", ""));
            result.setLanguage(language.toUpperCase());
            result.setServerless(true);
            result.setArchitecture("100% Serverless");
            result.setExecutionType(getExecutionTypeForLanguage(language));
            
            // 🆕 NEW: Include execution time from Lambda response
            Object executionTimeObj = lambdaResponse.get("executionTimeMs");
            if (executionTimeObj instanceof Integer) {
                result.setExecutionTimeMs((Integer) executionTimeObj);
            }

            // 🆕 NEW: Log test execution details
            Boolean hasInput = (Boolean) lambdaResponse.get("hasInput");
            if (hasInput != null && hasInput) {
                System.out.println("🧪 Test execution completed: " + 
                    (result.isSuccess() ? "SUCCESS" : "FAILED"));
            }

            return result;

        } catch (Exception e) {
            System.err.println("❌ Lambda execution error: " + e.getMessage());
            return createErrorResult("Execution error: " + e.getMessage(), language);
        }
    }

    /**
     * Enhanced batch execution with input support
     */
    public BatchExecutionResult executeBatch(BatchExecutionRequest batchRequest) {
        System.out.println("🚀 Starting batch execution for " + batchRequest.getSubmissions().size() + " submissions");
        
        long startTime = System.currentTimeMillis();
        Map<String, CodeExecutionResult> results = new ConcurrentHashMap<>();
        List<CompletableFuture<Void>> futures = new ArrayList<>();

        // Group submissions by language for optimal processing
        Map<String, List<BatchExecutionRequest.SubmissionInfo>> submissionsByLanguage = 
            batchRequest.getSubmissions().stream()
                .collect(Collectors.groupingBy(submission -> 
                    detectLanguageFromFilename(submission.getFilename())));

        System.out.println("📊 Grouped submissions by language: " + submissionsByLanguage.keySet());

        // Process each language group
        for (Map.Entry<String, List<BatchExecutionRequest.SubmissionInfo>> entry : submissionsByLanguage.entrySet()) {
            String language = entry.getKey();
            List<BatchExecutionRequest.SubmissionInfo> submissions = entry.getValue();

            System.out.println("🔥 Processing " + submissions.size() + " " + language + " submissions");

            // Create parallel execution futures for each submission
            for (BatchExecutionRequest.SubmissionInfo submission : submissions) {
                CompletableFuture<Void> future = CompletableFuture.runAsync(() -> {
                    try {
                        // Create CodeFile from submission
                        CodeFile codeFile = new CodeFile();
                        codeFile.setFilename(submission.getFilename());
                        codeFile.setContent(submission.getCode());

                        // Create execution request
                        CodeExecutionRequest request = new CodeExecutionRequest();
                        request.setFiles(List.of(codeFile));
                        request.setMainClassName(getMainClassNameFromFilename(submission.getFilename()));
                        request.setPlatform(batchRequest.getPlatform());
                        request.setAssignmentId(batchRequest.getAssignmentId());
                        request.setStudentId(submission.getStudentId());
                        
                        // 🆕 NEW: Check if there's test input for this submission
                        // This could be enhanced to include per-submission test input
                        // For now, batch execution doesn't use test input

                        // Execute code
                        CodeExecutionResult result = executeCode(language, request);
                        
                        // Store result with submission ID as key
                        results.put(submission.getSubmissionId(), result);
                        
                        System.out.println("✅ Completed execution for submission: " + submission.getSubmissionId() + 
                                         " (Student: " + submission.getStudentName() + ")");

                    } catch (Exception e) {
                        System.err.println("❌ Error executing submission " + submission.getSubmissionId() + ": " + e.getMessage());
                        
                        // Store error result
                        CodeExecutionResult errorResult = createErrorResult(
                            "Batch execution error: " + e.getMessage(), language);
                        results.put(submission.getSubmissionId(), errorResult);
                    }
                });

                futures.add(future);
            }
        }

        // Wait for all executions to complete with timeout
        try {
            CompletableFuture<Void> allFutures = CompletableFuture.allOf(
                futures.toArray(new CompletableFuture[0]));
            
            allFutures.get(batchTimeoutSeconds, java.util.concurrent.TimeUnit.SECONDS);
            
        } catch (Exception e) {
            System.err.println("⚠️ Batch execution timeout or error: " + e.getMessage());
            
            // Cancel remaining futures
            futures.forEach(future -> future.cancel(true));
        }

        long totalTime = System.currentTimeMillis() - startTime;
        
        // Create batch result
        BatchExecutionResult batchResult = new BatchExecutionResult();
        batchResult.setAssignmentId(batchRequest.getAssignmentId());
        batchResult.setBatchId(UUID.randomUUID().toString());
        batchResult.setResults(results);
        batchResult.setTotalSubmissions(batchRequest.getSubmissions().size());
        batchResult.setSuccessfulExecutions((int) results.values().stream().filter(CodeExecutionResult::isSuccess).count());
        batchResult.setFailedExecutions(results.size() - batchResult.getSuccessfulExecutions());
        batchResult.setExecutionTimeMs(totalTime);
        batchResult.setStartTime(new Date(startTime));
        batchResult.setEndTime(new Date());

        System.out.println("🎉 Batch execution completed:");
        System.out.println("   Total submissions: " + batchResult.getTotalSubmissions());
        System.out.println("   Successful: " + batchResult.getSuccessfulExecutions());
        System.out.println("   Failed: " + batchResult.getFailedExecutions());
        System.out.println("   Total time: " + totalTime + "ms");

        return batchResult;
    }

    /**
     * Detect programming language from filename extension
     */
    private String detectLanguageFromFilename(String filename) {
        if (filename == null || !filename.contains(".")) {
            return "unknown";
        }
        
        String extension = filename.substring(filename.lastIndexOf(".") + 1).toLowerCase();
        
        switch (extension) {
            case "py":
                return "python";
            case "js":
                return "javascript";
            case "java":
                return "java";
            case "cpp":
            case "cc":
            case "cxx":
            case "c":
                return "cpp";
            default:
                return "unknown";
        }
    }

    /**
     * Get main class name from filename (for Java mainly)
     */
    private String getMainClassNameFromFilename(String filename) {
        if (filename == null || !filename.contains(".")) {
            return filename;
        }
        
        String baseName = filename.substring(0, filename.lastIndexOf("."));
        
        // For Java, ensure first letter is capitalized
        if (filename.toLowerCase().endsWith(".java")) {
            return baseName.substring(0, 1).toUpperCase() + baseName.substring(1);
        }
        
        return baseName;
    }

    // Helper methods
    private CodeExecutionResult createErrorResult(String error, String language) {
        CodeExecutionResult result = new CodeExecutionResult();
        result.setSuccess(false);
        result.setOutput("");
        result.setError(error);
        result.setLanguage(language.toUpperCase());
        result.setServerless(true);
        result.setArchitecture("100% Serverless");
        return result;
    }

    private String getLambdaUrlForLanguage(String language) {
        switch (language.toLowerCase()) {
            case "python": return pythonLambdaUrl;
            case "javascript": case "js": return javascriptLambdaUrl;
            case "java": return javaLambdaUrl;
            case "cpp": case "c++": return cppLambdaUrl;
            default: return null;
        }
    }

    private String getExecutionTypeForLanguage(String language) {
        switch (language.toLowerCase()) {
            case "python": return "🚀 🐍 Zip-based Lambda (fast startup)";
            case "javascript": return "🚀 📜 Zip-based Lambda (fast startup)";
            case "java": return "🚀 ☕ Container-based Lambda with JDK";
            case "cpp": return "🚀 ⚡ Container-based Lambda with g++";
            default: return "🚀 Serverless Lambda execution";
        }
    }

    public Map<String, Object> getStatus() {
        Map<String, Object> status = new HashMap<>();
        status.put("service", "FocusEd AI Code Execution");
        status.put("architecture", "100% Serverless via AWS Lambda");
        status.put("features", Arrays.asList(
            "🚀 Single code execution",
            "📦 Batch parallel execution", 
            "🧪 Test input/output support",
            "🔒 Enhanced security validation",
            "⚡ Fast serverless architecture"
        ));
        
        Map<String, String> urls = new HashMap<>();
        urls.put("python", isConfigured(pythonLambdaUrl) ? "✅ Configured" : "❌ Not configured");
        urls.put("javascript", isConfigured(javascriptLambdaUrl) ? "✅ Configured" : "❌ Not configured");
        urls.put("java", isConfigured(javaLambdaUrl) ? "✅ Configured" : "❌ Not configured");
        urls.put("cpp", isConfigured(cppLambdaUrl) ? "✅ Configured" : "❌ Not configured");
        status.put("lambdaUrls", urls);
        
        return status;
    }

    private boolean isConfigured(String url) {
        return url != null && !url.isEmpty() && !url.contains("your-");
    }

    public Map<String, Object> testAllLanguages() {
        Map<String, Object> results = new HashMap<>();
        results.put("note", "Testing all configured Lambda functions with input support");
        
        Map<String, Object> testResults = new HashMap<>();
        
        // Test each language with and without input
        testResults.put("python", testLanguage("python", 
            "name = input('Enter name: ')\nprint(f'Hello {name}!')", 
            "test.py", "John"));
            
        testResults.put("javascript", testLanguage("javascript", 
            "console.log('Hello from JavaScript!');", 
            "test.js", null));
            
        testResults.put("java", testLanguage("java", 
            "import java.util.Scanner;\npublic class Test {\npublic static void main(String[] args) {\nScanner sc = new Scanner(System.in);\nSystem.out.print('Enter name: ');\nString name = sc.nextLine();\nSystem.out.println('Hello ' + name + '!');\n}\n}", 
            "Test.java", "Alice"));
            
        testResults.put("cpp", testLanguage("cpp", 
            "#include <iostream>\nusing namespace std;\nint main() { cout << \"Hello from C++!\" << endl; return 0; }", 
            "test.cpp", null));
        
        results.put("results", testResults);
        return results;
    }

    private Map<String, Object> testLanguage(String language, String code, String filename, String testInput) {
        Map<String, Object> result = new HashMap<>();
        
        if (!isConfigured(getLambdaUrlForLanguage(language))) {
            result.put("status", "not_configured");
            result.put("message", "Lambda URL not configured for " + language);
            return result;
        }

        try {
            CodeFile testFile = new CodeFile();
            testFile.setFilename(filename);
            testFile.setContent(code);
            
            CodeExecutionRequest request = new CodeExecutionRequest();
            request.setFiles(List.of(testFile));
            request.setMainClassName(filename.split("\\.")[0]);
            request.setPlatform("test");
            request.setInput(testInput); // 🆕 NEW: Include test input
            
            CodeExecutionResult executionResult = executeCode(language, request);
            
            result.put("status", executionResult.isSuccess() ? "success" : "error");
            result.put("output", executionResult.getOutput());
            result.put("error", executionResult.getError());
            result.put("hasTestInput", testInput != null);
            
        } catch (Exception e) {
            result.put("status", "error");
            result.put("error", "Test failed: " + e.getMessage());
        }
        
        return result;
    }
}