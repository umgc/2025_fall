package com.careconnect.demo.dto;

public record UserInfo(String name, String[] roles) {}
public record Note(String id, String user, String text, String createdAt) {}
public record TriggerProposal(String type, String source, String title, boolean aiDerived, String createdAt, String note, String proposer) {}
public record TextBody(String text) {}
