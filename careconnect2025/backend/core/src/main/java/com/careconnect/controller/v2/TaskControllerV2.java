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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.careconnect.dto.v2.TaskDtoV2;
import com.careconnect.service.v2.TaskServiceV2;

@RestController
@RequestMapping("/v2/api/tasks")
public class TaskControllerV2 {

    private final TaskServiceV2 taskService;

    public TaskControllerV2(TaskServiceV2 taskService) {
        this.taskService = taskService;
    }

    @GetMapping
    public ResponseEntity<List<TaskDtoV2>> getAllTasks() {
        return ResponseEntity.ok(taskService.getAllTasks());
    }

    @GetMapping("/{id}")
    public ResponseEntity<TaskDtoV2> getTaskById(@PathVariable Long id) {
        return ResponseEntity.ok(taskService.getTaskDtoById(id));
    }

    @GetMapping("/patient/{patientId}")
    public ResponseEntity<List<TaskDtoV2>> getTasksByPatient(@PathVariable Long patientId) {
        return ResponseEntity.ok(taskService.getTasksByPatient(patientId));
    }

    @PostMapping("/patient/{patientId}")
    public ResponseEntity<TaskDtoV2> createTask(
            @PathVariable Long patientId,
            @RequestBody TaskDtoV2 task) {
        return ResponseEntity.ok(taskService.createTask(patientId, task));
    }

    @PutMapping("/{id}")
    public ResponseEntity<TaskDtoV2> updateTask(
            @PathVariable Long id,
            @RequestBody TaskDtoV2 task) {
        return ResponseEntity.ok(taskService.updateTask(id, task));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTask(
            @PathVariable Long id,
            @RequestParam(name = "deleteSeries", defaultValue = "false") boolean deleteSeries) {
        taskService.deleteTask(id, deleteSeries);
        return ResponseEntity.noContent().build();
    }

}