/* Pure selection/validation logic, shared by the app, importer and tests. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.ShamsQuizEngine=api})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const languages=['az','tr','ru','en','ar'],categories=['quran','prophets','history','prayer','ramadan','basics','hadith','general'];
const norm=s=>String(s||'').normalize('NFKC').toLocaleLowerCase().replace(/[\p{P}\p{S}\p{Z}\s\u064b-\u065f\u0670\u0640]+/gu,' ').trim();
const topic=q=>q.topic||(q.category==='names'?'basics':q.category==='culture'?'general':q.category);
const tier=q=>Math.min(3,Math.max(1,Number(q.tier||q.difficulty)||1));
const optionIds=q=>q.option_ids||q.options.map((_,i)=>q.id+':'+i);
const correctId=q=>q.correct_option_id||optionIds(q)[q.correct];
function validate(q,{newContent=false}={}){
 const errors=[];if(!q||!/^[-\w]{1,100}$/.test(q.id||''))return ['Invalid question ID'];
 if(!categories.includes(topic(q)))errors.push('Invalid category');
 if(!Number.isInteger(q.difficulty)||q.difficulty<1||q.difficulty>4)errors.push('Invalid difficulty');
 if(q.tier!==undefined&&(!Number.isInteger(q.tier)||q.tier<1||q.tier>3))errors.push('Invalid tier');
 if(!Array.isArray(q.options)||q.options.length!==4)return errors.concat('Exactly four options required');
 const ids=optionIds(q);if(ids.length!==4||new Set(ids).size!==4||ids.some(x=>typeof x!=='string'||!/^[-\w:]{1,140}$/.test(x)))errors.push('Invalid option identifiers');
 if(!Number.isInteger(q.correct)||q.correct<0||q.correct>3||correctId(q)!==ids[q.correct])errors.push('Answer key mismatch');
 for(const l of languages){
  if(!q.question?.[l]?.trim()||!q.explanation?.[l]?.trim()||q.options.some(o=>!o?.[l]?.trim()))errors.push('Missing translation: '+l);
  if(new Set(q.options.map(o=>norm(o?.[l]))).size!==4)errors.push('Duplicate/empty options: '+l);
 }
 if(!q.source_reference?.trim()||!/^https:\/\/[^\s]+$/.test(q.source_url||''))errors.push('Missing source');
 if(typeof q.active!=='boolean'||typeof q.reviewed!=='boolean')errors.push('Missing publication flags');
 if(newContent&&q.active&&(!q.reviewed||q.review_status!=='approved'||!q.review?.reviewer?.trim()||!/^\d{4}-\d{2}-\d{2}/.test(q.review?.date||'')||q.review?.source_checked!==true||languages.some(l=>q.translation_review?.[l]!==true)))errors.push('Source and all language approvals required before activation');
 if(q.active&&q.controversial===true&&!q.review?.resolution?.trim())errors.push('Disputed question requires a documented review');
 return errors;
}
function usable(q,l){return languages.includes(l)&&q.active===true&&q.reviewed===true&&!validate(q,{newContent:q.review_status!=='legacy-reviewed'}).length&&Boolean(q.question[l]&&q.explanation[l]&&q.options.every(o=>o[l]))}
function audit(bank){
 const errors=[],duplicates=[],candidates=[],ids=new Set(),texts=new Map(),facts=new Map(),concepts=new Map();
 for(const q of bank){if(ids.has(q.id))errors.push({id:q.id,errors:['Duplicate ID']});ids.add(q.id);const concept=q.concept_id||q.id;if(concepts.has(concept)&&concepts.get(concept)!==q.id)duplicates.push({ids:[concepts.get(concept),q.id],reason:'Same concept'});else concepts.set(concept,q.id);const e=validate(q);if(e.length)errors.push({id:q.id,errors:e});
  for(const l of languages){const key=l+':'+norm(q.question?.[l]);if(texts.has(key)&&texts.get(key)!==q.id)duplicates.push({ids:[texts.get(key),q.id],language:l});else texts.set(key,q.id)}
  const key=String(q.source_reference)+'|'+norm(q.options?.[q.correct]?.en);if(facts.has(key))candidates.push({ids:[facts.get(key),q.id],reason:'Same source and answer: editorial comparison required'});else facts.set(key,q.id);
 }
 return {count:bank.length,errors,duplicates,candidates,categories:categories.map(c=>({category:c,count:bank.filter(q=>topic(q)===c&&q.active&&q.reviewed).length}))};
}
function shuffled(items,rng=Math.random){const a=items.slice();for(let i=a.length-1;i>0;i--){const j=Math.min(i,Math.floor(rng()*(i+1)));[a[i],a[j]]=[a[j],a[i]]}return a}
function select(bank,{language='az',category='all',level=1,history={},count=10,previous=[],rng=Math.random}={}){
 const seenConcepts=new Set(),seenTexts=new Set();let pool=[];
 for(const q of bank){if(!usable(q,language)||(category!=='all'&&topic(q)!==category))continue;const concept=q.concept_id||q.id,key=norm(q.question[language]);if(seenConcepts.has(concept)||seenTexts.has(key))continue;seenConcepts.add(concept);seenTexts.add(key);pool.push(q)}
 const chosen=[],usedCategories=new Map();pool=shuffled(pool,rng);
 while(pool.length&&chosen.length<Math.min(count,10)){
  pool.sort((a,b)=>{
   const ha=history[a.id]||history[a.concept_id]||{},hb=history[b.id]||history[b.concept_id]||{};
   // Unseen ALWAYS wins over preferred difficulty/category; then least recently shown.
   const sa=ha.shownAt||0,sb=hb.shownAt||0;if(!sa!==!sb)return sa?1:-1;
   if(sa&&sb&&sa!==sb)return sa-sb;
   return ((usedCategories.get(topic(a))||0)-(usedCategories.get(topic(b))||0))||Math.abs(tier(a)-level)-Math.abs(tier(b)-level);
  });const q=pool.shift();chosen.push(q);usedCategories.set(topic(q),(usedCategories.get(topic(q))||0)+1);
 }
 // Avoid an identical sequence when the only eligible deck has already been seen.
 if(chosen.length>1&&chosen.map(q=>q.id).join('|')===previous.join('|'))chosen.push(chosen.shift());
 return chosen.map(q=>({id:q.id,optionIds:shuffled(optionIds(q),rng),order:[]})).map(e=>({...e,order:e.optionIds.map(id=>optionIds(bank.find(q=>q.id===e.id)).indexOf(id))}));
}
function mark(history,q,{shownAt=0,answeredAt=0,selectedId=null}={}){const id=q.id,old=history[id]||history[q.concept_id]||{};return {...history,[id]:{shownAt:Math.max(old.shownAt||0,shownAt),answeredAt:Math.max(old.answeredAt||0,answeredAt),...(answeredAt>=(old.answeredAt||0)&&selectedId?{selectedId}:old.selectedId?{selectedId:old.selectedId}:{})}}}
function merge(a={},b={}){const out={...a};for(const [id,v] of Object.entries(b)){const old=out[id]||{};out[id]={shownAt:Math.max(old.shownAt||0,v.shownAt||0),answeredAt:Math.max(old.answeredAt||0,v.answeredAt||0),...((v.answeredAt||0)>=(old.answeredAt||0)&&v.selectedId?{selectedId:v.selectedId}:old.selectedId?{selectedId:old.selectedId}:{})}}return out}
function answer(q,id){if(!optionIds(q).includes(id))throw Error('Unknown option ID');return id===correctId(q)}
function recommend(rounds=[]){const recent=rounds.slice(-5),total=recent.reduce((s,r)=>s+(Number(r.total)||0),0),correct=recent.reduce((s,r)=>s+(Number(r.correct)||0),0);return total<5?1:correct/total>=.8?3:correct/total>=.5?2:1}
return {languages,categories,norm,topic,tier,optionIds,correctId,validate,usable,audit,shuffled,select,mark,merge,answer,recommend};
});
