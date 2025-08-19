package com.focusedai;

import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import com.focusedai.config.ExecutionConfig;

@SpringBootApplication
@EnableConfigurationProperties({ExecutionConfig.class})
public class FocusedAiApplication {

    public static void main(String[] args) {
        // Load .env file
        Dotenv dotenv = Dotenv.configure()
            .directory(".")
            .ignoreIfMalformed()
            .ignoreIfMissing()
            .load();
        
        // Set system properties from .env
        dotenv.entries().forEach(entry -> {
            System.setProperty(entry.getKey(), entry.getValue());
        });
        
        SpringApplication.run(FocusedAiApplication.class, args);
        
        System.out.println("🚀 FocusedAI Code Execution & Grading Service started successfully!");
        System.out.println("📡 API available at: http://localhost:8080");
        System.out.println("🔍 Health check: http://localhost:8080/api/execute/health");
        System.out.println("📊 Available endpoints:");
        System.out.println("   POST /api/execute/{language} - Execute code");
        System.out.println("   POST /api/execute/batch - Batch execute");
        System.out.println("   POST /api/grade/submission - Grade submission");
        System.out.println("   POST /api/grade/batch - Batch grade");
        System.out.println("   GET  /api/execute/strategies - Available strategies");
        System.out.println("   POST /api/testcases - Manage test cases");
        System.out.println("   GET  /api/courses - Get courses");
        System.out.println("   GET  /api/assignments/{assignmentId}/submissions - Get submissions");
    }
}