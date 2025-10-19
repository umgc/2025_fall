package com.careconnect.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.Statement;
import java.util.stream.Collectors;

/**
 * Development data loader that automatically injects mock data into the database
 * when running in dev profile with an empty database.
 *
 * This component loads the mock_data.sql file from src/main/resources/db/mock_data.sql
 * and executes it only if the database has no users (empty state).
 */
@Slf4j
@Component
@Profile("dev")
public class DevDataLoader implements CommandLineRunner {

    private final DataSource dataSource;
    private final boolean loadMockDataEnabled;

    public DevDataLoader(DataSource dataSource,
                         @Value("${careconnect.dev.load-mock-data:true}") boolean loadMockDataEnabled) {
        this.dataSource = dataSource;
        this.loadMockDataEnabled = loadMockDataEnabled;
    }

    @Override
    public void run(String... args) throws Exception {
        if (!loadMockDataEnabled) {
            log.info("Mock data loading is disabled");
            return;
        }

        if (shouldLoadMockData()) {
            loadMockData();
        } else {
            log.info("Database already contains data. Skipping mock data load.");
        }
    }

    /**
     * Check if mock data should be loaded by verifying if users table is empty
     */
    private boolean shouldLoadMockData() {
        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement()) {

            conn.setAutoCommit(true);
            var rs = stmt.executeQuery("SELECT COUNT(*) FROM users");

            if (rs.next()) {
                int userCount = rs.getInt(1);
                log.info("Found {} existing users in database", userCount);
                return userCount == 0;
            }

            return true;
        } catch (Exception e) {
            log.warn("Could not check user count: {}. Will attempt to load mock data.", e.getMessage());
            return true;
        }
    }

    /**
     * Load mock data from SQL file
     */
    private void loadMockData() {
        try {
            log.info("🔄 Loading mock data from db/migration/mock_data.sql...");

            // Read the SQL file from resources
            ClassPathResource resource = new ClassPathResource("db/migration/mock_data.sql");

            if (!resource.exists()) {
                log.error("❌ Mock data file not found at: db/migration/mock_data.sql");
                log.error("Please create the file at: src/main/resources/db/migration/mock_data.sql");
                return;
            }

            String sql = readResourceFile(resource);

            // Execute the SQL
            executeSqlScript(sql);

            // Verify the data was loaded
            verifyDataLoad();

            log.info("✅ Mock data loaded successfully!");
            log.info("📧 Login credentials:");
            log.info("   Patient:  patient@careconnect.com / password");
            log.info("   Caregiver: caregiver@careconnect.com / password");
            log.info("   Family:    family@careconnect.com / password");

        } catch (Exception e) {
            log.error("❌ Failed to load mock data: {}", e.getMessage(), e);
            log.error("You can manually load the data using:");
            log.error("  psql -U postgres -d careconnect -h localhost -p 5432 -f mock_data.sql");
        }
    }

    /**
     * Read resource file content as string
     */
    private String readResourceFile(ClassPathResource resource) throws Exception {
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8))) {
            return reader.lines().collect(Collectors.joining("\n"));
        }
    }

    /**
     * Execute SQL script by parsing individual SQL statements properly
     */
    private void executeSqlScript(String sql) {
        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement()) {

            // Ensure autocommit is enabled for immediate persistence
            conn.setAutoCommit(true);

            String[] lines = sql.split("\\r?\\n");
            StringBuilder currentStatement = new StringBuilder();
            int executedCount = 0;

            for (String line : lines) {
                String trimmedLine = line.trim();

                // Skip comment-only lines
                if (trimmedLine.isEmpty() || trimmedLine.startsWith("--")) {
                    continue;
                }

                // Add line to current statement
                if (currentStatement.length() > 0) {
                    currentStatement.append(" ");
                }
                currentStatement.append(trimmedLine);

                // If line ends with semicolon, execute the statement
                if (trimmedLine.endsWith(";")) {
                    String statement = currentStatement.toString();
                    // Remove the semicolon
                    statement = statement.substring(0, statement.length() - 1).trim();

                    if (!statement.isEmpty()) {
                        try {
                            log.debug("Executing statement: {}", statement.substring(0, Math.min(100, statement.length())) + "...");
                            stmt.executeUpdate(statement);
                            executedCount++;
                            log.debug("Successfully executed statement #{}", executedCount);
                        } catch (Exception e) {
                            log.warn("Failed to execute statement: {}", e.getMessage());
                            log.debug("Full statement was: {}", statement);
                        }
                    }

                    // Reset for next statement
                    currentStatement = new StringBuilder();
                }
            }

            log.info("Executed {} SQL statements with autocommit=true", executedCount);
        } catch (Exception e) {
            log.error("Failed to execute SQL script: {}", e.getMessage(), e);
        }
    }

    /**
     * Verify that data was successfully loaded
     */
    private void verifyDataLoad() {
        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement()) {

            conn.setAutoCommit(true);

            int userCount = 0, patientCount = 0, caregiverCount = 0, medicationCount = 0;

            var rs = stmt.executeQuery("SELECT COUNT(*) FROM users");
            if (rs.next()) userCount = rs.getInt(1);
            rs.close();

            rs = stmt.executeQuery("SELECT COUNT(*) FROM patient");
            if (rs.next()) patientCount = rs.getInt(1);
            rs.close();

            rs = stmt.executeQuery("SELECT COUNT(*) FROM caregiver");
            if (rs.next()) caregiverCount = rs.getInt(1);
            rs.close();

            try {
                rs = stmt.executeQuery("SELECT COUNT(*) FROM patient_medication");
                if (rs.next()) medicationCount = rs.getInt(1);
                rs.close();
            } catch (Exception e) {
                // Table might not exist, ignore
            }

            log.info("📊 Data loaded: {} users, {} patients, {} caregivers, {} medications",
                    userCount, patientCount, caregiverCount, medicationCount);

        } catch (Exception e) {
            log.warn("Could not verify data load: {}", e.getMessage());
        }
    }
}