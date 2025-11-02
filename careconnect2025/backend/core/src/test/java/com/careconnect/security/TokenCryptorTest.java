package com.careconnect.security;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class TokenCryptorTest {

    @Test
    void roundTripEncryptionAndDecryption() {
        var cryptor = new TokenCryptor("unit-test-secret-32-bytes-long!!!");

        String encrypted = cryptor.encrypt("sensitive-token");

        assertNotNull(encrypted);
        assertNotEquals("sensitive-token", encrypted);
        assertEquals("sensitive-token", cryptor.decrypt(encrypted));
    }

    @Test
    void handlesNullAndBlankValuesGracefully() {
        var cryptor = new TokenCryptor("unit-test-secret-32-bytes-long!!!");

        assertNull(cryptor.encrypt(null));
        assertEquals("", cryptor.encrypt(""));
        assertNull(cryptor.decrypt(null));
        assertEquals("", cryptor.decrypt(""));
    }
}
