import { DescribeTaskDefinitionCommand, ECSClient, RunTaskCommand } from "@aws-sdk/client-ecs";
import { PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { DsqlSigner } from "@aws-sdk/dsql-signer";
import postgres from "postgres";
import { createSubmissionsZip } from './moodle.js';

/**
 * Starts the ECS task to evaluate student submissions
 * @param {string} s3Uri s3Uri S3 URI for zip file containing student submissions
 * @param {string|number} assignmentId 
 * @param {string|number} courseId 
 * @returns 
 */
async function startECSTask(s3Uri, assignmentId, courseId){
    const ecsClient = new ECSClient({ region: process.env.AWS_REGION });
    const subnets = process.env.SUBNET_IDS.split(",");
    const securityGroups = process.env.SECURITY_GROUP_IDS.split(",");

    try {
        // Grab the task definition info to get the latest container name
        const taskDefName = process.env.ECS_TASK_NAME
        const taskDefCmd = new DescribeTaskDefinitionCommand({
            taskDefinition: taskDefName,
        });
        const taskDefResponse = await ecsClient.send(taskDefCmd);

        console.log('taskDefResponse', taskDefResponse)

        const { taskDefinition } = taskDefResponse
        // Latest container definition
        const container = taskDefinition.containerDefinitions[0];
        
        console.log(taskDefResponse.taskDefinition.containerDefinitions)
        const functionName = process.env.AWS_LAMBDA_FUNCTION_NAME;

        const command = new RunTaskCommand({
            cluster: process.env.ECS_CLUSTER_ARN, // ECS cluster name or ARN
            taskDefinition: taskDefinition.taskDefinitionArn, // family:revision or ARN
            launchType: "FARGATE", // or "EC2"
            networkConfiguration: {
                awsvpcConfiguration: {
                    subnets: subnets,
                    securityGroups: securityGroups,
                    assignPublicIp: "ENABLED",
                },
            },
            overrides: {
                containerOverrides: [
                    {
                        name: container.name, // must match container name in task definition
                        environment: [
                            { name: "CODE_S3_URI", value: s3Uri },
                            { name: "LAMBDA_NAME", value: functionName },
                            { name: "ASSIGNMENT_ID", value: assignmentId.toString() },
                            { name: "COURSE_ID", value: courseId.toString() },
                        ],
                    },
                ],
            },
        });

        const response = await ecsClient.send(command);
        console.log("Task started:", response.tasks);
        return response;
    }
    catch (err) {
        console.error("Error running ECS task:", err);
        throw err;
    }
}

async function startEvaluation(body){
    const { assignmentId, courseId, expectedOutput } = body
    const zipFile = await createSubmissionsZip(assignmentId)
    const s3Client = new S3Client({ region: "us-east-1" });
    console.log('uploading to S3')
    const key = `${courseId}/${assignmentId}/submissions.zip`;
    
    const bucket = process.env.S3_BUCKET;
    await s3Client.send(
        new PutObjectCommand({
            Bucket: bucket,
            Key: key,
            Body: zipFile,
            ContentType: "application/zip",
        })
    );

    return await startECSTask(`s3://${bucket}/${key}`, assignmentId, courseId)
}

async function storeEvaluationResults(client, courseId, assignmentId, evaluation){
    await client`
        UPDATE code_evaluation 
        SET status = 'JOB FINISHED', finish_time = now(),
            results_json = ${JSON.stringify(evaluation)}
        WHERE course_id = ${courseId}
        AND assignment_id = ${assignmentId};
    `
}

/**
 * Retrieves the results of code evaluations for a course
 * @param {postgres.Sql} client 
 * @param {object} event 
 * @param {object} context 
 */
async function handleGET(client, event, context){
    const cmd = event.queryStringParameters?.command
    if(cmd){
        switch(cmd){
            case 'createDb':
                return await client`CREATE TABLE IF NOT EXISTS code_evaluation (
                    course_id varchar NOT NULL,
                    assignment_id varchar NOT NULL,
                    expected_output varchar NOT NULL,
                    language varchar NOT NULL,
                    username varchar NOT NULL,
                    status varchar NOT NULL,
                    results_json text,
                    start_time timestamptz NOT NULL DEFAULT now(),
                    finish_time timestamptz,
                    primary key (course_id, assignment_id, username)
                );`
            case 'start':
                const body = JSON.parse(event.body)
                const taskDef = await startEvaluation(body)
                
                return {
                    statusCode: 200,
                    body: JSON.stringify(taskDef)
                }
        }
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
            ${body.language},
            ${body.username},
            'JOB STARTED'
        )
        ON CONFLICT (assignment_id, course_id, username) DO UPDATE
        SET status = EXCLUDED.status,
            expected_output = EXCLUDED.expected_output,
            language = EXCLUDED.language,
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
    const hostname = process.env.AWS_DB_CLUSTER
    const signer = new DsqlSigner({
        hostname: hostname,
        region: process.env.AWS_REGION,
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

    // evalution key being present signifies payload from ECS container
    if(event.evaluation){
        await storeEvaluationResults(client, event.courseId, event.assignmentId, event.evaluation)
        return {
            statusCode: 200,
            body: 'Success'
        }
    }

    const method = event["requestContext"]["http"]["method"];

    if(method === 'POST'){
        return await handlePOST(client, event, context)
    }

    if(method === 'GET'){
        return await handleGET(client, event, context)
    }
};
