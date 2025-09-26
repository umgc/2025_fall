package com.careconnect.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.careconnect.model.Task;
import com.careconnect.model.User;

public interface TaskRepository extends JpaRepository<Task, Long> {
    Optional<List<Task>> findByPatient(User user);

    Optional<List<Task>> findByPatientId(Long patientId);

    List<Task> findByParentTaskId(Long parentTaskId);

}
