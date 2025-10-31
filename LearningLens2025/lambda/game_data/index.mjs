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
    if (command === "getForStudent") {
      const assignedTo = BigInt(event["queryStringParameters"]["assignedTo"]);
      return await getGamesForStudent(client, assignedTo);
    }
    if (command === "getForTeacher") {
      const createdBy = BigInt(event["queryStringParameters"]["createdBy"]);
      return await getGamesForTeacher(client, createdBy);
    }
  }
  if (method === "POST") {
    if (command === "createDb") {
      await buildDatabase(client);
      return "Database created successfully.";
    }
    if (command === "completeGame") {
      await completeGame(client, event["body"]);
      return "Completed game successfully.";
    }
    if (command === "createGame") {
      await createGame(client, event["body"]);
      return "Added game successfully";
    }
  }
  if (method === "DELETE") {
    await deleteGame(client, event["body"]);
    return "Database created successfully.";
  }
};

  async function buildDatabase(client) {
    try {
    await client`CREATE TABLE IF NOT EXISTS GAMES (
      game_id UUID PRIMARY KEY,
      course_id BIGINT,
      student_id BIGINT,
      title VARCHAR,
      data VARCHAR,
      game_type SMALLINT,
      score NUMERIC(5,2),
      raw_correct SMALLINT,
      max_score SMALLINT,
      assigned_by BIGINT,
      assigned_date TIMESTAMP
    );`;
    try {
      await client`ALTER TABLE GAMES ALTER COLUMN score TYPE NUMERIC(5,2);`;
      await client`ALTER TABLE GAMES ADD COLUMN IF NOT EXISTS raw_correct SMALLINT;`;
      await client`ALTER TABLE GAMES ADD COLUMN IF NOT EXISTS max_score SMALLINT;`;
    } catch (alterError) {
      console.warn("Skipping score column alter: ", alterError);
    }
    }
    catch (error) {
      console.error("Failed to create database table: ", error);
      throw error;
    }
};

  async function deleteGame(client, body) {
    try {
      let log = JSON.parse(body);
      await client`DELETE FROM GAMES WHERE game_id = ${log.gameId};`;
    }
    catch (error) {
      console.error("Failed to delete game: ", error);
      throw error;
    }
};

  async function getGamesForStudent(client, studentId) {
    try {
      return await client`SELECT game_id, course_id, student_id, title, data, game_type, score, raw_correct, max_score, assigned_by, assigned_date FROM GAMES WHERE
      student_id = ${studentId};`;
    }
    catch (error) {
      console.error("Failed to get games for student ", error);
      throw error;
    }
  };

    async function getGamesForTeacher(client, assignedBy) {
    try {
      return await client`SELECT game_id, course_id, student_id, title, data, game_type, score, raw_correct, max_score, assigned_by, assigned_date FROM GAMES WHERE
      assigned_by = ${assignedBy};`;
    }
    catch (error) {
      console.error("Failed to get games for teacher ", error);
      throw error;
    }
  };

    async function createGame(client, body) {
    try {
      let log = JSON.parse(body);
      return await client`
      INSERT INTO GAMES (
        game_id,
        course_id,
        student_id,
        title,
        data,
        game_type,
        score,
        raw_correct,
        max_score,
        assigned_by,
        assigned_date
      ) VALUES (
        gen_random_uuid(),
        ${log.courseId},
        ${log.studentId},
        ${log.title},
        ${log.data},
        ${log.gameType},
        NULL,
        NULL,
        NULL,
        ${log.assignedBy},
        ${log.assignedDate}
      );`;
    }
    catch (error) {
      console.error("Failed to add game ", error);
      throw error;
    }
  };

      async function completeGame(client, body) {
    try {
      let log = JSON.parse(body);
      let rawScore = Number(log.score);
      if (!Number.isFinite(rawScore)) {
        rawScore = 0;
      }
      const normalizedScore = Math.max(
        0,
        Math.min(rawScore > 1 ? rawScore / 100 : rawScore, 1)
      );

      let rawCorrect = Number.isFinite(Number(log.rawCorrect))
        ? Number(log.rawCorrect)
        : null;
      if (rawCorrect !== null) {
        rawCorrect = Math.max(0, Math.round(rawCorrect));
      }
      let maxScore = Number.isFinite(Number(log.maxScore))
        ? Number(log.maxScore)
        : null;
      if (maxScore !== null) {
        maxScore = Math.max(0, Math.round(maxScore));
      }
      return await client`
      UPDATE GAMES
      SET score = ${normalizedScore},
          raw_correct = ${rawCorrect},
          max_score = ${maxScore}
      WHERE game_id = ${log.gameId};`;
    }
    catch (error) {
      console.error("Failed to update score ", error);
      throw error;
    }
  };
