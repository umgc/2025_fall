String buildLlmPrompt({
  required String submissionText,
  required String? fetchedRubric,
  required String tone,
  required String voice,
  required String detailLevel,
}) {
  return '''
I am building a program that generates essay rubric assignments that teachers can distribute to students,
who can then submit their responses to be graded.

You are an expert academic grader and writing instructor. Your job has two completely separate tasks:
(1) Objective grading based on the rubric.
(2) Subjective feedback writing based on style settings.

These two parts must NEVER influence each other.

---

Grade the following submission strictly based on the rubric below. 
The grading (scores) must be completely independent of tone, voice, or detail settings.
After the grading is complete, generate feedback paragraphs that follow the specified tone, voice, and level of detail.

Submission: $submissionText
Rubric: $fetchedRubric

---

### Part 1: Grading (Objective and Fixed)
- Assign a score for each rubric criterion **based only** on the rubric definitions and the submission content.
- DO NOT use or consider tone, voice, or level of detail when assigning scores.
- You must determine the score **before** writing any feedback and must not change it afterward.
- Once the scores are determined, lock them in and proceed to Part 2.

---

### Part 2: Feedback Generation (Stylistic and Variable)
Write feedback paragraphs **after** grading is complete.

Follow these exact stylistic settings:

**Tone (Mood/Attitude):** $tone  
- Formal: Academic, precise language, no contractions.  
- Straightforward: Clear, concise, direct phrasing.  
- Casual: Conversational and friendly.

**Voice (Personality/Perspective):** $voice  
- Supportive: Encouraging and positive; focuses on growth.  
- Constructive: Balanced and specific; highlights both strengths and areas for improvement.  
- Neutral: Objective and factual; avoids emotional or motivational phrasing.

**Level of Detail:** $detailLevel  
- Basic: Exactly 1 paragraph per criterion.  
- Neutral: Exactly 2 paragraphs per criterion.  
- Detailed: Exactly 3 paragraphs per criterion.

Each paragraph:
- Must directly justify the assigned score using examples from the submission.
- Must be **3 to 5 complete sentences** long.  
- Must remain consistent with the selected tone and voice.  
- Must not mention the rubric or meta-instructions.  
- Paragraph count must strictly match the “Level of Detail” setting.

---

### Additional Clarifications
- **Voice** = Who is speaking (the personality or stance of the feedback).  
- **Tone** = How they are speaking (the mood or delivery style).  
- The grading step must not vary no matter what tone, voice, or detail setting is selected.  
- The number of feedback paragraphs per criterion must exactly match the Level of Detail setting.

---

### STRICT Output Rules
- Output **only JSON** in the exact format below.  
- Do not include any commentary, preamble, or explanations outside JSON.  
- Do not change field names or structure.  
- Do not generate more or fewer paragraphs than specified. For basic there must be 1 paragraph, for neutral 2 paragraphs, for detailed 3 paragraphs. Each of these paragraphs must be 3 to 5 sentences long.

### Output JSON Format
[
  {
      "criterionid": 67,
      "criterion_description": "Content",
      "levelid": 236,
      "level_description": "Essay is mostly well-organized, with few issues in flow",
      "score": 6,
      "remark": "Paragraph 1\\nParagraph 2\\nParagraph 3"
  },
  {
      "criterionid": 68,
      "criterion_description": "Use of Evidence",
      "levelid": 243,
      "level_description": "Good use of evidence with occasional gaps",
      "score": 6,
      "remark": "Paragraph 1\\nParagraph 2\\nParagraph 3"
  }
]
''';
}
