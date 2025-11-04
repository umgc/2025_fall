package com.careconnect.repository;

import com.careconnect.model.Mood;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MoodRepository extends JpaRepository<Mood, Long> {
    List<Mood> findByUserIdOrderByCreatedAtDesc(Long userId);
}
