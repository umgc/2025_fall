package com.focused_ai.DTOs;

public class CourseDto {
    public int id;
    public String fullName;
    public String shortName;
    public String subject;

    public CourseDto(int id, String fullName, String shortName, String subject) {
        this.id = id;
        this.fullName = fullName;
        this.shortName = shortName;
        this.subject = subject;
    }
}
