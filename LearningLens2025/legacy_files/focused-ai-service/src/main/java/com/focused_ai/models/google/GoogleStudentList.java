package com.focused_ai.models.google;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class GoogleStudentList {
    private List<GoogleStudent> students;

    public List<GoogleStudent> getStudents() { return students; }
    public void setStudents(List<GoogleStudent> students) { this.students = students; }
}