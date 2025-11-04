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
      },
    });

    } catch (error) {
      console.error("Failed to create connection: ", error);
      throw error;
    }
  const command = event["queryStringParameters"]["command"];
  const method = event["requestContext"]["http"]["method"];
  console.log(command);

  if (method === "GET") {
    if (command === "getReflection") {
      const courseId = BigInt(event["queryStringParameters"]["courseId"]);
      const assignmentId = BigInt(event["queryStringParameters"]["assignmentId"]);
      const lms = parseInt(event["queryStringParameters"]["lmsType"]);
      return await getReflectionForAssignment(client, courseId, assignmentId, lms);
    }
    if (command === "getCompletedReflection") {
      const reflectionId = event["queryStringParameters"]["reflectionId"];
      const studentId = BigInt(event["queryStringParameters"]["studentId"]);
      return await getReflectionForSubmission(client, reflectionId, studentId);
    }
  }
  if (method === "POST") {
    if (command === "createDb") {
      await buildDatabase(client);
      return "Database created successfully.";
    }
    if (command === "completeReflection") {
      await completeReflection(client, event["body"]);
      return "Completed reflection successfully.";
    }
    if (command === "createReflection") {
      await createReflection(client, event["body"]);
      return "Added reflection successfully";
    }
  }
};

  async function buildDatabase(client) {
    try {
    await client`CREATE TABLE IF NOT EXISTS REFLECTIONS (
      reflection_id UUID PRIMARY KEY,
      course_id BIGINT,
      assignment_id BIGINT,
      question VARCHAR,
      date TIMESTAMP,
      lms_service SMALLINT
    );`;
    await client`CREATE TABLE IF NOT EXISTS REFLECTION_RESPONSES (
      response_id UUID PRIMARY KEY,
      student_id BIGINT,
      response VARCHAR,
      date TIMESTAMP,
      reflection UUID
    );`
    }
    catch (error) {
      console.error("Failed to create database table: ", error);
      throw error;
    }
};

  async function getReflectionForAssignment(client, courseId, assignmentId, lms) {
    try {
      return await client`SELECT reflection_id, question FROM REFLECTIONS WHERE
      course_id = ${courseId} AND
      assignment_id = ${assignmentId} AND
      lms_service = ${lms};`;
    }
    catch (error) {
      console.error("Failed to get reflections for assignment ", error);
      throw error;
    }
  };

    async function getReflectionForSubmission(client, reflectionId, studentId) {
    try {
      return await client`SELECT response_id, response, reflection FROM REFLECTION_RESPONSES WHERE
      reflection = ${reflectionId} AND
      student_id = ${studentId};`;
    }
    catch (error) {
      console.error("Failed to get reflection for assignment ", error);
      throw error;
    }
  };

    async function createReflection(client, body) {
    try {
      let log = JSON.parse(body);
      return await client`
      INSERT INTO REFLECTIONS (
        reflection_id,
        course_id,
        assignment_id,
        question,
        date,
        lms_service
      ) VALUES (
        gen_random_uuid(),
        ${log.courseId},
        ${log.assignmentId},
        ${log.question},
        current_timestamp AT TIME ZONE 'UTC',
        ${log.lmsType}
      );`;
    }
    catch (error) {
      console.error("Failed to add reflection ", error);
      throw error;
    }
  };

  async function completeReflection(client, body) {
    try {
      let log = JSON.parse(body);
      return await client`
      INSERT INTO REFLECTION_RESPONSES (
        response_id,
        student_id,
        response,
        date,
        reflection
      ) VALUES (
        gen_random_uuid(),
        ${log.studentId},
        ${log.response},
        current_timestamp AT TIME ZONE 'UTC',
        ${log.reflectionId}
      );`;
    }
    catch (error) {
      console.error("Failed to update reflection ", error);
      throw error;
    }
  };
