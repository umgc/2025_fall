package com.careconnect.service.chat;

import lombok.RequiredArgsConstructor;
// The correct import for version 1.0.0-M6
import org.springframework.ai.model.Media;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.stereotype.Service;
import org.springframework.util.MimeTypeUtils;
import org.springframework.web.multipart.MultipartFile;
import reactor.core.publisher.Flux;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class GenericAiService {

    private final ChatModel chatModel;

    /**
     * Handles a standard chat request, now with an optional file.
     */
    public String getAiResponse(String context, String userPrompt, MultipartFile file) {
        // Use the helper to build the full message list
        List<Message> messages = buildMessages(context, userPrompt, file);

        Prompt prompt = new Prompt(messages);

        // Using getContent() is generally safer as it's the more generic accessor
        return chatModel.call(prompt).getResult().getOutput().getText();
    }

    /**
     * Handles a streaming chat request, now with an optional file.
     */
    public Flux<String> streamAiResponse(String context, String userPrompt, MultipartFile file) {
        List<Message> messages = buildMessages(context, userPrompt, file);

        Prompt prompt = new Prompt(messages);

        return chatModel.stream(prompt)
                .map(chatResponse -> chatResponse.getResult().getOutput().getText());
    }

    /**
     * Helper method to construct the list of messages.
     * It creates a multimodal UserMessage if a file is present.
     */
    private List<Message> buildMessages(String context, String userPrompt, MultipartFile file) {
        List<Message> messages = new ArrayList<>();

        if (context != null && !context.isBlank()) {
            messages.add(new SystemMessage(context));
        }

        UserMessage userMessage;
        if (file == null || file.isEmpty()) {
            userMessage = new UserMessage(userPrompt);
        } else {

                Media media = new Media(MimeTypeUtils.parseMimeType(file.getContentType()), file.getResource());
                userMessage = new UserMessage(userPrompt, List.of(media));

        }

        messages.add(userMessage);

        return messages;
    }
}