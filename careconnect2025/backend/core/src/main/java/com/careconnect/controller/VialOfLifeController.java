package com.careconnect.controller;

import com.careconnect.model.VialOfLife;
import com.careconnect.service.VialContactsServicePatch; // add this small patch service
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/v1/api/vial")
public class VialContactsPatchController {

    @Autowired
    private VialContactsServicePatch contactsService;

    // Accepts: { "patientId": 123, "contacts": ["Name|Role|Phone|PRIMARY", ...] }
    @PostMapping("/contacts/save")
    public ResponseEntity<VialOfLife> saveContacts(@RequestBody Map<String, Object> body) {
        Long patientId = ((Number) body.get("patientId")).longValue();
        @SuppressWarnings("unchecked")
        List<Object> list = (List<Object>) body.get("contacts");
        List<String> flattened = list.stream().map(Object::toString).collect(Collectors.toList());
        Optional<VialOfLife> saved = contactsService.updateContacts(patientId, flattened);
        return saved.map(ResponseEntity::ok).orElse(ResponseEntity.notFound().build());
    }
}
