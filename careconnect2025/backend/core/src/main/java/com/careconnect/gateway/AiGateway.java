package com.careconnect.gateway;


public interface AiGateway {
    AiResult chat(AiRequest request);
    <T> T structuredChat(AiRequest request, Class<T> targetType);
}
