package com.focusedai.controller;

import com.focusedai.service.lms.AssignmentService;
import com.focusedai.dto.AssignmentDto;
import com.focusedai.dto.SubmissionDto;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/assignments")
public class AssignmentController {

    @Autowired
    private AssignmentService assignmentService;

    @GetMapping("/{assignmentId}")
    public ResponseEntity<AssignmentDto> getAssignment(
            @PathVariable String assignmentId,
            @RequestHeader(value = "Authorization", required = false) String userContext) {
        
        AssignmentDto assignment = assignmentService.getAssignment(assignmentId, userContext);
        return ResponseEntity.ok(assignment);
    }

    @GetMapping("/{assignmentId}/submissions")
    public ResponseEntity<List<SubmissionDto>> getSubmissions(
            @PathVariable String assignmentId,
            @RequestHeader(value = "Authorization", required = false) String userContext) {
        
        List<SubmissionDto> submissions = assignmentService.getSubmissions(assignmentId, userContext);
        return ResponseEntity.ok(submissions);
    }
}