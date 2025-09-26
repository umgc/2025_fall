package com.careconnect.service;

import com.careconnect.model.EvvRecord;

public interface EvvIntegrationClient {
    String destination();
    void submit(EvvRecord record) throws Exception;
}
