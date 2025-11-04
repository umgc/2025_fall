package com.careconnect.service;

import com.careconnect.dto.ChatRequest;
import com.careconnect.dto.ChatResponse;
import com.careconnect.dto.ChatConversationSummary;
import com.careconnect.dto.ChatMessageSummary;
import com.careconnect.model.*;
import com.careconnect.model.UserAIConfig;
import com.careconnect.util.UserAIConfigDefaults;
import com.careconnect.service.security.InputSanitizationService;
import com.careconnect.service.security.ResponseSanitizationService;
import com.careconnect.service.security.LangChainGovernanceService;
import com.careconnect.service.security.SecurityAuditService;
import com.careconnect.service.cache.AIChatCacheService;
import com.careconnect.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import dev.langchain4j.memory.ChatMemory;
import dev.langchain4j.model.chat.ChatModel;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;
import dev.langchain4j.exception.AuthenticationException;

@Service
@Primary
@ConditionalOnProperty(name = "careconnect.deepseek.enabled", havingValue = "true")
public class DefaultAIChatService implements AIChatService {
    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(DefaultAIChatService.class);

    // LangChain4j components (inject or configure as needed)
    private final ChatModel chatModel; // Should be configured for OpenAI or DeepSeek

    private final UserAIConfigRepository userAIConfigRepository;
    private final ChatConversationRepository chatConversationRepository;
    private final ChatMessageRepository chatMessageRepository;
    private final PatientRepository patientRepository;
    private final MedicalContextService medicalContextService;
    private final PatientContextRetrievalService patientContextRetrievalService;
    private final ChatMemoryFactory chatMemoryFactory;
    private final ChatAuditService chatAuditService;
    private final CaregiverPatientLinkService caregiverPatientLinkService;
    private final InputSanitizationService inputSanitizationService;
    private final ResponseSanitizationService responseSanitizationService;
    private final LangChainGovernanceService langChainGovernanceService;
    private final AIChatCacheService cacheService;
    private final SecurityAuditService securityAuditService;
    private final DocumentProcessingService documentProcessingService;


    @Autowired
    public DefaultAIChatService(ChatModel chatModel,
                              UserAIConfigRepository userAIConfigRepository,
                              ChatConversationRepository chatConversationRepository,
                              ChatMessageRepository chatMessageRepository,
                              PatientRepository patientRepository,
                              MedicalContextService medicalContextService,
                              PatientContextRetrievalService patientContextRetrievalService,
                              ChatMemoryFactory chatMemoryFactory,
                              ChatAuditService chatAuditService,
                              CaregiverPatientLinkService caregiverPatientLinkService,
                              InputSanitizationService inputSanitizationService,
                              ResponseSanitizationService responseSanitizationService,
                              LangChainGovernanceService langChainGovernanceService,
                              AIChatCacheService cacheService,
                              SecurityAuditService securityAuditService,
                              DocumentProcessingService documentProcessingService) {
        this.chatModel = chatModel;
        this.userAIConfigRepository = userAIConfigRepository;
        this.chatConversationRepository = chatConversationRepository;
        this.chatMessageRepository = chatMessageRepository;
        this.patientRepository = patientRepository;
        this.medicalContextService = medicalContextService;
        this.patientContextRetrievalService = patientContextRetrievalService;
        this.chatMemoryFactory = chatMemoryFactory;
        this.chatAuditService = chatAuditService;
        this.caregiverPatientLinkService = caregiverPatientLinkService;
        this.inputSanitizationService = inputSanitizationService;
        this.responseSanitizationService = responseSanitizationService;
        this.langChainGovernanceService = langChainGovernanceService;
        this.cacheService = cacheService;
        this.securityAuditService = securityAuditService;
        this.documentProcessingService = documentProcessingService;
    }
    // Helper: Get or create patient AI config (with caching)
    private UserAIConfig getOrCreateUserAIConfig(Long userId, Long patientId) {
        return cacheService.findUserAIConfig(userId, patientId)
                .orElseGet(() -> createDefaultUserAIConfig(userId, patientId));
    }

    // Helper: Create default AI config (with caching)
    private UserAIConfig createDefaultUserAIConfig(Long userId, Long patientId) {
        UserAIConfig config = UserAIConfigDefaults.createMedicalDefaultConfig(userId, patientId);
        return cacheService.saveUserAIConfig(config);
    }

    // Helper: Get or create conversation (with caching)
    private ChatConversation getOrCreateConversation(ChatRequest request, UserAIConfig aiConfig) {
        if (request.getConversationId() != null) {
            Optional<ChatConversation> existing = cacheService.findConversation(request.getConversationId());
            if (existing.isPresent()) {
                return existing.get();
            } else {
                // ConversationId provided but not found: create new conversation for user/patient
                ChatConversation newConversation = ChatConversation.builder()
                        .conversationId(UUID.randomUUID().toString())
                        .patientId(request.getPatientId())
                        .userId(request.getUserId())
                        .chatType(request.getChatType())
                        .title(request.getTitle() != null ? request.getTitle() : generateConversationTitle(request.getMessage()))
                        .aiProviderUsed(aiConfig.getPreferredAiProvider())
                        .aiModelUsed(determineModel(request, aiConfig))
                        .isActive(true)
                        .build();
                return cacheService.saveConversation(newConversation);
            }
        }
        // No conversationId provided: create new conversation
        ChatConversation newConversation = ChatConversation.builder()
                .conversationId(UUID.randomUUID().toString())
                .patientId(request.getPatientId())
                .userId(request.getUserId())
                .chatType(request.getChatType())
                .title(request.getTitle() != null ? request.getTitle() : generateConversationTitle(request.getMessage()))
                .aiProviderUsed(aiConfig.getPreferredAiProvider())
                .aiModelUsed(determineModel(request, aiConfig))
                .isActive(true)
                .build();
        return cacheService.saveConversation(newConversation);
    }

    // Helper: Generate conversation title
    private String generateConversationTitle(String firstMessage) {
        if (firstMessage.length() > 50) {
            return firstMessage.substring(0, 47) + "...";
        }
        return firstMessage;
    }

    // Helper: Prepare messages for AI
    private List<Object> prepareMessagesForAI(ChatConversation conversation, String newMessage, String medicalContext, String systemPrompt) {
        List<Object> messages = new ArrayList<>();
        // Use prompt from request if available, else fallback to default
        String prompt = (systemPrompt != null && !systemPrompt.trim().isEmpty())
            ? systemPrompt
            : "You are a helpful AI assistant for patients. Be conversational and ask how you can help. Only provide medical information when specifically asked. Do not give unsolicited medical summaries or analysis.";
        messages.add(createMessage("system", prompt));
        if (medicalContext != null && !medicalContext.trim().isEmpty()) {
            messages.add(createMessage("system", medicalContext));
        }
        Integer historyLimit = 20;
        if (conversation.getUserId() != null && conversation.getPatientId() != null) {
            UserAIConfig config = getOrCreateUserAIConfig(conversation.getUserId(), conversation.getPatientId());
            historyLimit = (config != null && config.getConversationHistoryLimit() != null) ? config.getConversationHistoryLimit() : 20;
        }
        List<ChatMessage> recentMessages = chatMessageRepository
                .findTopNByConversationOrderByCreatedAtAsc(conversation, historyLimit);
        for (ChatMessage msg : recentMessages) {
            messages.add(createMessage(msg.getMessageType().getValue(), msg.getContent()));
        }
        messages.add(createMessage("user", newMessage));
        return messages;
    }

    // Helper: Prepare messages for AI (LangChain4j ChatMessage objects)
    private List<dev.langchain4j.data.message.ChatMessage> prepareChatMessagesForAI(ChatConversation conversation, String newMessage, String medicalContext, String systemPrompt) {
        List<dev.langchain4j.data.message.ChatMessage> messages = new ArrayList<>();
        // System prompt as system message
        String prompt = (systemPrompt != null && !systemPrompt.trim().isEmpty())
            ? systemPrompt
            : UserAIConfigDefaults.MEDICAL_SYSTEM_PROMPT;
        messages.add(dev.langchain4j.data.message.SystemMessage.from(prompt));
        if (medicalContext != null && !medicalContext.trim().isEmpty()) {
            messages.add(dev.langchain4j.data.message.SystemMessage.from(medicalContext));
        }
        Integer historyLimit = 20;
        if (conversation.getUserId() != null && conversation.getPatientId() != null) {
            UserAIConfig config = getOrCreateUserAIConfig(conversation.getUserId(), conversation.getPatientId());
            historyLimit = (config != null && config.getConversationHistoryLimit() != null) ? config.getConversationHistoryLimit() : 20;
        }
        List<ChatMessage> recentMessages = chatMessageRepository
                .findTopNByConversationOrderByCreatedAtAsc(conversation, historyLimit);
        for (ChatMessage msg : recentMessages) {
            switch (msg.getMessageType()) {
                case USER -> messages.add(new dev.langchain4j.data.message.UserMessage(msg.getContent()));
                case ASSISTANT -> messages.add(new dev.langchain4j.data.message.AiMessage(msg.getContent()));
                case SYSTEM -> messages.add(dev.langchain4j.data.message.SystemMessage.from(msg.getContent()));
            }
        }
        messages.add(new dev.langchain4j.data.message.UserMessage(newMessage));
        return messages;
    }

    // Helper: Create message map
    private Object createMessage(String role, String content) {
        return Map.of("role", role, "content", content);
    }

    // Helper: Determine model
    private String determineModel(ChatRequest request, UserAIConfig aiConfig) {
        if (request.getPreferredModel() != null) {
            return request.getPreferredModel();
        }
        return aiConfig.getPreferredAiProvider() == UserAIConfig.AIProvider.OPENAI ?
                aiConfig.getOpenaiModel() : aiConfig.getDeepseekModel();
    }

    // Disabled: All chat requests are now handled by LangChain4j chatModel. Direct OpenAI/DeepSeek calls are not used.
    // private Mono<ChatProcessingResult> callAIService(ChatProcessingContext context) { /* ...disabled... */ }



    // Helper: Save and build response
    @Transactional
    private ChatResponse saveAndBuildResponse(ChatProcessingResult result) {
        ChatProcessingContext context = result.context;
        Integer tokensUsed = result.tokensUsed != null ? result.tokensUsed : 0;
        ChatMessage userMessage = ChatMessage.builder()
                .conversation(context.conversation)
                .messageType(ChatMessage.MessageType.USER)
                .content(context.messages.get(context.messages.size() - 1).toString())
                .build();
        chatMessageRepository.save(userMessage);
        ChatMessage aiMessage = ChatMessage.builder()
                .conversation(context.conversation)
                .messageType(ChatMessage.MessageType.ASSISTANT)
                .content(result.aiResponse)
                .tokensUsed(tokensUsed)
                .processingTimeMs(result.processingTimeMs)
                .temperatureUsed(context.temperature)
                .aiModelUsed(context.model)
                .contextIncluded(buildContextSummary(context.medicalContext))
                .build();
        ChatMessage savedAiMessage = chatMessageRepository.save(aiMessage);
        context.conversation.setTotalTokensUsed(
                (context.conversation.getTotalTokensUsed() != null ? context.conversation.getTotalTokensUsed() : 0) + tokensUsed
        );
        // Ensure provider/model are set correctly in conversation
        context.conversation.setAiProviderUsed(context.aiConfig.getPreferredAiProvider());
        context.conversation.setAiModelUsed(context.model);
        chatConversationRepository.save(context.conversation);
        ChatResponse resp = new ChatResponse();
        resp.setConversationId(context.conversation.getConversationId());
        resp.setMessage(userMessage.getContent());
        resp.setAiResponse(result.aiResponse);
        resp.setMessageId(savedAiMessage.getId());
        resp.setAiProvider(context.aiConfig.getPreferredAiProvider().name());
        resp.setModelUsed(context.model);
        resp.setTokensUsed(tokensUsed);
        resp.setProcessingTimeMs(result.processingTimeMs);
        resp.setTemperatureUsed(context.temperature);
        resp.setContextIncluded(parseContextIncluded(context.medicalContext));
        resp.setIsNewConversation(context.conversation.getCreatedAt().isAfter(LocalDateTime.now().minusMinutes(1)));
        resp.setTimestamp(LocalDateTime.now());
        resp.setConversationTitle(context.conversation.getTitle());
        resp.setTotalMessagesInConversation(chatMessageRepository.countByConversation(context.conversation));
        resp.setTotalTokensUsedInConversation(context.conversation.getTotalTokensUsed());
        resp.setApproachingTokenLimit(context.conversation.getTotalTokensUsed() > (context.aiConfig.getMaxTokens() * 0.8));
        resp.setSuccess(true);
        return resp;
    }

    // Helper: Build context summary
    private String buildContextSummary(String medicalContext) {
        return medicalContext != null ? "Medical context included" : "No medical context";
    }

    // Helper: Parse context included
    private List<String> parseContextIncluded(String medicalContext) {
        List<String> contextTypes = new ArrayList<>();
        if (medicalContext != null && !medicalContext.trim().isEmpty()) {
            if (medicalContext.contains("Vitals:")) contextTypes.add("vitals");
            if (medicalContext.contains("Medications:")) contextTypes.add("medications");
            if (medicalContext.contains("Clinical Notes:")) contextTypes.add("notes");
            if (medicalContext.contains("Mood/Pain Logs:")) contextTypes.add("mood_pain_logs");
            if (medicalContext.contains("Allergies:")) contextTypes.add("allergies");
        }
        return contextTypes;
    }

    // Helper: Build error response
    private ChatResponse buildErrorResponse(ChatRequest request, String errorMessage) {
        ChatResponse resp = new ChatResponse();
        resp.setConversationId(request.getConversationId());
        resp.setMessage(request.getMessage());
        resp.setSuccess(false);
        resp.setErrorMessage(errorMessage);
        resp.setErrorCode("PROCESSING_ERROR");
        resp.setTimestamp(LocalDateTime.now());

        // Add a user-friendly response message
        resp.setAiResponse("I apologize, but I encountered an error while processing your request. Please try again or contact support if the issue persists.");

        // Include basic response structure for consistency
        resp.setAiProvider("DEEPSEEK_VIA_LANGCHAIN4J");
        resp.setTokensUsed(0);
        resp.setProcessingTimeMs(0L);

        return resp;
    }

    // Helper: Get patient conversations
    public List<ChatConversationSummary> getPatientConversations(Long patientId) {
        List<ChatConversation> conversations = chatConversationRepository
                .findByPatientIdAndIsActiveTrueOrderByUpdatedAtDesc(patientId);
        return conversations.stream()
                .map(this::convertToConversationSummary)
                .collect(Collectors.toList());
    }

    // Helper: Get conversation messages
    public List<ChatMessageSummary> getConversationMessages(String conversationId) {
        ChatConversation conversation = chatConversationRepository
                .findByConversationIdAndIsActiveTrue(conversationId)
                .orElseThrow(() -> new IllegalArgumentException("Conversation not found"));
        List<ChatMessage> messages = chatMessageRepository
                .findByConversationOrderByCreatedAtAsc(conversation);
        return messages.stream()
                .map(this::convertToMessageSummary)
                .collect(Collectors.toList());
    }

    // Helper: Get recent messages for user (from most recent active conversation)
    public List<ChatMessageSummary> getRecentMessagesForUser(Long userId, int limit) {
        // Find the most recent active conversation for the user
        List<ChatConversation> conversations = chatConversationRepository
                .findByUserIdAndIsActiveTrueOrderByUpdatedAtDesc(userId);
        
        if (conversations.isEmpty()) {
            return new ArrayList<>(); // No active conversations
        }
        
        // Get messages from the most recent conversation
        ChatConversation mostRecentConversation = conversations.get(0);
        List<ChatMessage> messages = chatMessageRepository
                .findTopNByConversationOrderByCreatedAtAsc(mostRecentConversation, limit);
        
        return messages.stream()
                .map(this::convertToMessageSummary)
                .collect(Collectors.toList());
    }

    // Helper: Deactivate conversation
    @Transactional
    public void deactivateConversation(String conversationId) {
        ChatConversation conversation = chatConversationRepository
                .findByConversationIdAndIsActiveTrue(conversationId)
                .orElseThrow(() -> new IllegalArgumentException("Conversation not found"));
        
        // Log conversation deletion
        chatAuditService.logConversationDeleted(
            conversation.getUserId(),
            conversationId,
            "user_initiated"
        );
        
        conversation.setIsActive(false);
        chatConversationRepository.save(conversation);
    }

    // Helper: Convert to conversation summary
    private ChatConversationSummary convertToConversationSummary(ChatConversation conversation) {
        int messageCount = chatMessageRepository.countByConversation(conversation);
        ChatConversationSummary summary = new ChatConversationSummary();
        summary.setConversationId(conversation.getConversationId());
        summary.setTitle(conversation.getTitle());
        summary.setChatType(conversation.getChatType());
        summary.setAiProvider(conversation.getAiProviderUsed() != null ? conversation.getAiProviderUsed().name() : null);
        summary.setAiModel(conversation.getAiModelUsed());
        summary.setTotalMessages(messageCount);
        summary.setTotalTokensUsed(conversation.getTotalTokensUsed());
        summary.setLastMessageAt(conversation.getUpdatedAt());
        summary.setCreatedAt(conversation.getCreatedAt());
        summary.setIsActive(conversation.getIsActive());
        return summary;
    }

    // Helper: Convert to message summary
    private ChatMessageSummary convertToMessageSummary(ChatMessage message) {
        ChatMessageSummary summary = new ChatMessageSummary();
        summary.setMessageId(message.getId());
        summary.setMessageType(message.getMessageType());
        summary.setContent(message.getContent());
        summary.setTokensUsed(message.getTokensUsed());
        summary.setProcessingTimeMs(message.getProcessingTimeMs());
        summary.setAiModelUsed(message.getAiModelUsed());
        summary.setCreatedAt(message.getCreatedAt());
        return summary;
    }

    // Helper classes
    private static class ChatProcessingContext {
        final Patient patient;
        final UserAIConfig aiConfig;
        final ChatConversation conversation;
        final List<Object> messages;
        final String model;
        final Double temperature;
        final Integer max_tokens;
        final String medicalContext;
        final long startTime;

        ChatProcessingContext(Patient patient, UserAIConfig aiConfig, ChatConversation conversation,
                              List<Object> messages, String model, Double temperature, Integer max_tokens,
                              String medicalContext, long startTime) {
            this.patient = patient;
            this.aiConfig = aiConfig;
            this.conversation = conversation;
            this.messages = messages;
            this.model = model;
            this.temperature = temperature;
            this.max_tokens = max_tokens;
            this.medicalContext = medicalContext;
            this.startTime = startTime;
        }
    }

    private static class ChatProcessingResult {
        final ChatProcessingContext context;
        final String aiResponse;
        final Integer tokensUsed;
        final Long processingTimeMs;
        final String error;

        ChatProcessingResult(ChatProcessingContext context, String aiResponse, Integer tokensUsed,
                            Long processingTimeMs, String error) {
            this.context = context;
            this.aiResponse = aiResponse;
            this.tokensUsed = tokensUsed;
            this.processingTimeMs = processingTimeMs;
            this.error = error;
        }
    }

    @Transactional
    public ChatResponse processChat(ChatRequest request) {
        // Validate that we have either a patient ID or a user ID
        if (request.getPatientId() == null && request.getUserId() == null) {
            throw new IllegalArgumentException("Either Patient ID or User ID is required");
        }

        Patient patient = null;
        if (request.getPatientId() != null) {
            // Patient chat - validate patient exists (with caching)
            patient = cacheService.findPatient(request.getPatientId())
                    .orElseThrow(() -> new IllegalArgumentException("Patient not found"));
        } else {
            // Caregiver or other user chat - try to find associated patient through user
            // For now, we'll allow caregiver chats without a specific patient context
            log.info("Processing chat request for user ID: {} without specific patient context", request.getUserId());
        }

        // Always use LangChain4j chatModel for all chat requests
        if (request.getConversationId() != null && request.getConversationId().trim().isEmpty()) {
            request.setConversationId(null);
        }
        long startTime = System.currentTimeMillis();

        try {
            // Validate required fields
            if (request.getUserId() == null) {
                log.error("Chat request missing userId");
                return buildErrorResponse(request, "Authentication required: User ID is missing");
            }

            if ((request.getMessage() == null || request.getMessage().trim().isEmpty())
                    && (request.getUploadedFiles() == null || request.getUploadedFiles().isEmpty())) {
                log.error("Chat request missing message content and files");
                return buildErrorResponse(request, "Message content or at least one file is required");
            }
            // Validate patient exists and user has access
            

            // Get or create user AI configuration
            UserAIConfig aiConfig = getOrCreateUserAIConfig(request.getUserId(), request.getPatientId());

                   // Get or create conversation
                   ChatConversation conversation = getOrCreateConversation(request, aiConfig);

                   // Log chat session start if new conversation
                   if (conversation.getCreatedAt().isAfter(LocalDateTime.now().minusMinutes(1))) {
                       chatAuditService.logChatSessionStart(
                           request.getUserId(), 
                           conversation.getConversationId(),
                           "mobile_app", // Would get from request headers in real implementation
                           "127.0.0.1"   // Would get from request in real implementation
                       );
                   }

                   log.info("AIChatService (LangChain4j + DeepSeek) - Using model: {} for patient: {}, user: {}",
                       aiConfig.getDeepseekModel(), request.getPatientId(), request.getUserId());

            // Build medical context (only for patient-specific chats)
            String medicalContext = "";
            if (request.getPatientId() != null) {
                // For caregiver requests, validate they have access to the patient
                if (patient == null) {
                    // This is a caregiver request accessing a specific patient
                    boolean hasAccess = caregiverPatientLinkService.hasAccessToPatient(
                            request.getUserId(),
                            request.getPatientId()
                    );

                    if (!hasAccess) {
                        log.warn("Caregiver {} attempted to access patient {} without permission",
                                request.getUserId(), request.getPatientId());
                        return buildErrorResponse(request,
                                "Access denied: You are not authorized to access this patient's information");
                    }

                    // Load the patient for context building (with caching)
                    patient = cacheService.findPatient(request.getPatientId())
                            .orElseThrow(() -> new IllegalArgumentException("Patient not found"));
                }

                medicalContext = medicalContextService.buildPatientContext(
                        request.getPatientId(),
                        request,
                        aiConfig
                );
            }
            // Debug logging removed for cleaner logs

            // Sanitize user input first
            InputSanitizationService.SanitizationResult userInputResult =
                inputSanitizationService.sanitizeUserInput(
                    request.getMessage(),
                    request.getUserId(),
                    conversation.getConversationId()
                );

            if (userInputResult.isBlocked()) {
                log.warn("User input blocked for user {} in conversation {}: {}",
                    request.getUserId(), conversation.getConversationId(), userInputResult.getIssues());
                return buildErrorResponse(request, "Your message contains content that cannot be processed. Please rephrase and try again.");
            }

            String sanitizedUserMessage = userInputResult.getSanitizedContent();

            // Process uploaded files and append to message
            if (request.getUploadedFiles() != null && !request.getUploadedFiles().isEmpty()) {
                String fileContent = processUploadedFiles(request.getUploadedFiles());
                if (!fileContent.isEmpty()) {
                    InputSanitizationService.SanitizationResult fileContentResult =
                        inputSanitizationService.sanitizeUserInput(
                            fileContent,
                            request.getUserId(),
                            conversation.getConversationId()
                        );
                    if (fileContentResult.isBlocked()) {
                        log.warn("Uploaded file content blocked for user {} in conversation {}: {}",
                            request.getUserId(), conversation.getConversationId(), fileContentResult.getIssues());
                        return buildErrorResponse(request, "Your uploaded document contains content that cannot be processed. Please remove or modify the document and try again.");
                    }
                    sanitizedUserMessage += "\n\n**Attached Documents:**\n" + fileContentResult.getSanitizedContent();
                }
            }

            // System prompt
            String systemPrompt = null;
            if (request instanceof com.careconnect.dto.ChatRequest) {
                try {
                    java.lang.reflect.Method m = request.getClass().getMethod("getSystemPrompt");
                    Object val = m.invoke(request);
                    if (val != null && !val.toString().trim().isEmpty()) {
                        systemPrompt = val.toString();
                    }
                } catch (Exception ignore) {}
            }
            if (systemPrompt == null) {
                // Use caregiver-specific prompt for caregiver-only chats (no patient context)
                // Use medical prompt when caregiver is accessing specific patient data
                if (request.getPatientId() == null) {
                    systemPrompt = UserAIConfigDefaults.CAREGIVER_SYSTEM_PROMPT;
                } else {
                    // When caregiver has patient context, use medical prompt
                    systemPrompt = UserAIConfigDefaults.MEDICAL_SYSTEM_PROMPT;
                }
            }

            // Sanitize system prompt
            InputSanitizationService.SanitizationResult systemPromptResult =
                inputSanitizationService.sanitizeSystemPrompt(
                    systemPrompt,
                    request.getUserId(),
                    conversation.getConversationId()
                );

            if (systemPromptResult.isBlocked()) {
                log.error("System prompt blocked for user {} in conversation {}: {}",
                    request.getUserId(), conversation.getConversationId(), systemPromptResult.getIssues());
                return buildErrorResponse(request, "System configuration error. Please contact support.");
            }

            String sanitizedSystemPrompt = systemPromptResult.getSanitizedContent();

            // Create ChatMemory for this conversation (session-based with 15-minute timeout)
            ChatMemory chatMemory = chatMemoryFactory.createSessionBasedChatMemory(conversation, aiConfig);
            
            // Add system prompt and medical context to memory if not already present
            if (chatMemory.messages().isEmpty()) {
                chatMemory.add(dev.langchain4j.data.message.SystemMessage.from(sanitizedSystemPrompt));
                if (medicalContext != null && !medicalContext.trim().isEmpty()) {
                    chatMemory.add(dev.langchain4j.data.message.SystemMessage.from(medicalContext));
                }
            }

                   // Add sanitized user message to memory
                   chatMemory.add(dev.langchain4j.data.message.UserMessage.from(sanitizedUserMessage));

                   // Log user message sent
                   chatAuditService.logMessageSent(
                       request.getUserId(),
                       conversation.getConversationId(),
                       request.getMessage().length(),
                       0 // Response time will be calculated after AI response
                   );

                   String aiResponse;
                   long processingTimeMs = 0;
                   try {
                       long aiStartTime = System.currentTimeMillis();
                       // Use ChatMemory to get AI response
                       var response = chatModel.chat(chatMemory.messages());
                       processingTimeMs = System.currentTimeMillis() - aiStartTime;

                       // Extract the actual text content from the LangChain4j response
                       if (response != null && response.aiMessage() != null && response.aiMessage().text() != null) {
                           String rawAiResponse = response.aiMessage().text();

                           // Sanitize AI response for medical data protection and system information disclosure
                           ResponseSanitizationService.SanitizationResult responseResult =
                               responseSanitizationService.sanitizeAIResponse(
                                   rawAiResponse,
                                   request.getUserId(),
                                   conversation.getConversationId(),
                                   request.getPatientId()
                               );

                           aiResponse = responseResult.getSanitizedContent();

                           // Add sanitized AI response to memory (store sanitized version to prevent sensitive info leakage)
                           chatMemory.add(dev.langchain4j.data.message.AiMessage.from(aiResponse));

                           // Log AI response (use sanitized length for accurate metrics)
                           chatAuditService.logAiResponse(
                               request.getUserId(),
                               conversation.getConversationId(),
                               aiResponse.length(),
                               processingTimeMs
                           );
                       } else {
                           log.warn("Received null or empty response from AI model for conversation {}", conversation.getConversationId());
                           aiResponse = "I'm sorry, but I'm having trouble processing your request right now. Please try again in a moment, or rephrase your question.";
                           chatAuditService.logSystemError(
                               request.getUserId(),
                               conversation.getConversationId(),
                               "AI_RESPONSE_NULL",
                               "ai_service_error"
                           );
                       }
                   } catch (AuthenticationException e) {
                       log.error("AI service authentication failed - API key invalid or expired: {}", e.getMessage());
                       aiResponse = "I'm sorry, but the AI service is currently unavailable due to authentication issues. Please contact support.";
                       chatAuditService.logSystemError(
                           request.getUserId(),
                           conversation.getConversationId(),
                           "AI_AUTHENTICATION_ERROR",
                           "authentication_failure"
                       );
                   } catch (IllegalStateException e) {
                       log.error("DeepSeek API key not configured properly", e);
                       aiResponse = "I'm sorry, but the AI service is currently unavailable. Please contact support if this issue persists.";
                       chatAuditService.logSystemError(
                           request.getUserId(),
                           conversation.getConversationId(),
                           "AI_CONFIG_ERROR",
                           "configuration_error"
                       );
                   } catch (RuntimeException e) {
                       // Handle specific HTTP errors that might be wrapped in RuntimeException
                       String errorMessage = e.getMessage().toLowerCase();
                       if (errorMessage.contains("503") || errorMessage.contains("service unavailable")) {
                           log.error("AI service unavailable", e);
                           aiResponse = "The AI service is temporarily unavailable. Please try again in a few minutes.";
                           chatAuditService.logSystemError(
                               request.getUserId(),
                               conversation.getConversationId(),
                               "AI_SERVICE_UNAVAILABLE",
                               "service_unavailable"
                           );
                       } else if (errorMessage.contains("429") || errorMessage.contains("rate limit")) {
                           log.error("AI service rate limit exceeded", e);
                           aiResponse = "I'm currently receiving a high volume of requests. Please wait a moment and try again.";
                           chatAuditService.logSystemError(
                               request.getUserId(),
                               conversation.getConversationId(),
                               "AI_RATE_LIMIT",
                               "rate_limit_error"
                           );
                       } else {
                           log.error("AI service runtime error: {}", e.getMessage(), e);
                           aiResponse = "I encountered an error while processing your request. Please try again.";
                           chatAuditService.logSystemError(
                               request.getUserId(),
                               conversation.getConversationId(),
                               "AI_RUNTIME_ERROR",
                               "runtime_error"
                           );
                       }
                   } catch (Exception e) {
                       log.error("Unexpected error in AI chat processing for conversation {}: {}", conversation.getConversationId(), e.getMessage(), e);
                       aiResponse = "I apologize, but I encountered an unexpected error. Please try rephrasing your question or contact support if the issue continues.";
                       chatAuditService.logSystemError(
                           request.getUserId(),
                           conversation.getConversationId(),
                           "AI_PROCESSING_ERROR",
                           "ai_service_exception"
                       );
                   }

            // Build and return ChatResponse
            int totalMessages = chatMessageRepository.countByConversation(conversation);
            Integer totalTokens = chatMessageRepository.sumTokensUsedByConversation(conversation);
            ChatResponse resp = new ChatResponse();
            resp.setConversationId(conversation.getConversationId());
            resp.setMessage(request.getMessage());
            resp.setAiResponse(aiResponse);
            resp.setAiProvider("DEEPSEEK_VIA_LANGCHAIN4J");
            resp.setModelUsed(aiConfig.getDeepseekModel());
            resp.setTokensUsed(0);
            resp.setProcessingTimeMs(System.currentTimeMillis() - startTime);
            resp.setTemperatureUsed(request.getTemperature() != null ? request.getTemperature() : 0.1);
            resp.setContextIncluded(List.of("conversation_history", "medical_context"));
            resp.setIsNewConversation(conversation.getCreatedAt().isAfter(LocalDateTime.now().minusMinutes(1)));
            resp.setTimestamp(LocalDateTime.now());
            resp.setConversationTitle(conversation.getTitle());
            resp.setTotalMessagesInConversation(totalMessages);
            resp.setTotalTokensUsedInConversation(totalTokens != null ? totalTokens : 0);
            resp.setApproachingTokenLimit(false);
            resp.setSuccess(true);
            return resp;
        } catch (Exception error) {
            log.error("Error processing chat request: ", error);
            return buildErrorResponse(request, "An error occurred while processing your request");
        }
    }

    /**
     * Process uploaded files and extract text content
     */
    private String processUploadedFiles(List<com.careconnect.dto.UploadedFileDTO> uploadedFiles) {
        StringBuilder fileContent = new StringBuilder();

        for (com.careconnect.dto.UploadedFileDTO file : uploadedFiles) {
            try {
                log.debug("Processing uploaded file: {} ({})", file.getFilename(), file.getContentType());

                String extractedText = documentProcessingService.extractTextContent(file);

                if (extractedText != null && !extractedText.trim().isEmpty()) {
                    fileContent.append("**File: ").append(file.getFilename()).append("**\n");
                    fileContent.append(extractedText);
                    fileContent.append("\n\n");

                    log.info("Successfully processed file: {} ({} characters extracted)",
                             file.getFilename(), extractedText.length());
                } else {
                    log.warn("No text content extracted from file: {}", file.getFilename());
                    fileContent.append("**File: ").append(file.getFilename()).append("**\n");
                    fileContent.append("[File uploaded but no text content could be extracted]\n\n");
                }

            } catch (Exception e) {
                log.error("Error processing uploaded file {}: {}", file.getFilename(), e.getMessage());
                fileContent.append("**File: ").append(file.getFilename()).append("**\n");
                fileContent.append("[Error processing file: ").append(e.getMessage()).append("]\n\n");
            }
        }

        return fileContent.toString().trim();
    }

    // ...all other methods from original AIChatService...
}
