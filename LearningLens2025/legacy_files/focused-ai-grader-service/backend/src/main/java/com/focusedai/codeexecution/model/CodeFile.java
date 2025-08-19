// Create this file: backend/src/main/java/com/focusedai/codeexecution/model/CodeFile.java

package com.focusedai.codeexecution.model;

public class CodeFile {
    private String filename;
    private String content;

    // Default constructor
    public CodeFile() {}

    // Constructor with parameters
    public CodeFile(String filename, String content) {
        this.filename = filename;
        this.content = content;
    }

    // Getters and Setters
    public String getFilename() {
        return filename;
    }

    public void setFilename(String filename) {
        this.filename = filename;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    // Utility method to get file extension
    public String getFileExtension() {
        if (filename == null || !filename.contains(".")) {
            return "";
        }
        return filename.substring(filename.lastIndexOf(".") + 1).toLowerCase();
    }

    // Utility method to get filename without extension
    public String getFilenameWithoutExtension() {
        if (filename == null || !filename.contains(".")) {
            return filename;
        }
        return filename.substring(0, filename.lastIndexOf("."));
    }

    // Utility method to detect programming language
    public String detectLanguage() {
        String extension = getFileExtension();
        switch (extension) {
            case "java":
                return "java";
            case "py":
                return "python";
            case "js":
                return "javascript";
            case "cpp":
            case "cc":
            case "cxx":
                return "cpp";
            case "c":
                return "cpp"; // Use C++ compiler for C files
            default:
                return "unknown";
        }
    }

    // Utility method to check if file is empty
    public boolean isEmpty() {
        return content == null || content.trim().isEmpty();
    }

    // Utility method to get content size
    public int getContentSize() {
        return content != null ? content.length() : 0;
    }

    // toString method for debugging
    @Override
    public String toString() {
        return "CodeFile{" +
                "filename='" + filename + '\'' +
                ", contentSize=" + getContentSize() +
                ", language='" + detectLanguage() + '\'' +
                '}';
    }

    // equals and hashCode methods
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        CodeFile codeFile = (CodeFile) o;

        if (filename != null ? !filename.equals(codeFile.filename) : codeFile.filename != null) return false;
        return content != null ? content.equals(codeFile.content) : codeFile.content == null;
    }

    @Override
    public int hashCode() {
        int result = filename != null ? filename.hashCode() : 0;
        result = 31 * result + (content != null ? content.hashCode() : 0);
        return result;
    }

    // Builder pattern for easy object creation
    public static class Builder {
        private String filename;
        private String content;

        public Builder filename(String filename) {
            this.filename = filename;
            return this;
        }

        public Builder content(String content) {
            this.content = content;
            return this;
        }

        public CodeFile build() {
            return new CodeFile(filename, content);
        }
    }

    // Static factory method for builder
    public static Builder builder() {
        return new Builder();
    }
}