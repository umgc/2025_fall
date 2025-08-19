package com.focusedai.model.testcase;

public class TestCase {
    private String id;
    private String assignmentId;
    private String name;
    private String description;
    private String input;
    private String expectedOutput;
    private double points;
    private boolean isVisible = true;
    private boolean isRequired = true;
    private int timeoutMs = 30000;
    private String category = "FUNCTIONAL"; // FUNCTIONAL, PERFORMANCE, EDGE_CASE
    
    // Constructors
    public TestCase() {}
    
    public TestCase(String name, String input, String expectedOutput, double points) {
        this.name = name;
        this.input = input;
        this.expectedOutput = expectedOutput;
        this.points = points;
    }
    
    // Getters and setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    
    public String getAssignmentId() { return assignmentId; }
    public void setAssignmentId(String assignmentId) { this.assignmentId = assignmentId; }
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    
    public String getInput() { return input; }
    public void setInput(String input) { this.input = input; }
    
    public String getExpectedOutput() { return expectedOutput; }
    public void setExpectedOutput(String expectedOutput) { this.expectedOutput = expectedOutput; }
    
    public double getPoints() { return points; }
    public void setPoints(double points) { this.points = points; }
    
    public boolean isVisible() { return isVisible; }
    public void setVisible(boolean visible) { isVisible = visible; }
    
    public boolean isRequired() { return isRequired; }
    public void setRequired(boolean required) { isRequired = required; }
    
    public int getTimeoutMs() { return timeoutMs; }
    public void setTimeoutMs(int timeoutMs) { this.timeoutMs = timeoutMs; }
    
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
}