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
      const lms = parseInt(event["queryStringParameters"]["lmsType"]);
      return await getGamesForStudent(client, assignedTo, lms);
    }
    if (command === "getForTeacher") {
      const createdBy = BigInt(event["queryStringParameters"]["createdBy"]);
      const lms = parseInt(event["queryStringParameters"]["lmsType"]);
      return await getGamesForTeacher(client, createdBy, lms);
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
      return createGame(client, event["body"]);
    }
    if (command === "assignGame") {
      await assignGame(client, event["body"]);
      return "Assigned game successfully";
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
      title VARCHAR,
      data VARCHAR,
      game_type SMALLINT,
      assigned_by BIGINT,
      assigned_date TIMESTAMP,
      lms_service SMALLINT
    );`;
    await client`CREATE TABLE IF NOT EXISTS GAME_SCORES (
      score_id UUID PRIMARY KEY,
      student_id BIGINT,
      score NUMERIC(5,2),
      raw_correct SMALLINT,
      max_score SMALLINT,
      game UUID
    );`;
    }
    catch (error) {
      console.error("Failed to create database table: ", error);
      throw error;
    }
};

  async function deleteGame(client, body) {
    try {
      let log = JSON.parse(body);
      await client`DELETE FROM GAME_SCORES WHERE game = ${log.gameId};`;
      await client`DELETE FROM GAMES WHERE game_id = ${log.gameId};`;
    }
    catch (error) {
      console.error("Failed to delete game: ", error);
      throw error;
    }
};

  async function getGamesForStudent(client, studentId, lms) {
    try {
      return await client`SELECT game_id, course_id, student_id, title, data, game_type, score, raw_correct, max_score, assigned_by, lms_service, assigned_date FROM GAMES INNER JOIN GAME_SCORES ON game = game_id WHERE
      student_id = ${studentId}
      AND lms_service = ${lms};`;
    }
    catch (error) {
      console.error("Failed to get games for student ", error);
      throw error;
    }
  };

    async function getGamesForTeacher(client, assignedBy, lms) {
    try {
      return await client`SELECT game_id, course_id, student_id, title, data, game_type, score, raw_correct, max_score, assigned_by, assigned_date FROM GAMES INNER JOIN GAME_SCORES ON game = game_id WHERE
      assigned_by = ${assignedBy}
      AND lms_service = ${lms};`;
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
        title,
        data,
        game_type,
        assigned_by,
        assigned_date,
        lms_service
      ) VALUES (
        gen_random_uuid(),
        ${log.courseId},
        ${log.title},
        ${log.data},
        ${log.gameType},
        ${log.assignedBy},
        ${log.assignedDate},
        ${log.lmsType}
      ) RETURNING game_id;`;
    }
    catch (error) {
      console.error("Failed to add game ", error);
      throw error;
    }
  };

  async function assignGame(client, body) {
    try {
      let log = JSON.parse(body);
      return await client`
      INSERT INTO GAME_SCORES (
        score_id,
        student_id,
        score,
        raw_correct,
        max_score,
        game
      ) VALUES (
        gen_random_uuid(),
        ${log.studentId},
        NULL,
        NULL,
        NULL,
        ${log.game}
      );`;
    }
    catch (error) {
      console.error("Failed to add game score ", error);
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
      UPDATE GAME_SCORES
      SET score = ${normalizedScore},
          raw_correct = ${rawCorrect},
          max_score = ${maxScore}
      WHERE game = ${log.gameId} AND student_id = ${log.studentId};`;
    }
    catch (error) {
      console.error("Failed to update score ", error);
      throw error;
    }
  };
