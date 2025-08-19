package com.focused_ai.DTOs;

public class QuestionStatsDto {
    public int id;
    public String questionType;
    public String questionText;
    public int numCorrect;
    public int numIncorrect;
    public int numPartial;
    public int totalAttempts;

    public QuestionStatsDto(int id, String questionType, String questionText,
                             int numCorrect, int numIncorrect, int numPartial, int totalAttempts) {
        this.id = id;
        this.questionType = questionType;
        this.questionText = questionText;
        this.numCorrect = numCorrect;
        this.numIncorrect = numIncorrect;
        this.numPartial = numPartial;
        this.totalAttempts = totalAttempts;
    }
}
