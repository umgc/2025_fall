package com.focusedai.model.execution;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;

public class CodeAnalysis {
    private String language;
    private int fileCount;
    private boolean hasMainMethod;
    private boolean hasScanner;
    private boolean hasFileIO;
    private boolean hasTestAnnotations;
    private boolean hasSystemOut;
    private boolean isPackageExecution;
    private String packageName;
    private String mainClassName;
    private String recommendedStrategy;
    private String targetMethod;
    private List<String> classNames = new ArrayList<>();
    private List<String> publicMethods = new ArrayList<>();
    private List<String> detectedFeatures = new ArrayList<>();
    private double confidence;
    
    // Constructors
    public CodeAnalysis() {}
    
    // Convert to map for serialization
    public Map<String, Object> toMap() {
        Map<String, Object> map = new HashMap<>();
        map.put("language", language);
        map.put("fileCount", fileCount);
        map.put("hasMainMethod", hasMainMethod);
        map.put("hasScanner", hasScanner);
        map.put("hasFileIO", hasFileIO);
        map.put("hasTestAnnotations", hasTestAnnotations);
        map.put("hasSystemOut", hasSystemOut);
        map.put("isPackageExecution", isPackageExecution);
        map.put("packageName", packageName);
        map.put("mainClassName", mainClassName);
        map.put("recommendedStrategy", recommendedStrategy);
        map.put("targetMethod", targetMethod);
        map.put("classNames", classNames);
        map.put("publicMethods", publicMethods);
        map.put("detectedFeatures", detectedFeatures);
        map.put("confidence", confidence);
        return map;
    }
    
    // Getters and setters
    public String getLanguage() { return language; }
    public void setLanguage(String language) { this.language = language; }
    
    public int getFileCount() { return fileCount; }
    public void setFileCount(int fileCount) { this.fileCount = fileCount; }
    
    public boolean isHasMainMethod() { return hasMainMethod; }
    public void setHasMainMethod(boolean hasMainMethod) { this.hasMainMethod = hasMainMethod; }
    
    public boolean isHasScanner() { return hasScanner; }
    public void setHasScanner(boolean hasScanner) { this.hasScanner = hasScanner; }
    
    public boolean isHasFileIO() { return hasFileIO; }
    public void setHasFileIO(boolean hasFileIO) { this.hasFileIO = hasFileIO; }
    
    public boolean isHasTestAnnotations() { return hasTestAnnotations; }
    public void setHasTestAnnotations(boolean hasTestAnnotations) { this.hasTestAnnotations = hasTestAnnotations; }
    
    public boolean isHasSystemOut() { return hasSystemOut; }
    public void setHasSystemOut(boolean hasSystemOut) { this.hasSystemOut = hasSystemOut; }
    
    public boolean isPackageExecution() { return isPackageExecution; }
    public void setPackageExecution(boolean packageExecution) { isPackageExecution = packageExecution; }
    
    public String getPackageName() { return packageName; }
    public void setPackageName(String packageName) { this.packageName = packageName; }
    
    public String getMainClassName() { return mainClassName; }
    public void setMainClassName(String mainClassName) { this.mainClassName = mainClassName; }
    
    public String getRecommendedStrategy() { return recommendedStrategy; }
    public void setRecommendedStrategy(String recommendedStrategy) { this.recommendedStrategy = recommendedStrategy; }
    
    public String getTargetMethod() { return targetMethod; }
    public void setTargetMethod(String targetMethod) { this.targetMethod = targetMethod; }
    
    public List<String> getClassNames() { return classNames; }
    public void setClassNames(List<String> classNames) { this.classNames = classNames; }
    
    public List<String> getPublicMethods() { return publicMethods; }
    public void setPublicMethods(List<String> publicMethods) { this.publicMethods = publicMethods; }
    
    public List<String> getDetectedFeatures() { return detectedFeatures; }
    public void setDetectedFeatures(List<String> detectedFeatures) { this.detectedFeatures = detectedFeatures; }
    
    public double getConfidence() { return confidence; }
    public void setConfidence(double confidence) { this.confidence = confidence; }
    
    @Override
    public String toString() {
        return String.format("CodeAnalysis{language='%s', strategy='%s', confidence=%.1f%%, features=%s}", 
                language, recommendedStrategy, confidence, detectedFeatures);
    }
}