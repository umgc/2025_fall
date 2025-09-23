import { DsqlSigner } from "@aws-sdk/dsql-signer";
import postgres from "postgres"

export const handler = async (event, context) => {
  const signer = new DsqlSigner({
    hostname: process.env.AWS_DB_CLUSTER,
    region: process.env.AWS_REGION,
  });
  let client;
  try {
    // Use `getDbConnectAuthToken` if you are _not_ logging in as the `admin` user
    const token = await signer.getDbConnectAdminAuthToken();

    client = postgres({
      host: process.env.AWS_DB_CLUSTER,
      user: "admin",
      password: token,
      database: "postgres",
      port: 5432,
      idle_timeout: 2,
      ssl: {
        rejectUnauthorized: true,
      }
    });

    } catch (error) {
      console.error("Failed to create connection: ", error);
      throw error;
    }
  const command = event["queryStringParameters"]["command"];
  const method = event["requestContext"]["http"]["method"];
  console.log(command);

  if (method === "GET") {
    if (command === "getLogs") {
      const courseId = parseInt(event["queryStringParameters"]["courseId"]);
      const assignmentId = parseInt(event["queryStringParameters"]["assignmentId"]);
      const studentId = parseInt(event["queryStringParameters"]["studentId"]);
      const lms = parseInt(event["queryStringParameters"]["lmsType"]);
      return await getAllLogs(client, courseId, assignmentId, studentId, lms);
    }
  }
  if (method === "POST") {
    if (command === "createDb") {
      await buildDatabase(client);
      return "Database created successfully.";
    }
    if (command === "addLog") {
      console.log(event);
      await addLog(client, event["body"]);
      return "Added log successfully";
    }
  }
};

  async function buildDatabase(client) {
    try {
    await client`CREATE TABLE IF NOT EXISTS AI_LOGS (
      log_id UUID PRIMARY KEY,
      student_id BIGINT,
      assignment_id BIGINT,
      course_id BIGINT,
      prompt VARCHAR,
      response VARCHAR,
      reflection VARCHAR,
      ai_model SMALLINT,
      lms_service SMALLINT,
      time TIMESTAMP
    );`;
    }
    catch (error) {
      console.error("Failed to create database table: ", error);
      throw error;
    }
};

  async function getAllLogs(client, courseId, assignmentId, studentId, lms) {
    try {
      return await client`SELECT * FROM AI_LOGS WHERE
      course_id = ${courseId} AND
      lms_service = ${lms} AND
      (${assignmentId} = -1 OR assignment_id = ${assignmentId}) AND
      (${studentId} = -1  OR student_id = ${studentId});`;
    }
    catch (error) {
      console.error("Failed to get logs ", error);
      throw error;
    }
  };

    async function addLog(client, body) {
    try {
      let log = JSON.parse(body);
      return await client`
      INSERT INTO AI_LOGS VALUES (
      gen_random_uuid(),
      ${log.studentId},
      ${log.assignmentId},
      ${log.courseId},
      ${log.prompt},
      ${log.response},
      ${log.reflection},
      ${log.model},
      ${log.lms},
      current_timestamp
      );`;
    }
    catch (error) {
      console.error("Failed to add log ", error);
      throw error;
    }
  };
