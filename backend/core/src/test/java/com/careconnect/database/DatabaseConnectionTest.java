package com.careconnect.database;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.ResultSet;
import java.sql.SQLException;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("dev")
@Transactional
class DatabaseConnectionTest {

    @Autowired
    private DataSource dataSource;

    @Test
    @DisplayName("Database connection should be established successfully")
    void testDatabaseConnection() throws SQLException {
        // Test that we can get a connection from the data source
        assertNotNull(dataSource, "DataSource should not be null");

        try (Connection connection = dataSource.getConnection()) {
            // Verify connection is valid
            assertNotNull(connection, "Connection should not be null");
            assertTrue(connection.isValid(5), "Connection should be valid");
            assertFalse(connection.isClosed(), "Connection should not be closed");

            // Get database metadata
            DatabaseMetaData metaData = connection.getMetaData();
            assertNotNull(metaData, "Database metadata should not be null");

            // Log database information
            System.out.println("Database Product Name: " + metaData.getDatabaseProductName());
            System.out.println("Database Product Version: " + metaData.getDatabaseProductVersion());
            System.out.println("Driver Name: " + metaData.getDriverName());
            System.out.println("Driver Version: " + metaData.getDriverVersion());
            System.out.println("Database URL: " + metaData.getURL());

            // Verify we're connected to PostgreSQL (in dev mode)
            String productName = metaData.getDatabaseProductName().toLowerCase();
            assertTrue(productName.contains("postgresql"),
                "Should be connected to PostgreSQL in dev mode, but connected to: " + productName);
        }
    }

    @Test
    @DisplayName("Database should support basic SQL operations")
    void testBasicDatabaseOperations() throws SQLException {
        try (Connection connection = dataSource.getConnection()) {
            // Test basic SQL operations
            var statement = connection.createStatement();

            // Test simple query
            ResultSet resultSet = statement.executeQuery("SELECT 1 as test_value");
            assertTrue(resultSet.next(), "Query should return at least one row");
            assertEquals(1, resultSet.getInt("test_value"), "Test value should be 1");

            // Test current timestamp
            ResultSet timeResult = statement.executeQuery("SELECT CURRENT_TIMESTAMP as current_time");
            assertTrue(timeResult.next(), "Timestamp query should return a row");
            assertNotNull(timeResult.getTimestamp("current_time"), "Current timestamp should not be null");

            // Test database schema existence
            ResultSet schemaResult = statement.executeQuery("SELECT CURRENT_SCHEMA() as schema_name");
            assertTrue(schemaResult.next(), "Schema query should return a row");
            String schemaName = schemaResult.getString("schema_name");
            assertNotNull(schemaName, "Schema name should not be null");
            System.out.println("Current schema: " + schemaName);
        }
    }

    @Test
    @DisplayName("Connection pool should be working")
    void testConnectionPool() throws SQLException {
        // Test that we can get multiple connections
        Connection conn1 = null;
        Connection conn2 = null;

        try {
            conn1 = dataSource.getConnection();
            conn2 = dataSource.getConnection();

            assertNotNull(conn1, "First connection should not be null");
            assertNotNull(conn2, "Second connection should not be null");
            assertNotSame(conn1, conn2, "Connections should be different instances");

            assertTrue(conn1.isValid(5), "First connection should be valid");
            assertTrue(conn2.isValid(5), "Second connection should be valid");

        } finally {
            // Clean up connections
            if (conn1 != null && !conn1.isClosed()) {
                conn1.close();
            }
            if (conn2 != null && !conn2.isClosed()) {
                conn2.close();
            }
        }
    }

    @Test
    @DisplayName("Database should be accessible with correct credentials")
    void testDatabaseCredentials() throws SQLException {
        try (Connection connection = dataSource.getConnection()) {
            DatabaseMetaData metaData = connection.getMetaData();
            String url = metaData.getURL();

            // Verify connection URL contains expected database details
            assertNotNull(url, "Database URL should not be null");
            assertTrue(url.contains("postgresql"), "URL should indicate PostgreSQL connection");
            assertTrue(url.contains("localhost") || url.contains("127.0.0.1"),
                "URL should connect to localhost");
            assertTrue(url.contains("5432"), "URL should use default PostgreSQL port 5432");

            System.out.println("Successfully connected to: " + url);
        }
    }
}