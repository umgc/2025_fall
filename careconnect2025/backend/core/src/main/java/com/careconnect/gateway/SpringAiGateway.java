package com.careconnect.gateway;

import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.ChatOptions;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.converter.BeanOutputConverter;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class SpringAiGateway implements AiGateway {

    private final Map<String, ChatModel> registry;
    private final ChatModel defaultModel;

    public SpringAiGateway(Map<String, ChatModel> registry, ChatModel defaultModel) {
        this.registry = registry;
        this.defaultModel = defaultModel;
    }

    @Override
    public AiResult chat(AiRequest request) {
        ChatModel model = resolveModel(request.getProvider());
        List<Message> messages = buildMessages(request.getSystemPrompt(), request.getUserPrompt());
        Prompt prompt = new Prompt(messages, resolveOptions(request));
        ChatResponse resp = model.call(prompt);
        String text = resp.getResult().getOutput().getText();
        return new AiResult(text);
    }

    @Override
    public <T> T structuredChat(AiRequest request, Class<T> targetType) {
        ChatModel model = resolveModel(request.getProvider());

        // Build converter and inject format instructions into the prompt
        BeanOutputConverter<T> converter = new BeanOutputConverter<>(targetType);
        String formatInstructions = converter.getFormat();

        String userWithFormat = request.getUserPrompt() == null
                ? formatInstructions
                : request.getUserPrompt() + "\n\n" + formatInstructions;

        List<Message> messages = buildMessages(request.getSystemPrompt(), userWithFormat);
        Prompt prompt = new Prompt(messages, resolveOptions(request));

        ChatResponse resp = model.call(prompt);
        String content = resp.getResult().getOutput().getText();
        return converter.convert(content);
    }

    private ChatModel resolveModel(String provider) {
        if (provider == null || provider.isBlank()) {
            return defaultModel;
        }
        return registry.getOrDefault(provider, defaultModel);
    }

    private List<Message> buildMessages(String systemPrompt, String userPrompt) {
        List<Message> messages = new ArrayList<>();
        if (systemPrompt != null && !systemPrompt.isBlank()) {
            messages.add(new SystemMessage(systemPrompt));
        }
        messages.add(new UserMessage(userPrompt != null ? userPrompt : ""));
        return messages;
    }

    private ChatOptions resolveOptions(AiRequest req) {
        boolean hasTemp = req.getTemperature() != null;
        boolean hasMax = req.getMaxTokens() != null;

        if (!hasTemp && !hasMax) {
            return null;
        }

        ChatOptions.Builder builder = ChatOptions.builder();
        if (hasTemp) builder.temperature(req.getTemperature());
        if (hasMax) builder.maxTokens(req.getMaxTokens());
        return builder.build();
    }
}
