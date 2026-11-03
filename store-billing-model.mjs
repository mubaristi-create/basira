export const PRODUCT='shams_premium_yearly';
export function googleResult(data,basePlan,now=Date.now()){
 const line=data.lineItems?.find(l=>l.productId===PRODUCT&&l.offerDetails?.basePlanId===basePlan);if(!line)throw Error('Unexpected product/base plan');
 const states={SUBSCRIPTION_STATE_ACTIVE:'active',SUBSCRIPTION_STATE_IN_GRACE_PERIOD:'grace',SUBSCRIPTION_STATE_CANCELED:'canceled',SUBSCRIPTION_STATE_PENDING:'pending',SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED:'expired',SUBSCRIPTION_STATE_ON_HOLD:'hold',SUBSCRIPTION_STATE_PAUSED:'paused',SUBSCRIPTION_STATE_EXPIRED:'expired'};
 const state=states[data.subscriptionState];if(!state)throw Error('Unknown state');const expiry=Date.parse(line.expiryTime);if(!Number.isFinite(expiry)&&['active','grace','canceled'].includes(state))throw Error('Missing expiry');
 return{state,expires_at:new Date(Number.isFinite(expiry)?expiry:0).toISOString(),renewing:line.autoRenewingPlan?.autoRenewEnabled===true,environment:data.testPurchase?'Sandbox':'Production',active:['active','grace','canceled'].includes(state)&&expiry>now};
}
export function appleResult(transaction,status,renewal,now=Date.now()){
 if(![1,2,3,4,5].includes(status))throw Error('Unknown Apple subscription status');
 if(transaction.productId!==PRODUCT||transaction.type!=='Auto-Renewable Subscription')throw Error('Unexpected Apple product');
 const expiry=Number(transaction.expiresDate);if(!Number.isFinite(expiry))throw Error('Missing expiry');
 const revoked=!!transaction.revocationDate||status===5;const grace=status===4&&Number(renewal?.gracePeriodExpiresDate)>now;
 return{state:revoked?'revoked':grace?'grace':status===1&&expiry>now?(renewal?.autoRenewStatus===0?'canceled':'active'):status===3?'hold':'expired',expires_at:new Date(grace?Number(renewal.gracePeriodExpiresDate):expiry).toISOString(),renewing:renewal?.autoRenewStatus===1,environment:transaction.environment};
}
