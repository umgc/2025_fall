package com.careconnect.service;

import com.careconnect.dto.PatientProfileDTO;
import com.careconnect.dto.MedicationDTO;
import com.careconnect.dto.FamilyMemberLinkResponse;
import com.careconnect.model.Patient;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.apache.pdfbox.pdmodel.interactive.form.PDAcroForm;
import org.apache.pdfbox.pdmodel.interactive.form.PDField;
import org.apache.pdfbox.Loader;
import java.awt.Color;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDate;
import java.time.Period;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;

@Service
public class VialOfLifePdfService {

    private static final Logger logger = LoggerFactory.getLogger(VialOfLifePdfService.class);

    @Autowired
    private PatientService patientService;

    @Autowired
    private MedicationService medicationService;

    @Autowired
    private FamilyMemberService familyMemberService;

    private static final String TEMPLATE_PATH = "templates/vial-of-life-form.pdf";

    /**
     * Generate a pre-filled Vial of Life PDF for a patient
     */
    public byte[] generateVialOfLifePdf(String emergencyId) throws Exception {
        logger.info("Generating Vial of Life PDF for emergency ID: {}", emergencyId);

        // Extract patient ID from emergency ID
        Long patientId = extractPatientIdFromEmergencyId(emergencyId);

        // Get patient information
        Optional<PatientProfileDTO> patientProfile = patientService.getPatientProfile(patientId);
        if (patientProfile.isEmpty()) {
            throw new IllegalArgumentException("Patient not found for emergency ID: " + emergencyId);
        }

        // Get additional patient data
        List<MedicationDTO> medications = medicationService.getAllMedicationsForPatient(patientId);
        List<FamilyMemberLinkResponse> emergencyContacts = familyMemberService.getFamilyMembersByPatientId(patientId);

        return fillPdfForm(patientProfile.get(), medications, emergencyContacts);
    }

    /**
     * Analyze the PDF form to understand its field structure
     */
    public void analyzePdfForm() throws IOException {
        ClassPathResource resource = new ClassPathResource(TEMPLATE_PATH);

        byte[] pdfBytes = resource.getInputStream().readAllBytes();
        try (PDDocument document = Loader.loadPDF(pdfBytes)) {
            PDAcroForm acroForm = document.getDocumentCatalog().getAcroForm();

            if (acroForm == null) {
                logger.warn("No form fields found in the PDF");
                return;
            }

            logger.info("Analyzing Vial of Life PDF form fields:");
            for (PDField field : acroForm.getFields()) {
                String fieldName = field.getFullyQualifiedName();
                String fieldValue = field.getValueAsString();
                logger.info("Field: {} = '{}'", fieldName, fieldValue);
            }
        }
    }

    /**
     * Generate a professional emergency PDF from scratch
     */
    private byte[] fillPdfForm(PatientProfileDTO patient, List<MedicationDTO> medications,
                              List<FamilyMemberLinkResponse> emergencyContacts) throws IOException {

        logger.info("Generating professional emergency PDF from scratch");

        ByteArrayOutputStream baos = new ByteArrayOutputStream();

        // Create a new PDF document
        try (PDDocument document = new PDDocument()) {
            PDPage page = new PDPage();
            document.addPage(page);

            // Create the professional emergency document
            createProfessionalEmergencyPdf(document, page, patient, medications, emergencyContacts);

            document.save(baos);
        }

        return baos.toByteArray();
    }

    /**
     * Create a professional emergency PDF document from scratch
     */
    private void createProfessionalEmergencyPdf(PDDocument document, PDPage page, PatientProfileDTO patient,
                                              List<MedicationDTO> medications,
                                              List<FamilyMemberLinkResponse> emergencyContacts) throws IOException {

        try (PDPageContentStream contentStream = new PDPageContentStream(document, page)) {

            // Page setup
            float pageWidth = page.getMediaBox().getWidth();
            float pageHeight = page.getMediaBox().getHeight();
            float margin = 50;
            float yPosition = pageHeight - margin;

            // Draw red cross header
            drawRedCrossHeader(contentStream, pageWidth, yPosition);
            yPosition -= 80;

            // Title
            drawTitle(contentStream, pageWidth, yPosition);
            yPosition -= 50;

            // Patient Information Section
            yPosition = drawPatientInfoSection(contentStream, patient, margin, yPosition);
            yPosition -= 30;

            // Medical Information Section
            yPosition = drawMedicalInfoSection(contentStream, patient, medications, margin, yPosition);
            yPosition -= 30;

            // Emergency Contacts Section
            yPosition = drawEmergencyContactsSection(contentStream, emergencyContacts, margin, yPosition);
            yPosition -= 40;

            // Footer
            drawFooter(contentStream, pageWidth, yPosition);
        }
    }

    /**
     * Draw red cross medical symbol at the top of the document
     */
    private void drawRedCrossHeader(PDPageContentStream contentStream, float pageWidth, float yPosition) throws IOException {
        // Draw red cross symbol
        float crossSize = 40;
        float crossX = pageWidth / 2 - crossSize / 2;
        float crossY = yPosition - crossSize;

        // Set red color
        contentStream.setNonStrokingColor(Color.RED);

        // Draw horizontal bar of cross
        contentStream.addRect(crossX - 5, crossY + crossSize/3, crossSize + 10, crossSize/3);
        contentStream.fill();

        // Draw vertical bar of cross
        contentStream.addRect(crossX + crossSize/3, crossY - 5, crossSize/3, crossSize + 10);
        contentStream.fill();

        // Reset color
        contentStream.setNonStrokingColor(Color.BLACK);

        // Add "EMERGENCY MEDICAL INFORMATION" text
        contentStream.beginText();
        contentStream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 18);
        String headerText = "EMERGENCY MEDICAL INFORMATION";
        float textWidth = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD).getStringWidth(headerText) / 1000 * 18;
        contentStream.newLineAtOffset((pageWidth - textWidth) / 2, crossY - 25);
        contentStream.showText(headerText);
        contentStream.endText();
    }

    /**
     * Draw document title
     */
    private void drawTitle(PDPageContentStream contentStream, float pageWidth, float yPosition) throws IOException {
        contentStream.beginText();
        contentStream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 14);
        String titleText = "VIAL OF LIFE - Critical Emergency Information";
        float textWidth = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD).getStringWidth(titleText) / 1000 * 14;
        contentStream.newLineAtOffset((pageWidth - textWidth) / 2, yPosition);
        contentStream.showText(titleText);
        contentStream.endText();
    }

    /**
     * Draw patient information section
     */
    private float drawPatientInfoSection(PDPageContentStream contentStream, PatientProfileDTO patient, float margin, float yPosition) throws IOException {
        // Section title
        drawSectionTitle(contentStream, "PATIENT INFORMATION", margin, yPosition);
        yPosition -= 25;

        // Patient details in a clean format
        yPosition = drawInfoLine(contentStream, "Name:", patient.firstName() + " " + patient.lastName(), margin, yPosition);

        if (patient.dob() != null) {
            try {
                LocalDate dobDate = LocalDate.parse(patient.dob());
                int age = Period.between(dobDate, LocalDate.now()).getYears();
                yPosition = drawInfoLine(contentStream, "Date of Birth:", patient.dob() + " (Age: " + age + ")", margin, yPosition);
            } catch (Exception e) {
                yPosition = drawInfoLine(contentStream, "Date of Birth:", patient.dob(), margin, yPosition);
            }
        }

        if (patient.gender() != null) {
            yPosition = drawInfoLine(contentStream, "Gender:", patient.gender().toString(), margin, yPosition);
        }

        if (patient.phone() != null) {
            yPosition = drawInfoLine(contentStream, "Phone:", patient.phone(), margin, yPosition);
        }

        return yPosition;
    }

    /**
     * Draw medical information section
     */
    private float drawMedicalInfoSection(PDPageContentStream contentStream, PatientProfileDTO patient, List<MedicationDTO> medications, float margin, float yPosition) throws IOException {
        drawSectionTitle(contentStream, "CRITICAL MEDICAL INFORMATION", margin, yPosition);
        yPosition -= 25;

        // Critical Allergies with red highlighting
        if (patient.allergies() != null && !patient.allergies().isEmpty()) {
            contentStream.beginText();
            contentStream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 11);
            contentStream.setNonStrokingColor(Color.RED);
            contentStream.newLineAtOffset(margin, yPosition);
            contentStream.showText("CRITICAL ALLERGIES:");
            contentStream.endText();
            contentStream.setNonStrokingColor(Color.BLACK);
            yPosition -= 18;

            for (var allergy : patient.allergies()) {
                String allergyText = "• " + allergy.allergen();
                if (allergy.severity() != null) {
                    allergyText += " [" + allergy.severity().toString() + "]";
                }
                if (allergy.reaction() != null) {
                    allergyText += " - " + allergy.reaction();
                }
                yPosition = drawBulletPoint(contentStream, allergyText, margin + 10, yPosition);
            }
            yPosition -= 10;
        }

        // Current Medications
        if (medications != null && !medications.isEmpty()) {
            List<MedicationDTO> activeMeds = medications.stream()
                .filter(MedicationDTO::isActive)
                .toList();

            if (!activeMeds.isEmpty()) {
                yPosition = drawInfoLine(contentStream, "Current Medications:", "", margin, yPosition);
                yPosition -= 5;

                for (MedicationDTO med : activeMeds) {
                    String medText = "• " + med.medicationName();
                    if (med.dosage() != null) {
                        medText += " - " + med.dosage();
                    }
                    if (med.frequency() != null) {
                        medText += " (" + med.frequency() + ")";
                    }
                    yPosition = drawBulletPoint(contentStream, medText, margin + 10, yPosition);
                }
            }
        }

        return yPosition;
    }

    /**
     * Draw emergency contacts section
     */
    private float drawEmergencyContactsSection(PDPageContentStream contentStream, List<FamilyMemberLinkResponse> emergencyContacts, float margin, float yPosition) throws IOException {
        drawSectionTitle(contentStream, "EMERGENCY CONTACTS", margin, yPosition);
        yPosition -= 25;

        if (emergencyContacts != null && !emergencyContacts.isEmpty()) {
            for (FamilyMemberLinkResponse contact : emergencyContacts) {
                String contactText = contact.familyMemberName();
                if (contact.relationship() != null) {
                    contactText += " (" + contact.relationship() + ")";
                }
                yPosition = drawInfoLine(contentStream, "Contact:", contactText, margin, yPosition);

                if (contact.familyMemberEmail() != null) {
                    yPosition = drawInfoLine(contentStream, "Email:", contact.familyMemberEmail(), margin, yPosition);
                }
                yPosition -= 5;
            }
        } else {
            yPosition = drawInfoLine(contentStream, "", "No emergency contacts on file", margin, yPosition);
        }

        return yPosition;
    }

    /**
     * Draw document footer
     */
    private void drawFooter(PDPageContentStream contentStream, float pageWidth, float yPosition) throws IOException {
        // Draw separator line
        contentStream.setStrokingColor(Color.GRAY);
        contentStream.moveTo(50, yPosition + 10);
        contentStream.lineTo(pageWidth - 50, yPosition + 10);
        contentStream.stroke();

        // Footer text
        contentStream.beginText();
        contentStream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 9);
        contentStream.setNonStrokingColor(Color.GRAY);
        contentStream.newLineAtOffset(50, yPosition - 10);
        contentStream.showText("This document contains confidential medical information.");
        contentStream.endText();

        contentStream.beginText();
        contentStream.newLineAtOffset(50, yPosition - 25);
        contentStream.showText("Generated by CareConnect Emergency Information System - For medical emergencies, contact 911 immediately.");
        contentStream.endText();

        // Generation timestamp
        contentStream.beginText();
        contentStream.newLineAtOffset(pageWidth - 200, yPosition - 10);
        contentStream.showText("Generated: " + LocalDate.now().format(DateTimeFormatter.ofPattern("MM/dd/yyyy")));
        contentStream.endText();

        contentStream.setNonStrokingColor(Color.BLACK);
    }

    /**
     * Helper method to draw section titles
     */
    private void drawSectionTitle(PDPageContentStream contentStream, String title, float margin, float yPosition) throws IOException {
        // Draw background rectangle for section title
        contentStream.setNonStrokingColor(new Color(240, 240, 240));
        contentStream.addRect(margin - 5, yPosition - 15, 500, 20);
        contentStream.fill();

        // Draw title text
        contentStream.beginText();
        contentStream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 12);
        contentStream.setNonStrokingColor(Color.BLACK);
        contentStream.newLineAtOffset(margin, yPosition - 12);
        contentStream.showText(title);
        contentStream.endText();
    }

    /**
     * Helper method to draw information lines
     */
    private float drawInfoLine(PDPageContentStream contentStream, String label, String value, float margin, float yPosition) throws IOException {
        contentStream.beginText();
        contentStream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 10);
        contentStream.newLineAtOffset(margin, yPosition);
        contentStream.showText(label);
        contentStream.endText();

        if (!value.isEmpty()) {
            contentStream.beginText();
            contentStream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 10);
            contentStream.newLineAtOffset(margin + 100, yPosition);
            contentStream.showText(value);
            contentStream.endText();
        }

        return yPosition - 18;
    }

    /**
     * Helper method to draw bullet points
     */
    private float drawBulletPoint(PDPageContentStream contentStream, String text, float margin, float yPosition) throws IOException {
        contentStream.beginText();
        contentStream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 10);
        contentStream.newLineAtOffset(margin, yPosition);
        contentStream.showText(text);
        contentStream.endText();

        return yPosition - 15;
    }

    private void fillPatientBasicInfo(PDAcroForm acroForm, PatientProfileDTO patient) throws IOException {
        // Common field names that might exist in Vial of Life forms
        // These will need to be adjusted based on the actual form fields

        setFieldValue(acroForm, "name", patient.firstName() + " " + patient.lastName());
        setFieldValue(acroForm, "firstName", patient.firstName());
        setFieldValue(acroForm, "lastName", patient.lastName());

        if (patient.dob() != null) {
            setFieldValue(acroForm, "dateOfBirth", patient.dob());
            setFieldValue(acroForm, "dob", patient.dob());

            // Try to parse DOB and calculate age if possible
            try {
                LocalDate dobDate = LocalDate.parse(patient.dob());
                int age = Period.between(dobDate, LocalDate.now()).getYears();
                setFieldValue(acroForm, "age", String.valueOf(age));
            } catch (Exception e) {
                logger.warn("Could not parse DOB for age calculation: {}", patient.dob());
            }
        }

        setFieldValue(acroForm, "gender", patient.gender() != null ? patient.gender().toString() : "");
        setFieldValue(acroForm, "bloodType", ""); // bloodType not available in current DTO

        // Address information
        if (patient.address() != null) {
            setFieldValue(acroForm, "address", patient.address().toString());
        }
    }

    private void fillMedicalInfo(PDAcroForm acroForm, PatientProfileDTO patient, List<MedicationDTO> medications) throws IOException {
        // Fill allergies
        if (patient.allergies() != null && !patient.allergies().isEmpty()) {
            StringBuilder allergiesText = new StringBuilder();
            for (var allergy : patient.allergies()) {
                if (allergiesText.length() > 0) allergiesText.append(", ");
                allergiesText.append(allergy.allergen());
                if (allergy.severity() != null && allergy.severity().toString().equalsIgnoreCase("CRITICAL")) {
                    allergiesText.append(" (CRITICAL)");
                }
            }
            setFieldValue(acroForm, "allergies", allergiesText.toString());
            setFieldValue(acroForm, "medicalAllergies", allergiesText.toString());
        }

        // Medical conditions not available in current DTO structure

        // Fill current medications
        if (medications != null && !medications.isEmpty()) {
            StringBuilder medicationsText = new StringBuilder();
            List<MedicationDTO> activeMeds = medications.stream()
                .filter(MedicationDTO::isActive)
                .toList();

            for (MedicationDTO med : activeMeds) {
                if (medicationsText.length() > 0) medicationsText.append("\n");
                medicationsText.append(med.medicationName());
                if (med.dosage() != null) {
                    medicationsText.append(" - ").append(med.dosage());
                }
                if (med.frequency() != null) {
                    medicationsText.append(" (").append(med.frequency()).append(")");
                }
            }
            setFieldValue(acroForm, "medications", medicationsText.toString());
            setFieldValue(acroForm, "currentMedications", medicationsText.toString());
        }
    }

    private void fillEmergencyContacts(PDAcroForm acroForm, List<FamilyMemberLinkResponse> emergencyContacts) throws IOException {
        if (emergencyContacts != null && !emergencyContacts.isEmpty()) {
            // Primary emergency contact
            FamilyMemberLinkResponse primaryContact = emergencyContacts.get(0);
            setFieldValue(acroForm, "emergencyContactName", primaryContact.familyMemberName());
            setFieldValue(acroForm, "emergencyContactEmail", primaryContact.familyMemberEmail());
            setFieldValue(acroForm, "emergencyContactRelationship", primaryContact.relationship());

            // Secondary emergency contact (if available)
            if (emergencyContacts.size() > 1) {
                FamilyMemberLinkResponse secondaryContact = emergencyContacts.get(1);
                setFieldValue(acroForm, "emergencyContact2Name", secondaryContact.familyMemberName());
                setFieldValue(acroForm, "emergencyContact2Email", secondaryContact.familyMemberEmail());
                setFieldValue(acroForm, "emergencyContact2Relationship", secondaryContact.relationship());
            }
        }
    }

    private void setFieldValue(PDAcroForm acroForm, String fieldName, String value) {
        try {
            PDField field = acroForm.getField(fieldName);
            if (field != null && value != null) {
                field.setValue(value);
                logger.debug("Set field '{}' = '{}'", fieldName, value);
            } else if (field == null) {
                logger.debug("Field '{}' not found in form", fieldName);
            }
        } catch (IOException e) {
            logger.warn("Could not set value for field '{}': {}", fieldName, e.getMessage());
        }
    }

    /**
     * Extract patient ID from emergency ID
     */
    private Long extractPatientIdFromEmergencyId(String emergencyId) {
        try {
            if (emergencyId.startsWith("VIAL")) {
                String idPart = emergencyId.substring(4);
                return Long.parseLong(idPart);
            }
        } catch (NumberFormatException e) {
            logger.error("Could not parse patient ID from emergency ID: {}", emergencyId);
        }

        throw new IllegalArgumentException("Invalid emergency ID format: " + emergencyId);
    }
}