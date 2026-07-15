const state = { data: null, q: '', printScope: 'class' };
const $ = id => document.getElementById(id);
async function api(path, options={}){
  const res = await fetch(path, {headers:{'Content-Type':'application/json'}, ...options});
  const json = await res.json();
  if(!res.ok) throw new Error(json.error || 'Request failed');
  return json;
}
function esc(v){return String(v ?? '').replace(/[&<>"']/g, m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]))}
function setStatus(msg, error=false){$('status').textContent=msg;$('status').className=error?'error':'';if(msg) setTimeout(()=>{$('status').textContent=''},2500)}
async function load(){state.data = await api('/api/workbook'); render();}
function filteredStudents(){const q=state.q.toLowerCase();return state.data.students.filter(s=>!q||s.roll_no.toLowerCase().includes(q)||s.name.toLowerCase().includes(q));}
function markFor(student, subject){const m=state.data.marks.find(x=>x.student_id===student.id&&x.subject_id===subject.id); return m ? m.marks : 0;}
function render(){
  const subjects=state.data.subjects;
  $('sheet').innerHTML = `<div class="grid-wrap"><table class="grid"><thead><tr><th>S.No.</th><th>Roll No.</th><th>Student Name</th>${subjects.map(s=>`<th>${esc(s.name)}</th>`).join('')}<th>Total</th></tr></thead><tbody>${filteredStudents().map((student,i)=>`<tr><td>${i+1}</td><td>${esc(student.roll_no)}</td><td>${esc(student.name)}</td>${subjects.map(subject=>`<td><input class="cell-input mark" data-student="${student.id}" data-subject="${subject.id}" value="${markFor(student, subject)}" type="number" min="0" max="${subject.max_marks}"></td>`).join('')}<td class="total">${subjects.reduce((sum,s)=>sum+Number(markFor(student,s)||0),0)}</td></tr>`).join('')}</tbody></table></div>`;
  renderSettings(); bindMarks();
}
function bindMarks(){document.querySelectorAll('.mark').forEach(input=>input.onchange=async()=>{try{state.data=await api('/api/marks',{method:'POST',body:JSON.stringify({student_id:Number(input.dataset.student),subject_id:Number(input.dataset.subject),marks:Number(input.value||0)})});setStatus('Autosaved');render();}catch(e){setStatus(e.message,true);load();}})}
function renderSettings(){const s=state.data.settings;$('settings').innerHTML=`<details><summary>Print & export setup</summary><div class="settings-grid">
<label>School Name<input id="schoolName" value="${esc(s.school_name)}"></label><label>School Address<input id="schoolAddress" value="${esc(s.school_address)}"></label><label>Logo URL<input id="schoolLogo" value="${esc(s.school_logo)}"></label><label>Page Size<select id="pageSize"><option ${s.page_size==='A4'?'selected':''}>A4</option><option ${s.page_size==='Letter'?'selected':''}>Letter</option><option ${s.page_size==='Legal'?'selected':''}>Legal</option></select></label><label>Margins (mm)<input id="pageMargin" type="number" value="${esc(s.page_margin_mm)}"></label><label>Header<input id="headerText" value="${esc(s.header_text)}"></label><label>Footer<input id="footerText" value="${esc(s.footer_text)}"></label><label>Class Teacher<input id="teacherName" value="${esc(s.teacher_name)}"></label><label>Principal<input id="principalName" value="${esc(s.principal_name)}"></label></div><button id="savePrintSettings">Save print settings</button></details>`;
$('savePrintSettings').onclick=saveSettings;}
async function saveSettings(){const s=state.data.settings; const payload={...s, school_name:$('schoolName').value, school_address:$('schoolAddress').value, school_logo:$('schoolLogo').value, page_size:$('pageSize').value, page_margin_mm:Number($('pageMargin').value||12), header_text:$('headerText').value, footer_text:$('footerText').value, teacher_name:$('teacherName').value, principal_name:$('principalName').value, subjects:state.data.subjects, remark_rules:s.remark_rules}; state.data=await api('/api/settings',{method:'POST',body:JSON.stringify(payload)}); setStatus('Print settings saved'); render();}
function preview(scope='class'){let url='/api/print?scope='+scope; const id=$('studentSelect').value; if(scope==='student'&&id) url+='&student_id='+id; window.open(url,'_blank');}
$('search').oninput=()=>{state.q=$('search').value; render();};
$('printClass').onclick=()=>preview('class'); $('printStudent').onclick=()=>preview('student');
$('exportPdf').onclick=()=>{location.href='/api/export/report.pdf'}; $('exportExcel').onclick=()=>{location.href='/api/export/report.xlsx'};
load().then(()=>{$('studentSelect').innerHTML=state.data.students.map(s=>`<option value="${s.id}">${esc(s.roll_no)} - ${esc(s.name)}</option>`).join('')}).catch(e=>setStatus(e.message,true));
