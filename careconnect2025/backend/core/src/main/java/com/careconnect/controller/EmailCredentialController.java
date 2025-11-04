package com.careconnect.controller;

import com.careconnect.repository.EmailCredentialRepository;
import com.careconnect.model.EmailCredential;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class EmailCredentialController {

    private final EmailCredentialRepository credRepo;

    @GetMapping("/email-credentials/status")
    public ResponseEntity<Boolean> getConnectionStatus(@RequestParam String userId) {
        boolean hasValidCredentials = credRepo
                .findFirstByUserIdAndProviderOrderByIdDesc(userId, EmailCredential.Provider.GMAIL)
                .filter(cred -> cred.getAccessTokenEnc() != null && !cred.getAccessTokenEnc().isEmpty())
                .isPresent();

        return ResponseEntity.ok(hasValidCredentials);
    }
}