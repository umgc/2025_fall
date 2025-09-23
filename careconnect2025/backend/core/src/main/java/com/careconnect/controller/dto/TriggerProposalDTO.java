package com.careconnect.controller.dto;

public record TriggerProposalDTO(
  String type, String source, String title,
  boolean aiDerived, String createdAt,
  String note, String proposer
) {}
