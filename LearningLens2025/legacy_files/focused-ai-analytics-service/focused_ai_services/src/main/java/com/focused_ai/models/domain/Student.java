// src/main/java/com/example/model/Student.java
package com.focused_ai.models.domain;

public class Student {
    private String userId;
    private String name;
    private Double grade;

    public Student() {}

    public Student(String userId, String name, Double grade) {
        this.userId = userId;
        this.name = name;
        this.grade = grade;
    }

    // Getters and setters
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public Double getGrade() { return grade; }
    public void setGrade(Double grade) { this.grade = grade; }
}

