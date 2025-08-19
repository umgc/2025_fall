package com.focused_ai.models.domain;

import java.util.List;
import lombok.Data;

@Data
public class CourseList {
    private List<Course> courses;

    public List<Course> getCourses() { return courses; }
    public void setCourses(List<Course> courses) { this.courses = courses; }
}