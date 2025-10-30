package com.careconnect.controller;

import com.careconnect.dto.evv.EvvLocationRequest;
import com.careconnect.dto.evv.EvvLocationResponse;
import com.careconnect.model.evv.EvvLocationRole;
import com.careconnect.service.evv.EvvLocationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/api/evv/locations")
@RequiredArgsConstructor
@Tag(name = "EVV Locations", description = "EVV check-in and check-out location management")
public class EvvLocationController {
    
    private final EvvLocationService locationService;
    
    /**
     * Save or update an EVV location (check-in or check-out)
     * Supports both GPS coordinates and patient address
     */
    @PostMapping
    @Operation(summary = "Save EVV location", 
               description = "Save or update check-in/check-out location for an EVV record. " +
                           "Supports GPS coordinates or patient address snapshot.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Location saved successfully"),
        @ApiResponse(responseCode = "201", description = "Location created successfully"),
        @ApiResponse(responseCode = "400", description = "Invalid request data"),
        @ApiResponse(responseCode = "404", description = "EVV record or patient not found")
    })
    public ResponseEntity<EvvLocationResponse> saveLocation(@Valid @RequestBody EvvLocationRequest request) {
        // Perform custom validation
        request.validate();
        
        // Save the location (upsert)
        EvvLocationResponse response = locationService.saveLocation(request);
        
        // Return 201 for new, 200 for update (we can't easily tell which, so return 200)
        return ResponseEntity.ok(response);
    }
    
    /**
     * Get all locations for an EVV record
     */
    @GetMapping("/records/{evvRecordId}")
    @Operation(summary = "Get locations for EVV record", 
               description = "Retrieve all locations (check-in and check-out) for a specific EVV record")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Locations retrieved successfully"),
        @ApiResponse(responseCode = "404", description = "EVV record not found")
    })
    public ResponseEntity<List<EvvLocationResponse>> getLocationsForRecord(
            @PathVariable Long evvRecordId) {
        List<EvvLocationResponse> locations = locationService.getLocationsForRecord(evvRecordId);
        return ResponseEntity.ok(locations);
    }
    
    /**
     * Get a specific location by role
     */
    @GetMapping("/records/{evvRecordId}/{role}")
    @Operation(summary = "Get specific location by role", 
               description = "Retrieve check-in or check-out location for an EVV record")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Location retrieved successfully"),
        @ApiResponse(responseCode = "404", description = "Location not found")
    })
    public ResponseEntity<EvvLocationResponse> getLocationByRole(
            @PathVariable Long evvRecordId,
            @PathVariable EvvLocationRole role) {
        EvvLocationResponse location = locationService.getLocationByRole(evvRecordId, role);
        return ResponseEntity.ok(location);
    }
    
    /**
     * Delete a location
     */
    @DeleteMapping("/records/{evvRecordId}/{role}")
    @Operation(summary = "Delete location", 
               description = "Delete a check-in or check-out location for an EVV record")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "204", description = "Location deleted successfully"),
        @ApiResponse(responseCode = "404", description = "Location not found")
    })
    public ResponseEntity<Void> deleteLocation(
            @PathVariable Long evvRecordId,
            @PathVariable EvvLocationRole role) {
        locationService.deleteLocation(evvRecordId, role);
        return ResponseEntity.noContent().build();
    }
}

