package com.focused_ai.models.domain;

import java.util.List;
import lombok.Data;

@Data
public class StudentList {
    private List<Student> students;

    public List<Student> getStudents() { return students; }
    public void setStudents(List<Student> students) { this.students = students; }
}