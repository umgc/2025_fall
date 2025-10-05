// com.careconnect.model.Question
package com.careconnect.model;

import jakarta.persistence.*;
import lombok.*;

@Entity @Table(name = "questions")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Question {
  @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(nullable = false, columnDefinition = "text")
  private String prompt;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 32)
  private QuestionType type; // TEXT | YES_NO | TRUE_FALSE | NUMBER

  @Builder.Default
  @Column(nullable = false)
  private boolean required = false;

  @Builder.Default
  @Column(nullable = false)
  private boolean active = true;

  @Builder.Default
  @Column(nullable = false)
  private int ordinal = 0;
}
