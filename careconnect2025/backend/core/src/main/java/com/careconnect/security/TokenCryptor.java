package com.careconnect.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Lightweight AES-GCM wrapper for encrypting sensitive email tokens at rest.
 * In production we should swap this out for a managed KMS solution, but this
 * at least keeps tokens out of the database in plaintext for now.
 */
@Component
public class TokenCryptor {

    private static final String CIPHER = "AES/GCM/NoPadding";
    private static final int GCM_TAG_BITS = 128;
    private static final byte CURRENT_VERSION = 1;

    private final SecureRandom secureRandom = new SecureRandom();
    private final SecretKey key;

    public TokenCryptor(@Value("${email.crypto.secret}") String secret) {
        if (secret == null || secret.isBlank()) {
            throw new IllegalStateException("Missing email.crypto.secret configuration");
        }
        try {
            byte[] material = MessageDigest.getInstance("SHA-256")
                    .digest(secret.getBytes(StandardCharsets.UTF_8));
            this.key = new SecretKeySpec(material, "AES");
        } catch (Exception e) {
            throw new IllegalStateException("Unable to initialise TokenCryptor", e);
        }
    }

    public String encrypt(String plainText) {
        if (plainText == null || plainText.isBlank()) return plainText;
        try {
            byte[] iv = new byte[12];
            secureRandom.nextBytes(iv);

            Cipher cipher = Cipher.getInstance(CIPHER);
            cipher.init(Cipher.ENCRYPT_MODE, key, new GCMParameterSpec(GCM_TAG_BITS, iv));

            byte[] cipherBytes = cipher.doFinal(plainText.getBytes(StandardCharsets.UTF_8));

            ByteBuffer buffer = ByteBuffer.allocate(1 + iv.length + cipherBytes.length);
            buffer.put(CURRENT_VERSION);
            buffer.put(iv);
            buffer.put(cipherBytes);
            return Base64.getEncoder().encodeToString(buffer.array());
        } catch (Exception e) {
            throw new IllegalStateException("Failed to encrypt token", e);
        }
    }

    public String decrypt(String cipherText) {
        if (cipherText == null || cipherText.isBlank()) return cipherText;
        try {
            byte[] raw = Base64.getDecoder().decode(cipherText);
            ByteBuffer buffer = ByteBuffer.wrap(raw);
            byte version = buffer.get();
            if (version != CURRENT_VERSION) {
                throw new IllegalStateException("TokenCryptor version mismatch");
            }

            byte[] iv = new byte[12];
            buffer.get(iv);
            byte[] cipherBytes = new byte[buffer.remaining()];
            buffer.get(cipherBytes);

            Cipher cipher = Cipher.getInstance(CIPHER);
            cipher.init(Cipher.DECRYPT_MODE, key, new GCMParameterSpec(GCM_TAG_BITS, iv));
            byte[] plain = cipher.doFinal(cipherBytes);
            return new String(plain, StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to decrypt token", e);
        }
    }
}
