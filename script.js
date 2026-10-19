// 플레이스홀더 스크립트: 마이크 기능은 추가 구현 필요
document.addEventListener('DOMContentLoaded',()=>{
  const startBtn=document.getElementById('start-button');
  const stopBtn=document.getElementById('stop-button');
  const ambientBtn=document.getElementById('ambient-button');
  const voiceBtn=document.getElementById('voice-button');
  const ambientValue=document.getElementById('ambient-value');
  const voiceValue=document.getElementById('voice-value');
  const result=document.getElementById('result');
  const message=document.getElementById('message');

  let stream=null;

  startBtn.addEventListener('click',async()=>{
    try{
      stream=await navigator.mediaDevices.getUserMedia({audio:true});
      message.textContent='측정 준비 완료';
      startBtn.disabled=true;
      ambientBtn.disabled=false;
      stopBtn.disabled=false;
    }catch(err){
      message.textContent='마이크 권한을 허용해 주세요.';
    }
  });

  stopBtn.addEventListener('click',()=>{
    if(stream){
      stream.getTracks().forEach(t=>t.stop());
      stream=null;
    }
    message.textContent='측정이 중지되었습니다.';
    startBtn.disabled=false;
    ambientBtn.disabled=true;
    voiceBtn.disabled=true;
    stopBtn.disabled=true;
  });

  ambientBtn.addEventListener('click',()=>{
    ambientValue.textContent='측정 완료 (예시: 40)';
    ambientBtn.disabled=true;
    voiceBtn.disabled=false;
  });

  voiceBtn.addEventListener('click',()=>{
    voiceValue.textContent='측정 완료 (예시: 55)';
    result.textContent='권장: 현재보다 조금 더 크게 말하세요';
    voiceBtn.disabled=true;
  });
});
