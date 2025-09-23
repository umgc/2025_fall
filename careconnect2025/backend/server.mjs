import express from "express";
import basicAuth from "basic-auth";
import cors from "cors";

const app = express();
const PORT = process.env.PORT || 8000;
const HOST = process.env.HOST || "0.0.0.0";

app.use(cors());
app.use(express.json());

// --- super-light RBAC demo ---
const USERS = {
  patient: { pass: "pass", role: "PATIENT" },
  caregiver: { pass: "pass", role: "CAREGIVER" },
};

function auth(req, res, next) {
  const creds = basicAuth(req);
  if (!creds || !USERS[creds.name] || USERS[creds.name].pass !== creds.pass) {
    res.set("WWW-Authenticate", 'Basic realm="CareConnect Demo"');
    return res.status(401).json({ error: "Unauthorized" });
  }
  req.user = { name: creds.name, role: USERS[creds.name].role };
  next();
}

// --- health ---
app.get("/health", (_req, res) => res.json({ status: "ok" }));

// --- auth/me ---
app.get("/auth/me", auth, (req, res) => {
  res.json({ user: req.user });
});

// --- in-memory notes store (demo only) ---
const notes = [];
app.post("/notes", auth, (req, res) => {
  const { text } = req.body || {};
  if (!text) return res.status(400).json({ error: "text required" });
  const note = {
    id: String(notes.length + 1),
    user: req.user.name,
    text,
    created_at: new Date().toISOString(),
  };
  notes.push(note);
  res.status(201).json(note);
});

app.get("/notes", auth, (req, res) => {
  const q = (req.query.q || "").toString().toLowerCase();
  const filtered = q
    ? notes.filter((n) => n.text.toLowerCase().includes(q))
    : notes;
  res.json(filtered);
});

// --- triggers → calendar proposal ---
app.post("/triggers/propose", auth, (req, res) => {
  const { text } = req.body || {};
  if (!text) return res.status(400).json({ error: "text required" });
  const match = /follow[- ]?up|appointment|schedule/i.test(text);
  const proposal = {
    type: "calendar_proposal",
    source: "AI-derived",
    title: match ? "Follow-up from notes" : "Proposed item",
    details: { note: text, proposer: req.user.name },
    aiDerived: true,
    created_at: new Date().toISOString(),
  };
  res.json(proposal);
});

// --- PII sanitize (email, US phone, SSN) ---
function sanitizePII(s) {
  if (!s) return s;
  return s
    .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, "[email]")
    .replace(/(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b/g, "[phone]")
    .replace(/\b\d{3}-\d{2}-\d{4}\b/g, "[ssn]");
}
app.post("/pii/sanitize", auth, (req, res) => {
  const { text } = req.body || {};
  if (typeof text !== "string") return res.status(400).json({ error: "text required" });
  const sanitized = sanitizePII(text);
  res.json({ original: text, sanitized });
});

// --- listen ---
app.listen(PORT, HOST, () => {
  console.log(`CareConnect demo API on http://${HOST}:${PORT}`);
});
