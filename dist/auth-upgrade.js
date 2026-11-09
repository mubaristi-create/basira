/* Keep native refresh tokens in Android Keystore; web retains its existing session. */
let authRefreshFlight=null,authGoogleReady=false,authExchanging=false;
const authWords={google:['Google ilə davam et','Google ile devam et','Продолжить с Google','Continue with Google','المتابعة باستخدام Google'],guest:['Qonaq kimi davam et','Misafir olarak devam et','Продолжить как гость','Continue as guest','المتابعة كضيف'],unavailable:['Google girişi hələ aktivləşdirilməyib. E-poçt və ya qonaq girişindən istifadə edin.','Google girişi henüz etkin değil. E-posta veya misafir girişini kullanın.','Вход Google пока не настроен. Используйте почту или гостевой режим.','Google sign-in is not configured yet. Use email or guest access.','لم يُفعّل تسجيل Google بعد. استخدم البريد أو وضع الضيف.'],privacy:['Reklam məxfilik seçimləri','Reklam gizlilik seçenekleri','Настройки конфиденциальности рекламы','Ad privacy choices','خيارات خصوصية الإعلانات'],storage:['Giriş cihazda təhlükəsiz saxlanmadı. Yenidən cəhd edin.','Oturum güvenli kaydedilemedi. Tekrar deneyin.','Не удалось безопасно сохранить вход. Повторите.','Could not save sign-in securely. Try again.','تعذر حفظ تسجيل الدخول بأمان. حاول مجددًا.']};
function aw(k){return authWords[k][['az','tr','ru','en','ar'].indexOf(lang())]}
function authNativeVault(){return !!window.ShamsAndroid?.secureRead&&!!window.ShamsAndroid?.secureWrite}
function authRead(name){if(authNativeVault()){const raw=window.ShamsAndroid.secureRead(name);if(raw)return JSON.parse(raw);if(name==='session'){const old=read('shams-cloud-session',null);if(old){if(!window.ShamsAndroid.secureWrite(name,JSON.stringify(old)))throw Error(aw('storage'));localStorage.removeItem('shams-cloud-session');return old;}}return null;}return read(name==='session'?'shams-cloud-session':'shams-oauth-pkce',null)}
function authWrite(name,value){if(authNativeVault()){if(!window.ShamsAndroid.secureWrite(name,value?JSON.stringify(value):''))throw Error(aw('storage'));if(name==='session')localStorage.removeItem('shams-cloud-session');}else{const key=name==='session'?'shams-cloud-session':'shams-oauth-pkce';if(value){if(!safeWrite(key,value))throw Error(aw('storage'));}else localStorage.removeItem(key);}}
async function authGoogle(){
 if(!authGoogleReady){toast(aw('unavailable'));return;}
 try{const bytes=crypto.getRandomValues(new Uint8Array(48)),base64=b=>btoa(String.fromCharCode(...b)).replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/g,''),verifier=base64(bytes),challenge=base64(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(verifier))));
  authWrite('oauth',{verifier,created:Date.now()});const redirect=authNativeVault()?'com.shams.play://auth/callback':SHAMS_PUBLIC_URL;
  const url=SHAMS_CLOUD_CONFIG.url+'/auth/v1/authorize?'+new URLSearchParams({provider:'google',redirect_to:redirect,code_challenge:challenge,code_challenge_method:'s256'});
  if(authNativeVault())window.ShamsAndroid.openAuth(url);else location.assign(url);
 }catch(e){toast(e.message||cw('error'));}
}
async function authExchange(code){
 if(authExchanging)return;authExchanging=true;
 try{const pending=authRead('oauth');if(!pending?.verifier||Date.now()-pending.created>600000)throw Error(cw('error'));
  const response=await fetch(SHAMS_CLOUD_CONFIG.url+'/auth/v1/token?grant_type=pkce',{method:'POST',headers:{apikey:SHAMS_CLOUD_CONFIG.key,'Content-Type':'application/json'},body:JSON.stringify({auth_code:code,code_verifier:pending.verifier}),signal:AbortSignal.timeout(20000)});
  if(!response.ok)throw Error(cw('error'));const session=await response.json();cloudStoreSession(session);authWrite('oauth',null);await loadCloudProfile();go(ideaReturn?'community':'home');cloudPaint();
 }catch(e){cloudState.error=e.message;cloudPaint();}finally{authExchanging=false;}
}
function initializeAuthUpgrade(){
 // Install before initializeCloud schedules its restore, and before downstream session wrappers.
 cloudRefresh=function(){if(authRefreshFlight)return authRefreshFlight;const current=cloudState.session;if(!current?.refresh_token)return Promise.reject(Error(cw('error')));
  authRefreshFlight=(async()=>{const response=await fetch(SHAMS_CLOUD_CONFIG.url+'/auth/v1/token?grant_type=refresh_token',{method:'POST',headers:{apikey:SHAMS_CLOUD_CONFIG.key,'Content-Type':'application/json'},body:JSON.stringify({refresh_token:current.refresh_token}),signal:AbortSignal.timeout(20000)});
   if(!response.ok){if([400,401,403].includes(response.status)&&cloudState.session?.refresh_token===current.refresh_token)cloudStoreSession(null);throw Error(cw('error'));}
   const next=await response.json();if(cloudState.session?.refresh_token!==current.refresh_token)return;cloudStoreSession(next);
  })().finally(()=>authRefreshFlight=null);return authRefreshFlight;};
 const original=accountPage;accountPage=function(){let html=original();if(!cloudState.session)html=html.replace('<div class="tabs">',`<section class="card auth-options"><button class="secondarybtn wide" onclick="authGoogle()" ${authGoogleReady?'':'disabled'}>${aw('google')}</button>${authGoogleReady?'':`<p class="notice">${aw('unavailable')}</p>`}<button class="textbtn wide" onclick="go('home')">${aw('guest')}</button></section><div class="tabs">`);if(window.ShamsAndroid?.adsPrivacy&&window.ShamsAndroid.adsMode?.()!=='off')html+=`<section class="card"><button class="textbtn wide" onclick="window.ShamsAndroid.adsPrivacy()">${aw('privacy')}</button></section>`;return html;};
 fetch(SHAMS_CLOUD_CONFIG.url+'/auth/v1/settings',{headers:{apikey:SHAMS_CLOUD_CONFIG.key},signal:AbortSignal.timeout(10000)}).then(r=>r.ok?r.json():{}).then(data=>{authGoogleReady=data.external?.google===true;cloudPaint();}).catch(()=>{});
 const poll=()=>{if(document.hidden)return;const code=window.ShamsAndroid?.consumeAuthCode?.();if(code)authExchange(code);if(cloudState.session&&cloudState.session.expires_at<Date.now()/1000+120)cloudRefresh().catch(()=>{});window.ShamsAndroid?.adsUpdate?.(route,cloudState.session?.access_token||'');};
 setInterval(poll,30000);window.addEventListener('hashchange',poll);document.addEventListener('visibilitychange',poll);window.addEventListener('focus',poll);
 setTimeout(()=>{const code=new URLSearchParams(location.search).get('code');if(code){history.replaceState(null,'',location.pathname+'#account');authExchange(code);}poll();},0);
}
