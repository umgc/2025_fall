import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import pkg from "pg";
dotenv.config({ path: "./.env" });
const { Pool } = pkg;

const app = express();
const port = process.env.PORT || 8000;
app.use(cors()); app.use(express.json());

app.get("/health", (_req, res) => res.json({ status: "ok", time: new Date().toISOString() }));

let pool;
if (process.env.DATABASE_URL) {
  pool = new Pool({ connectionString: process.env.DATABASE_URL });
  app.get("/db-ping", async (_req, res) => {
    try { const r = await pool.query("SELECT 1 as ok"); res.json({ db:"ok", rows:r.rows }); }
    catch (e) { res.status(500).json({ error:String(e) }); }
  });
}
app.listen(port, "0.0.0.0", () => console.log(`API listening on ${port}`));
