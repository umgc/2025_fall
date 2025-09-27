String buildLlmPrompt({
  required String submissionText,
  required String? fetchedRubric,
}) {
  return '''
I am building a program that generates essay rubric assignments that teachers can distribute to students
who can then submit their responses to be graded. Here is an example format of a rubric roughly:
[
    {
        "id": 82,
        "rubric_criteria": [
            {
                "id": 52,
                "description": "Content",
                "levels": [
                    {
                        "id": 157,
                        "score": 1,
                        "definition": "Poor"
                    },
                    {
                        "id": 156,
                        "score": 3,
                        "definition": "Good"
                    },
                    {
                        "id": 155,
                        "score": 5,
                        "definition": "Excellent"
                    }
                ]
            },
            {
                "id": 53,
                "description": "Clarity",
                "levels": [
                    {
                        "id": 160,
                        "score": 1,
                        "definition": "Unclear"
                    },
                    {
                        "id": 159,
                        "score": 3,
                        "definition": "Somewhat Clear"
                    },
                    {
                        "id": 158,
                        "score": 5,
                        "definition": "Very Clear"
                    }
                ]
            }
        ]
    }
]

I have the following generated essay rubric:
Rubric: $fetchedRubric

Grade the following submission based on that rubric: 
Submission: $submissionText 

You must reply with a representation of the rubric in JSON format that matches this example format, 
obviously put your generated scores in and be specific with the remarks on the scoring and give specific examples from the 
submitted assignment that were either good or bad depending on the score given. Also cut out anything that is not
the json response. No extraneous comments outside that: 
[
  {
      "criterionid": 67,
      "criterion_description": "Content",
      "levelid": 236,
      "level_description": "Essay is mostly well-organized, with few issues in flow",
      "score": 6,
      "remark": "The essay has a clear structure and transitions between paragraphs. Each paragraph focuses on a different aspect of having a park, such as relaxation, activity, and aesthetics. However, there are a few places where the flow could be improved, like the transition between the third and fourth paragraphs."
  },
  {
      "criterionid": 68,
      "criterion_description": "Use of Evidence",
      "levelid": 243,
      "level_description": "Good use of evidence with occasional gaps",
      "score": 6,
      "remark": "The essay uses good evidence to support its claims, such as 'Spending time outside can make us feel happier and less anxious, which would help us do better in class.' However, there are occasional gaps where more specific or detailed evidence could strengthen the arguments further."
  }
]
''';
}
