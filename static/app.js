const state = { data: null, analytics: null, reports: null, q: '', view: 'workbook', sort: 'rank', dir: 'asc', busy: false };
const $ = id => document.getElementById(id);
const esc = v => String(v ?? '').replace(/[&<>"']/g, m => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[m]));

function setBusy(isBusy, message = 'Loading…') {
  state.busy = isBusy;
  const overlay = $('loading');
  overlay.hidden = !isBusy;
  overlay.querySelector('span').textContent = message;
  document.querySelectorAll('button,input,select,textarea').forEach(el => el.disabled = isBusy && !el.closest('#loading'));
}
function showDialog(title, message, kind = 'error') {
  $('dialogTitle').textContent = title;
  $('dialogMessage').textContent = message;
  $('messageDialog').className = kind;
  $('messageDialog').showModal();
}
function setStatus(msg, kind = 'success') {
  $('status').textContent = msg;
  $('status').className = kind;
  if (msg) setTimeout(() => { $('status').textContent = ''; $('status').className = ''; }, 3500);
}
async function api(path, options = {}) {
  const res = await fetch(path, { headers: { 'Content-Type': 'application/json' }, ...options });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(json.error || 'Request failed');
  return json;
}
async function load() {
  try {
    setBusy(true, 'Opening workbook…');
    state.data = await api('/api/workbook');
    applyTheme();
    await refreshComputed();
    render();
  } catch (e) { showDialog('Unable to load ResultMaster', e.message); }
  finally { setBusy(false); }
}
async function refreshComputed() {
  [state.analytics, state.reports] = await Promise.all([
    api('/api/analytics'),
    api(`/api/reports?q=${encodeURIComponent(state.q)}&sort=${state.sort}&direction=${state.dir}`),
  ]);
}
function applyTheme() {
  const theme = state.data?.settings?.theme || 'system';
  document.documentElement.dataset.theme = theme;
}
function markFor(student, subject) { return state.data.marks.find(x => x.student_id === student.id && x.subject_id === subject.id)?.marks ?? 0; }
function render() {
  document.querySelectorAll('.tab').forEach(b => b.classList.toggle('active', b.dataset.view === state.view));
  renderSettings();
  if (state.view === 'analytics') renderAnalytics(); else if (state.view === 'reports') renderReports(); else if (state.view === 'data') renderData(); else renderWorkbook();
  $('studentSelect').innerHTML = state.data.students.map(s => `<option value="${s.id}">${esc(s.roll_no)} - ${esc(s.name)}</option>`).join('');
}
function renderWorkbook() {
  const subjects = state.data.subjects, q = state.q.toLowerCase();
  const students = state.data.students.filter(s => !q || s.roll_no.toLowerCase().includes(q) || s.name.toLowerCase().includes(q));
  $('sheet').innerHTML = `<div class="grid-wrap" tabindex="0" aria-label="Marks workbook table"><table class="grid"><thead><tr><th>S.No.</th><th>Roll No.</th><th>Student Name</th>${subjects.map(s => `<th>${esc(s.name)}</th>`).join('')}<th>Total</th></tr></thead><tbody>${students.map((student, i) => `<tr><td>${i + 1}</td><td>${esc(student.roll_no)}</td><td>${esc(student.name)}</td>${subjects.map(subject => `<td><input class="cell-input mark" aria-label="${esc(student.name)} ${esc(subject.name)} marks" data-student="${student.id}" data-subject="${subject.id}" value="${markFor(student, subject)}" inputmode="decimal" type="number" min="0" max="${subject.max_marks}" step="0.01"></td>`).join('')}<td class="total">${subjects.reduce((sum, s) => sum + Number(markFor(student, s) || 0), 0)}</td></tr>`).join('')}</tbody></table></div>`;
  bindMarks();
}
function renderAnalytics() {
  const a = state.analytics;
  $('sheet').innerHTML = `<div class="panel"><h2>Analytics Dashboard</h2><div class="cards"><div><b>${a.pass_percentage}%</b><span>Pass Percentage</span></div><div><b>${a.overall_class_performance}%</b><span>Overall Performance</span></div><div><b>${a.highest_marks}</b><span>Highest Marks</span></div><div><b>${a.lowest_marks}</b><span>Lowest Marks</span></div></div><h3>Grade Distribution</h3><div class="bars">${Object.entries(a.grade_distribution).map(([k, v]) => `<label>${esc(k)}<span style="width:${Math.max(4, v * 28)}px">${v}</span></label>`).join('')}</div><h3>Subject Averages</h3><div class="table-scroll">${subjectAverageTable(a.subject_averages)}</div></div>`;
}
function subjectAverageTable(rows) { return `<table class="grid report"><thead><tr><th>Subject</th><th>Average</th><th>Highest</th><th>Lowest</th><th>Pass %</th></tr></thead><tbody>${rows.map(s => `<tr><td>${esc(s.name)}</td><td>${s.average}</td><td>${s.highest}</td><td>${s.lowest}</td><td>${s.pass_percentage}%</td></tr>`).join('')}</tbody></table>`; }
function renderReports() {
  const r = state.reports;
  $('sheet').innerHTML = `<div class="panel"><h2>Advanced Reports</h2><div class="cards"><div><b>${r.pass_fail_analysis.pass}</b><span>Pass</span></div><div><b>${r.pass_fail_analysis.fail}</b><span>Fail</span></div><div><b>${esc(r.topper_list[0]?.student_name || '-')}</b><span>Topper</span></div><div><b>${r.merit_list.length}</b><span>Merit List</span></div></div><h3>Class / Section Report</h3><div class="table-scroll">${summaryTable(r.rows)}</div><h3>Topper List</h3><div class="table-scroll">${summaryTable(r.topper_list)}</div><h3>Merit List</h3><div class="table-scroll">${summaryTable(r.merit_list)}</div><h3>Subject-wise Report</h3>${r.subject_report.map(s => `<details><summary>${esc(s.subject)} — Avg ${s.average}, High ${s.highest}, Low ${s.lowest}</summary></details>`).join('')}</div>`;
}
function summaryTable(rows) { const subs = state.data.subjects; return `<table class="grid report"><thead><tr><th>Rank</th><th>Roll No.</th><th>Student Name</th>${subs.map(s => `<th>${esc(s.name)}</th>`).join('')}<th>Total</th><th>%</th><th>Result</th></tr></thead><tbody>${rows.map(r => `<tr><td>${r.rank}</td><td>${esc(r.roll_no)}</td><td>${esc(r.student_name)}</td>${subs.map(s => `<td>${r.subjects[s.name]}</td>`).join('')}<td>${r.grand_total}</td><td>${r.percentage}</td><td class="${r.result.toLowerCase()}">${r.result}</td></tr>`).join('')}</tbody></table>`; }
function renderData() {
  $('sheet').innerHTML = `<div class="panel"><h2>Data Management</h2><p>Export CSV, Excel, PDF report cards, create SQLite backups, and restore verified local backups.</p><div class="actions"><a href="/api/export/students.csv">Export Students CSV</a><a href="/api/export/marks.csv">Export Marks CSV</a><a href="/api/export/settings.json">Export Settings JSON</a><a href="/api/export/report.xlsx">Export Excel</a><a href="/api/export/report.pdf">Export PDF</a><a href="/api/backup">Download Backup</a></div><label>Import students CSV<textarea id="bulkStudents" placeholder="roll_no,name\n201,New Student"></textarea></label><button id="importStudents">Import / Bulk Edit Students</button><label>Import marks CSV<textarea id="bulkMarks" placeholder="roll_no,name,subject,marks\n201,New Student,English,88"></textarea></label><button id="importMarks">Import / Bulk Edit Marks</button><label>Restore base64 SQLite backup<textarea id="restoreText" placeholder="Paste base64-encoded .sqlite3 backup here"></textarea></label><button id="restoreBtn" class="danger">Restore Database</button></div>`;
  $('importStudents').onclick = () => postImport('/api/import/students', $('bulkStudents').value);
  $('importMarks').onclick = () => postImport('/api/import/marks', $('bulkMarks').value);
  $('restoreBtn').onclick = async () => { if (!confirm('Restore will replace current local data. Continue?')) return; await runAction('Restoring backup…', async () => { state.data = await api('/api/restore', { method: 'POST', body: JSON.stringify({ backup_base64: $('restoreText').value.trim() }) }); await refreshComputed(); applyTheme(); setStatus('Database restored'); render(); }); };
}
async function runAction(message, fn) { try { setBusy(true, message); await fn(); } catch (e) { showDialog('Action failed', e.message); } finally { setBusy(false); } }
async function postImport(path, csv) { await runAction('Importing data…', async () => { state.data = await api(path, { method: 'POST', body: JSON.stringify({ csv }) }); await refreshComputed(); setStatus('Import complete'); render(); }); }
function bindMarks() { document.querySelectorAll('.mark').forEach(input => input.onchange = async () => { const max = Number(input.max); const value = Number(input.value || 0); if (value < 0 || value > max) { showDialog('Invalid marks', `Marks must be between 0 and ${max}.`); input.focus(); return; } await runAction('Autosaving…', async () => { state.data = await api('/api/marks', { method: 'POST', body: JSON.stringify({ student_id: Number(input.dataset.student), subject_id: Number(input.dataset.subject), marks: value }) }); await refreshComputed(); setStatus('Autosaved'); render(); }); }); }
function renderSettings() {
  const s = state.data.settings;
  $('settings').innerHTML = `<details><summary>Application, print & export setup</summary><div class="settings-grid"><label>Theme<select id="theme"><option value="system" ${s.theme === 'system' ? 'selected' : ''}>System</option><option value="light" ${s.theme === 'light' ? 'selected' : ''}>Light</option><option value="dark" ${s.theme === 'dark' ? 'selected' : ''}>Dark</option></select></label><label>Default Export<select id="defaultExport"><option value="xlsx" ${s.default_export === 'xlsx' ? 'selected' : ''}>Excel</option><option value="pdf" ${s.default_export === 'pdf' ? 'selected' : ''}>PDF</option></select></label><label class="check"><input id="autosaveEnabled" type="checkbox" ${s.autosave_enabled ? 'checked' : ''}> Autosave edits</label><label>School Name<input id="schoolName" value="${esc(s.school_name)}" maxlength="160"></label><label>School Address<input id="schoolAddress" value="${esc(s.school_address)}" maxlength="240"></label><label>Logo URL<input id="schoolLogo" value="${esc(s.school_logo)}" maxlength="500"></label><label>Page Size<select id="pageSize"><option ${s.page_size === 'A4' ? 'selected' : ''}>A4</option><option ${s.page_size === 'Letter' ? 'selected' : ''}>Letter</option><option ${s.page_size === 'Legal' ? 'selected' : ''}>Legal</option></select></label><label>Margins (mm)<input id="pageMargin" type="number" min="0" max="50" value="${esc(s.page_margin_mm)}"></label><label>Header<input id="headerText" value="${esc(s.header_text)}" maxlength="160"></label><label>Footer<input id="footerText" value="${esc(s.footer_text)}" maxlength="200"></label><label>Class Teacher<input id="teacherName" value="${esc(s.teacher_name)}" maxlength="120"></label><label>Principal<input id="principalName" value="${esc(s.principal_name)}" maxlength="120"></label></div><button id="savePrintSettings">Save settings</button></details>`;
  $('savePrintSettings').onclick = saveSettings;
  $('theme').onchange = () => { state.data.settings.theme = $('theme').value; applyTheme(); };
}
async function saveSettings() {
  const s = state.data.settings;
  const payload = { ...s, theme: $('theme').value, default_export: $('defaultExport').value, autosave_enabled: $('autosaveEnabled').checked ? 1 : 0, school_name: $('schoolName').value, school_address: $('schoolAddress').value, school_logo: $('schoolLogo').value, page_size: $('pageSize').value, page_margin_mm: Number($('pageMargin').value || 12), header_text: $('headerText').value, footer_text: $('footerText').value, teacher_name: $('teacherName').value, principal_name: $('principalName').value, subjects: state.data.subjects, remark_rules: s.remark_rules };
  await runAction('Saving settings…', async () => { state.data = await api('/api/settings', { method: 'POST', body: JSON.stringify(payload) }); applyTheme(); await refreshComputed(); setStatus('Settings saved'); render(); });
}
function preview(scope = 'class') { let url = '/api/print?scope=' + scope; const id = $('studentSelect').value; if (scope === 'student' && id) url += '&student_id=' + id; window.open(url, '_blank'); }
$('dialogClose').onclick = () => $('messageDialog').close();
$('search').oninput = async () => { state.q = $('search').value; await refreshComputed(); render(); };
$('sortBy').onchange = async () => { state.sort = $('sortBy').value; await refreshComputed(); render(); };
$('sortDir').onclick = async () => { state.dir = state.dir === 'asc' ? 'desc' : 'asc'; $('sortDir').textContent = state.dir === 'asc' ? 'Asc' : 'Desc'; await refreshComputed(); render(); };
document.querySelectorAll('.tab').forEach(b => b.onclick = () => { state.view = b.dataset.view; render(); });
$('printClass').onclick = () => preview('class');
$('printStudent').onclick = () => preview('student');
$('exportExcel').onclick = () => { location.href = state.data?.settings?.default_export === 'pdf' ? '/api/export/report.pdf' : '/api/export/report.xlsx'; };
$('backupDb').onclick = () => { location.href = '/api/backup'; };
document.addEventListener('keydown', e => { if ((e.ctrlKey || e.metaKey) && e.key === '/') { e.preventDefault(); $('search').focus(); } });
load();
