package com.careconnect.service;

import com.careconnect.model.evv.EvvRecord;

public interface EvvIntegrationClient {
    String destination();
    void submit(EvvRecord record) throws Exception;
}
