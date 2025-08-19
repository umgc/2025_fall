package com.focused_ai.models.moodle;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class MoodleTeacherList {
    private List<MoodleTeacher> teachers;

    public List<MoodleTeacher> getTeachers() { return teachers; }
    public void setTeachers(List<MoodleTeacher> teachers) { this.teachers = teachers; }
}