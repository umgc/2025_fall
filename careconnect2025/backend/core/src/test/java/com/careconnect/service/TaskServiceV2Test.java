package com.careconnect.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import com.careconnect.dto.v2.TaskDtoV2;
import com.careconnect.exception.TaskNotFoundException;
import com.careconnect.model.Patient;
import com.careconnect.model.Task;
import com.careconnect.repository.PatientRepository;
import com.careconnect.repository.TaskRepository;
import com.careconnect.service.v2.TaskServiceV2;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Unit tests for {@link TaskServiceV2}.
 * These tests focus on logic inside the service layer, mocking out database
 * dependencies.
 */
class TaskServiceV2Test {

    @Mock
    private TaskRepository taskRepository;

    @Mock
    private PatientRepository patientRepository;

    @InjectMocks
    private TaskServiceV2 taskService;

    private ObjectMapper mapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        taskService = new TaskServiceV2(taskRepository, patientRepository, mapper);
    }

    // --------------------------------------------------------------------------
    // getTaskById
    // --------------------------------------------------------------------------
    @Test
    @DisplayName("getTaskById should return task when found")
    void testGetTaskById_found() {
        Task task = Task.builder().id(1L).name("Test Task").build();
        when(taskRepository.findById(1L)).thenReturn(Optional.of(task));

        Task result = taskService.getTaskById(1L);

        assertNotNull(result);
        assertEquals("Test Task", result.getName());
        verify(taskRepository).findById(1L);
    }

    @Test
    @DisplayName("getTaskById should throw when not found")
    void testGetTaskById_notFound() {
        when(taskRepository.findById(99L)).thenReturn(Optional.empty());

        assertThrows(TaskNotFoundException.class, () -> taskService.getTaskById(99L));
        verify(taskRepository).findById(99L);
    }

    // --------------------------------------------------------------------------
    // getTasksByPatient
    // --------------------------------------------------------------------------
    @Test
    @DisplayName("getTasksByPatient should map entity list to DTOs")
    void testGetTasksByPatient() {
        Task t1 = Task.builder().id(1L).name("Check Vitals").build();
        Task t2 = Task.builder().id(2L).name("Take Medication").build();
        when(taskRepository.findByPatientId(5L)).thenReturn(Optional.of(List.of(t1, t2)));

        List<TaskDtoV2> dtos = taskService.getTasksByPatient(5L);

        assertEquals(2, dtos.size());
        assertEquals("Check Vitals", dtos.get(0).getName());
        verify(taskRepository).findByPatientId(5L);
    }

    // --------------------------------------------------------------------------
    // updateCompletionStatus
    // --------------------------------------------------------------------------
    @Test
    @DisplayName("updateCompletionStatus should update task completion and save")
    void testUpdateCompletionStatus() {
        Task task = Task.builder().id(1L).isCompleted(false).name("Do something").build();
        when(taskRepository.findById(1L)).thenReturn(Optional.of(task));
        when(taskRepository.save(any(Task.class))).thenAnswer(inv -> inv.getArgument(0));

        TaskDtoV2 result = taskService.updateCompletionStatus(1L, true);

        assertTrue(result.isCompleted());
        verify(taskRepository).save(any(Task.class));
    }

    // --------------------------------------------------------------------------
    // createTask
    // --------------------------------------------------------------------------
    @Test
    @DisplayName("createTask should save a new task for patient")
    void testCreateTask_savesNewTask() {
        Patient patient = Patient.builder().id(5L).build();
        when(patientRepository.findById(5L)).thenReturn(Optional.of(patient));

        TaskDtoV2 dto = TaskDtoV2.builder()
                .name("Daily Check")
                .description("Measure blood pressure")
                .date(LocalDate.now().toString())
                .timeOfDay("08:00")
                .frequency("daily")
                .interval(1)
                .count(1)
                .taskType("Health")
                .isCompleted(false)
                .build();

        when(taskRepository.save(any(Task.class))).thenAnswer(inv -> {
            Task saved = inv.getArgument(0);
            saved.setId(10L);
            return saved;
        });

        TaskDtoV2 result = taskService.createTask(5L, dto);

        assertNotNull(result);
        assertEquals("Daily Check", result.getName());
        assertEquals(10L, result.getId());
        verify(taskRepository, atLeastOnce()).save(any(Task.class));
        verify(patientRepository).findById(5L);
    }

    // --------------------------------------------------------------------------
    // existsById
    // --------------------------------------------------------------------------
    @Test
    @DisplayName("existsById should return true when repository finds a match")
    void testExistsById_true() {
        when(taskRepository.findById(7L)).thenReturn(Optional.of(Task.builder().id(7L).build()));

        assertTrue(taskService.existsById(7L));
    }

    @Test
    @DisplayName("existsById should return false when no match found")
    void testExistsById_false() {
        when(taskRepository.findById(8L)).thenReturn(Optional.empty());

        assertFalse(taskService.existsById(8L));
    }

    // --------------------------------------------------------------------------
    // getAllTasks
    // --------------------------------------------------------------------------
    @Test
    @DisplayName("getAllTasks should map all tasks to DTOs")
    void testGetAllTasks() {
        Task t1 = Task.builder().id(1L).name("Task1").build();
        Task t2 = Task.builder().id(2L).name("Task2").build();
        when(taskRepository.findAll()).thenReturn(List.of(t1, t2));

        List<TaskDtoV2> result = taskService.getAllTasks();

        assertEquals(2, result.size());
        assertEquals("Task1", result.get(0).getName());
        verify(taskRepository).findAll();
    }

    @Test
    @DisplayName("getAllTasks should throw if repository empty")
    void testGetAllTasks_emptyThrows() {
        when(taskRepository.findAll()).thenReturn(List.of());

        assertThrows(TaskNotFoundException.class, () -> taskService.getAllTasks());
    }

    // --------------------------------------------------------------------------
    // Internal logic (calculateCount) – tested indirectly using reflection
    // --------------------------------------------------------------------------
    @Test
    @DisplayName("calculateCount should compute correct number of days for daily recurrence")
    void testCalculateCount_daily() throws Exception {
        var method = TaskServiceV2.class.getDeclaredMethod(
                "calculateCount", LocalDate.class, LocalDate.class, String.class, int.class, List.class);
        method.setAccessible(true);

        int result = (int) method.invoke(taskService,
                LocalDate.of(2025, 1, 1),
                LocalDate.of(2025, 1, 5),
                "daily", 1, null);

        assertEquals(5, result);
    }

    @Test
    @DisplayName("calculateCount weekly with daysOfWeek mask should count correctly")
    void testCalculateCount_weeklyDays() throws Exception {
        var method = TaskServiceV2.class.getDeclaredMethod(
                "calculateCount", LocalDate.class, LocalDate.class, String.class, int.class, List.class);
        method.setAccessible(true);

        // daysOfWeek = Sunday + Wednesday true (Sun=0)
        List<Boolean> days = List.of(true, false, false, true, false, false, false);

        int result = (int) method.invoke(taskService,
                LocalDate.of(2025, 1, 1),
                LocalDate.of(2025, 1, 15),
                "weekly", 1, days);

        assertTrue(result > 0);
    }
}
