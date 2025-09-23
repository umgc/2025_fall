import express from "express";
import cors from "cors";
import dotenv from "dotenv";
dotenv.config();

const app = express();
app.use(cors()); app.use(express.json());
const PORT = process.env.PORT || 8000;

const users = new Map([["patient","PATIENT"],["caregiver","CAREGIVER"],["admin","ADMIN"]]);
const requireAuth = (req,res,next)=>{
  const auth = req.headers.authorization||"";
  const [type, cred] = auth.split(" ");
  if(type!=="Basic"||!cred) return res.status(401).json({error:"unauthorized"});
  const [user,] = Buffer.from(cred,"base64").toString().split(":");
  if(!users.has(user)) return res.status(401).json({error:"unauthorized"});
  req.user = {name:user, role:users.get(user)};
  next();
};
const requireRole = (...roles)=> (req,res,next)=>{
  if(!req.user || !roles.includes(req.user.role)) return res.status(403).json({error:"forbidden"});
  next();
};

app.post("/auth/register",(req,res)=> res.json({ok:true}));
app.post("/auth/login",(req,res)=> res.json({ok:true, hint:"send Authorization: Basic base64(user:pass) and call /auth/me"}));
app.get("/auth/me", requireAuth, (req,res)=> res.json(req.user));
app.get("/notes", requireAuth, requireRole("PATIENT","CAREGIVER","ADMIN"), (_req,res)=> res.json([{id:1,text:"Example note"}]));
app.get("/health", (_req,res)=> res.json({status:"ok"}));

app.listen(PORT

git add careconnect2025/backend
git commit -m "feat(auth+rbac): Basic auth endpoints + role-gated sample — closes #224"
git push

cat > careconnect2025/backend/src/main/java/com/careconnect/controller/PiiController.java <<'JAVA'
package com.careconnect.controller;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/pii")
public class PiiController {

  @PostMapping("/sanitize")
  @PreAuthorize("hasAnyRole('PATIENT','CAREGIVER','ADMIN')")
  public Map<String,String> sanitize(@RequestBody Map<String,String> body){
    String text = body.getOrDefault("text","");
    String masked = text
      .replaceAll("(?i)[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", "•••@•••.••")
      .replaceAll("\\b(?:\\+?1[-.\\s]?)?(?:\\(\\d{3}\\)|\\d{3})[-.\\s]?\\d{3}[-.\\s]?\\d{4}\\b","(***) ***-****")
      .replaceAll("\\b\\d{3}-\\d{2}-\\d{4}\\b","***-**-****");
    return Map.of("masked", masked);
  }
}
JAVA

cat >> careconnect2025/backend/server.mjs <<'JS'

// --- PII sanitize ---
app.post("/pii/sanitize", requireAuth, (req,res)=>{
  let text = String((req.body||{}).text||"");
  text = text.replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/ig,"•••@•••.••")
             .replace(/\b(?:\+?1[-.\s]?)?(?:\(\d{3}\)|\d{3})[-.\s]?\d{3}[-.\s]?\d{4}\b/g,"(***) ***-****")
             .replace(/\b\d{3}-\d{2}-\d{4}\b/g,"***-**-****");
  res.json({masked:text});
});
