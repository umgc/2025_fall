package com.careconnect.controller;

import org.springframework.web.bind.annotation.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/alexa")
public class alexaController {
    // In-memory storage that resets when application restarts
    private List<String> reminders = new ArrayList<>(List.of(
            "Appointment at 9 A.M.",
            "Meds ready",
            "Test Appointment"));

    @GetMapping("/calenderReminders")
    public List<String> getReminders() {
        return reminders;
    }
    
    @PostMapping("/calenderReminders")
    public Map<String, Object> addReminder(@RequestBody Map<String, String> request) {
        String reminderText = request.get("reminder");
        
        if (reminderText != null && !reminderText.trim().isEmpty()) {
            reminders.add(reminderText);
            return Map.of(
                "success", true,
                "message", "Reminder added successfully",
                "reminder", reminderText
            );
        } else {
            return Map.of(
                "success", false,
                "message", "Reminder text cannot be empty"
            );
        }
    }
}