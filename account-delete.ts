import {createClient} from 'npm:@supabase/supabase-js@2';
const headers={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization,apikey,content-type','Access-Control-Allow-Methods':'POST,OPTIONS','Cache-Control':'no-store','Content-Type':'application/json'};
const reply=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers});
Deno.serve(async req=>{if(req.method==='OPTIONS')return new Response(null,{headers});if(req.method!=='POST')return reply({error:'POST required'},405);
 try{const token=req.headers.get('Authorization')?.match(/^Bearer (\S+)$/)?.[1];if(!token)return reply({error:'Sign in required'},401);
 const db=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false,autoRefreshToken:false}});
 const {data,error}=await db.auth.getUser(token);if(error||!data.user)return reply({error:'Sign in required'},401);
 const raw=await req.text();if(raw.length>100||JSON.parse(raw).confirm!=='DELETE')return reply({error:'Explicit DELETE confirmation required'},400);
 const cleanup=await db.rpc('shams_delete_user_posts',{p_user:data.user.id});if(cleanup.error)return reply({error:'Administrator accounts must transfer their role before deletion'},409);
 const deleted=await db.auth.admin.deleteUser(data.user.id);if(deleted.error)return reply({error:'Deletion could not finish. Please retry or contact support.'},503);
 return reply({deleted:true});
 }catch{return reply({error:'Request could not be completed'},400)}
});
