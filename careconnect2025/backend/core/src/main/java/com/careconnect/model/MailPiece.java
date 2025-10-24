package com.careconnect.model;

public record MailPiece(
        String id,
        String sender,
        String summary,
        String imageDataUrl,
        String dateIso,
        ActionLinks actions
) {}