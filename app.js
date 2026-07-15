let state = null;
let summaryRows = [];
const $ = (selector) => document.querySelector(selector);

async function loadWorkbook() {
  state = await fetch('/api/workbook').then(r => r.json());
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
  $('#remark-rules').innerHTML = state.settings.remark_rules.map((rule, index) => `<div class="rule"><label>Min % <input type="number" step="0.01" value="${rule.min}" data-rule="${index}" data-field="min"></label><label>Remark <input value="${rule.remark}" data-rule="${index}" data-field="remark"></label></div>`).join('');
  $('#settings').querySelectorAll('input').forEach(input => input.addEventListener('input', saveSettings));
}

async function saveSettings() {
  state.settings.pass_marks = Number($('#pass-marks').value || 0);
  state.settings.max_marks = Number($('#max-marks').value || 1);
  $('#remark-rules').querySelectorAll('input').forEach(input => state.settings.remark_rules[Number(input.dataset.rule)][input.dataset.field] = input.dataset.field === 'min' ? Number(input.value || 0) : input.value);
  renderMarks();
  calculateAndRenderSummary();
  state = await fetch('/api/settings', {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(state.settings)}).then(r => r.json());
}

function fmt(value) { return Number.isInteger(value) ? value : Number(value).toFixed(2); }

document.querySelectorAll('.tab').forEach(tab => tab.addEventListener('click', () => {
  document.querySelectorAll('.tab,.panel').forEach(el => el.classList.remove('active'));
  tab.classList.add('active');
  $('#' + tab.dataset.tab).classList.add('active');
}));
$('#search').addEventListener('input', renderSummary);
$('#sort').addEventListener('change', renderSummary);
loadWorkbook();
