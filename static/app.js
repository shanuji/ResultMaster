const state = {active:'English', data:null, q:''};
const $ = id => document.getElementById(id);
async function api(path, options={}){
  const res = await fetch(path, {headers:{'Content-Type':'application/json'}, ...options});
  const json = await res.json();
  if(!res.ok) throw new Error(json.error || 'Request failed');
  return json;
}
function setStatus(msg, error=false){$('status').textContent=msg;$('status').className=error?'error':'';if(msg) setTimeout(()=>{$('status').textContent=''},2500)}
async function load(){state.data = await api('/api/workbook?q='+encodeURIComponent(state.q)); render();}
function renderTabs(){
  $('tabs').innerHTML = state.data.tabs.map(t=>`<button class="tab ${t===state.active?'active':''}" data-tab="${t}">${t}</button>`).join('');
  document.querySelectorAll('.tab').forEach(b=>b.onclick=()=>{state.active=b.dataset.tab;render();});
}
function render(){renderTabs(); const sheet=$('sheet');
  if(!state.data.subjects.includes(state.active)){sheet.innerHTML=`<div class="placeholder"><h2>${state.active}</h2><p>${state.active} calculations are not implemented yet.</p></div>`;return;}
  const comps = state.data.components;
  sheet.innerHTML = `<div class="grid-wrap"><table class="grid"><thead><tr><th>S.No.</th><th>Roll No.</th><th>Student Name</th>${comps.map(c=>`<th>${c}</th>`).join('')}<th>TOTAL</th><th>Actions</th></tr></thead><tbody>${state.data.students.map(s=>row(s, comps)).join('')}</tbody></table></div>`;
  bind();
}
function row(s, comps){ const marks=s.subjects[state.active]; return `<tr data-id="${s.id}"><td>${s.serial}</td><td><input class="cell-input roll" value="${esc(s.roll_no)}"></td><td><input class="cell-input name" value="${esc(s.name)}"></td>${comps.map(c=>`<td><input class="cell-input mark" data-comp="${c}" value="${esc(marks[c])}" inputmode="text"></td>`).join('')}<td class="total">${marks.TOTAL}</td><td><div class="row-actions"><button class="delete">Delete</button></div></td></tr>`}
function esc(v){return String(v ?? '').replace(/[&<>"]/g, m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[m]))}
function valid(v){v=v.trim().toUpperCase(); if(v===''||v==='AB')return v; if(!/^\d{1,3}$/.test(v))throw new Error('Enter 0-100 or AB.'); const n=Number(v); if(n<0||n>100)throw new Error('Marks cannot be negative or exceed maximum 100.'); return String(n)}
function bind(){
  document.querySelectorAll('.mark').forEach(inp=>inp.onchange=async()=>{try{inp.value=valid(inp.value);state.data=await api('/api/marks',{method:'POST',body:JSON.stringify({student_id:inp.closest('tr').dataset.id,subject:state.active,component:inp.dataset.comp,value:inp.value})});setStatus('Autosaved');render();}catch(e){setStatus(e.message,true);load();}});
  document.querySelectorAll('.roll,.name').forEach(inp=>inp.onchange=async()=>{const tr=inp.closest('tr');try{state.data=await api('/api/students/'+tr.dataset.id,{method:'PUT',body:JSON.stringify({roll_no:tr.querySelector('.roll').value,name:tr.querySelector('.name').value})});setStatus('Autosaved');render();}catch(e){setStatus(e.message,true);load();}});
  document.querySelectorAll('.delete').forEach(btn=>btn.onclick=async()=>{if(confirm('Delete this student?')){state.data=await api('/api/students/'+btn.closest('tr').dataset.id,{method:'DELETE'});setStatus('Autosaved');render();}})
}
$('insertStudent').onclick=async()=>{const roll=prompt('Roll Number'); if(!roll)return; const name=prompt('Student Name'); if(!name)return; try{state.data=await api('/api/students',{method:'POST',body:JSON.stringify({roll_no:roll,name})});setStatus('Autosaved');render();}catch(e){setStatus(e.message,true)}};
$('search').oninput=()=>{state.q=$('search').value; clearTimeout(window.searchTimer); window.searchTimer=setTimeout(load,120)};
load().catch(e=>setStatus(e.message,true));
