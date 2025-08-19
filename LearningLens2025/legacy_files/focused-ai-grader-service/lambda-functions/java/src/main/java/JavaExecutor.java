import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;

public class JavaExecutor implements RequestHandler<Object, Object> {
    
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    @Override
    public Object handleRequest(Object input, Context context) {
        long startTime = System.currentTimeMillis();
        
        try {
            // Parse input
            String inputString = objectMapper.writeValueAsString(input);
            JsonNode inputNode = objectMapper.readTree(inputString);
            
            // Handle HTTP Function URL format
            JsonNode actualInput = inputNode;
            if (inputNode.has("body")) {
                if (inputNode.get("body").isTextual()) {
                    actualInput = objectMapper.readTree(inputNode.get("body").asText());
                } else {
                    actualInput = inputNode.get("body");
                }
            }
            
            // Extract files
            if (!actualInput.has("files") || !actualInput.get("files").isArray()) {
                return createErrorResponse("No files provided");
            }
            
            JsonNode files = actualInput.get("files");
            if (files.size() == 0) {
                return createErrorResponse("No files in request");
            }
            
            JsonNode firstFile = files.get(0);
            if (!firstFile.has("content")) {
                return createErrorResponse("No content in file");
            }
            
            String code = firstFile.get("content").asText();
            String filename = firstFile.has("filename") ? 
                            firstFile.get("filename").asText() : "Main.java";
            
            // Execute Java code
            ExecutionResult result = executeJavaCode(code, filename);
            
            long executionTime = System.currentTimeMillis() - startTime;
            
            // Create response
            Map<String, Object> response = new HashMap<>();
            response.put("success", result.success);
            response.put("output", result.output);
            response.put("error", result.error);
            response.put("language", "JAVA");
            response.put("executionTimeMs", executionTime);
            response.put("container", "java:openjdk");
            
            // Handle HTTP Function URL response format
            if (inputString.contains("\"body\"")) {
                Map<String, Object> httpResponse = new HashMap<>();
                httpResponse.put("statusCode", 200);
                
                Map<String, String> headers = new HashMap<>();
                headers.put("Content-Type", "application/json");
                headers.put("Access-Control-Allow-Origin", "*");
                headers.put("Access-Control-Allow-Methods", "POST");
                headers.put("Access-Control-Allow-Headers", "*");
                httpResponse.put("headers", headers);
                
                httpResponse.put("body", objectMapper.writeValueAsString(response));
                return httpResponse;
            } else {
                return response;
            }
            
        } catch (Exception e) {
            long executionTime = System.currentTimeMillis() - startTime;
            
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("output", "");
            errorResponse.put("error", "Internal error: " + e.getMessage());
            errorResponse.put("language", "JAVA");
            errorResponse.put("executionTimeMs", executionTime);
            
            return errorResponse;
        }
    }
    
    private ExecutionResult executeJavaCode(String code, String filename) {
        ExecutionResult result = new ExecutionResult();
        
        try {
            // Create temporary directory
            Path tempDir = Files.createTempDirectory("java_execution_");
            
            // Extract class name from filename or code
            String className = extractClassName(code, filename);
            String javaFile = className + ".java";
            
            // Write source code
            Path sourceFile = tempDir.resolve(javaFile);
            
            // Add imports and enhance code if needed
            String enhancedCode = enhanceJavaCode(code, className);
            Files.write(sourceFile, enhancedCode.getBytes());
            
            // Compile Java code
            ExecutionResult compileResult = compileJava(sourceFile, tempDir);
            if (!compileResult.success) {
                return compileResult;
            }
            
            // Execute Java code
            return executeJava(className, tempDir);
            
        } catch (Exception e) {
            result.success = false;
            result.error = "Execution failed: " + e.getMessage();
            return result;
        }
    }
    
    private String extractClassName(String code, String filename) {
        // Try to extract class name from code
        String[] lines = code.split("\n");
        for (String line : lines) {
            line = line.trim();
            if (line.startsWith("public class ")) {
                String[] parts = line.split("\\s+");
                if (parts.length >= 3) {
                    return parts[2].replaceAll("[^a-zA-Z0-9_]", "");
                }
            }
        }
        
        // Fall back to filename
        return filename.replaceAll("\\.java$", "").replaceAll("[^a-zA-Z0-9_]", "");
    }
    
    private String enhanceJavaCode(String code, String className) {
        // If code already has a class definition, use it as-is
        if (code.contains("public class") || code.contains("class ")) {
            return code;
        }
        
        // Wrap code in a main method and class
        StringBuilder enhanced = new StringBuilder();
        enhanced.append("import java.util.*;\n");
        enhanced.append("import java.io.*;\n");
        enhanced.append("import java.math.*;\n");
        enhanced.append("import java.text.*;\n\n");
        enhanced.append("public class ").append(className).append(" {\n");
        enhanced.append("    public static void main(String[] args) {\n");
        enhanced.append("        ").append(code.replace("\n", "\n        ")).append("\n");
        enhanced.append("    }\n");
        enhanced.append("}\n");
        
        return enhanced.toString();
    }
    
    private ExecutionResult compileJava(Path sourceFile, Path tempDir) {
        ExecutionResult result = new ExecutionResult();
        
        try {
            ProcessBuilder pb = new ProcessBuilder(
                "javac", 
                "-cp", tempDir.toString(),
                sourceFile.toString()
            );
            pb.directory(tempDir.toFile());
            pb.redirectErrorStream(true);
            
            Process process = pb.start();
            
            // Read compilation output
            StringBuilder output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line).append("\n");
                }
            }
            
            boolean finished = process.waitFor(30, TimeUnit.SECONDS);
            if (!finished) {
                process.destroyForcibly();
                result.success = false;
                result.error = "Compilation timeout";
                return result;
            }
            
            if (process.exitValue() == 0) {
                result.success = true;
            } else {
                result.success = false;
                result.error = "Compilation failed: " + output.toString();
            }
            
            return result;
            
        } catch (Exception e) {
            result.success = false;
            result.error = "Compilation error: " + e.getMessage();
            return result;
        }
    }
    
    private ExecutionResult executeJava(String className, Path tempDir) {
        ExecutionResult result = new ExecutionResult();
        
        try {
            ProcessBuilder pb = new ProcessBuilder(
                "java",
                "-cp", tempDir.toString(),
                className
            );
            pb.directory(tempDir.toFile());
            pb.redirectErrorStream(true);
            
            Process process = pb.start();
            
            // Read execution output
            StringBuilder output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line).append("\n");
                    
                    // Prevent excessive output
                    if (output.length() > 50000) {
                        process.destroyForcibly();
                        result.success = false;
                        result.error = "Output size limit exceeded";
                        return result;
                    }
                }
            }
            
            boolean finished = process.waitFor(30, TimeUnit.SECONDS);
            if (!finished) {
                process.destroyForcibly();
                result.success = false;
                result.error = "Execution timeout";
                return result;
            }
            
            result.success = true;
            result.output = output.toString();
            
            return result;
            
        } catch (Exception e) {
            result.success = false;
            result.error = "Execution error: " + e.getMessage();
            return result;
        }
    }
    
    private Map<String, Object> createErrorResponse(String errorMessage) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("output", "");
        response.put("error", errorMessage);
        response.put("language", "JAVA");
        return response;
    }
    
    private static class ExecutionResult {
        boolean success = false;
        String output = "";
        String error = "";
    }
}
