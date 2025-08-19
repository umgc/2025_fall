package com.focused_ai.models.domain;

import java.util.List;

public class CourseWorkWithSubmissions {
    private String courseWorkId;
    private String title;
    private String workType;
    private List<Grade> grades;

    public CourseWorkWithSubmissions(String courseWorkId, String title, String workType, List<Grade> grades) {
        this.courseWorkId = courseWorkId;
        this.title = title;
        this.workType = workType;
        this.grades = grades;
    }

    public String getCourseWorkId() { return courseWorkId; }
    public String getTitle() { return title; }
    public String getWorkType() { return workType; }
    public List<Grade> getGrades() { return grades; }
}
