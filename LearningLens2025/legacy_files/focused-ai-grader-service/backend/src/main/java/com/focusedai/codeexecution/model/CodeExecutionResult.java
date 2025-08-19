// Create this file: backend/src/main/java/com/focusedai/codeexecution/model/CodeExecutionResult.java

package com.focusedai.codeexecution.model;

public class CodeExecutionResult {
    private boolean success;
    private String output;
    private String error;
    private String language;
    private boolean serverless;
    private String architecture;
    private String endpoint;
    private String executionType;
    private Integer executionTimeMs;

    // Default constructor
    public CodeExecutionResult() {
        this.serverless = true;
        this.architecture = "100% Serverless";
    }

    // Constructor with basic fields
    public CodeExecutionResult(boolean success, String output, String error, String language) {
        this();
        this.success = success;
        this.output = output;
        this.error = error;
        this.language = language;
    }

    // Constructor with all fields
    public CodeExecutionResult(boolean success, String output, String error, String language, 
                              String executionType, Integer executionTimeMs) {
        this(success, output, error, language);
        this.executionType = executionType;
        this.executionTimeMs = executionTimeMs;
    }

    // Getters and Setters
    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public String getOutput() {
        return output;
    }

    public void setOutput(String output) {
        this.output = output;
    }

    public String getError() {
        return error;
    }

    public void setError(String error) {
        this.error = error;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public boolean isServerless() {
        return serverless;
    }

    public void setServerless(boolean serverless) {
        this.serverless = serverless;
    }

    public String getArchitecture() {
        return architecture;
    }

    public void setArchitecture(String architecture) {
        this.architecture = architecture;
    }

    public String getEndpoint() {
        return endpoint;
    }

    public void setEndpoint(String endpoint) {
        this.endpoint = endpoint;
    }

    public String getExecutionType() {
        return executionType;
    }

    public void setExecutionType(String executionType) {
        this.executionType = executionType;
    }

    public Integer getExecutionTimeMs() {
        return executionTimeMs;
    }

    public void setExecutionTimeMs(Integer executionTimeMs) {
        this.executionTimeMs = executionTimeMs;
    }

    // Utility methods
    public boolean hasOutput() {
        return output != null && !output.trim().isEmpty();
    }

    public boolean hasError() {
        return error != null && !error.trim().isEmpty();
    }

    public String getExecutionTimeFormatted() {
        if (executionTimeMs == null) {
            return "Unknown";
        }
        if (executionTimeMs < 1000) {
            return executionTimeMs + "ms";
        } else {
            return String.format("%.2fs", executionTimeMs / 1000.0);
        }
    }

    public String getStatusSummary() {
        if (success) {
            return "✅ Execution successful";
        } else if (hasError()) {
            return "❌ Execution failed: " + (error.length() > 50 ? error.substring(0, 50) + "..." : error);
        } else {
            return "❌ Execution failed";
        }
    }

    // Static factory methods for common scenarios
    public static CodeExecutionResult success(String output, String language) {
        return new CodeExecutionResult(true, output, "", language);
    }

    public static CodeExecutionResult error(String error, String language) {
        return new CodeExecutionResult(false, "", error, language);
    }

    public static CodeExecutionResult notConfigured(String language) {
        return new CodeExecutionResult(
            false, 
            "", 
            "Lambda URL not configured for " + language + ". Please configure lambda." + language.toLowerCase() + ".url in application.properties", 
            language.toUpperCase()
        );
    }

    // toString method for debugging
    @Override
    public String toString() {
        return "CodeExecutionResult{" +
                "success=" + success +
                ", language='" + language + '\'' +
                ", outputLength=" + (output != null ? output.length() : 0) +
                ", errorLength=" + (error != null ? error.length() : 0) +
                ", executionTimeMs=" + executionTimeMs +
                ", executionType='" + executionType + '\'' +
                '}';
    }

    // equals and hashCode methods
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        CodeExecutionResult that = (CodeExecutionResult) o;

        if (success != that.success) return false;
        if (serverless != that.serverless) return false;
        if (output != null ? !output.equals(that.output) : that.output != null) return false;
        if (error != null ? !error.equals(that.error) : that.error != null) return false;
        if (language != null ? !language.equals(that.language) : that.language != null) return false;
        if (architecture != null ? !architecture.equals(that.architecture) : that.architecture != null)
            return false;
        if (endpoint != null ? !endpoint.equals(that.endpoint) : that.endpoint != null) return false;
        if (executionType != null ? !executionType.equals(that.executionType) : that.executionType != null)
            return false;
        return executionTimeMs != null ? executionTimeMs.equals(that.executionTimeMs) : that.executionTimeMs == null;
    }

    @Override
    public int hashCode() {
        int result = (success ? 1 : 0);
        result = 31 * result + (output != null ? output.hashCode() : 0);
        result = 31 * result + (error != null ? error.hashCode() : 0);
        result = 31 * result + (language != null ? language.hashCode() : 0);
        result = 31 * result + (serverless ? 1 : 0);
        result = 31 * result + (architecture != null ? architecture.hashCode() : 0);
        result = 31 * result + (endpoint != null ? endpoint.hashCode() : 0);
        result = 31 * result + (executionType != null ? executionType.hashCode() : 0);
        result = 31 * result + (executionTimeMs != null ? executionTimeMs.hashCode() : 0);
        return result;
    }

    // Builder pattern for easy object creation
    public static class Builder {
        private boolean success;
        private String output = "";
        private String error = "";
        private String language;
        private String executionType;
        private Integer executionTimeMs;

        public Builder success(boolean success) {
            this.success = success;
            return this;
        }

        public Builder output(String output) {
            this.output = output;
            return this;
        }

        public Builder error(String error) {
            this.error = error;
            return this;
        }

        public Builder language(String language) {
            this.language = language;
            return this;
        }

        public Builder executionType(String executionType) {
            this.executionType = executionType;
            return this;
        }

        public Builder executionTimeMs(Integer executionTimeMs) {
            this.executionTimeMs = executionTimeMs;
            return this;
        }

        public CodeExecutionResult build() {
            return new CodeExecutionResult(success, output, error, language, executionType, executionTimeMs);
        }
    }

    // Static factory method for builder
    public static Builder builder() {
        return new Builder();
    }
}