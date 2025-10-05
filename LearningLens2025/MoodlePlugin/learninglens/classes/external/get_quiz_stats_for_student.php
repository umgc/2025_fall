<?php
namespace local_learninglens\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use external_function_parameters;
use external_single_structure;
use external_multiple_structure;
use external_value;
use external_api;

class get_quiz_stats_for_student extends external_api {

    /**
     * Define parameter structure for the function.
     */
    public static function execute_parameters() {
        return new external_function_parameters([
            'quizid' => new external_value(PARAM_INT, 'ID of the quiz'),
            'userid' => new external_value(PARAM_INT, 'ID of the student'),
        ]);
    }

    /**
     * Main execution function. This is what gets called by the web service.
     */
    public static function execute($quizid, $userid) {
        // Validate incoming parameters.
        $params = self::validate_parameters(self::execute_parameters(), [
            'quizid' => $quizid,
            'userid' => $userid
        ]);

        // *Optional*: permission checks (capabilities, context, etc.)

        // Actually fetch data.
        $records = self::get_quiz_stats_for_student($params['quizid'], $params['userid']);

        // Return the array of data.
        return $records;
    }

    /**
     * The real logic. Query for questions (similar to your existing logic)
     * but also compute correct/incorrect stats or any other analytics.
     */
    private static function get_quiz_stats_for_student($quizid, $userid) {
        global $DB;
    
        // 1) Gather the questions (same as before)
        $sql_questions = "
            SELECT q.id,
                   q.name,
                   q.questiontext,
                   q.qtype
              FROM {question} q
             WHERE q.id IN (
                SELECT qbe.id
                  FROM {question_bank_entries} qbe
                 WHERE qbe.questioncategoryid = (
                    SELECT qc.id
                      FROM {question_categories} qc
                     WHERE (
                         SELECT quiz.intro
                           FROM {quiz} quiz
                          WHERE quiz.id = :quizid
                     ) LIKE CONCAT('%', qc.name, '%')
                     LIMIT 1
                 )
             )
        ";
    
        $questions = $DB->get_records_sql($sql_questions, ['quizid' => $quizid]);
        if (!$questions) {
            return [];
        }
    
        // 2) Gather attempt stats by looking for 'gradedright', 'gradedwrong', 'gradedpartial'
        //    instead of 'complete' or fraction-based checks
        $sql_stats = "
            SELECT
                qa.questionid,
                quiza.userid,
                qs.state,
                qa.rightanswer,
                qa.responsesummary
              FROM {quiz_attempts} quiza
              JOIN {question_usages} qu ON qu.id = quiza.uniqueid
              JOIN {question_attempts} qa ON qa.questionusageid = qu.id
              JOIN {question_attempt_steps} qs ON qs.questionattemptid = qa.id
                   AND qs.sequencenumber = (
                       SELECT MAX(qs2.sequencenumber)
                         FROM {question_attempt_steps} qs2
                        WHERE qs2.questionattemptid = qa.id
                   )
             WHERE quiza.quiz = :quizid2 AND quiza.userid = :userid
        ";
    
        $statsrecords = $DB->get_records_sql($sql_stats, ['quizid2' => $quizid, 'userid' => $userid]);
    
        // 3) Merge stats with the question array
        $results = [];
        foreach ($questions as $q) {
            $qid = $q->id;
    
            // Default empty
            $state   = '';
            $right = '';
            $answer = '';
    
            if (isset($statsrecords[$qid])) {
                $record    = $statsrecords[$qid];
                $state     = $record->state;
                $right     = $record->rightanswer;
                $answer    = $record->responsesummary;
            }
    
            $results[] = [
                'id'           => $qid,
                'name'         => $q->name,
                'questiontext' => $q->questiontext,
                'qtype'        => $q->qtype,
                'qstate'       => $state,
                'qright'       => $right,
                'qanswer'      => $answer,
            ];
        }
    
        return $results;
    }
    

    /**
     * Define the return structure.
     */
    public static function execute_returns() {
        return new external_multiple_structure(
            new external_single_structure([
                'id'            => new external_value(PARAM_INT, 'Question ID'),
                'name'          => new external_value(PARAM_TEXT, 'Question name'),
                'questiontext'  => new external_value(PARAM_RAW, 'Question text'),
                'qtype'         => new external_value(PARAM_ALPHANUMEXT, 'Question type'),
                'qstate'        => new external_value(PARAM_TEXT, 'Question attempt state'),
                'qright'       => new external_value(PARAM_RAW, 'Correct answer text'),
                'qanswer'       => new external_value(PARAM_RAW, 'Selected answer text'),
            ])
        );
    }
    
}
