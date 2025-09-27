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

Grade the following submission based on the rubric below: 
Submission: $submissionText
Rubric: $fetchedRubric

Instructions:

1. Tone options: Formal, Straightforward, Casual. Selected: $tone.
2. Voice options: Supportive, Neutral, Constructive. Selected: $voice.
3. Level of Detail options: Basic, Neutral, Detailed. Selected: $detailLevel.
   - Basic: 1 paragraph per criterion
   - Neutral: 2 paragraphs per criterion
   - Detailed: 3 paragraphs per criterion

**Strict Rules**:
- Generate exactly the number of paragraphs specified by the Level of Detail.
- Combine all paragraphs into the "remark" field as a single JSON string.
- Separate paragraphs with `\\n` inside the JSON string.
- Include examples from the submission in each paragraph to justify the score.
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
