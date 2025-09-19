import { useEffect, useState } from "react";

export default function App() {
  const [msg, setMsg] = useState("loading...");
  const api = import.meta.env.VITE_API_URL;

  useEffect(() => {
    fetch(`${api}/health`)
      .then(r => r.json())
      .then(d => setMsg(JSON.stringify(d, null, 2)))
      .catch(e => setMsg("error: " + e));
  }, [api]);

  return (
    <div style={{ fontFamily: "system-ui", padding: 24 }}>
      <h1>CareConnect Demo</h1>
      <p>API URL: {api}</p>
      <pre>{msg}</pre>
    </div>
  );
}
