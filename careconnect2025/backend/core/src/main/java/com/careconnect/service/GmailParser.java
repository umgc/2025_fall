package com.careconnect.service;

import com.careconnect.model.*;
import org.springframework.stereotype.Service;
import java.time.ZoneOffset;
import java.util.List;

@Service
public class GmailParser {
    public UspsDigest toDomain(GmailClient.GmailRaw raw) {
        // TODO: real parsing; return empty digest to prove wiring
        return new UspsDigest(raw.internalDate().atOffset(ZoneOffset.UTC), List.of(), List.of());
    }
}
