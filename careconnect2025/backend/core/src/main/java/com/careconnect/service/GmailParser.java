package com.careconnect.service;

import com.careconnect.model.*;
import org.springframework.stereotype.Service;
import java.time.ZoneOffset;
import java.util.List;

@Service
public class GmailParser {
    public USPSDigest toDomain(GmailClient.GmailRaw raw) {
        // TODO: real parsing; return empty digest to prove wiring
        return new USPSDigest(raw.internalDate().atOffset(ZoneOffset.UTC), List.of(), List.of());
    }
}
