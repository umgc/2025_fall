package com.focused_ai.models.moodle;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class MoodleStudentList {
    private List<MoodleStudent> students;

    public List<MoodleStudent> getStudents() { return students; }
    public void setStudents(List<MoodleStudent> students) { this.students = students; }
}