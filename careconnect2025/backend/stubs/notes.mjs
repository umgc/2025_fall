const notes = []; // demo only
export function saveNote({id=Date.now(), text}){ notes.push({id,text,ts:new Date().toISOString()}); return {id}; }
export function listNotes(q){ return notes.filter(n=>!q || n.text.includes(q)); }
