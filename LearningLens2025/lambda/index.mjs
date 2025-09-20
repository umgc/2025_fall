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
    if (command === "getAllLogs") {
      return await getAllLogs(client);
    }
  }
  else if (method === "POST") {
    if (command === "createDb") {
      await buildDatabase(client);
      return "Database created successfully.";
    }
  }
};

  async function buildDatabase(client) {
    try {
    await client`CREATE TABLE IF NOT EXISTS AI_LOGS (
      log_id UUID PRIMARY KEY,
      student_id int,
      assignment_id int,
      course_id int,
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

  async function getAllLogs(client) {
    try {
      return await client`SELECT * FROM AI_LOGS;`;
    }
    catch (error) {
      console.error("Failed to get logs ", error);
      throw error;
    }
  };
