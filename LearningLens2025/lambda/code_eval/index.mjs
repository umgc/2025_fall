import { DsqlSigner } from "@aws-sdk/dsql-signer";
import postgres from "postgres";

/**
 * Retrieves the results of code evaluations for a course
 * @param {postgres.Sql} client 
 * @param {object} event 
 * @param {object} context 
 */
async function handleGET(client, event, context){
    const cmd = event.queryStringParameters?.command
    if(cmd && cmd == 'createDb'){
        return await client`CREATE TABLE IF NOT EXISTS code_evaluation (
            course_id varchar NOT NULL,
            assignment_id varchar NOT NULL,
            expected_output varchar NOT NULL,
            username varchar NOT NULL,
            status varchar NOT NULL,
            results_json text,
            start_time timestamptz NOT NULL DEFAULT now(),
            finish_time timestamptz,
            primary key (course_id, assignment_id, username)
        );`
    }

    const username = event.queryStringParameters?.username
    if(!username){
        return {
            statusCode: 400,
            body: 'Missing username',
        }
    }

    return await client`
        SELECT * FROM code_evaluation
        WHERE username = ${username};
    `
}

/**
 * Starts a code evaluation
 * @param {postgres.Sql} client 
 * @param {object} event 
 * @param {object} context 
 */
async function handlePOST(client, event, context){
    const body = JSON.parse(event.body)
    
    if(!body.assignmentId || !body.courseId){
        return {
            statusCode: 400,
            body: 'Missing assignmentId, courseId, or both',
        }
    }

    /**
     * Query will basically reset columns for results and start/finish times
     * if an insert is done for the same assignment twice. 
     * Inserts for the same assignment may happen when a
     * teacher wants to reassess an existing assignment.
     */
    await client`
        INSERT INTO code_evaluation VALUES (
            ${body.courseId},
            ${body.assignmentId},
            ${body.expectedOutput},
            ${body.username},
            'JOB STARTED'
        )
        ON CONFLICT (assignment_id, course_id, username) DO UPDATE
        SET status = EXCLUDED.status,
            expected_output = EXCLUDED.expected_output,
            results_json = NULL,
            start_time = now(),
            finish_time = NULL;
    `

    return {
        statusCode: 200,
        body: 'Success',
    }
}

export const handler = async (event, context) => {
    const hostname = '2bthdlvyqq5d5zl2bxxmm6r25m.dsql.us-east-1.on.aws'
    const signer = new DsqlSigner({
        hostname: hostname,
        region: 'us-east-1',
    })

    const token = await signer.getDbConnectAdminAuthToken()

    const client = postgres({
      host: hostname,
      user: "admin",
      password: token,
      database: "postgres",
      port: 5432,
      idle_timeout: 2,
      ssl: {
        rejectUnauthorized: true,
      },
    })

    const method = event["requestContext"]["http"]["method"];

    if(method === 'POST'){
        return await handlePOST(client, event, context)
    }

    if(method === 'GET'){
        return await handleGET(client, event, context)
    }
};
