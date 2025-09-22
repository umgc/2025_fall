package com.careconnect.service.v2;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.careconnect.dto.v2.TaskDtoV2;
import com.careconnect.exception.AppException;
import com.careconnect.model.Patient;
import com.careconnect.model.Task;
import com.careconnect.repository.PatientRepository;
import com.careconnect.repository.TaskRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;

@Service
@Transactional
public class TaskServiceV2 {

    private TaskRepository taskRepository;
    private PatientRepository patientRepository;

    public TaskServiceV2(TaskRepository taskRepository, PatientRepository patientRepository) {
        this.taskRepository = taskRepository;
        this.patientRepository = patientRepository;
    }

    public Task getTaskById(Long taskId) {
        return taskRepository.findById(taskId)
                .orElseThrow(() -> new AppException(HttpStatus.NOT_FOUND, "Task not found"));
    }

    public List<Task> getTasksByPatient(Long patientId) {
        Optional<List<Task>> tasksOpt = taskRepository.findByPatientId(patientId);
        return tasksOpt.orElseGet(ArrayList::new);
    }

    public Task createTask(Long patientId, TaskDtoV2 task) {
        // Get the patient and ensure it exists
        Patient patient = patientRepository.findById(patientId).orElseThrow(
                () -> new AppException(HttpStatus.NOT_FOUND, "Patient not found"));
        System.out.println("Creating task for patient: " + patient.getId());
        System.out.println("Task details: " + task);
        Task newTask = Task.builder()
                .name(task.getName())
                .description(task.getDescription())
                .date(task.getDate())
                .timeOfDay(task.getTimeOfDay())
                .isCompleted(task.isCompleted())
                .frequency(task.getFrequency())
                .taskInterval(task.getInterval() != null ? task.getInterval() : 0)
                .doCount(task.getCount() != null ? task.getCount() : 0)
                .daysOfWeek(task.getDaysOfWeek())
                .taskType(task.getTaskType())
                .patient(patient)
                .build();
        System.out.println("New task created: " + newTask);
        ObjectMapper mapper = new ObjectMapper();
        mapper.enable(SerializationFeature.INDENT_OUTPUT);
        try {
            String jsonString = mapper.writeValueAsString(newTask);
            System.out.println("Serialized task: " + jsonString);
            return taskRepository.save(newTask);
        } catch (Exception e) {
            throw new AppException(HttpStatus.INTERNAL_SERVER_ERROR,
                    "Failed to create task: " + e.getMessage());
        }
    }

    public Task updateTask(Long taskId, TaskDtoV2 task) {
        Task existingTask = getTaskById(taskId);

        // Reassign patient only if provided
        if (task.getPatientId() != null) {
            Patient newPatient = patientRepository.findById(task.getPatientId())
                    .orElseThrow(() -> new AppException(HttpStatus.NOT_FOUND, "Patient not found"));
            existingTask.setPatient(newPatient);
        }

        // Update fields as necessary
        existingTask.setName(task.getName());
        existingTask.setDescription(task.getDescription());
        existingTask.setDate(task.getDate());
        existingTask.setTimeOfDay(task.getTimeOfDay());
        existingTask.setCompleted(task.isCompleted());
        existingTask.setTaskType(task.getTaskType());
        existingTask.setFrequency(task.getFrequency());
        existingTask.setTaskInterval(task.getInterval());
        existingTask.setDoCount(task.getCount());
        existingTask.setDaysOfWeek(task.getDaysOfWeek());

        // Only overwrite recurrence fields if they’re provided
        if (task.getInterval() != null) {
            existingTask.setTaskInterval(task.getInterval());
        }
        if (task.getCount() != null) {
            existingTask.setDoCount(task.getCount());
        }

        // Save the updated task
        return taskRepository.save(existingTask);
    }

    public boolean deleteTask(Long taskId) {
        Task task = getTaskById(taskId);
        taskRepository.delete(task);
        return true;
    }

    public boolean existsById(Long taskId) {
        return taskRepository.findById(taskId).isPresent();
    }

    public List<Task> getAllTasks() {
        List<Task> tasks = taskRepository.findAll();
        if (tasks.isEmpty()) {
            throw new AppException(HttpStatus.NOT_FOUND, "No tasks found");
        }
        return tasks;
    }

    // Additional methods for TaskService can be added here
}
