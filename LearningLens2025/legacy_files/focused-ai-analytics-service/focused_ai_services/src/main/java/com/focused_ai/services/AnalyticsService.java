package com.focused_ai.services;

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.focused_ai.DTOs.AssessmentDto;
import com.focused_ai.DTOs.CourseDto;
import com.focused_ai.DTOs.ParticipantDto;
import com.focused_ai.DTOs.QuestionStatsDto;

@Service
public class AnalyticsService {

    public List<CourseDto> getAllCourses() {
        // Replace with real LMS call or DB fetch
        return List.of(new CourseDto(1, "Math 101", "MTH101", "Math"));
    }

    public List<AssessmentDto> getAssessments(int courseId) {
        return List.of(
            new AssessmentDto(10, "Essay 1", "essay"),
            new AssessmentDto(11, "Quiz 1", "quiz")
        );
    }

    public List<ParticipantDto> getStudentBreakdown(int courseId, int assessmentId) {
        return List.of(new ParticipantDto(100, "John Doe", 85.0));
    }

    public List<QuestionStatsDto> getQuestionStats(int assessmentId) {
        return List.of(new QuestionStatsDto(1, "MCQ", "What is 2+2?", 10, 2, 0, 12));
    }

    public List<Map<String, Object>> performAIAnalysis(String prompt) {
        // Fake OpenAI-style response for demo
        return List.of(
            Map.of("Student", "John Doe", "Status", "Excellent", "Comments", "Great performance"),
            Map.of("Student", "Jane Smith", "Status", "Needs Improvement", "Comments", "Struggled with key concepts")
        );
    }
}
