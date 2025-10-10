package com.careconnect.model;

import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class CheckInQuestionId implements Serializable {
    private Long checkInId;
    private Long questionId;

    public CheckInQuestionId() {}
    public CheckInQuestionId(Long checkInId, Long questionId) {
        this.checkInId = checkInId;
        this.questionId = questionId;
    }

    public Long getCheckInId() { return checkInId; }
    public Long getQuestionId() { return questionId; }
    public void setCheckInId(Long checkInId) { this.checkInId = checkInId; }
    public void setQuestionId(Long questionId) { this.questionId = questionId; }

    @Override public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof CheckInQuestionId that)) return false;
        return Objects.equals(checkInId, that.checkInId) &&
               Objects.equals(questionId, that.questionId);
    }
    @Override public int hashCode() { return Objects.hash(checkInId, questionId); }
}
