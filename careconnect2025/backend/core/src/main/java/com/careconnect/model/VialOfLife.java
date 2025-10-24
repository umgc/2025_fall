package com.careconnect.model;

import jakarta.persistence.*;
import java.util.List;

@Entity
@Table(name = "vial_of_life")
public class VialOfLife {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long patientId;
    private String bloodType;

    @ElementCollection
    private List<String> allergies;

    @ElementCollection
    private List<String> medications;

    @ElementCollection
    private List<String> conditions;

    @ElementCollection
    private List<String> emergencyContacts;

    @Column(columnDefinition = "TEXT")
    private String tracker; // plain text history log

    // Constructors
    public VialOfLife() {}

    public VialOfLife(Long patientId, String bloodType, List<String> allergies, List<String> medications,
                      List<String> conditions, List<String> emergencyContacts, String tracker) {
        this.patientId = patientId;
        this.bloodType = bloodType;
        this.allergies = allergies;
        this.medications = medications;
        this.conditions = conditions;
        this.emergencyContacts = emergencyContacts;
        this.tracker = tracker;
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getPatientId() { return patientId; }
    public void setPatientId(Long patientId) { this.patientId = patientId; }

    public String getBloodType() { return bloodType; }
    public void setBloodType(String bloodType) { this.bloodType = bloodType; }

    public List<String> getAllergies() { return allergies; }
    public void setAllergies(List<String> allergies) { this.allergies = allergies; }

    public List<String> getMedications() { return medications; }
    public void setMedications(List<String> medications) { this.medications = medications; }

    public List<String> getConditions() { return conditions; }
    public void setConditions(List<String> conditions) { this.conditions = conditions; }

    public List<String> getEmergencyContacts() { return emergencyContacts; }
    public void setEmergencyContacts(List<String> emergencyContacts) { this.emergencyContacts = emergencyContacts; }

    public String getTracker() { return tracker; }
    public void setTracker(String tracker) { this.tracker = tracker; }
}
