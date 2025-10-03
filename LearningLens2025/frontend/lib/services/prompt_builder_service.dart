String buildLlmPrompt({
  required String submissionText,
  required String? fetchedRubric,
  required String tone,
  required String voice,
  required String detailLevel,
}) {
  return '''
I am building a program that generates essay rubric assignments that teachers can distribute to students
who can then submit their responses to be graded.

Grade the following submission strictly based on the rubric below, and then generate feedback. 
The grading (scores) must be independent of tone/voice/detail settings, but feedback paragraphs
must respect those options.

Submission: $submissionText
Rubric: $fetchedRubric

Instructions:

**Part 1: Grading**
- Assign a score for each rubric criterion based only on the submission and rubric.
- Do not let tone, voice, or level of detail affect the score.

**Part 2: Feedback**
- After grading, generate feedback remarks according to the following options:
  - Tone: $tone (Formal, Straightforward, Casual)
  - Voice: $voice (Supportive, Neutral, Constructive)
  - Level of Detail: $detailLevel
    * Basic: 1 paragraph per criterion
    * Neutral: 2 paragraphs per criterion
    * Detailed: 3 paragraphs per criterion
- Feedback paragraphs must include examples from the submission to justify the score.
- Combine all paragraphs into the "remark" field as a single JSON string.
- Separate paragraphs with `\\n` inside the JSON string.

**Strict Rules**:
- Only output JSON in the format below.
- Do not include any text outside JSON.
- Do not generate more or fewer paragraphs than specified.

Output JSON format:

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
