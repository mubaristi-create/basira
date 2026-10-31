// Same-origin server: app + verified Premium API + admin.
const {createApp,config}=require('./backend/server.cjs');const c=config();const app=createApp(c);app.server.listen(c.port,c.host,()=>console.log('Shams: '+c.origin));app.sync();setInterval(()=>app.sync(),6*3600000);
