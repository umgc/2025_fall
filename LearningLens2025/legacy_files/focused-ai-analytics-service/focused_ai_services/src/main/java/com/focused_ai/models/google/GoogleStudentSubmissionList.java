package com.focused_ai.models.google;

import java.util.List;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class GoogleStudentSubmissionList {
    private List<GoogleStudentSubmission> studentSubmissions;

    public List<GoogleStudentSubmission> getStudentSubmissions() {
        return studentSubmissions;
    }

    public void setStudentSubmissions(List<GoogleStudentSubmission> studentSubmissions) {
        this.studentSubmissions = studentSubmissions;
    }
}
