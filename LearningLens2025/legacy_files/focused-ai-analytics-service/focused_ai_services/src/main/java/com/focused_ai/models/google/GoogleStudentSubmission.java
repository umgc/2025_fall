package com.focused_ai.models.google;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class GoogleStudentSubmission {
   private String id;
    private String userId;
    private Integer assignedGrade;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public Integer getAssignedGrade() { return assignedGrade; }
    public void setAssignedGrade(Integer assignedGrade) { this.assignedGrade = assignedGrade; } 
}
