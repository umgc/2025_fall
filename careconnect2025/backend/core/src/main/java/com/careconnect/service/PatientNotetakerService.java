package com.careconnect.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import lombok.extern.slf4j.Slf4j;

import com.careconnect.dto.PatientNoteDTO;
import com.careconnect.dto.PatientNotetakerConfigDTO;
import com.careconnect.dto.v2.TaskDtoV2;
import com.careconnect.model.PatientNote;
import com.careconnect.model.PatientNotetakerConfig;
import com.careconnect.model.PatientNotetakerKeyword;
import com.careconnect.model.PatientNotetakerKeyword.EventType;
import com.careconnect.repository.PatientNoteRepository;
import com.careconnect.repository.PatientNotetakerConfigRepository;
import com.careconnect.service.OpenRouterService.Message;
import com.careconnect.service.OpenRouterService.OpenRouterChatRequest;
import com.careconnect.service.OpenRouterService.OpenRouterResponse;
import com.careconnect.service.v2.TaskServiceV2;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;


@Slf4j
@Service
public class PatientNotetakerService {
    private final TaskServiceV2 taskService;
    private final OpenRouterService openRouterService;
    private final PatientNoteRepository patientNoteRepository;
    private final PatientNotetakerConfigRepository patientNotetakerConfigRepository;
    private final PatientService patientService;
    private final String model = "deepseek/deepseek-chat-v3.1:free";

    public PatientNotetakerService(PatientNoteRepository patientNoteRepository, 
        PatientNotetakerConfigRepository patientNotetakerConfigRepository, 
        PatientService patientService,
        OpenRouterService openRouterService,
        TaskServiceV2 taskService
        ) {
        this.patientNoteRepository = patientNoteRepository;
        this.patientNotetakerConfigRepository = patientNotetakerConfigRepository;
        this.patientService = patientService;
        this.openRouterService = openRouterService;
        this.taskService = taskService;
    }

    public PatientNotetakerConfigDTO getNotetakerConfigByPatientId(Long patientId) {
        validatePatientId(patientId);
        return new PatientNotetakerConfigDTO(patientNotetakerConfigRepository.findByPatientId(patientId));
    }

    @Transactional
    public PatientNotetakerConfigDTO createOrUpdatePatientNotetakerConfig(Long patientId, PatientNotetakerConfigDTO configDTO) {
        validatePatientId(patientId);
        if(configDTO == null) {
            throw new IllegalArgumentException("Configuration data is required.");
        }

        PatientNotetakerConfig existingConfig = patientNotetakerConfigRepository.findByPatientId(patientId);
        if(existingConfig == null) {
            PatientNotetakerConfig newConfig = configDTO.toEntity();
            newConfig.setPatientId(patientId);
            newConfig.setUpdatedAt(LocalDateTime.now());
            return new PatientNotetakerConfigDTO(patientNotetakerConfigRepository.save(newConfig));
        }

        existingConfig.setIsEnabled(configDTO.getIsEnabled()); 
        existingConfig.setPatientId(patientId);
        existingConfig.setPermitCaregiverAccess(configDTO.getPermitCaregiverAccess());
        existingConfig.setTriggerKeywords(configDTO.getTriggerKeywords());
        existingConfig.setUpdatedAt(LocalDateTime.now());
        return new PatientNotetakerConfigDTO(patientNotetakerConfigRepository.save(existingConfig));
    }

    public List<PatientNoteDTO> getAllNotesForPatient(Long patientId) {
        validatePatientId(patientId);
         return patientNoteRepository.findByPatientId(patientId).orElse(new ArrayList<PatientNote>())
            .stream()
            .map(x -> new PatientNoteDTO(x))
            .toList();
    }

    public PatientNoteDTO getNoteById(Long patientId, Long noteId) {
        validatePatientId(patientId);
        PatientNoteDTO result = new PatientNoteDTO(patientNoteRepository.findById(noteId)
            .orElseThrow(() -> new IllegalArgumentException("Note not found")));
        return result;
    }

    @Transactional
    public PatientNoteDTO createNoteForPatient(Long patientId, PatientNoteDTO noteDTO) {
        validatePatientId(patientId);
        if(noteDTO == null) {
            throw new IllegalArgumentException("Note data is required.");
        }
        PatientNote newNote = noteDTO.toEntity();
        newNote.setPatientId(patientId);
        newNote.setCreatedAt(LocalDateTime.now());
        newNote.setUpdatedAt(LocalDateTime.now());
        newNote.setAiSummary(processAiSummary(noteDTO.getNote()));
        PatientNoteDTO result = new PatientNoteDTO(patientNoteRepository.save(newNote));
        detectKeyWords(patientId, newNote.getNote());
       
        return result;
    }

    @Transactional
    public PatientNoteDTO updateNoteForPatient(Long patientId, Long noteId, PatientNoteDTO noteDTO) {
        validatePatientId(patientId);
        if(noteDTO == null) {
            throw new IllegalArgumentException("Note data is required.");
        }
        PatientNote existingNote = patientNoteRepository.findById(noteId).orElseThrow();
        existingNote.setPatientId(patientId);
        existingNote.setNote(noteDTO.getNote());
        if((!noteDTO.getAiSummary().isBlank() || !noteDTO.getAiSummary().isEmpty()) && noteDTO.getAiSummary() != "Failed to generate AI Summary") {
            existingNote.setAiSummary(noteDTO.getAiSummary());
        } else {
            existingNote.setAiSummary(processAiSummary(noteDTO.getNote()));
        }
        existingNote.setUpdatedAt(LocalDateTime.now());
        return new PatientNoteDTO(patientNoteRepository.save(existingNote));
    }

    @Transactional
    public void deleteNoteById(Long noteId) {
        patientNoteRepository.deleteById(noteId);
    }

    private void validatePatientId(Long patientId) {
        if(patientService.getPatientById(patientId) == null) {
            throw new IllegalArgumentException("Patient not found");
        }
    }
    
    @Async
    private List<String> detectKeyWords(Long patientId, String fileData) {
        PatientNotetakerConfig config = patientNotetakerConfigRepository.findByPatientId(patientId);
        if(config == null) {
            return  Collections.emptyList();
        }
        List<PatientNotetakerKeyword> keywords = config.getTriggerKeywords();
        List<String> foundKeywords = new ArrayList<>();
        //make lowercase for case insensitive comparisions
        fileData = fileData.toLowerCase();
        for(PatientNotetakerKeyword keyword : keywords) {
            String lowercaseKeyword = keyword.getKeyword().toLowerCase();
            if(fileData.contains(lowercaseKeyword)) {
                String truncatedMessage = fileData.substring(
                    Math.max(fileData.indexOf(lowercaseKeyword) - 200, 0),
                    Math.min(fileData.indexOf(lowercaseKeyword) + 200, fileData.length()-1)
                );
                foundKeywords.add(keyword.getKeyword());
                triggerEventForKeywords(patientId, keyword, truncatedMessage);
            }
        }
        return foundKeywords;
    }

    @Async
    private void triggerEventForKeywords(Long patientId, PatientNotetakerKeyword keyword, String truncatedMessage) {
        if (keyword.getEventType() == EventType.ALERT) {
            // TODO notification to caregiver when implemented
            return;
        } else if (keyword.getEventType() == EventType.TASK) {

            String prompt = "Given the following keyword '" + keyword.getKeyword().toLowerCase()
                    + "', generate a json object with the following properties: "
                    + "name (string), "
                    + "date (string) , "
                    + "daysOfWeek (array of booleans for each day of the week), "
                    + "description (string), "
                    + "count (int), "
                    + "frequency (string), "
                    + "taskType (string, one of the following: medication, appointment, exercise, general, lab, pharmacy),"
                    + "timeOfDay (localdatetime as a string)"
                    + ". The json should be in the following format: {\"date\":\"YYYY-MM-DD\", \"daysOfWeek\":[true, false, false, false, false, false, false], \"description\":\"description text\", \"count\":1, \"frequency\":\"once\", \"taskType\":\"general\", \"timeOfDay\":\"hr:min:sec\"}. "
                    + "Use the following text to derive these properties as they relate to the keyword: '"
                    + truncatedMessage
                    + ". Name, date and description are the most important properties to decipher. If you are unable to determine any of the properties, set them null or empty. Only respond with the json object beginning with { and ending with }.";
            System.out.println("Sending OpenRouter request...");
            OpenRouterChatRequest request = new OpenRouterChatRequest(
                    model,
                    Arrays.asList(new Message("system", "You are an expert language interpreter and software engineer"),new Message("user", prompt)),
                    0.2,
                    256);

            OpenRouterResponse response; 
            try {
                response = openRouterService.sendChatRequest(request);
            } catch (Exception e) {
                log.error("Unable to reach OpenRouter service: {}", e.getMessage());
                return;
            }
            String aiContent = null;
            if (response != null && response.getChoices() != null && !response.getChoices().isEmpty()
                    && response.getChoices().get(0).getMessage() != null) {
                aiContent = response.getChoices().get(0).getMessage().getContent();
            } else {
                aiContent = "";
            }

            TaskDtoV2 aiTask = mapJson(aiContent, TaskDtoV2.class);
            if (aiTask == null || aiTask.getName() == null || aiTask.getTaskType() == null
                    || aiTask.getDescription() == null || aiTask.getDate() == null) {
                log.error("Invalid AI Task generated for keyword '{}': {}", keyword.getKeyword(), aiTask);
                return;
            }
            log.info("OpenRouter response for keyword '{}': {}", keyword.getKeyword(), response);
            log.info("Created Task from AI: {}", aiTask);
            aiTask.setDescription("AI GENERATED TASK: " + aiTask.getDescription());
            aiTask.setCompleted(false);
            //deepseek model is old, so it gets the current year wrong, fix.
            LocalDate date = LocalDate.parse(aiTask.getDate()); 
            aiTask.setDate(date.withYear(LocalDate.now().getYear()).toString());
            taskService.createTask(patientId, aiTask);
        }
    }

    @Async
    private String processAiSummary(String noteContent) {
        String prompt = "Given the following converation transcription, summarize the following into a maximum of 1-2 concise sentences, focusing on key health information and any action items or takeaways. Specify which individual identified in the conversation each item pertains to: '"
                + noteContent + "'";

        OpenRouterChatRequest request = new OpenRouterChatRequest(
                model,
                Arrays.asList(new Message("system", "You are a helpful assistant who's main focus is to summarize detailed conversations into simple, concise takeways. do not use verbose language or symbols."),new Message("user", prompt)),
                0.2,
                256);

        OpenRouterResponse response; 
        try {
            response = openRouterService.sendChatRequest(request);
        } catch (Exception e) {
            log.error("Unable to reach OpenRouter service: {}", e.getMessage());
            return "Failed to generate AI Summary";
        }
        String aiSummary = null;
        if (response != null && response.getChoices() != null && !response.getChoices().isEmpty()
                && response.getChoices().get(0).getMessage() != null) {
            aiSummary = response.getChoices().get(0).getMessage().getContent();
            aiSummary = aiSummary.split("<")[0].trim();
        } else {
            aiSummary = "";
        }
        log.info("AI Summary generated: {}", aiSummary);
        return aiSummary;
    }

    private <T> T mapJson(String json, Class<T> object) {
        ObjectMapper objectMapper = new ObjectMapper();
        try {
            return objectMapper.readValue(json, object);
        } catch (JsonProcessingException e) {
            log.error("Error mapping JSON to object: {}", e.getMessage());
            return null;
        }
    }
}
