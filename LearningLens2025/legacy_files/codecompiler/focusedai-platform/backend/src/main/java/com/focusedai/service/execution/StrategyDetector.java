package com.focusedai.service.execution;

import com.focusedai.model.execution.ExecutionRequest;
import com.focusedai.model.execution.CodeAnalysis;
import com.focusedai.model.execution.CodeFile;

import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

@Service
public class StrategyDetector {

    // Java code analysis patterns
    private static final Pattern PACKAGE_PATTERN = Pattern.compile("package\\s+([a-zA-Z][a-zA-Z0-9_]*(?:\\.[a-zA-Z][a-zA-Z0-9_]*)*);");
    private static final Pattern CLASS_PATTERN = Pattern.compile("(?:public\\s+)?class\\s+([A-Za-z][A-Za-z0-9_]*)");
    private static final Pattern MAIN_METHOD_PATTERN = Pattern.compile("public\\s+static\\s+void\\s+main\\s*\\(\\s*String\\s*(?:\\[\\]|\\.\\.\\.)\\s*\\w*\\s*\\)");
    private static final Pattern PUBLIC_METHOD_PATTERN = Pattern.compile("public\\s+(?!static\\s+void\\s+main)\\w+\\s+(\\w+)\\s*\\([^)]*\\)");
    private static final Pattern SCANNER_PATTERN = Pattern.compile("Scanner|System\\.in|BufferedReader.*System\\.in");
    private static final Pattern FILE_IO_PATTERN = Pattern.compile("FileReader|FileWriter|Files\\.|BufferedWriter|PrintWriter");
    private static final Pattern TEST_PATTERN = Pattern.compile("@Test|assertEquals|assertTrue|assertFalse|assertNull|JUnit");
    private static final Pattern SYSTEM_OUT_PATTERN = Pattern.compile("System\\.out\\.print");
    
    /**
     * Analyze code and determine optimal execution strategy
     */
    public CodeAnalysis analyzeCode(ExecutionRequest request) {
        System.out.println("🔍 Analyzing code for strategy detection");
        
        CodeAnalysis analysis = new CodeAnalysis();
        analysis.setLanguage(request.getLanguage());
        
        if ("java".equalsIgnoreCase(request.getLanguage())) {
            return analyzeJavaCode(request, analysis);
        } else {
            return analyzeNonJavaCode(request, analysis);
        }
    }

    /**
     * Get available execution strategies
     */
    public Map<String, Object> getAvailableStrategies() {
        Map<String, Object> strategies = new HashMap<>();
        
        strategies.put("STDIN_STDOUT", Map.of(
            "name", "Standard Input/Output",
            "description", "Traditional main method with console input/output testing",
            "suitable", "Programs with main method that read from stdin and write to stdout",
            "languages", List.of("java", "python", "cpp", "javascript")
        ));
        
        strategies.put("METHOD_CALL", Map.of(
            "name", "Method Call Testing",
            "description", "Direct method invocation with parameter testing",
            "suitable", "Classes with public methods that can be tested independently",
            "languages", List.of("java", "python")
        ));
        
        strategies.put("UNIT_TEST", Map.of(
            "name", "Unit Testing",
            "description", "JUnit-style test method execution",
            "suitable", "Classes with @Test annotations or test methods",
            "languages", List.of("java")
        ));
        
        strategies.put("INTERACTIVE", Map.of(
            "name", "Interactive Programs",
            "description", "Multi-step interactive programs with user input",
            "suitable", "Programs with loops, menus, or multiple user interactions",
            "languages", List.of("java", "python", "cpp")
        ));
        
        strategies.put("FILE_IO", Map.of(
            "name", "File Input/Output",
            "description", "Programs that read from and write to files",
            "suitable", "Programs using FileReader, FileWriter, or Files API",
            "languages", List.of("java", "python", "cpp")
        ));
        
        return Map.of(
            "strategies", strategies,
            "defaultStrategy", "STDIN_STDOUT",
            "autoDetection", true
        );
    }

    // ========== JAVA CODE ANALYSIS ==========

    private CodeAnalysis analyzeJavaCode(ExecutionRequest request, CodeAnalysis analysis) {
        String combinedCode = combineFileContents(request.getFiles());
        
        // Basic structure analysis
        analysis.setFileCount(request.getFiles().size());
        analysis.setHasMainMethod(MAIN_METHOD_PATTERN.matcher(combinedCode).find());
        analysis.setHasScanner(SCANNER_PATTERN.matcher(combinedCode).find());
        analysis.setHasFileIO(FILE_IO_PATTERN.matcher(combinedCode).find());
        analysis.setHasTestAnnotations(TEST_PATTERN.matcher(combinedCode).find());
        analysis.setHasSystemOut(SYSTEM_OUT_PATTERN.matcher(combinedCode).find());
        
        // Extract package information
        Matcher packageMatcher = PACKAGE_PATTERN.matcher(combinedCode);
        if (packageMatcher.find()) {
            analysis.setPackageName(packageMatcher.group(1));
            analysis.setPackageExecution(true);
        } else {
            analysis.setPackageExecution(request.getFiles().size() > 1);
        }
        
        // Extract class names and find main class
        List<String> classNames = new ArrayList<>();
        Matcher classMatcher = CLASS_PATTERN.matcher(combinedCode);
        while (classMatcher.find()) {
            String className = classMatcher.group(1);
            classNames.add(className);
            
            if (analysis.getMainClassName() == null && analysis.isHasMainMethod()) {
                String classSection = extractClassSection(combinedCode, className);
                if (classSection != null && MAIN_METHOD_PATTERN.matcher(classSection).find()) {
                    analysis.setMainClassName(className);
                }
            }
        }
        analysis.setClassNames(classNames);
        
        // Find public methods
        List<String> publicMethods = new ArrayList<>();
        Matcher methodMatcher = PUBLIC_METHOD_PATTERN.matcher(combinedCode);
        while (methodMatcher.find()) {
            String methodName = methodMatcher.group(1);
            if (!"main".equals(methodName)) {
                publicMethods.add(methodName);
            }
        }
        analysis.setPublicMethods(publicMethods);
        
        // Determine execution strategy
        String strategy = determineJavaStrategy(analysis, combinedCode);
        analysis.setRecommendedStrategy(strategy);
        
        // Set target method for METHOD_CALL strategy
        if ("METHOD_CALL".equals(strategy) && !publicMethods.isEmpty()) {
            analysis.setTargetMethod(selectBestTargetMethod(publicMethods));
        }
        
        // Calculate confidence
        analysis.setConfidence(calculateConfidence(analysis, combinedCode));
        
        // Set detected features
        analysis.setDetectedFeatures(extractDetectedFeatures(analysis));
        
        System.out.println("📊 Java analysis complete: " + strategy + " (confidence: " + analysis.getConfidence() + "%)");
        
        return analysis;
    }

    private String determineJavaStrategy(CodeAnalysis analysis, String code) {
        System.out.println("🔍 Determining Java execution strategy...");
        
        // Priority order for strategy detection
        if (analysis.isHasTestAnnotations()) {
            System.out.println("🧪 Detected: UNIT_TEST (has test annotations)");
            return "UNIT_TEST";
        }
        
        if (analysis.isHasFileIO()) {
            System.out.println("📁 Detected: FILE_IO (file operations found)");
            return "FILE_IO";
        }
        
        if (detectInteractivePattern(code)) {
            System.out.println("💬 Detected: INTERACTIVE (interactive pattern)");
            return "INTERACTIVE";
        }
        
        if (analysis.isHasMainMethod() && analysis.isHasScanner()) {
            System.out.println("📥 Detected: STDIN_STDOUT (main + scanner)");
            return "STDIN_STDOUT";
        }
        
        if (analysis.isHasMainMethod() && analysis.isHasSystemOut()) {
            System.out.println("📤 Detected: STDIN_STDOUT (main + output)");
            return "STDIN_STDOUT";
        }
        
        if (!analysis.getPublicMethods().isEmpty() && !analysis.isHasMainMethod()) {
            System.out.println("🔧 Detected: METHOD_CALL (public methods, no main)");
            return "METHOD_CALL";
        }
        
        if (analysis.isHasMainMethod() && !analysis.getPublicMethods().isEmpty() && isSimpleMainMethod(code)) {
            System.out.println("🔧 Detected: METHOD_CALL (simple main + public methods)");
            return "METHOD_CALL";
        }
        
        // Default fallback
        System.out.println("📝 Default: STDIN_STDOUT");
        return "STDIN_STDOUT";
    }

    // ========== NON-JAVA CODE ANALYSIS ==========

    private CodeAnalysis analyzeNonJavaCode(ExecutionRequest request, CodeAnalysis analysis) {
        String combinedCode = combineFileContents(request.getFiles());
        
        analysis.setFileCount(request.getFiles().size());
        analysis.setRecommendedStrategy("STDIN_STDOUT"); // Default for non-Java
        analysis.setConfidence(70.0); // Lower confidence for non-Java analysis
        
        // Language-specific analysis
        switch (request.getLanguage().toLowerCase()) {
            case "python":
                analyzePythonCode(analysis, combinedCode);
                break;
            case "javascript":
                analyzeJavaScriptCode(analysis, combinedCode);
                break;
            case "cpp":
            case "c++":
                analyzeCppCode(analysis, combinedCode);
                break;
        }
        
        analysis.setDetectedFeatures(extractDetectedFeatures(analysis));
        
        return analysis;
    }

    private void analyzePythonCode(CodeAnalysis analysis, String code) {
        // Python-specific patterns
        boolean hasInput = code.contains("input(") || code.contains("sys.stdin");
        boolean hasPrint = code.contains("print(");
        boolean hasFileIO = code.contains("open(") || code.contains("with open");
        boolean hasDefFunctions = Pattern.compile("def\\s+\\w+\\s*\\(").matcher(code).find();
        
        analysis.setHasScanner(hasInput);
        analysis.setHasSystemOut(hasPrint);
        analysis.setHasFileIO(hasFileIO);
        
        if (hasFileIO) {
            analysis.setRecommendedStrategy("FILE_IO");
        } else if (hasDefFunctions && !hasInput) {
            analysis.setRecommendedStrategy("METHOD_CALL");
        }
        
        analysis.setConfidence(80.0);
    }

    private void analyzeJavaScriptCode(CodeAnalysis analysis, String code) {
        // JavaScript-specific patterns
        boolean hasConsoleLog = code.contains("console.log");
        boolean hasReadline = code.contains("readline") || code.contains("prompt");
        boolean hasFileIO = code.contains("fs.") || code.contains("require('fs')");
        boolean hasFunctions = Pattern.compile("function\\s+\\w+\\s*\\(").matcher(code).find();
        
        analysis.setHasSystemOut(hasConsoleLog);
        analysis.setHasScanner(hasReadline);
        analysis.setHasFileIO(hasFileIO);
        
        if (hasFileIO) {
            analysis.setRecommendedStrategy("FILE_IO");
        } else if (hasFunctions && !hasReadline) {
            analysis.setRecommendedStrategy("METHOD_CALL");
        }
        
        analysis.setConfidence(75.0);
    }

    private void analyzeCppCode(CodeAnalysis analysis, String code) {
        // C++ specific patterns
        boolean hasCout = code.contains("cout") || code.contains("printf");
        boolean hasCin = code.contains("cin") || code.contains("scanf");
        boolean hasFileIO = code.contains("fstream") || code.contains("ifstream") || code.contains("ofstream");
        boolean hasMainFunction = code.contains("int main(") || code.contains("void main(");
        
        analysis.setHasMainMethod(hasMainFunction);
        analysis.setHasSystemOut(hasCout);
        analysis.setHasScanner(hasCin);
        analysis.setHasFileIO(hasFileIO);
        
        if (hasFileIO) {
            analysis.setRecommendedStrategy("FILE_IO");
        }
        
        analysis.setConfidence(85.0);
    }

    // ========== HELPER METHODS ==========

    private String combineFileContents(List<CodeFile> files) {
        StringBuilder combined = new StringBuilder();
        for (CodeFile file : files) {
            if (file.getContent() != null) {
                combined.append(file.getContent()).append("\n");
            }
        }
        return combined.toString();
    }

    private boolean detectInteractivePattern(String code) {
        boolean hasLoop = Pattern.compile("while\\s*\\(|for\\s*\\(|do\\s*\\{").matcher(code).find();
        boolean hasMultipleInput = code.split("nextLine\\(\\)|next\\(\\)|nextInt\\(\\)").length > 3;
        boolean hasMenuPattern = Pattern.compile("menu|choice|option|select", Pattern.CASE_INSENSITIVE).matcher(code).find();
        return (hasLoop && hasMultipleInput) || hasMenuPattern;
    }

    private boolean isSimpleMainMethod(String code) {
        Pattern mainPattern = Pattern.compile("public\\s+static\\s+void\\s+main[^{]*\\{([^}]*)\\}", Pattern.DOTALL);
        Matcher matcher = mainPattern.matcher(code);
        
        if (matcher.find()) {
            String mainContent = matcher.group(1).trim();
            boolean isMinimal = mainContent.split("\n").length <= 5;
            boolean hasObjectCreation = Pattern.compile("new\\s+\\w+\\s*\\(").matcher(mainContent).find();
            boolean hasMethodCalls = Pattern.compile("\\w+\\.\\w+\\s*\\(").matcher(mainContent).find();
            boolean noComplexInput = !Pattern.compile("Scanner|nextLine|nextInt").matcher(mainContent).find();
            
            return isMinimal && (hasObjectCreation || hasMethodCalls) && noComplexInput;
        }
        
        return false;
    }

    private String extractClassSection(String code, String className) {
        Pattern classPattern = Pattern.compile("class\\s+" + className + "\\s*\\{", Pattern.CASE_INSENSITIVE);
        Matcher matcher = classPattern.matcher(code);
        
        if (matcher.find()) {
            int start = matcher.start();
            int braceCount = 0;
            int i = matcher.end() - 1;
            
            while (i < code.length()) {
                char c = code.charAt(i);
                if (c == '{') braceCount++;
                else if (c == '}') braceCount--;
                
                if (braceCount == 0) {
                    return code.substring(start, i + 1);
                }
                i++;
            }
        }
        
        return null;
    }

    private String selectBestTargetMethod(List<String> methods) {
        if (methods.size() == 1) {
            return methods.get(0);
        }
        
        // Prefer common method names
        String[] commonNames = {"add", "subtract", "multiply", "divide", "calculate", 
                               "process", "compute", "solve", "run", "execute"};
        
        for (String commonName : commonNames) {
            if (methods.contains(commonName)) {
                return commonName;
            }
        }
        
        return methods.get(0);
    }

    private double calculateConfidence(CodeAnalysis analysis, String code) {
        double confidence = 50.0; // Base confidence
        
        // Higher confidence factors
        if (analysis.isHasMainMethod()) confidence += 20;
        if (analysis.isHasTestAnnotations()) confidence += 30;
        if (analysis.isHasFileIO()) confidence += 25;
        if (!analysis.getPublicMethods().isEmpty()) confidence += 15;
        if (analysis.isHasScanner() || analysis.isHasSystemOut()) confidence += 10;
        
        // Interactive pattern detection
        if (detectInteractivePattern(code)) confidence += 20;
        
        return Math.min(95.0, confidence); // Cap at 95%
    }

    private List<String> extractDetectedFeatures(CodeAnalysis analysis) {
        List<String> features = new ArrayList<>();
        
        if (analysis.isHasMainMethod()) features.add("main_method");
        if (analysis.isHasScanner()) features.add("input_handling");
        if (analysis.isHasSystemOut()) features.add("output_generation");
        if (analysis.isHasFileIO()) features.add("file_operations");
        if (analysis.isHasTestAnnotations()) features.add("unit_tests");
        if (analysis.isPackageExecution()) features.add("package_structure");
        if (!analysis.getPublicMethods().isEmpty()) features.add("public_methods");
        if (analysis.getClassNames().size() > 1) features.add("multiple_classes");
        
        return features;
    }
}