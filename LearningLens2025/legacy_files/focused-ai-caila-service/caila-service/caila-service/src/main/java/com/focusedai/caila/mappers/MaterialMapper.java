// File: src/main/java/com/focusedai/caila/mappers/MaterialMapper.java
package com.focusedai.caila.mappers;

import com.focusedai.caila.models.domain.GeneratedMaterial;
import com.focusedai.caila.models.MaterialRequest;
import com.focusedai.caila.models.CailaResponse;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Component
public class MaterialMapper {
    
    /**
     * Create GeneratedMaterial from MaterialRequest
     */
    public GeneratedMaterial fromMaterialRequest(MaterialRequest request, String teacherId, 
                                                String content, String prompt) {
        GeneratedMaterial material = GeneratedMaterial.builder()
                .id(UUID.randomUUID().toString())
                .teacherId(teacherId)
                .courseId(request.getCourseId())
                .courseName(request.getCourseName())
                .title(request.getTitle())
                .type(request.getMaterialType())
                .content(content)
                .prompt(prompt)
                .platform("caila")
                .version(1)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .versions(new ArrayList<>())
                .build();
        
        // Add first version
        GeneratedMaterial.MaterialVersion firstVersion = GeneratedMaterial.MaterialVersion.builder()
                .version(1)
                .content(content)
                .prompt(prompt)
                .createdAt(LocalDateTime.now())
                .build();
        material.getVersions().add(firstVersion);
        
        return material;
    }
    
    /**
     * Create GeneratedMaterial with full parameters
     */
    public GeneratedMaterial createMaterial(String teacherId, String courseId, String courseName,
                                          String title, String type, String content, String prompt,
                                          String platform) {
        GeneratedMaterial material = GeneratedMaterial.builder()
                .id(UUID.randomUUID().toString())
                .teacherId(teacherId)
                .courseId(courseId)
                .courseName(courseName)
                .title(title)
                .type(type)
                .content(content)
                .prompt(prompt)
                .platform(platform != null ? platform : "caila")
                .version(1)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .versions(new ArrayList<>())
                .build();
        
        // Add first version
        GeneratedMaterial.MaterialVersion firstVersion = GeneratedMaterial.MaterialVersion.builder()
                .version(1)
                .content(content)
                .prompt(prompt)
                .createdAt(LocalDateTime.now())
                .build();
        material.getVersions().add(firstVersion);
        
        return material;
    }
    
    /**
     * Update material with new version
     */
    public GeneratedMaterial updateMaterialWithNewVersion(GeneratedMaterial material, 
                                                         String newContent, String newPrompt) {
        int nextVersion = material.getVersion() + 1;
        
        // Create new version
        GeneratedMaterial.MaterialVersion newVersion = GeneratedMaterial.MaterialVersion.builder()
                .version(nextVersion)
                .content(newContent)
                .prompt(newPrompt)
                .createdAt(LocalDateTime.now())
                .build();
        
        // Update material
        material.setContent(newContent);
        material.setPrompt(newPrompt);
        material.setVersion(nextVersion);
        material.setUpdatedAt(LocalDateTime.now());
        
        // Add to versions list
        if (material.getVersions() == null) {
            material.setVersions(new ArrayList<>());
        }
        material.getVersions().add(newVersion);
        
        return material;
    }
    
    /**
     * Convert GeneratedMaterial to API response format
     */
    public Map<String, Object> toApiResponse(GeneratedMaterial material) {
        Map<String, Object> response = new HashMap<>();
        
        response.put("id", material.getId());
        response.put("teacherId", material.getTeacherId());
        response.put("courseId", material.getCourseId());
        response.put("courseName", material.getCourseName());
        response.put("title", material.getTitle());
        response.put("type", material.getType());
        response.put("content", material.getContent());
        response.put("prompt", material.getPrompt());
        response.put("platform", material.getPlatform());
        response.put("version", material.getVersion());
        response.put("createdAt", material.getCreatedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        response.put("updatedAt", material.getUpdatedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        
        // Add version history
        List<Map<String, Object>> versionHistory = new ArrayList<>();
        if (material.getVersions() != null) {
            for (GeneratedMaterial.MaterialVersion version : material.getVersions()) {
                Map<String, Object> versionMap = new HashMap<>();
                versionMap.put("version", version.getVersion());
                versionMap.put("content", version.getContent());
                versionMap.put("prompt", version.getPrompt());
                versionMap.put("createdAt", version.getCreatedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
                versionHistory.add(versionMap);
            }
        }
        response.put("versions", versionHistory);
        
        return response;
    }
    
    /**
     * Convert list of GeneratedMaterials to API response format
     */
    public List<Map<String, Object>> toApiResponseList(List<GeneratedMaterial> materials) {
        List<Map<String, Object>> responseList = new ArrayList<>();
        for (GeneratedMaterial material : materials) {
            responseList.add(toApiResponse(material));
        }
        return responseList;
    }
    
    /**
     * Create material summary (without full content)
     */
    public Map<String, Object> toSummaryResponse(GeneratedMaterial material) {
        Map<String, Object> summary = new HashMap<>();
        
        summary.put("id", material.getId());
        summary.put("teacherId", material.getTeacherId());
        summary.put("courseId", material.getCourseId());
        summary.put("courseName", material.getCourseName());
        summary.put("title", material.getTitle());
        summary.put("type", material.getType());
        summary.put("platform", material.getPlatform());
        summary.put("version", material.getVersion());
        summary.put("createdAt", material.getCreatedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        summary.put("updatedAt", material.getUpdatedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        
        // Add content preview (first 200 characters)
        String contentPreview = material.getContent();
        if (contentPreview != null && contentPreview.length() > 200) {
            contentPreview = contentPreview.substring(0, 200) + "...";
        }
        summary.put("contentPreview", contentPreview);
        
        // Add version count
        summary.put("versionCount", material.getVersions() != null ? material.getVersions().size() : 0);
        
        return summary;
    }
    
    /**
     * Create teacher materials dashboard response
     */
    public Map<String, Object> createTeacherMaterialsDashboard(List<GeneratedMaterial> materials, String teacherId) {
        Map<String, Object> dashboard = new HashMap<>();
        
        if (materials.isEmpty()) {
            dashboard.put("teacherId", teacherId);
            dashboard.put("totalMaterials", 0);
            dashboard.put("materials", new ArrayList<>());
            dashboard.put("materialsByType", new HashMap<>());
            dashboard.put("materialsByCourse", new HashMap<>());
            dashboard.put("recentActivity", new ArrayList<>());
            return dashboard;
        }
        
        // Group by type
        Map<String, List<GeneratedMaterial>> materialsByType = new HashMap<>();
        for (GeneratedMaterial material : materials) {
            String type = material.getType();
            materialsByType.computeIfAbsent(type, k -> new ArrayList<>()).add(material);
        }
        
        // Group by course
        Map<String, List<GeneratedMaterial>> materialsByCourse = new HashMap<>();
        for (GeneratedMaterial material : materials) {
            String courseId = material.getCourseId();
            materialsByCourse.computeIfAbsent(courseId, k -> new ArrayList<>()).add(material);
        }
        
        // Create type summary
        Map<String, Object> typeSummary = new HashMap<>();
        for (Map.Entry<String, List<GeneratedMaterial>> entry : materialsByType.entrySet()) {
            Map<String, Object> typeInfo = new HashMap<>();
            typeInfo.put("count", entry.getValue().size());
            typeInfo.put("latestUpdate", entry.getValue().stream()
                    .map(GeneratedMaterial::getUpdatedAt)
                    .max(LocalDateTime::compareTo)
                    .map(time -> time.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
                    .orElse(null));
            typeSummary.put(entry.getKey(), typeInfo);
        }
        
        // Create course summary
        Map<String, Object> courseSummary = new HashMap<>();
        for (Map.Entry<String, List<GeneratedMaterial>> entry : materialsByCourse.entrySet()) {
            Map<String, Object> courseInfo = new HashMap<>();
            courseInfo.put("count", entry.getValue().size());
            courseInfo.put("courseName", entry.getValue().get(0).getCourseName());
            courseInfo.put("latestUpdate", entry.getValue().stream()
                    .map(GeneratedMaterial::getUpdatedAt)
                    .max(LocalDateTime::compareTo)
                    .map(time -> time.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
                    .orElse(null));
            courseSummary.put(entry.getKey(), courseInfo);
        }
        
        // Recent activity (last 10 materials)
        List<GeneratedMaterial> recentMaterials = materials.stream()
                .sorted((a, b) -> b.getUpdatedAt().compareTo(a.getUpdatedAt()))
                .limit(10)
                .collect(ArrayList::new, (list, item) -> list.add(item), ArrayList::addAll);
        
        List<Map<String, Object>> recentActivity = new ArrayList<>();
        for (GeneratedMaterial material : recentMaterials) {
            recentActivity.add(toSummaryResponse(material));
        }
        
        dashboard.put("teacherId", teacherId);
        dashboard.put("totalMaterials", materials.size());
        dashboard.put("materials", toApiResponseList(materials));
        dashboard.put("materialsByType", typeSummary);
        dashboard.put("materialsByCourse", courseSummary);
        dashboard.put("recentActivity", recentActivity);
        dashboard.put("generatedAt", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        
        return dashboard;
    }
    
    /**
     * Convert material to CailaResponse format
     */
    public CailaResponse toCailaResponse(GeneratedMaterial material) {
        return CailaResponse.builder()
                .response(material.getContent())
                .materialId(material.getId())
                .timestamp(material.getUpdatedAt())
                .success(true)
                .build();
    }
    
    /**
     * Create material export format
     */
    public Map<String, Object> toExportFormat(GeneratedMaterial material, String exportType) {
        Map<String, Object> export = new HashMap<>();
        
        export.put("materialId", material.getId());
        export.put("title", material.getTitle());
        export.put("type", material.getType());
        export.put("courseId", material.getCourseId());
        export.put("courseName", material.getCourseName());
        export.put("content", material.getContent());
        export.put("exportType", exportType);
        export.put("exportedAt", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        export.put("platform", material.getPlatform());
        export.put("version", material.getVersion());
        
        // Add formatted content based on export type
        switch (exportType.toLowerCase()) {
            case "pdf":
                export.put("formattedContent", formatForPDF(material));
                break;
            case "word":
                export.put("formattedContent", formatForWord(material));
                break;
            case "html":
                export.put("formattedContent", formatForHTML(material));
                break;
            case "moodle":
                export.put("formattedContent", formatForMoodle(material));
                break;
            case "google":
                export.put("formattedContent", formatForGoogle(material));
                break;
            default:
                export.put("formattedContent", material.getContent());
                break;
        }
        
        return export;
    }
    
    /**
     * Create material statistics
     */
    public Map<String, Object> createMaterialStatistics(List<GeneratedMaterial> materials) {
        Map<String, Object> stats = new HashMap<>();
        
        if (materials.isEmpty()) {
            stats.put("totalMaterials", 0);
            stats.put("uniqueTeachers", 0);
            stats.put("uniqueCourses", 0);
            stats.put("materialTypes", new HashMap<>());
            return stats;
        }
        
        Set<String> uniqueTeachers = new HashSet<>();
        Set<String> uniqueCourses = new HashSet<>();
        Map<String, Integer> typeCount = new HashMap<>();
        Map<String, Integer> platformCount = new HashMap<>();
        
        for (GeneratedMaterial material : materials) {
            uniqueTeachers.add(material.getTeacherId());
            uniqueCourses.add(material.getCourseId());
            
            String type = material.getType();
            typeCount.put(type, typeCount.getOrDefault(type, 0) + 1);
            
            String platform = material.getPlatform();
            platformCount.put(platform, platformCount.getOrDefault(platform, 0) + 1);
        }
        
        stats.put("totalMaterials", materials.size());
        stats.put("uniqueTeachers", uniqueTeachers.size());
        stats.put("uniqueCourses", uniqueCourses.size());
        stats.put("materialTypes", typeCount);
        stats.put("platforms", platformCount);
        
        // Time-based statistics
        LocalDateTime earliestDate = materials.stream()
                .map(GeneratedMaterial::getCreatedAt)
                .min(LocalDateTime::compareTo)
                .orElse(null);
        LocalDateTime latestDate = materials.stream()
                .map(GeneratedMaterial::getUpdatedAt)
                .max(LocalDateTime::compareTo)
                .orElse(null);
        
        stats.put("earliestMaterial", earliestDate != null ? earliestDate.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME) : null);
        stats.put("latestMaterial", latestDate != null ? latestDate.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME) : null);
        
        // Version statistics
        int totalVersions = materials.stream()
                .mapToInt(m -> m.getVersions() != null ? m.getVersions().size() : 0)
                .sum();
        stats.put("totalVersions", totalVersions);
        stats.put("averageVersionsPerMaterial", materials.size() > 0 ? (double) totalVersions / materials.size() : 0);
        
        return stats;
    }
    
    // Private helper methods for formatting
    private String formatForPDF(GeneratedMaterial material) {
        StringBuilder formatted = new StringBuilder();
        formatted.append("Title: ").append(material.getTitle()).append("\n");
        formatted.append("Type: ").append(material.getType()).append("\n");
        formatted.append("Course: ").append(material.getCourseName()).append("\n");
        formatted.append("Created: ").append(material.getCreatedAt().format(DateTimeFormatter.ofPattern("MMM dd, yyyy"))).append("\n\n");
        formatted.append(material.getContent());
        return formatted.toString();
    }
    
    private String formatForWord(GeneratedMaterial material) {
        // Similar to PDF but with Word-specific formatting
        return formatForPDF(material);
    }
    
    private String formatForHTML(GeneratedMaterial material) {
        StringBuilder html = new StringBuilder();
        html.append("<!DOCTYPE html><html><head><title>").append(material.getTitle()).append("</title></head><body>");
        html.append("<h1>").append(material.getTitle()).append("</h1>");
        html.append("<p><strong>Type:</strong> ").append(material.getType()).append("</p>");
        html.append("<p><strong>Course:</strong> ").append(material.getCourseName()).append("</p>");
        html.append("<p><strong>Created:</strong> ").append(material.getCreatedAt().format(DateTimeFormatter.ofPattern("MMM dd, yyyy"))).append("</p>");
        html.append("<hr>");
        html.append("<div>").append(material.getContent().replaceAll("\n", "<br>")).append("</div>");
        html.append("</body></html>");
        return html.toString();
    }
    
    private String formatForMoodle(GeneratedMaterial material) {
        StringBuilder formatted = new StringBuilder();
        formatted.append("<div style='border: 3px solid #ff9800; padding: 15px; margin-bottom: 20px; background-color: #fff3e0;'>");
        formatted.append("<h2 style='color: #ff9800; margin: 0;'>🎓 CAILA Generated ").append(material.getType().toUpperCase()).append("</h2>");
        formatted.append("<p style='margin: 8px 0 0 0;'>");
        formatted.append("<strong>Title:</strong> ").append(material.getTitle()).append("<br>");
        formatted.append("<strong>Course:</strong> ").append(material.getCourseName()).append("<br>");
        formatted.append("<strong>Generated:</strong> ").append(material.getCreatedAt().format(DateTimeFormatter.ofPattern("MMM dd, yyyy 'at' HH:mm"))).append("<br>");
        formatted.append("</p>");
        formatted.append("</div>");
        formatted.append("<div style='border: 1px solid #ddd; padding: 15px; background-color: white;'>");
        formatted.append(material.getContent().replaceAll("\n", "<br>"));
        formatted.append("</div>");
        return formatted.toString();
    }
    
    private String formatForGoogle(GeneratedMaterial material) {
        StringBuilder formatted = new StringBuilder();
        formatted.append("CAILA Generated ").append(material.getType().toUpperCase()).append("\n");
        formatted.append("=".repeat(50)).append("\n");
        formatted.append("Title: ").append(material.getTitle()).append("\n");
        formatted.append("Course: ").append(material.getCourseName()).append("\n");
        formatted.append("Generated: ").append(material.getCreatedAt().format(DateTimeFormatter.ofPattern("MMM dd, yyyy 'at' HH:mm"))).append("\n");
        formatted.append("=".repeat(50)).append("\n\n");
        formatted.append(material.getContent()).append("\n\n");
        formatted.append("-".repeat(30)).append("\n");
        formatted.append("Generated by CAILA AI Assistant");
        return formatted.toString();
    }
}