/* Native receipts never grant access. The authenticated, leased server status does. */
let storeExpiryTimer=null,storeUser=null,storeAccountVersion=0,storeStatusSequence=0,storeVerifying=0;
function nativeStoreKind(){return window.ShamsAndroid?.storeProducts?'google':window.webkit?.messageHandlers?.shamsStore?'apple':null}
function nativeStoreCall(action){const user=cloudState.session?.user?.id;if(nativeStoreKind()==='google'){if(action==='products')window.ShamsAndroid.storeProducts(premiumState.config?.basePlan||'');if(action==='purchase')window.ShamsAndroid.storePurchase(user);if(action==='restore')window.ShamsAndroid.storeRestore()}else if(nativeStoreKind()==='apple')window.webkit.messageHandlers.shamsStore.postMessage({action,userId:user})}
async function nativeStoreStatus(){
 const sequence=++storeStatusSequence,user=cloudState.session?.user?.id;if(!user){if(nativeStoreKind())premiumState.premium=false;return}
 const data=await cloudRequest('/rest/v1/rpc/shams_premium_status',{});
 if(sequence!==storeStatusSequence||cloudState.session?.user?.id!==user)return;
 const beforePremium=premiumState.premium;
 const remaining=Date.parse(data.expires_at)-Date.parse(data.server_time);clearTimeout(storeExpiryTimer);
 premiumState.premium=data.premium===true&&Number.isFinite(remaining)&&remaining>0;
 if(beforePremium!==premiumState.premium)window.ShamsAndroid?.adsRecheck?.(route,cloudState.session?.access_token||'');
 if(premiumState.premium)storeExpiryTimer=setTimeout(()=>{premiumState.premium=false;premiumPaint();loadPremium(true)},Math.min(remaining,90000));
}
window.shamsStoreEvent=async function(event){
 const s=premiumState;
 if(event.type==='product'&&event.id==='shams_premium_yearly'&&/^[A-Z]{3}$/.test(event.currency)&&Number(event.value)>0){s.detail={itemId:event.id,price:{value:event.value,currency:event.currency},subscriptionPeriod:'P1Y'};s.service={native:true};s.csrf='native';if(!event.checkout)s.loading=storeVerifying>0;premiumPaint();return}
 if(event.type==='purchase'){
  const user=cloudState.session?.user?.id;if(!user){toast(cw('signin'));s.loading=false;return}
  const accountVersion=storeAccountVersion;storeVerifying++;s.loading=true;premiumPaint();
  try{
   await cloudRequest('/functions/v1/store-billing',{action:'verify',store:event.store,purchaseToken:event.token,signedTransaction:event.jws});
   if(accountVersion!==storeAccountVersion||cloudState.session?.user?.id!==user)return;
   await nativeStoreStatus();toast(s.premium?pw('active'):pw('pending'));
   if(event.store==='apple')window.webkit?.messageHandlers?.shamsStore?.postMessage({action:'finish',transactionId:event.transactionId});
  }catch{toast(pw('error'))}finally{storeVerifying=Math.max(0,storeVerifying-1);s.loading=storeVerifying>0;premiumPaint()}return;
 }
 s.loading=storeVerifying>0;
 if(event.type==='unavailable'){s.service=null;s.detail=null}
 if(event.type==='pending')toast(pw('pending'));
 if(event.type==='none'){try{await nativeStoreStatus();toast(s.premium?pw('active'):pw('none'))}catch{toast(pw('error'))}}
 if(event.type==='error')toast(pw('error'));premiumPaint();
};
function initializeNativeStore(){
 const sessionWriter=cloudStoreSession;
 cloudStoreSession=function(session){const previous=cloudState.session?.user?.id;sessionWriter(session);if(previous!==cloudState.session?.user?.id){storeAccountVersion++;storeStatusSequence++;clearTimeout(storeExpiryTimer);premiumState.premium=false;premiumState.loaded=false;storeUser=cloudState.session?.user?.id||null;setTimeout(()=>loadPremium(true),0)}};
 const kind=nativeStoreKind();
 if(!kind){const previous=loadPremium;loadPremium=async function(force=false){await previous(force);if(cloudState.session)try{await nativeStoreStatus()}catch{premiumState.premium=false}premiumPaint()}}
 else{
  premiumPrice=function(){const d=premiumState.detail;return d?{monthly:premiumMoney(Number(d.price.value)/12,d.price.currency),annual:premiumMoney(Number(d.price.value),d.price.currency),actual:true}:{monthly:'—',annual:'—',actual:false}};
  const html=premiumPageHTML;
  premiumPageHTML=function(){let out=html().replace(/<details class="card premium-recovery">[\s\S]*?<\/details>/,'');if(!cloudState.session)out=out.replace('</section>',`<button class="secondarybtn wide" onclick="go('account')">${cw('signin')}</button></section>`);if(premiumState.config?.enabled&&cloudState.session&&!premiumState.loading)out=out.replace(/(onclick="restorePremium\(\)"\s*)disabled/,'$1');if(kind==='apple')out=out.replace(/https:\/\/play.google.com\/store\/account\/subscriptions\?[^" ]*/g,'https://apps.apple.com/account/subscriptions');return out};
  loadPremium=async function(force=false){const s=premiumState;if(s.loading)return;if(s.loaded&&!force)return;s.loading=true;s.error=false;s.premium=false;premiumPaint();try{const result=await cloudRequest('/functions/v1/store-billing',{action:'config'});s.config={enabled:result[kind]===true,product:'shams_premium_yearly',basePlan:result.basePlan,package:kind==='google'?'com.shams.play':'storekit'};await nativeStoreStatus();s.csrf='native';if(s.config.enabled&&cloudState.session)nativeStoreCall('products');else{s.service=null;s.detail=null}}catch{s.error=true;s.service=null;s.premium=false}finally{s.loaded=true;s.loading=storeVerifying>0;premiumPaint()}};
  purchasePremium=function(){if(!cloudState.session){go('account');return}if(!premiumState.config?.enabled||!premiumState.detail||premiumState.loading)return;premiumState.loading=true;premiumPaint();nativeStoreCall('purchase')};
  restorePremium=function(){if(!cloudState.session){go('account');return}if(!premiumState.config?.enabled||premiumState.loading)return;premiumState.loading=true;premiumPaint();nativeStoreCall('restore')};
 }
 setInterval(()=>{const uid=cloudState.session?.user?.id||null;if(uid!==storeUser){storeUser=uid;storeAccountVersion++;storeStatusSequence++;clearTimeout(storeExpiryTimer);premiumState.premium=false;premiumState.loaded=false;loadPremium(true)}},2000);
 setInterval(async()=>{if(document.hidden||!cloudState.session||premiumState.loading)return;const before=premiumState.premium;try{await nativeStoreStatus()}catch{premiumState.premium=false}if(before!==premiumState.premium)premiumPaint()},30000);
 document.addEventListener('visibilitychange',()=>{if(!document.hidden)loadPremium(true)});
}
