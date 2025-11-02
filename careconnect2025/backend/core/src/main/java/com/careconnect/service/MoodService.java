package com.careconnect.service;

import com.careconnect.model.Mood;
import com.careconnect.repository.MoodRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class MoodService {

    @Autowired
    private MoodRepository moodRepository;

    public Mood saveMood(Long userId, int score, String label) {
        Mood mood = new Mood(userId, score, label);
        return moodRepository.save(mood);
    }

    public List<Mood> getMoods(Long userId) {
        return moodRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }
}
