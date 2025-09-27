package com.careconnect.service.v2;

import java.time.DayOfWeek;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.careconnect.dto.ScheduledNotificationDTO;
import com.careconnect.dto.v2.TaskDtoV2;
import com.careconnect.exception.ParentTaskNotFoundException;
import com.careconnect.exception.PatientNotFoundException;
import com.careconnect.exception.TaskNotFoundException;
import com.careconnect.model.Patient;
import com.careconnect.model.ScheduledNotification;
import com.careconnect.model.Task;
import com.careconnect.repository.PatientRepository;
import com.careconnect.repository.TaskRepository;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Service layer for managing tasks (API v2).
 *
 * <p>
 * This class contains business logic for creating, updating,
 * retrieving, and deleting tasks. It also handles recurrence
 * expansion, mapping between {@link Task} entities and
 * {@link TaskDtoV2} DTOs, and scheduling of associated
 * {@link ScheduledNotification}s.
 * </p>
 *
 * <p>
 * Key responsibilities:
 * <ul>
 * <li>CRUD operations on tasks</li>
 * <li>Recurrence expansion (daily, weekly, monthly, yearly)</li>
 * <li>Selective updates of recurring series</li>
 * <li>Mapping between entity and DTO representations</li>
 * <li>Notification management and time-shifting across occurrences</li>
 * </ul>
 * </p>
 */
@Service
@Transactional
public class TaskServiceV2 {

    private static final Logger log = LoggerFactory.getLogger(TaskServiceV2.class);
    private TaskRepository taskRepository;
    private PatientRepository patientRepository;
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ISO_LOCAL_DATE_TIME;
    private final ObjectMapper mapper;

    /**
     * Constructs the service with required repositories and mapper.
     *
     * @param taskRepository    repository for tasks
     * @param patientRepository repository for patients
     * @param mapper            Jackson object mapper
     */
    public TaskServiceV2(TaskRepository taskRepository, PatientRepository patientRepository, ObjectMapper mapper) {
        this.taskRepository = taskRepository;
        this.patientRepository = patientRepository;
        this.mapper = mapper;
    }

    /**
     * Retrieves a task entity by its ID.
     *
     * @param taskId the ID of the task
     * @return the {@link Task} entity
     * @throws TaskNotFoundException if task not found
     */
    public Task getTaskById(Long taskId) {
        return taskRepository.findById(taskId)
                .orElseThrow(() -> new TaskNotFoundException(taskId));
    }

    /**
     * Retrieves a task as a DTO by its ID.
     *
     * @param taskId the ID of the task
     * @return the {@link TaskDtoV2}
     */
    public TaskDtoV2 getTaskDtoById(Long taskId) {
        Task task = getTaskById(taskId);
        return mapToDto(task);
    }

    /**
     * Retrieves all tasks for a given patient.
     *
     * @param patientId the ID of the patient
     * @return list of {@link TaskDtoV2} objects (empty if none found)
     */
    public List<TaskDtoV2> getTasksByPatient(Long patientId) {
        Optional<List<Task>> tasksOpt = taskRepository.findByPatientId(patientId);
        return tasksOpt.orElseGet(ArrayList::new).stream()
                .map(this::mapToDto)
                .toList();
    }

    /**
     * Creates a new task for a patient. Expands recurrence
     * into additional occurrences if defined.
     *
     * @param patientId the ID of the patient
     * @param taskDto   DTO containing task details
     * @return the created {@link TaskDtoV2}
     */
    public TaskDtoV2 createTask(Long patientId, TaskDtoV2 taskDto) {
        Patient patient = patientRepository.findById(patientId)
                .orElseThrow(() -> new PatientNotFoundException(patientId));

        log.info("Creating task for patient: " + patient.getId());
        log.debug("Task details: " + taskDto);

        Task parentTask = Task.builder()
                .name(taskDto.getName())
                .description(taskDto.getDescription())
                .date(taskDto.getDate())
                .timeOfDay(taskDto.getTimeOfDay())
                .isCompleted(taskDto.isCompleted())
                .frequency(taskDto.getFrequency())
                .taskInterval(taskDto.getInterval() != null ? taskDto.getInterval() : 0)
                .doCount(taskDto.getCount() != null ? taskDto.getCount() : 0)
                .daysOfWeek(TaskMapper.serializeDays(taskDto.getDaysOfWeek()))
                .taskType(taskDto.getTaskType())
                .patient(patient)
                .parentTaskId(null)
                .build();
        if (taskDto.getNotifications() != null && !taskDto.getNotifications().isEmpty()) {
            for (ScheduledNotificationDTO n : taskDto.getNotifications()) {
                ScheduledNotification sn = ScheduledNotification.builder()
                        .receiverId(n.getReceiverId())
                        .title(n.getTitle())
                        .body(n.getBody())
                        .notificationType(n.getNotificationType())
                        .scheduledTime(LocalDateTime.parse(n.getScheduledTime(), FORMATTER))
                        .status("PENDING")
                        .task(parentTask)
                        .build();

                parentTask.getNotifications().add(sn);
            }
        }
        Task savedParent = taskRepository.save(parentTask);
        log.info("New task created: " + parentTask);

        // Expand occurrences if recurrence is defined
        if (taskDto.getFrequency() != null && taskDto.getCount() != null && taskDto.getCount() > 1) {
            generateOccurrences(savedParent, taskDto, patient);
        }

        return mapToDto(savedParent);

    }

    /**
     * Updates a task. Can apply updates to a single task
     * or an entire recurring series based on {@code updateSeries}.
     *
     * @param taskId  ID of the task to update
     * @param taskDto updated task details
     * @return the updated {@link TaskDtoV2}
     */
    public TaskDtoV2 updateTask(Long taskId, TaskDtoV2 taskDto) {
        Task existingTask = getTaskById(taskId);

        if (!Boolean.TRUE.equals(taskDto.getUpdateSeries())) {
            // Single-task update
            applyTaskUpdates(existingTask, taskDto, false);
            Task saved = taskRepository.save(existingTask);
            return mapToDto(saved);
        }

        // --- SERIES UPDATE ---
        Long parentId = (existingTask.getParentTaskId() != null)
                ? existingTask.getParentTaskId()
                : existingTask.getId();

        Task parentTask = (existingTask.getParentTaskId() == null)
                ? existingTask
                : taskRepository.findById(parentId)
                        .orElseThrow(() -> new ParentTaskNotFoundException(parentId));

        // Snapshot old fields to detect changes
        String oldName = parentTask.getName();
        String oldDesc = parentTask.getDescription();
        String oldType = parentTask.getTaskType();
        String oldFreq = parentTask.getFrequency();
        Integer oldInterval = parentTask.getTaskInterval();
        Integer oldCount = parentTask.getDoCount();
        String oldDays = parentTask.getDaysOfWeek();

        // 1) Update parent itself
        applyTaskUpdates(parentTask, taskDto, true);
        taskRepository.save(parentTask);

        // Detect changes
        boolean nameChanged = !java.util.Objects.equals(oldName, parentTask.getName());
        boolean descChanged = !java.util.Objects.equals(oldDesc, parentTask.getDescription());
        boolean typeChanged = !java.util.Objects.equals(oldType, parentTask.getTaskType());
        boolean freqChanged = !java.util.Objects.equals(oldFreq, parentTask.getFrequency());
        boolean intvChanged = !java.util.Objects.equals(oldInterval, parentTask.getTaskInterval());
        boolean countChanged = !java.util.Objects.equals(oldCount, parentTask.getDoCount());
        boolean daysChanged = !java.util.Objects.equals(oldDays, parentTask.getDaysOfWeek());

        // 2) Update children selectively
        List<Task> children = taskRepository.findByParentTaskId(parentId);
        for (Task child : children) {
            applySeriesFieldUpdatesToChild(child, taskDto,
                    nameChanged, descChanged, typeChanged,
                    freqChanged, intvChanged, countChanged, daysChanged);
        }
        taskRepository.saveAll(children);

        // 3) Ensure missing ones are added (never delete extras)
        TaskDtoV2 freshDto = mapToDto(parentTask);

        if (parentTask.getDate() != null) {
            String normalized = parentTask.getDate().length() >= 10
                    ? parentTask.getDate().substring(0, 10)
                    : parentTask.getDate();
            freshDto.setDate(normalized);
        }
        if (parentTask.getTimeOfDay() != null) {
            freshDto.setTimeOfDay(parentTask.getTimeOfDay());
        }
        generateOccurrences(parentTask, freshDto, parentTask.getPatient());

        return mapToDto(parentTask);
    }

    /**
     * Applies selective updates from a parent DTO to a child task
     * in a recurring series.
     *
     * <p>
     * This method is used during series updates to propagate
     * only the fields that actually changed on the parent, leaving
     * other child-specific details untouched (e.g., completion state).
     * </p>
     *
     * @param task         the child {@link Task} to update
     * @param dto          the updated task DTO
     * @param nameChanged  whether the name field changed
     * @param descChanged  whether the description field changed
     * @param typeChanged  whether the task type field changed
     * @param freqChanged  whether the frequency field changed
     * @param intvChanged  whether the interval field changed
     * @param countChanged whether the occurrence count changed
     * @param daysChanged  whether the days-of-week field changed
     */
    private void applySeriesFieldUpdatesToChild(
            Task task, TaskDtoV2 dto,
            boolean nameChanged, boolean descChanged, boolean typeChanged,
            boolean freqChanged, boolean intvChanged, boolean countChanged, boolean daysChanged) {
        if (nameChanged)
            task.setName(dto.getName());
        if (descChanged)
            task.setDescription(dto.getDescription());
        if (typeChanged)
            task.setTaskType(dto.getTaskType());

        if (freqChanged)
            task.setFrequency(dto.getFrequency());
        if (intvChanged)
            task.setTaskInterval(dto.getInterval());
        if (countChanged)
            task.setDoCount(dto.getCount());
        if (daysChanged)
            task.setDaysOfWeek(TaskMapper.serializeDays(dto.getDaysOfWeek()));
    }

    /**
     * Deletes a task. If {@code deleteSeries} is true,
     * deletes the entire recurring series.
     *
     * @param taskId       ID of the task to delete
     * @param deleteSeries whether to delete just this task or the whole series
     */
    public void deleteTask(Long taskId, boolean deleteSeries) {
        Task task = getTaskById(taskId);

        if (deleteSeries) {
            Long parentId = task.getParentTaskId() != null
                    ? task.getParentTaskId()
                    : task.getId();

            List<Task> seriesTasks = taskRepository.findByParentTaskId(parentId);
            seriesTasks.add(taskRepository.findById(parentId)
                    .orElseThrow(() -> new ParentTaskNotFoundException(parentId)));

            taskRepository.deleteAll(seriesTasks);
            log.info(" Deleted series with parentId=" + parentId + " (count=" + seriesTasks.size() + ")");
        } else {
            if (task.getParentTaskId() == null) {
                // Deleting the parent but not the series → promote a child
                List<Task> children = taskRepository.findByParentTaskId(task.getId());
                if (!children.isEmpty()) {
                    Task newParent = children.get(0); // promote the first child
                    newParent.setParentTaskId(null);
                    taskRepository.save(newParent);

                    for (int i = 1; i < children.size(); i++) {
                        children.get(i).setParentTaskId(newParent.getId());
                    }
                    taskRepository.saveAll(children.subList(1, children.size()));
                    log.info("Promoted child " + newParent.getId() + " as new parent for series");
                }
            }
            taskRepository.delete(task);
            log.info("Deleted single task id=" + taskId);
        }
    }

    /**
     * Checks if a task exists by ID.
     *
     * @param taskId the task ID
     * @return true if found, false otherwise
     */
    public boolean existsById(Long taskId) {
        return taskRepository.findById(taskId).isPresent();
    }

    /**
     * Retrieves all tasks in the system.
     *
     * @return list of all {@link TaskDtoV2}
     * @throws TaskNotFoundException if no tasks exist
     */
    public List<TaskDtoV2> getAllTasks() {
        List<Task> tasks = taskRepository.findAll();
        if (tasks.isEmpty()) {
            throw new TaskNotFoundException("No tasks found");
        }
        return tasks.stream().map(this::mapToDto).toList();
    }

    // -----------------------------
    // Private helpers (mapping, recurrence, updates)
    // -----------------------------

    /**
     * Maps a {@link Task} entity to a {@link TaskDtoV2}.
     */
    private TaskDtoV2 mapToDto(Task task) {
        return TaskDtoV2.builder()
                .id(task.getId())
                .name(task.getName())
                .description(task.getDescription())
                .date(task.getDate())
                .timeOfDay(task.getTimeOfDay())
                .isCompleted(task.isCompleted())
                .frequency(task.getFrequency())
                .interval(task.getTaskInterval())
                .count(task.getDoCount())
                .daysOfWeek(TaskMapper.parseDays(task.getDaysOfWeek()))
                .taskType(task.getTaskType())
                .patientId(task.getPatient() != null ? task.getPatient().getId() : null)
                .notifications(task.getNotifications() != null
                        ? task.getNotifications().stream()
                                .map(n -> new ScheduledNotificationDTO(
                                        n.getReceiverId(),
                                        n.getTitle(),
                                        n.getBody(),
                                        n.getNotificationType(),
                                        n.getScheduledTime().toString()))
                                .toList()
                        : null)
                .build();
    }

    /**
     * Generates missing occurrences of a recurring task series.
     */
    private void generateOccurrences(Task parentTask, TaskDtoV2 dto, Patient patient) {
        List<LocalDate> expectedDates = calculateExpectedDates(dto);
        if (expectedDates.isEmpty())
            return;

        LocalDate startDate = LocalDate.parse(dto.getDate().substring(0, 10));
        LocalTime baseTime = LocalTime.parse(dto.getTimeOfDay());
        LocalDateTime baseDateTime = startDate.atTime(baseTime);

        Long parentId = parentTask.getParentTaskId() != null
                ? parentTask.getParentTaskId()
                : parentTask.getId();

        // Load existing occurrences for this series only
        List<Task> existing = taskRepository.findByParentTaskId(parentId);
        existing.add(parentTask);

        // Track existing by (parentIdOrSelf, date)
        Set<String> existingKeys = existing.stream()
                .map(t -> {
                    String d = t.getDate();
                    String normalized = (d != null && d.length() >= 10) ? d.substring(0, 10) : d;
                    return parentId + "|" + normalized;
                })
                .collect(Collectors.toSet());

        List<Task> newOnes = new ArrayList<>();

        for (LocalDate occurrenceDate : expectedDates) {
            String key = parentId + "|" + occurrenceDate.toString();
            if (!existingKeys.contains(key)) {
                newOnes.add(buildOccurrence(parentTask, dto, patient, baseDateTime, occurrenceDate));
            }
        }

        if (!newOnes.isEmpty()) {
            taskRepository.saveAll(newOnes);
            log.info("Added " + newOnes.size() + " new occurrences to series " + parentTask.getId());
        }
    }

    /**
     * Applies updates from a DTO to a task.
     *
     * @param task         task entity to update
     * @param dto          DTO with updates
     * @param updateSeries whether to allow updates of recurrence fields
     */
    private void applyTaskUpdates(Task task, TaskDtoV2 dto, boolean updateSeries) {
        // Patient assignment only if explicitly set
        if (dto.getPatientId() != null) {
            Patient newPatient = patientRepository.findById(dto.getPatientId())
                    .orElseThrow(() -> new PatientNotFoundException(dto.getPatientId()));
            task.setPatient(newPatient);
        }

        // Only override if non-null in DTO
        if (dto.getName() != null) {
            task.setName(dto.getName());
        }
        if (dto.getDescription() != null) {
            task.setDescription(dto.getDescription());
        }

        // completed is boolean, so always set (if you want to respect one-off,
        // you could add Boolean wrapper in TaskDtoV2 instead of primitive)
        task.setCompleted(dto.isCompleted());

        if (dto.getTaskType() != null) {
            task.setTaskType(dto.getTaskType());
        }

        if (updateSeries) {
            if (dto.getFrequency() != null) {
                task.setFrequency(dto.getFrequency());
            }
            if (dto.getInterval() != null) {
                task.setTaskInterval(dto.getInterval());
            }
            if (dto.getCount() != null) {
                task.setDoCount(dto.getCount());
            }
            if (dto.getDaysOfWeek() != null) {
                task.setDaysOfWeek(TaskMapper.serializeDays(dto.getDaysOfWeek()));
            }

            // Parent should stay anchored to earliest occurrence
            if (task.getParentTaskId() == null) {
                if (dto.getDate() != null) {
                    LocalDate newStart = LocalDate.parse(dto.getDate().substring(0, 10));
                    LocalDate currentParent = LocalDate.parse(task.getDate().substring(0, 10));

                    // Only move parent earlier, never later
                    if (newStart.isBefore(currentParent)) {
                        task.setDate(dto.getDate());
                    }
                }
                if (dto.getTimeOfDay() != null) {
                    task.setTimeOfDay(dto.getTimeOfDay());
                }
            }
        } else {
            // One-off edits
            if (dto.getDate() != null) {
                task.setDate(dto.getDate());
            }
            if (dto.getTimeOfDay() != null) {
                task.setTimeOfDay(dto.getTimeOfDay());
            }
            if (dto.getFrequency() != null) {
                task.setFrequency(dto.getFrequency());
            }
            if (dto.getInterval() != null) {
                task.setTaskInterval(dto.getInterval());
            }
            if (dto.getCount() != null) {
                task.setDoCount(dto.getCount());
            }
            if (dto.getDaysOfWeek() != null) {
                task.setDaysOfWeek(TaskMapper.serializeDays(dto.getDaysOfWeek()));
            }
        }

        // Notifications (replace only if explicitly passed)
        if (dto.getNotifications() != null) {
            if (task.getNotifications() == null) {
                task.setNotifications(new ArrayList<>());
            } else {
                task.getNotifications().clear();
            }

            for (ScheduledNotificationDTO n : dto.getNotifications()) {
                ScheduledNotification sn = ScheduledNotification.builder()
                        .receiverId(n.getReceiverId())
                        .title(n.getTitle())
                        .body(n.getBody())
                        .notificationType(n.getNotificationType())
                        .scheduledTime(LocalDateTime.parse(n.getScheduledTime(), FORMATTER))
                        .status("PENDING")
                        .task(task)
                        .build();
                task.getNotifications().add(sn);
            }
        }
    }

    /**
     * Builds a new recurring occurrence based on parent task and DTO.
     */
    private Task buildOccurrence(Task parentTask, TaskDtoV2 dto, Patient patient,
            LocalDateTime baseDateTime, LocalDate occurrenceDate) {
        LocalDateTime occurrenceDateTime = occurrenceDate.atTime(LocalTime.parse(dto.getTimeOfDay()));

        Task occurrence = Task.builder()
                .name(dto.getName())
                .description(dto.getDescription())
                .date(occurrenceDate.toString())
                .timeOfDay(dto.getTimeOfDay())
                .isCompleted(false)
                .taskType(dto.getTaskType())
                .frequency(dto.getFrequency())
                .taskInterval(dto.getInterval())
                .doCount(dto.getCount())
                .daysOfWeek(TaskMapper.serializeDays(dto.getDaysOfWeek()))
                .patient(patient)
                .parentTaskId(parentTask.getId())
                .build();

        // Notifications: shift relative to base
        if (dto.getNotifications() != null && !dto.getNotifications().isEmpty()) {
            for (ScheduledNotificationDTO n : dto.getNotifications()) {
                LocalDateTime originalScheduledTime = LocalDateTime.parse(n.getScheduledTime(), FORMATTER);
                Duration offset = Duration.between(baseDateTime, originalScheduledTime);

                LocalDateTime adjustedTime = occurrenceDateTime.plus(offset);

                ScheduledNotification sn = ScheduledNotification.builder()
                        .receiverId(n.getReceiverId())
                        .title(n.getTitle())
                        .body(n.getBody())
                        .notificationType(n.getNotificationType())
                        .scheduledTime(adjustedTime)
                        .status("PENDING")
                        .task(occurrence)
                        .build();

                occurrence.getNotifications().add(sn);
            }
        }

        return occurrence;
    }

    /**
     * Calculates expected occurrence dates for a recurring task.
     *
     * <p>
     * Supports daily, weekly, monthly, yearly frequencies.
     * </p>
     */
    private List<LocalDate> calculateExpectedDates(TaskDtoV2 dto) {
        LocalDate startDate = LocalDate.parse(dto.getDate().substring(0, 10));
        int interval = (dto.getInterval() != null && dto.getInterval() > 0) ? dto.getInterval() : 1;
        int count = dto.getCount() != null ? dto.getCount() : 1;

        List<LocalDate> dates = new ArrayList<>();

        switch (dto.getFrequency().toLowerCase()) {
            case "daily" -> {
                for (int i = 0; i < count; i++) {
                    dates.add(startDate.plusDays(i * interval));
                }
            }
            case "weekly" -> {
                List<Boolean> daysOfWeek = dto.getDaysOfWeek();
                if (daysOfWeek == null || daysOfWeek.isEmpty())
                    return dates;

                int created = 0;
                LocalDate weekCursor = startDate;

                while (created < count) {
                    LocalDate weekStart = weekCursor.with(DayOfWeek.SUNDAY);
                    for (int i = 0; i < 7 && created < count; i++) {
                        if (Boolean.TRUE.equals(daysOfWeek.get(i))) {
                            DayOfWeek targetDOW = DayOfWeek.of(((i + 6) % 7) + 1);
                            LocalDate occurrenceDate = weekStart.with(targetDOW);

                            if (!occurrenceDate.isBefore(startDate)) {
                                dates.add(occurrenceDate);
                                created++;
                            }
                        }
                    }
                    weekCursor = weekCursor.plusWeeks(interval);
                }
            }
            case "monthly" -> {
                for (int i = 0; i < count; i++) {
                    dates.add(startDate.plusMonths(i * interval));
                }
            }
            case "yearly" -> {
                for (int i = 0; i < count; i++) {
                    dates.add(startDate.plusYears(i * interval));
                }
            }
        }
        return dates;
    }

}
