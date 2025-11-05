// com.careconnect.model.Question
package com.careconnect.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.Set;

@Entity
@Table(name = "questions")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Question {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, columnDefinition = "text")
    private String prompt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private QuestionType type;  // TEXT | YES_NO | TRUE_FALSE | NUMBER

    @Column(nullable = false)
    private boolean required = false;

    @Column(nullable = false)
    private boolean active = true;

    @Column(nullable = false)
    private int ordinal = 0;

    @OneToMany(mappedBy = "question", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<CheckInQuestion> usedInCheckIns;
}
