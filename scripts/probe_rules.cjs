const {initializeTestEnvironment}=require('@firebase/rules-unit-testing');
const {doc,setDoc}=require('firebase/firestore');
(async()=>{
  const expressions=[
    `request.resource.data.s.lower() == 'École'`,
    `request.resource.data.s.lower() == 'école'`,
    `'école'.matches('(?i)ÉCOLE')`,
    `'a.b'.matches('(?i)\\\\Qa.b\\\\E')`,
    `'a.b'.matches('(?i)\\\\Q' + 'a.b' + '\\\\E')`,
    `'a\\\\Eb'.matches('\\\\Q' + 'a\\\\Eb'.replace('\\\\\\\\E', '\\\\E\\\\\\\\E\\\\Q') + '\\\\E')`,
  ];
  for(let i=0;i<expressions.length;i++) {
    const condition=expressions[i];
    const rules=`rules_version='2';service cloud.firestore {match /databases/{d}/documents {match /p/{id}{allow write: if ${condition};}}}`;
    let env;
    try {
      env=await initializeTestEnvironment({projectId:`demo-probe-${i}`,firestore:{rules}});
      await setDoc(doc(env.authenticatedContext('a').firestore(),'p','x'),{s:'ÉCOLE'});
      console.log('PASS',condition);
    } catch(e) {console.log('FAIL',condition,e.message.slice(0,250));}
    finally {await env?.cleanup();}
  }
})();
