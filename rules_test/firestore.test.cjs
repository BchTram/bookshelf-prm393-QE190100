const {readFileSync} = require('node:fs');
const {test, before, after, beforeEach} = require('node:test');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, getDocs, collection, query, where, updateDoc, deleteDoc,
  Timestamp, runTransaction, setLogLevel} = require('firebase/firestore');
setLogLevel('silent');
const assert = require('node:assert/strict');
const folds=JSON.parse(readFileSync('rules_test/unicode_fold.json','utf8'));
const fold = s => Array.from(s,c=>String.fromCodePoint(folds[c.codePointAt(0)]??c.codePointAt(0))).join('');
const escape = s => s.replaceAll('%','%25').replaceAll('\\','%5c').replaceAll('/','%2f').replaceAll('|','%7c');
const id = (uid,title,author) => `${escape(uid)}|${escape(fold(title))}|${escape(fold(author))}`;
const book = (uid='UserA', title='Dune', author='Frank Herbert') => ({
  id: id(uid,title,author), userId: uid, title, author, genre:'Fiction', status:'To Read',
  rating:null, favorite:false, notes:'', createdAt:Timestamp.fromMillis(1000)
});
let env, a,b,anon;
const ref = (db,d) => doc(db,'books',d.id);
before(async () => {
  env = await initializeTestEnvironment({projectId:'demo-bookshelf',
    firestore:{rules:readFileSync('firestore.rules','utf8')}});
  a = env.authenticatedContext('UserA').firestore();
  b = env.authenticatedContext('UserB').firestore();
  anon = env.unauthenticatedContext().firestore();
});
beforeEach(async () => env.clearFirestore());
after(async () => env?.cleanup());

test('anonymous read/create/update/delete denied', async () => {
  const d=book(); await setDoc(ref(a,d),d);
  await assertFails(getDoc(ref(anon,d))); await assertFails(setDoc(ref(anon,d),d));
  await assertFails(updateDoc(ref(anon,d),{favorite:true})); await assertFails(deleteDoc(ref(anon,d)));
});
test('own CRUD and scoped query; cross-account access and spoof denied', async () => {
  const d=book(); await assertSucceeds(setDoc(ref(a,d),d));
  await assertSucceeds(getDoc(ref(a,d)));
  await assertSucceeds(getDocs(query(collection(a,'books'),where('userId','==','UserA'))));
  await assertFails(getDocs(collection(a,'books')));
  await assertFails(getDoc(ref(b,d))); await assertFails(updateDoc(ref(b,d),{favorite:true}));
  await assertFails(deleteDoc(ref(b,d))); await assertFails(setDoc(ref(b,d),d));
  await assertSucceeds(updateDoc(ref(a,d),{favorite:true}));
  await assertSucceeds(deleteDoc(ref(a,d)));
});
for (const [field,value] of [
  ['title','   '],['title','x'.repeat(101)],['title',42],['author','\t '],['author','x'.repeat(61)],
  ['author',null],['genre','Novel'],['genre',1],['status','Done'],['status',null],
  ['rating',-1],['rating',6],['rating',2.5],['rating','3'],['rating',true],
  ['notes','x'.repeat(301)],['notes',null],['favorite','yes'],['createdAt','today'],
  ['id','arbitrary'],['userId','UserB'],['extra','forbidden']
]) test(`invalid ${field} ${JSON.stringify(value).slice(0,45)} denied`,async () => {
  const d=book(); const key=d.id; d[field]=value;
  await assertFails(setDoc(doc(a,'books',key),d));
});
for (const field of ['id','userId','title','author','genre','status','favorite','createdAt'])
test(`missing ${field} denied`, async () => {
  const d=book(); const key=d.id; delete d[field]; await assertFails(setDoc(doc(a,'books',key),d));
});
test('optional fields absent and boundary values accepted',async () => {
  const d=book('UserA','x'.repeat(100),'y'.repeat(60));
  delete d.rating; delete d.notes; await assertSucceeds(setDoc(ref(a,d),d));
  await assertSucceeds(updateDoc(ref(a,d),{rating:0,notes:'x'.repeat(300)}));
  await assertSucceeds(updateDoc(ref(a,d),{rating:5}));
});
test('arbitrary ID and case-variant alternate IDs denied; same book across users allowed',async () => {
  const d=book(); await setDoc(ref(a,d),d);
  const duplicate=book('UserA','dUNE','fRANK hERBERT');
  assert.equal(d.id,duplicate.id);
  await assertFails(setDoc(doc(a,'books','random'),{...duplicate,id:'random'}));
  const nonCanonical='UserA|DUNE|frank herbert';
  await assertFails(setDoc(doc(a,'books',nonCanonical),{...duplicate,id:nonCanonical}));
  const other=book('UserB'); await assertSucceeds(setDoc(ref(b,other),other));
  const docs=await getDocs(query(collection(a,'books'),where('userId','==','UserA')));
  assert.equal(docs.size,1);
});
test('concurrent create transaction creates one row; rejects duplicate', async () => {
  const d=book();
  const add=() => runTransaction(a,async tx => {
    const s=await tx.get(ref(a,d)); if(s.exists()) throw Error('duplicate'); tx.set(ref(a,d),d);
  });
  const results=await Promise.allSettled([add(),add()]);
  assert.equal(results.filter(x=>x.status==='fulfilled').length,1);
});
test('immutable identity/owner/time; invalid update denied',async () => {
  const d=book(); await setDoc(ref(a,d),d);
  for(const change of [{title:'Other'},{author:'Other'},{userId:'UserB'}, {id:'other'},
    {createdAt:Timestamp.fromMillis(2000)},{rating:9},{notes:'x'.repeat(301)}])
    await assertFails(updateDoc(ref(a,d),change));
  await assertSucceeds(updateDoc(ref(a,d),{title:'DUNE',status:'Finished',rating:5}));
});
test('atomic rename keeps timestamp/favorite; duplicate target rolls back source',async () => {
  const d=book(), next=book('UserA','Foundation','Asimov');
  d.favorite=true; next.favorite=true; await setDoc(ref(a,d),d);
  const move=async (old,target) => runTransaction(a, async tx => {
    const existing=await tx.get(ref(a,target)); const source=await tx.get(ref(a,old));
    if(existing.exists()) throw Error('duplicate');
    tx.set(ref(a,target),{...target,createdAt:source.data().createdAt,favorite:source.data().favorite});
    tx.delete(ref(a,old));
  });
  await assertSucceeds(move(d,next)); assert.equal((await getDoc(ref(a,d))).exists(),false);
  assert.equal((await getDoc(ref(a,next))).data().favorite,true);
  await setDoc(ref(a,d),d); await assert.rejects(move(d,next),/duplicate/);
  assert.equal((await getDoc(ref(a,d))).exists(),true);
});
for (const [title,author] of [['A|B','C'],['A','B|C'],['100% / BOOK','%2f|Author'],
  ['ĐƯỜNG VỀ 📚','TÁC GIẢ'],['ÉCOLE','ÅUTHOR'],['İSTANBUL','Σ AUTHOR'],[' a ',' b '],['Line\nBreak','Author']])
test(`canonical escaping/Unicode ${title}`,async () => {
  const d=book('UserA',title,author); await assertSucceeds(setDoc(ref(a,d),d));
});
test('UID case remains distinct',async () => {
  const lower=env.authenticatedContext('usera').firestore();
  await assertSucceeds(setDoc(ref(a,book()),book()));
  const d=book('usera'); await assertSucceeds(setDoc(ref(lower,d),d));
});

// These IDs are computed by the actual Dart client function, not a JS facsimile.
for (const vector of JSON.parse(readFileSync('rules_test/dart_identity_vectors.json','utf8')))
test(`Dart/Rules parity: ${vector.title}`,async () => {
  const d={...book('UserA',vector.title,vector.author),id:vector.id};
  await assertSucceeds(setDoc(ref(a,d),d));
});

test('Regex metacharacters and quote terminators remain literal',async()=>{
  for (const title of ['.*','a\\Eb','a\\Qb','[a-z]+(x)?^$','%5cE|/%']) {
    const d=book('UserA',title,'Author'); await assertSucceeds(setDoc(ref(a,d),d));
    const bad=book('UserA','Injected','Author');
    await assertFails(setDoc(ref(a,bad),{...d,id:bad.id}));
  }
});
const foldPoints=Object.keys(folds).map(Number);
for(let offset=0;offset<foldPoints.length;offset+=30)
test(`Unicode fold coverage ${offset}-${Math.min(offset+29,foldPoints.length-1)}`,async()=>{
  const title=String.fromCodePoint(...foldPoints.slice(offset,offset+30));
  const d=book('UserA',title,'Author'); await assertSucceeds(setDoc(ref(a,d),d));
});
