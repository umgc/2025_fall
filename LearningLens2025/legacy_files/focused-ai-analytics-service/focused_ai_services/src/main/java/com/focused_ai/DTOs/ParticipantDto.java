package com.focused_ai.DTOs;

public class ParticipantDto {
    public int id;
    public String fullname;
    public Double avgGrade;

    public ParticipantDto(int id, String fullname, Double avgGrade) {
        this.id = id;
        this.fullname = fullname;
        this.avgGrade = avgGrade;
    }
}
