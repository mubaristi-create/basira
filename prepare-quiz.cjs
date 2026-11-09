const fs=require('node:fs'),path=require('node:path'),engine=require('./dist/quiz-engine.js');
const bank=JSON.parse(fs.readFileSync(path.join(__dirname,'content-quiz.json'),'utf8')).questions;
const crypto=require('node:crypto'),baseline=JSON.parse(fs.readFileSync(path.join(__dirname,'legacy-quiz-review.json'),'utf8'));
for(const q of bank){const fingerprint=crypto.createHash('sha256').update(JSON.stringify(Object.fromEntries(baseline.fields.map(k=>[k,q[k]])))).digest('hex');const e=engine.validate(q,{newContent:q.review_status!=='legacy-reviewed'||baseline.hashes[q.id]!==fingerprint});if(e.length)throw Error(q.id+': '+e.join(', '));}
const report=engine.audit(bank);if(report.errors.length||report.duplicates.length)throw Error(JSON.stringify(report));
fs.writeFileSync(path.join(__dirname,'QUIZ-AUDIT.json'),JSON.stringify(report,null,2));
fs.mkdirSync(path.join(__dirname,'supabase/migrations'),{recursive:true});
const rows=bank.map(q=>"update shams_private.quiz_bank set payload="+"'"+JSON.stringify(q).replaceAll("'","''")+"'::jsonb where id='"+q.id+"';").join('\n');
const sql=fs.readFileSync(path.join(__dirname,'quiz-history.sql'),'utf8');
fs.writeFileSync(path.join(__dirname,'supabase/quiz-upgrade-deploy.sql'),sql.replace('commit;',()=>rows+'\ncommit;'));
console.log('Quiz v3 audit: '+bank.length+' records; '+report.candidates.length+' editorial candidates.');

fs.writeFileSync(path.join(__dirname,'supabase/migrations/20261108_quiz_payloads.sql'),'begin;\n'+rows+'\ncommit;\n');
