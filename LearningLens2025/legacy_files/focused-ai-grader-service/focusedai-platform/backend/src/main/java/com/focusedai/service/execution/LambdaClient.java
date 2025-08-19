package com.focusedai.service.execution;

import com.focusedai.config.ExecutionConfig;
import com.focusedai.model.execution.ExecutionRequest;
import com.focusedai.model.execution.ExecutionResult;
import com.focusedai.model.execution.CodeAnalysis;
import com.focusedai.exception.ExecutionException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;

import java.util.Map;
import java.util.HashMap;

@Service
public class LambdaClient {

    @Autowired
    @Qualifier("executionRestTemplate")
    private RestTemplate restTemplate;

    @Autowired
    private ExecutionConfig executionConfig;

    /**
     * Execute code on Lambda with strategy-aware payload
     */
    public ExecutionResult execute(ExecutionRequest request, CodeAnalysis analysis) {
        try {
            String lambdaUrl = getLambdaUrl(request.getLanguage());
            Map<String, Object> payload = createLambdaPayload(request, analysis);
            
            System.out.println("🚀 Sending to Lambda: " + lambdaUrl);
            System.out.println("📦 Strategy: " + analysis.getRecommendedStrategy());
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<Map<String, Object>> httpRequest = new HttpEntity<>(payload, headers);
            
            @SuppressWarnings("unchecked")
            Map<String, Object> response = restTemplate.postForObject(lambdaUrl, httpRequest, Map.class);
            
            if (response == null) {
                throw new ExecutionException("No response from Lambda execution service");
            }
            
            return parseExecutionResult(response, analysis);
            
        } catch (ExecutionException e) {
            throw e;
        } catch (Exception e) {
            System.err.println("❌ Lambda execution failed: " + e.getMessage());
            throw new ExecutionException("Lambda execution failed: " + e.getMessage(), e);
        }
    }

    /**
     * Check health of all Lambda endpoints
     */
    public Map<String, Object> checkHealth() {
        Map<String, Object> health = new HashMap<>();
        health.put("timestamp", System.currentTimeMillis());
        
        Map<String, Object> endpoints = new HashMap<>();
        endpoints.put("java", testEndpoint(executionConfig.getJavaUrl(), "java"));
        endpoints.put("python", testEndpoint(executionConfig.getPythonUrl(), "python"));
        endpoints.put("javascript", testEndpoint(executionConfig.getJavascriptUrl(), "javascript"));
        endpoints.put("cpp", testEndpoint(executionConfig.getCppUrl(), "cpp"));
        
        health.put("endpoints", endpoints);
        
        boolean allHealthy = endpoints.values().stream()
            .allMatch(status -> {
                @SuppressWarnings("unchecked")
                Map<String, Object> statusMap = (Map<String, Object>) status;
                return "healthy".equals(statusMap.get("status"));
            });
            
        health.put("overallStatus", allHealthy ? "healthy" : "degraded");
        
        return health;
    }

    // ========== PRIVATE HELPER METHODS ==========

    private String getLambdaUrl(String language) {
        switch (language.toLowerCase()) {
            case "java":
                return executionConfig.getJavaUrl();
            case "python":
                return executionConfig.getPythonUrl();
            case "javascript":
                return executionConfig.getJavascriptUrl();
            case "cpp":
            case "c++":
                return executionConfig.getCppUrl();
            default:
                throw new ExecutionException("Unsupported language: " + language);
        }
    }

    private Map<String, Object> createLambdaPayload(ExecutionRequest request, CodeAnalysis analysis) {
        Map<String, Object> payload = new HashMap<>();
        
        // Basic execution data
        payload.put("files", request.getFiles());
        payload.put("input", request.getTestInput());
        payload.put("expectedOutput", request.getExpectedOutput());
        payload.put("timeoutMs", request.getTimeoutMs());
        payload.put("maxMemoryMb", request.getMaxMemoryMb());
        
        // Strategy and analysis information
        String strategy = request.getForcedStrategy() != null ? 
            request.getForcedStrategy() : analysis.getRecommendedStrategy();
        payload.put("executionStrategy", strategy);
        
        // Java-specific configuration
        if ("java".equalsIgnoreCase(request.getLanguage())) {
            if (analysis.isPackageExecution()) {
                payload.put("packageExecution", true);
                if (analysis.getPackageName() != null) {
                    payload.put("packageName", analysis.getPackageName());
                }
                if (analysis.getMainClassName() != null) {
                    payload.put("mainFileName", analysis.getMainClassName());
                }
            }
            
            if ("METHOD_CALL".equals(strategy) && analysis.getTargetMethod() != null) {
                payload.put("targetMethod", analysis.getTargetMethod());
            }
        }
        
        // Metadata
        payload.put("submissionId", request.getSubmissionId());
        payload.put("assignmentId", request.getAssignmentId());
        payload.put("timestamp", System.currentTimeMillis());
        
        return payload;
    }

    private ExecutionResult parseExecutionResult(Map<String, Object> response, CodeAnalysis analysis) {
        ExecutionResult result = new ExecutionResult();
        
        // Basic execution results
        result.setSuccess(getBoolean(response, "success", false));
        result.setOutput(getString(response, "output", ""));
        result.setError(getString(response, "error", ""));
        result.setExecutionTimeMs(getLong(response, "executionTimeMs", 0L));
        result.setMemoryUsedMb(getInt(response, "memoryUsedMb", 0));
        result.setExitCode(getInt(response, "exitCode", -1));
        result.setTestPassed(getBoolean(response, "testPassed", false));
        result.setOutputSimilarity(getDouble(response, "outputSimilarity", 0.0));
        result.setUsedStrategy(getString(response, "usedStrategy", analysis.getRecommendedStrategy()));
        
        // Strategy-specific results
        @SuppressWarnings("unchecked")
        Map<String, Object> strategyResults = (Map<String, Object>) response.get("strategyResults");
        if (strategyResults != null) {
            result.setStrategyResults(strategyResults);
        }
        
        // Additional metadata
        @SuppressWarnings("unchecked")
        Map<String, Object> metadata = (Map<String, Object>) response.get("metadata");
        if (metadata != null) {
            result.setMetadata(metadata);
        }
        
        return result;
    }

    private Map<String, Object> testEndpoint(String url, String language) {
        try {
            Map<String, Object> testPayload = createTestPayload(language);
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<Map<String, Object>> request = new HttpEntity<>(testPayload, headers);
            
            long startTime = System.currentTimeMillis();
            @SuppressWarnings("unchecked")
            Map<String, Object> response = restTemplate.postForObject(url, request, Map.class);
            long responseTime = System.currentTimeMillis() - startTime;
            
            return Map.of(
                "status", "healthy",
                "responseTime", responseTime,
                "url", url,
                "testPassed", response != null && getBoolean(response, "success", false)
            );
            
        } catch (Exception e) {
            return Map.of(
                "status", "unhealthy",
                "error", e.getMessage(),
                "url", url
            );
        }
    }

    private Map<String, Object> createTestPayload(String language) {
        Map<String, Object> payload = new HashMap<>();
        
        // Create simple test based on language
        switch (language.toLowerCase()) {
            case "java":
                payload.put("files", java.util.List.of(
                    createCodeFile("HelloWorld.java", 
                        "public class HelloWorld {\n    public static void main(String[] args) {\n        System.out.println(\"Hello, World!\");\n    }\n}", 
                        "java")
                ));
                break;
            case "python":
                payload.put("files", java.util.List.of(
                    createCodeFile("main.py", "print('Hello, World!')", "python")
                ));
                break;
            case "javascript":
                payload.put("files", java.util.List.of(
                    createCodeFile("main.js", "console.log('Hello, World!');", "javascript")
                ));
                break;
            case "cpp":
                payload.put("files", java.util.List.of(
                    createCodeFile("main.cpp", 
                        "#include <iostream>\nint main() {\n    std::cout << \"Hello, World!\" << std::endl;\n    return 0;\n}", 
                        "cpp")
                ));
                break;
        }
        
        payload.put("input", "");
        payload.put("expectedOutput", "Hello, World!");
        payload.put("executionStrategy", "STDIN_STDOUT");
        payload.put("timeoutMs", 10000);
        
        return payload;
    }

    private Map<String, Object> createCodeFile(String filename, String content, String language) {
        Map<String, Object> file = new HashMap<>();
        file.put("filename", filename);
        file.put("content", content);
        file.put("language", language);
        return file;
    }

    // Helper methods for safe type conversion
    private boolean getBoolean(Map<String, Object> map, String key, boolean defaultValue) {
        Object value = map.get(key);
        return value instanceof Boolean ? (Boolean) value : defaultValue;
    }

    private String getString(Map<String, Object> map, String key, String defaultValue) {
        Object value = map.get(key);
        return value instanceof String ? (String) value : defaultValue;
    }

    private long getLong(Map<String, Object> map, String key, long defaultValue) {
        Object value = map.get(key);
        if (value instanceof Number) {
            return ((Number) value).longValue();
        }
        return defaultValue;
    }

    private int getInt(Map<String, Object> map, String key, int defaultValue) {
        Object value = map.get(key);
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }
        return defaultValue;
    }

    private double getDouble(Map<String, Object> map, String key, double defaultValue) {
        Object value = map.get(key);
        if (value instanceof Number) {
            return ((Number) value).doubleValue();
        }
        return defaultValue;
    }
}