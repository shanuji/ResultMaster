let state = null;
let dashboard = null;
let summaryRows = [];
const DEFAULT_SCORE_BANDS = [{min:90,label:"A+"},{min:75,label:"A"},{min:60,label:"B"},{min:40,label:"C"},{min:0,label:"D"}];
const $ = (selector) => document.querySelector(selector);

async function loadWorkbook() {
  state = await fetch('/api/workbook').then(r => r.json());
  dashboard = await fetch('/api/dashboard').then(r => r.json());
  renderDashboard();
  renderMarks();
  renderSettings();
  calculateAndRenderSummary();
}

function markValue(studentId, subjectId) {
  return state.marks.find(m => m.student_id === studentId && m.subject_id === subjectId)?.marks ?? 0;
}

function renderMarks() {
  const table = $('#marks-table');
  const heads = ['S.No.', 'Roll No.', 'Student Name', ...state.subjects.map(s => s.name), 'Grand Total', 'Percentage', 'Result', 'Rank'];
  table.innerHTML = `<thead><tr>${heads.map(h => `<th>${h}</th>`).join('')}</tr></thead><tbody></tbody>`;
  const body = table.querySelector('tbody');
  const currentSummary = calculateSummary();
  state.students.forEach((student, index) => {
    const rowSummary = currentSummary.find(r => r.student_id === student.id);
    const tr = document.createElement('tr');
    tr.innerHTML = `<td>${index + 1}</td><td>${student.roll_no}</td><td>${student.name}</td>` +
      state.subjects.map(subject => `<td><input type="number" min="0" max="${state.settings.max_marks}" step="0.01" value="${markValue(student.id, subject.id)}" data-student="${student.id}" data-subject="${subject.id}"></td>`).join('') +
      `<td class="number">${fmt(rowSummary.grand_total)}</td><td class="number">${rowSummary.percentage.toFixed(2)}</td><td class="${rowSummary.result.toLowerCase()}">${rowSummary.result}</td><td class="number">${rowSummary.rank}</td>`;
    body.appendChild(tr);
  });
  table.querySelectorAll('input').forEach(input => input.addEventListener('input', onMarkChange));
}

async function onMarkChange(event) {
  const input = event.target;
  const marks = Number(input.value || 0);
  const student_id = Number(input.dataset.student);
  const subject_id = Number(input.dataset.subject);
  const existing = state.marks.find(m => m.student_id === student_id && m.subject_id === subject_id);
  if (existing) existing.marks = marks; else state.marks.push({student_id, subject_id, marks});
  $('#save-state').textContent = 'Saving...';
  renderMarks();
  calculateAndRenderSummary();
  state = await fetch('/api/marks', {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({student_id, subject_id, marks})}).then(r => r.json());
  $('#save-state').textContent = 'Autosaved';
  renderMarks();
  calculateAndRenderSummary();
}

function calculateSummary() {
  const percentageSubjects = state.subjects.filter(subject => Number(subject.include_percentage));
  const passFailSubjects = state.subjects.filter(subject => Number(subject.include_pass_fail));
  const maxTotal = percentageSubjects.length * Number(state.settings.max_marks || 0);
  const rows = state.students.map((student, idx) => {
    const subjects = Object.fromEntries(state.subjects.map(subject => [subject.name, Number(markValue(student.id, subject.id) || 0)]));
    const grand_total = percentageSubjects.reduce((sum, subject) => sum + subjects[subject.name], 0);
    const percentage = maxTotal ? Math.round((grand_total / maxTotal * 100) * 100) / 100 : 0;
    const result = passFailSubjects.every(subject => subjects[subject.name] >= Number(state.settings.pass_marks)) ? 'PASS' : 'FAIL';
    return {student_id: student.id, sno: idx + 1, roll_no: student.roll_no, student_name: student.name, subjects, grand_total, percentage, result, rank: 0, remarks: remarkFor(percentage), score_band: scoreBandFor(percentage)};
function configuredSubjects() {
  return state.subjects.filter(subject => subject.configured !== false);
}

function subjectMark(studentId, subject) {
  return Number(markValue(studentId, subject.id) || 0);
}

function subjectMax(subject) {
  return Number(subject.max_marks ?? state.settings.max_marks ?? 0);
}

function isIncluded(subject, field) {
  return subject[field] !== false && subject[field] !== 0;
}

function calculateResultRows() {
  const subjects = configuredSubjects();
  const percentageSubjects = subjects.filter(subject => isIncluded(subject, 'include_in_percentage'));
  const passFailSubjects = subjects.filter(subject => isIncluded(subject, 'include_in_pass_fail'));
  const maximum_marks = percentageSubjects.reduce((total, subject) => total + subjectMax(subject), 0);
  const rows = state.students.map((student, idx) => {
    const subject_totals = Object.fromEntries(subjects.map(subject => [subject.name, subjectMark(student.id, subject)]));
    const grand_total = percentageSubjects.reduce((total, subject) => total + subjectMark(student.id, subject), 0);
    const percentage = maximum_marks ? Math.round((grand_total / maximum_marks * 100) * 100) / 100 : 0;
    const result = passFailSubjects.every(subject => subjectMark(student.id, subject) >= Number(subject.pass_marks ?? state.settings.pass_marks ?? 0)) ? 'PASS' : 'FAIL';
    return {student_id: student.id, sno: idx + 1, roll_no: student.roll_no, student_name: student.name, subjects: subject_totals, grand_total, maximum_marks, percentage, result, rank: 0, remarks: remarkFor(percentage)};
  });
  [...rows].sort((a,b) => b.grand_total - a.grand_total || a.student_name.localeCompare(b.student_name)).forEach((row, index, sorted) => {
    row.rank = index && row.grand_total === sorted[index - 1].grand_total ? sorted[index - 1].rank : index + 1;
  });
  return rows;
}

function calculateSummary() {
  return calculateResultRows();
}

function remarkFor(percentage) {
  return [...state.settings.remark_rules].sort((a,b) => Number(b.min) - Number(a.min)).find(rule => percentage >= Number(rule.min))?.remark || '';
}

function scoreBandFor(percentage) {
  return [...(state.settings.score_bands || DEFAULT_SCORE_BANDS)].sort((a,b) => Number(b.min) - Number(a.min)).find(band => percentage >= Number(band.min))?.label || '';
}

function renderDashboard() {
  const query = ($('#dashboard-search')?.value || '').toLowerCase();
  const status = $('#dashboard-status')?.value || '';
  const container = $('#dashboard-groups');
  if (!container || !dashboard) return;
  container.innerHTML = dashboard.groups.map(group => {
    const exams = group.examinations.map(exam => {
      const cards = exam.workbooks.filter(w => (!query || `${w.class_name} ${w.examination_name}`.toLowerCase().includes(query)) && (!status || w.status === status));
      if (!cards.length) return '';
      return `<article class="exam-group"><h3>${exam.examination_name}</h3><div class="workbook-cards">${cards.map(w => `<div class="workbook-card"><div><strong>${w.class_name}-${w.section}</strong><span>${w.academic_year}</span></div><span class="status-pill ${w.status.toLowerCase().replaceAll(' ','-')}">${w.status}</span><progress max="100" value="${w.progress}"></progress><div>${w.progress.toFixed(2)}% complete · ${w.student_count} students · ${w.subject_count} subjects</div></div>`).join('')}</div></article>`;
    }).join('');
    return exams ? `<section class="class-group"><h2>${group.class_name}</h2>${exams}</section>` : '';
  }).join('') || '<p class="empty">No workbooks match the current filters.</p>';
}

function calculateAndRenderSummary() {
  summaryRows = calculateSummary();
  renderSummary();
  renderFinalSheet();
}

function renderSummary() {
  const query = $('#search')?.value?.toLowerCase() || '';
  const sort = $('#sort')?.value || 'roll_no';
  const rows = summaryRows.filter(r => r.roll_no.toLowerCase().includes(query) || r.student_name.toLowerCase().includes(query)).sort((a,b) => {
    if (['grand_total','rank','percentage'].includes(sort)) return Number(a[sort]) - Number(b[sort]);
    return String(a[sort]).localeCompare(String(b[sort]), undefined, {numeric:true});
  });
  if (sort === 'grand_total' || sort === 'percentage') rows.reverse();
  const subjects = configuredSubjects();
  const heads = ['S.No.', 'Roll No.', 'Student Name', ...subjects.map(s => s.name), 'Grand Total', 'Maximum Marks', 'Percentage', 'Result', 'Rank', 'Remarks'];
  $('#summary-table').innerHTML = `<thead><tr>${heads.map(h => `<th>${h}</th>`).join('')}</tr></thead><tbody>${rows.map(row => `<tr><td>${row.sno}</td><td>${row.roll_no}</td><td>${row.student_name}</td>${subjects.map(s => `<td class="number">${fmt(row.subjects[s.name])}</td>`).join('')}<td class="number">${fmt(row.grand_total)}</td><td class="number">${fmt(row.maximum_marks)}</td><td class="number">${row.percentage.toFixed(2)}</td><td class="${row.result.toLowerCase()}">${row.result}</td><td class="number">${row.rank}</td><td>${row.remarks}</td></tr>`).join('')}</tbody>`;
}

function renderFinalSheet() {
  const rows = calculateResultRows();
  const subjects = configuredSubjects();
  const heads = ['S.No.', 'Roll No.', 'Student Name', ...subjects.map(s => s.name), 'Total Marks', 'Maximum Marks', 'Percentage', 'Pass / Fail', 'Remarks'];
  $('#final-table').innerHTML = `<thead><tr>${heads.map(h => `<th>${h}</th>`).join('')}</tr></thead><tbody>${rows.map(row => `<tr><td>${row.sno}</td><td>${row.roll_no}</td><td>${row.student_name}</td>${subjects.map(s => `<td class="number">${fmt(row.subjects[s.name])}</td>`).join('')}<td class="number">${fmt(row.grand_total)}</td><td class="number">${fmt(row.maximum_marks)}</td><td class="number">${row.percentage.toFixed(2)}</td><td class="${row.result.toLowerCase()}">${row.result}</td><td>${row.remarks}</td></tr>`).join('')}</tbody>`;
}

function renderSettings() {
  $('#pass-marks').value = state.settings.pass_marks;
  $('#max-marks').value = state.settings.max_marks;
  $('#distinction-percentage').value = state.settings.distinction_percentage || 75;
  $('#qi-basis').value = state.settings.qi_basis || 'appeared';
  $('#score-bands').innerHTML = (state.settings.score_bands || DEFAULT_SCORE_BANDS).map((band, index) => `<div class="rule"><label>Min % <input type="number" step="0.01" value="${band.min}" data-band="${index}" data-field="min"></label><label>Band <input value="${band.label}" data-band="${index}" data-field="label"></label></div>`).join('');
  $('#subject-rules').innerHTML = state.subjects.map(subject => `<div class="subject-rule"><strong>${subject.name}</strong><label><input type="checkbox" data-subject="${subject.id}" data-field="include_pass_fail" ${Number(subject.include_pass_fail) ? 'checked' : ''}> Include in Pass/Fail</label><label><input type="checkbox" data-subject="${subject.id}" data-field="include_percentage" ${Number(subject.include_percentage) ? 'checked' : ''}> Include in Percentage</label></div>`).join('');
  $('#remark-rules').innerHTML = state.settings.remark_rules.map((rule, index) => `<div class="rule"><label>Min % <input type="number" step="0.01" value="${rule.min}" data-rule="${index}" data-field="min"></label><label>Remark <input value="${rule.remark}" data-rule="${index}" data-field="remark"></label></div>`).join('');
  $('#settings').querySelectorAll('input,select').forEach(input => input.addEventListener('input', saveSettings));
  $('#restore-bands').onclick = () => { state.settings.score_bands = DEFAULT_SCORE_BANDS.map(b => ({...b})); renderSettings(); saveSettings(); };
}

async function saveSettings() {
  state.settings.pass_marks = Number($('#pass-marks').value || 0);
  state.settings.max_marks = Number($('#max-marks').value || 1);
  state.settings.distinction_percentage = Number($('#distinction-percentage').value || 75);
  state.settings.qi_basis = $('#qi-basis').value;
  $('#score-bands').querySelectorAll('input').forEach(input => state.settings.score_bands[Number(input.dataset.band)][input.dataset.field] = input.dataset.field === 'min' ? Number(input.value || 0) : input.value);
  $('#subject-rules').querySelectorAll('input').forEach(input => { const subject = state.subjects.find(s => s.id === Number(input.dataset.subject)); subject[input.dataset.field] = input.checked ? 1 : 0; });
  $('#remark-rules').querySelectorAll('input').forEach(input => state.settings.remark_rules[Number(input.dataset.rule)][input.dataset.field] = input.dataset.field === 'min' ? Number(input.value || 0) : input.value);
  renderMarks();
  calculateAndRenderSummary();
  state = await fetch('/api/settings', {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({...state.settings, subjects: state.subjects})}).then(r => r.json());
}

function fmt(value) { return Number.isInteger(value) ? value : Number(value).toFixed(2); }

document.querySelectorAll('.tab').forEach(tab => tab.addEventListener('click', () => {
  document.querySelectorAll('.tab,.panel').forEach(el => el.classList.remove('active'));
  tab.classList.add('active');
  $('#' + tab.dataset.tab).classList.add('active');
}));
$('#search').addEventListener('input', renderSummary);
$('#dashboard-search').addEventListener('input', renderDashboard);
$('#dashboard-status').addEventListener('change', renderDashboard);
$('#sort').addEventListener('change', renderSummary);
loadWorkbook();
