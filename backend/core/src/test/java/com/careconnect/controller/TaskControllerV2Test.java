package com.careconnect.controller;

import static org.hamcrest.Matchers.is;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.careconnect.controller.v2.TaskControllerV2;
import com.careconnect.dto.v2.TaskDtoV2;
import com.careconnect.service.v2.TaskServiceV2;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Unit tests for {@link TaskControllerV2}.
 *
 * <p>
 * Uses {@link WebMvcTest} to test the controller layer in isolation
 * with a mocked {@link TaskServiceV2}.
 * </p>
 */
@WebMvcTest(TaskControllerV2.class)
@AutoConfigureMockMvc(addFilters = false)
class TaskControllerV2Test {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private TaskServiceV2 taskService;

    @Autowired
    private ObjectMapper objectMapper;

    private TaskDtoV2 sampleTask;

    @BeforeEach
    void setup() {
        sampleTask = TaskDtoV2.builder()
                .id(1L)
                .name("Check Blood Pressure")
                .description("Daily vitals check")
                .isCompleted(false)
                .taskType("Health")
                .build();
    }

    // --------------------------------------------------------------------------
    // GET /v2/api/tasks
    // --------------------------------------------------------------------------
    @Test
    @DisplayName("GET /v2/api/tasks should return all tasks")
    void testGetAllTasks() throws Exception {
        Mockito.when(taskService.getAllTasks()).thenReturn(List.of(sampleTask));

        mockMvc.perform(get("/v2/api/tasks"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].name", is("Check Blood Pressure")))
                .andExpect(jsonPath("$[0].id", is(1)));

        Mockito.verify(taskService).getAllTasks();
    }

    // --------------------------------------------------------------------------
    // GET /v2/api/tasks/{id}
    // --------------------------------------------------------------------------
    @Test
    @DisplayName("GET /v2/api/tasks/{id} should return a single task")
    void testGetTaskById() throws Exception {
        Mockito.when(taskService.getTaskDtoById(1L)).thenReturn(sampleTask);

        mockMvc.perform(get("/v2/api/tasks/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name", is("Check Blood Pressure")))
                .andExpect(jsonPath("$.id", is(1)));

        Mockito.verify(taskService).getTaskDtoById(1L);
    }

    // --------------------------------------------------------------------------
    // GET /v2/api/tasks/patient/{patientId}
    // --------------------------------------------------------------------------
    @Test
    @DisplayName("GET /v2/api/tasks/patient/{patientId} should return patient tasks")
    void testGetTasksByPatient() throws Exception {
        Mockito.when(taskService.getTasksByPatient(5L)).thenReturn(List.of(sampleTask));

        mockMvc.perform(get("/v2/api/tasks/patient/5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].name", is("Check Blood Pressure")));

        Mockito.verify(taskService).getTasksByPatient(5L);
    }

    // --------------------------------------------------------------------------
    // POST /v2/api/tasks/patient/{patientId}
    // --------------------------------------------------------------------------
    @Test
    @DisplayName("POST /v2/api/tasks/patient/{patientId} should create a task")
    void testCreateTask() throws Exception {
        Mockito.when(taskService.createTask(eq(5L), any(TaskDtoV2.class))).thenReturn(sampleTask);

        mockMvc.perform(post("/v2/api/tasks/patient/5")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(sampleTask)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name", is("Check Blood Pressure")));

        Mockito.verify(taskService).createTask(eq(5L), any(TaskDtoV2.class));
    }

    // --------------------------------------------------------------------------
    // PUT /v2/api/tasks/{id}
    // --------------------------------------------------------------------------
    @Test
    @DisplayName("PUT /v2/api/tasks/{id} should update a task")
    void testUpdateTask() throws Exception {
        TaskDtoV2 updated = TaskDtoV2.builder()
                .id(sampleTask.getId())
                .name(sampleTask.getName())
                .description(sampleTask.getDescription())
                .isCompleted(true)
                .taskType(sampleTask.getTaskType())
                .build();

        Mockito.when(taskService.updateTask(eq(1L), any(TaskDtoV2.class))).thenReturn(updated);

        mockMvc.perform(put("/v2/api/tasks/1")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(updated)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.completed", is(true)));

        Mockito.verify(taskService).updateTask(eq(1L), any(TaskDtoV2.class));
    }

    // --------------------------------------------------------------------------
    // PUT /v2/api/tasks/{id}/complete
    // --------------------------------------------------------------------------
    @Test
    @DisplayName("PUT /v2/api/tasks/{id}/complete should update completion status")
    void testUpdateTaskCompletion() throws Exception {
        TaskDtoV2 updated = TaskDtoV2.builder()
                .id(sampleTask.getId())
                .name(sampleTask.getName())
                .description(sampleTask.getDescription())
                .isCompleted(true)
                .taskType(sampleTask.getTaskType())
                .build();

        Mockito.when(taskService.updateCompletionStatus(1L, true)).thenReturn(updated);

        mockMvc.perform(put("/v2/api/tasks/1/complete")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("isComplete", true))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.completed", is(true)));

        Mockito.verify(taskService).updateCompletionStatus(1L, true);
    }

    // --------------------------------------------------------------------------
    // DELETE /v2/api/tasks/{id}
    // --------------------------------------------------------------------------
    @Test
    @DisplayName("DELETE /v2/api/tasks/{id} should call service and return 204")
    void testDeleteTask() throws Exception {
        mockMvc.perform(delete("/v2/api/tasks/1")
                .param("deleteSeries", "false"))
                .andExpect(status().isNoContent());

        Mockito.verify(taskService).deleteTask(1L, false);
    }
}
