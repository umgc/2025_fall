package com.careconnect.service;

import com.careconnect.model.*;
import org.springframework.stereotype.Service;
import java.time.ZoneOffset;
import java.util.List;

@Service
public class OutlookParser {
    public UspsDigest toDomain(OutlookClient.OutlookRaw raw) {
        return new UspsDigest(raw.received().atOffset(ZoneOffset.UTC), List.of(), List.of());
    }
}
