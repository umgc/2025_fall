import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.regex.Pattern;

public class JavaExecutor implements RequestHandler<Object, Map<String, Object>> {
    
    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final int EXECUTION_TIMEOUT_SECONDS = 60;
    private static final Pattern DANGEROUS_PATTERN = Pattern.compile(
        "(Runtime\\.getRuntime|ProcessBuilder|System\\.(exit|gc|load|setProperty|getProperty)|" +
        "Class\\.forName|Thread\\.|Unsafe|sun\\.|com\\.sun\\.|" +
        "java\\.lang\\.reflect\\.Method|java\\.io\\.File|java\\.nio\\.file\\.|" +
        "java\\.net\\.|java\\.security\\.|javax\\.script\\.|" +
        "java\\.awt\\.|javax\\.swing\\.|java\\.sql\\.)"
    );
    
    @Override
    public Map<String, Object> handleRequest(Object input, Context context) {
        long startTime = System.currentTimeMillis();
        
        try {
            // Handle both direct invoke and Function URL formats
            JsonNode eventNode;
            if (input instanceof String) {
                eventNode = objectMapper.readTree((String) input);
            } else {
                eventNode = objectMapper.valueToTree(input);
            }
            
            // Check for Function URL format
            JsonNode bodyNode = eventNode.get("body");
            if (bodyNode != null) {
                if (bodyNode.isTextual()) {
                    eventNode = objectMapper.readTree(bodyNode.asText());
                } else {
                    eventNode = bodyNode;
                }
            }
            
            // Parse the request
            JsonNode filesNode = eventNode.get("files");
            if (filesNode == null || !filesNode.isArray() || filesNode.size() == 0) {
                return createErrorResponse("No files provided");
            }
            
            // Get the main Java file
            JsonNode mainFile = filesNode.get(0);
            String code = mainFile.get("content").asText();
            String filename = mainFile.has("filename") ? mainFile.get("filename").asText() : "Main.java";
            
            // Extract class name from filename or code
            String className = extractClassName(filename, code);
            
            // Security validation
            if (!isCodeSafe(code)) {
                return createErrorResponse("Code contains potentially dangerous operations");
            }
            
            // Execute the code
            ExecutionResult result = executeJavaCode(code, filename, className);
            
            long executionTime = System.currentTimeMillis() - startTime;
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", result.success);
            response.put("output", result.output);
            response.put("error", result.error);
            response.put("language", "JAVA");
            response.put("executionTimeMs", executionTime);
            response.put("container", "java:17");
            
            // Return format for Function URL
            if (input instanceof Map && ((Map<?, ?>) input).containsKey("body")) {
                return createHttpResponse(response);
            } else {
                return response;
            }
            
        } catch (Exception e) {
            long executionTime = System.currentTimeMillis() - startTime;
            
            Map<String, Object> errorResult = new HashMap<>();
            errorResult.put("success", false);
            errorResult.put("output", "");
            errorResult.put("error", e.getMessage());
            errorResult.put("language", "JAVA");
            errorResult.put("executionTimeMs", executionTime);
            
            if (input instanceof Map && ((Map<?, ?>) input).containsKey("body")) {
                return createHttpResponse(errorResult);
            } else {
                return errorResult;
            }
        }
    }
    
    private String extractClassName(String filename, String code) {
        // Extract from filename first
        if (filename.endsWith(".java")) {
            String name = filename.substring(0, filename.length() - 5);
            if (name.matches("[A-Za-z][A-Za-z0-9_]*")) {
                return name;
            }
        }
        
        // Extract from code
        Pattern classPattern = Pattern.compile("public\\s+class\\s+([A-Za-z][A-Za-z0-9_]*)");
        java.util.regex.Matcher matcher = classPattern.matcher(code);
        if (matcher.find()) {
            return matcher.group(1);
        }
        
        return "Main"; // Default fallback
    }
    
    private boolean isCodeSafe(String code) {
        // Check for dangerous patterns
        if (DANGEROUS_PATTERN.matcher(code).find()) {
            return false;
        }
        
        // Check for additional dangerous constructs
        String[] dangerousKeywords = {
            "System.exit", "Runtime.getRuntime", "ProcessBuilder",
            "Thread.sleep", "File(", "FileWriter", "FileReader", "FileInputStream", "FileOutputStream",
            "Socket", "ServerSocket", "URL(", "URLConnection", "HttpURLConnection",
            "ClassLoader", "SecurityManager", "Package.",
            "native ", "strictfp ", "synchronized ", "volatile ",
            "java.lang.reflect", "java.net", "java.io.File", "java.nio.file",
            "java.security", "java.sql", "javax.script",
            "java.awt", "javax.swing"
        };
        
        String codeLower = code.toLowerCase();
        for (String keyword : dangerousKeywords) {
            if (codeLower.contains(keyword.toLowerCase())) {
                return false;
            }
        }
        
        return true;
    }
    
    private ExecutionResult executeJavaCode(String code, String filename, String className) {
        // Create temporary directory
        Path tempDir;
        try {
            tempDir = Files.createTempDirectory("java_execution");
        } catch (IOException e) {
            return new ExecutionResult(false, "", "Failed to create temporary directory: " + e.getMessage());
        }
        
        try {
            // Ensure proper filename matches class name
            String properFilename = className + ".java";
            Path javaFile = tempDir.resolve(properFilename);
            Path classDir = tempDir.resolve("classes");
            Files.createDirectories(classDir);
            
            // Write Java code to file
            Files.write(javaFile, code.getBytes("UTF-8"));
            
            // Compile the Java code
            CompileResult compileResult = compileJava(javaFile, classDir);
            if (!compileResult.success) {
                return new ExecutionResult(false, "", "Compilation failed: " + compileResult.error);
            }
            
            // Execute the compiled Java code
            return executeCompiledJava(classDir, className);
            
        } catch (Exception e) {
            return new ExecutionResult(false, "", "Execution failed: " + e.getMessage());
        } finally {
            // Clean up temporary files
            deleteDirectory(tempDir);
        }
    }
    
    private CompileResult compileJava(Path javaFile, Path classDir) {
        try {
            ProcessBuilder pb = new ProcessBuilder(
                "javac", 
                "-d", classDir.toString(),
                "-cp", classDir.toString(),
                "-Xlint:deprecation",
                "-Xlint:unchecked",
                javaFile.toString()
            );
            
            pb.redirectErrorStream(true);
            Process process = pb.start();
            
            // Wait for compilation with timeout
            boolean finished = process.waitFor(45, TimeUnit.SECONDS);
            if (!finished) {
                process.destroyForcibly();
                return new CompileResult(false, "Compilation timeout (45 seconds)");
            }
            
            // Get compilation output
            StringBuilder output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line).append("\n");
                }
            }
            
            if (process.exitValue() != 0) {
                return new CompileResult(false, output.toString().trim());
            }
            
            return new CompileResult(true, "");
            
        } catch (Exception e) {
            return new CompileResult(false, "Compilation error: " + e.getMessage());
        }
    }
    
    private ExecutionResult executeCompiledJava(Path classDir, String className) {
        try {
            ProcessBuilder pb = new ProcessBuilder(
                "java",
                "-cp", classDir.toString(),
                "-Xms32m",
                "-Xmx256m",
                "-XX:+UseSerialGC",
                "-Djava.security.manager=default",
                "-Djava.security.policy=all.policy",
                "-Djava.awt.headless=true",
                className
            );
            
            pb.redirectErrorStream(true);
            Process process = pb.start();
            
            // Create executor for handling timeout
            ExecutorService executor = Executors.newSingleThreadExecutor();
            Future<String> outputFuture = executor.submit(() -> {
                StringBuilder output = new StringBuilder();
                try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        output.append(line).append("\n");
                        
                        // Prevent excessive output
                        if (output.length() > 10000) {
                            process.destroyForcibly();
                            return output.toString() + "\n[Output truncated - limit exceeded]";
                        }
                    }
                } catch (IOException e) {
                    return "Error reading output: " + e.getMessage();
                }
                return output.toString();
            });
            
            try {
                // Wait for execution with timeout
                String output = outputFuture.get(EXECUTION_TIMEOUT_SECONDS, TimeUnit.SECONDS);
                
                // Wait for process to complete
                boolean finished = process.waitFor(2, TimeUnit.SECONDS);
                if (!finished) {
                    process.destroyForcibly();
                }
                
                return new ExecutionResult(true, output.trim(), "");
                
            } catch (TimeoutException e) {
                process.destroyForcibly();
                outputFuture.cancel(true);
                return new ExecutionResult(false, "", "Execution timeout (" + EXECUTION_TIMEOUT_SECONDS + " seconds)");
            } finally {
                executor.shutdown();
            }
            
        } catch (Exception e) {
            return new ExecutionResult(false, "", "Execution error: " + e.getMessage());
        }
    }
    
    private void deleteDirectory(Path path) {
        try {
            Files.walk(path)
                .sorted((a, b) -> b.compareTo(a))
                .forEach(p -> {
                    try {
                        Files.deleteIfExists(p);
                    } catch (IOException e) {
                        // Ignore cleanup errors
                    }
                });
        } catch (IOException e) {
            // Ignore cleanup errors
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
    
    private Map<String, Object> createHttpResponse(Map<String, Object> result) {
        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", 200);
        
        Map<String, String> headers = new HashMap<>();
        headers.put("Content-Type", "application/json");
        headers.put("Access-Control-Allow-Origin", "*");
        headers.put("Access-Control-Allow-Methods", "POST");
        headers.put("Access-Control-Allow-Headers", "*");
        response.put("headers", headers);
        
        try {
            response.put("body", objectMapper.writeValueAsString(result));
        } catch (Exception e) {
            response.put("body", "{\"success\":false,\"error\":\"Response serialization failed\"}");
        }
        
        return response;
    }
    
    // Helper classes
    private static class ExecutionResult {
        final boolean success;
        final String output;
        final String error;
        
        ExecutionResult(boolean success, String output, String error) {
            this.success = success;
            this.output = output;
            this.error = error;
        }
    }
    
    private static class CompileResult {
        final boolean success;
        final String error;
        
        CompileResult(boolean success, String error) {
            this.success = success;
            this.error = error;
        }
    }
}
