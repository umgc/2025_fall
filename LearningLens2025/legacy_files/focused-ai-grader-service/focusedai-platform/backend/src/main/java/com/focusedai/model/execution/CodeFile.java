package com.focusedai.model.execution;

public class CodeFile {
    private String filename;
    private String content;
    private String language;
    
    // Constructors
    public CodeFile() {}
    
    public CodeFile(String filename, String content, String language) {
        this.filename = filename;
        this.content = content;
        this.language = language;
    }
    
    // Getters and setters
    public String getFilename() { return filename; }
    public void setFilename(String filename) { this.filename = filename; }
    
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    
    public String getLanguage() { return language; }
    public void setLanguage(String language) { this.language = language; }
}