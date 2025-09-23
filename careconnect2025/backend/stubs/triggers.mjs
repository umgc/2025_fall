export function proposeFromTriggers(text){
  const hits = [];
  const rules = [/schedule/i,/prescribe/i,/go to/i];
  for(const rx of rules){ if(rx.test(text)) hits.push(rx.source); }
  if(!hits.length) return null;
  return {
    type:"calendar_proposal",
    source:"AI-derived",
    title:"Follow-up from notes",
    detail:`Triggers: ${hits.join(", ")}`,
    when:new Date(Date.now()+86400000).toISOString()
  };
}
