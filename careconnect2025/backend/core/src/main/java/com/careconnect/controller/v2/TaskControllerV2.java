package com.careconnect.controller.v2;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.careconnect.dto.v2.TaskDtoV2;
import com.careconnect.model.Task;
import com.careconnect.service.v2.TaskServiceV2;

@RestController
@RequestMapping("/v2/api/tasks")
public class TaskControllerV2 {

    private final TaskServiceV2 taskService;

    public TaskControllerV2(TaskServiceV2 taskService) {
        this.taskService = taskService;
    }

    @GetMapping
    public ResponseEntity<List<Task>> getAllTasks() {
        return ResponseEntity.ok(taskService.getAllTasks());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Task> getTaskById(@PathVariable Long id) {
        Task task = taskService.getTaskById(id);
        return task != null ? ResponseEntity.ok(task) : ResponseEntity.notFound().build();
    }

    @GetMapping("/patient/{patientId}")
    public ResponseEntity<List<Task>> getTasksByPatient(@PathVariable Long patientId) {
        return ResponseEntity.ok(taskService.getTasksByPatient(patientId));
    }

    @PostMapping("/patient/{patientId}")
    public ResponseEntity<Task> createTask(@PathVariable Long patientId, @RequestBody TaskDtoV2 task) {
        return ResponseEntity.ok(taskService.createTask(patientId, task));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Task> updateTask(@PathVariable Long id, @RequestBody TaskDtoV2 task) {
        Task updated = taskService.updateTask(id, task);
        return updated != null ? ResponseEntity.ok(updated) : ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTask(@PathVariable Long id) {
        return taskService.deleteTask(id) ? ResponseEntity.noContent().build() : ResponseEntity.notFound().build();
    }
}