package com.focused_ai.controllers;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.focused_ai.DTOs.AssessmentDto;
import com.focused_ai.DTOs.CourseDto;
import com.focused_ai.DTOs.ParticipantDto;
import com.focused_ai.DTOs.QuestionStatsDto;
import com.focused_ai.services.AnalyticsService;

@RestController
@RequestMapping("/analytics")
public class AnalyticsController {

    @Autowired
    private AnalyticsService analyticsService;

    @GetMapping("/courses")
    public List<CourseDto> getCourses() {
        return analyticsService.getAllCourses();
    }

    @GetMapping("/assessments")
    public List<AssessmentDto> getAssessments(@RequestParam int courseId) {
        return analyticsService.getAssessments(courseId);
    }

    @GetMapping("/report")
    public List<ParticipantDto> getStudentReport(@RequestParam int courseId, @RequestParam int assessmentId) {
        return analyticsService.getStudentBreakdown(courseId, assessmentId);
    }

    @GetMapping("/questions")
    public List<QuestionStatsDto> getQuestionStats(@RequestParam int assessmentId) {
        return analyticsService.getQuestionStats(assessmentId);
    }

    @PostMapping("/ai/analyze")
    public List<Map<String, Object>> analyzeWithAI(@RequestBody Map<String, String> request) {
        String prompt = request.get("prompt");
        return analyticsService.performAIAnalysis(prompt);
    }
}
