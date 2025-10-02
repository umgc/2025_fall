import { DsqlSigner } from "@aws-sdk/dsql-signer";
import postgres from "postgres";

/**
 * Retrieves the results of code evaluations for a course
 * @param {postgres.Sql} client 
 * @param {object} event 
 * @param {object} context 
 */
async function handleGET(client, event, context){
    const courseId = event.queryStringParameters?.courseId
    if(!courseId){
        return {
            statusCode: 400,
            body: 'Missing courseId',
        }
    }

    return await client`
        SELECT * FROM code_evaluation
        WHERE course_id = ${courseId};
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
            ${body.assignmentId},
            ${body.courseId},
            'JOB STARTED'
        )
        ON CONFLICT (assignment_id, course_id) DO UPDATE
        SET status = EXCLUDED.status,
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
    const signer = new DsqlSigner({
        hostname: 'avtgqkrvpgwur5hk6x5lruqjim.dsql.us-east-1.on.aws',
        region: 'us-east-1',
    })

    const token = await signer.getDbConnectAdminAuthToken()

    const client = postgres({
      host: 'avtgqkrvpgwur5hk6x5lruqjim.dsql.us-east-1.on.aws',
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
