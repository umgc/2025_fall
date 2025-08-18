package com.focused_ai.models.google;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class GoogleCourseList {
    private List<GoogleCourse> courses;

    public List<GoogleCourse> getCourses() { return courses; }
    public void setCourses(List<GoogleCourse> courses) { this.courses = courses; }
}