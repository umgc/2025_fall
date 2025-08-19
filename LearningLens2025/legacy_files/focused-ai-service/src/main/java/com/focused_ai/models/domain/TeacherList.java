package com.focused_ai.models.domain;

import java.util.List;
import lombok.Data;

@Data
public class TeacherList {
    private List<Teacher> teachers;

    public List<Teacher> getTeachers() { return teachers; }
    public void setTeachers(List<Teacher> teachers) { this.teachers = teachers; }
}