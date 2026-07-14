from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs
import json, sqlite3, os, re

DB_PATH = os.environ.get('RESULTMASTER_DB', 'resultmaster.sqlite3')
SUBJECTS = ['English', 'Hindi', 'Mathematics', 'Science', 'SST']
TABS = SUBJECTS + ['Summary', 'Final']
COMPONENTS = ['FA1', 'Notebook', 'Project', 'Half Yearly']
MAX_MARK = 100


def db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute('PRAGMA foreign_keys = ON')
    conn.executescript('''
    CREATE TABLE IF NOT EXISTS students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        roll_no TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        position INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS marks (
        student_id INTEGER NOT NULL,
        subject TEXT NOT NULL,
        component TEXT NOT NULL,
        value TEXT NOT NULL,
        PRIMARY KEY (student_id, subject, component),
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
    );
    ''')
    if conn.execute('SELECT COUNT(*) FROM students').fetchone()[0] == 0:
        for idx, (roll, name) in enumerate([('101','Aarav Sharma'),('102','Diya Singh'),('103','Kabir Verma'),('104','Ananya Gupta'),('105','Rohan Mehta')], 1):
            conn.execute('INSERT INTO students (roll_no, name, position) VALUES (?, ?, ?)', (roll, name, idx))
        conn.commit()
    return conn


def valid_mark(value):
    v = str(value).strip().upper()
    if v == '': return ''
    if v == 'AB': return 'AB'
    if not re.fullmatch(r'\d{1,3}', v): raise ValueError('Marks must be 0-100 or AB.')
    n = int(v)
    if n < 0 or n > MAX_MARK: raise ValueError('Marks cannot be negative or exceed 100.')
    return str(n)


def total_for(row):
    total = 0
    absent = False
    for c in COMPONENTS:
        v = row.get(c, '')
        if v == 'AB': absent = True
        elif v != '': total += int(v)
    return 'AB' if absent and total == 0 else str(total)


def workbook(conn, q=''):
    q = q.strip().lower()
    students = conn.execute('SELECT * FROM students ORDER BY position, id').fetchall()
    ids = [s['id'] for s in students]
    marks = {}
    if ids:
        for r in conn.execute('SELECT * FROM marks'):
            marks[(r['student_id'], r['subject'], r['component'])] = r['value']
    out = []
    serial = 0
    for s in students:
        if q and q not in s['roll_no'].lower() and q not in s['name'].lower():
            continue
        serial += 1
        subjects = {}
        for subj in SUBJECTS:
            vals = {c: marks.get((s['id'], subj, c), '') for c in COMPONENTS}
            vals['TOTAL'] = total_for(vals)
            subjects[subj] = vals
        out.append({'id': s['id'], 'serial': serial, 'roll_no': s['roll_no'], 'name': s['name'], 'subjects': subjects})
    return {'tabs': TABS, 'subjects': SUBJECTS, 'components': COMPONENTS, 'students': out}


class Handler(BaseHTTPRequestHandler):
    def send(self, code, payload):
        data = json.dumps(payload).encode()
        self.send_response(code); self.send_header('Content-Type','application/json'); self.send_header('Content-Length',str(len(data))); self.end_headers(); self.wfile.write(data)
    def do_GET(self):
        p = urlparse(self.path)
        if p.path == '/api/workbook':
            with db() as conn: self.send(200, workbook(conn, parse_qs(p.query).get('q',[''])[0]))
        elif p.path in ('/', '/index.html'):
            data = open('static/index.html','rb').read(); self.send_response(200); self.send_header('Content-Type','text/html'); self.send_header('Content-Length',str(len(data))); self.end_headers(); self.wfile.write(data)
        elif p.path == '/static/app.css':
            data = open('static/app.css','rb').read(); self.send_response(200); self.send_header('Content-Type','text/css'); self.send_header('Content-Length',str(len(data))); self.end_headers(); self.wfile.write(data)
        elif p.path == '/static/app.js':
            data = open('static/app.js','rb').read(); self.send_response(200); self.send_header('Content-Type','application/javascript'); self.send_header('Content-Length',str(len(data))); self.end_headers(); self.wfile.write(data)
        else: self.send(404, {'error':'Not found'})
    def do_POST(self):
        length = int(self.headers.get('Content-Length','0'))
        body = json.loads(self.rfile.read(length) or b'{}')
        try:
            with db() as conn:
                if self.path == '/api/students':
                    roll = str(body.get('roll_no','')).strip(); name = str(body.get('name','')).strip()
                    if not roll or not name: raise ValueError('Roll number and name are required.')
                    pos = conn.execute('SELECT COALESCE(MAX(position),0)+1 FROM students').fetchone()[0]
                    conn.execute('INSERT INTO students (roll_no,name,position) VALUES (?,?,?)',(roll,name,pos)); conn.commit(); self.send(200, workbook(conn)); return
                if self.path == '/api/marks':
                    sid = int(body['student_id']); subj = body['subject']; comp = body['component']
                    if subj not in SUBJECTS or comp not in COMPONENTS: raise ValueError('Invalid mark cell.')
                    val = valid_mark(body.get('value',''))
                    if val == '': conn.execute('DELETE FROM marks WHERE student_id=? AND subject=? AND component=?',(sid,subj,comp))
                    else: conn.execute('INSERT OR REPLACE INTO marks VALUES (?,?,?,?)',(sid,subj,comp,val))
                    conn.commit(); self.send(200, workbook(conn)); return
            self.send(404, {'error':'Not found'})
        except sqlite3.IntegrityError: self.send(400, {'error':'Duplicate roll numbers are not allowed.'})
        except Exception as e: self.send(400, {'error':str(e)})
    def do_PUT(self):
        body = json.loads(self.rfile.read(int(self.headers.get('Content-Length','0'))) or b'{}')
        try:
            sid = int(self.path.rsplit('/',1)[-1]); roll=str(body.get('roll_no','')).strip(); name=str(body.get('name','')).strip()
            if not roll or not name: raise ValueError('Roll number and name are required.')
            with db() as conn:
                conn.execute('UPDATE students SET roll_no=?, name=? WHERE id=?',(roll,name,sid)); conn.commit(); self.send(200, workbook(conn))
        except sqlite3.IntegrityError: self.send(400, {'error':'Duplicate roll numbers are not allowed.'})
        except Exception as e: self.send(400, {'error':str(e)})
    def do_DELETE(self):
        try:
            sid = int(self.path.rsplit('/',1)[-1])
            with db() as conn:
                conn.execute('DELETE FROM students WHERE id=?',(sid,))
                rows = conn.execute('SELECT id FROM students ORDER BY position,id').fetchall()
                for i,r in enumerate(rows,1): conn.execute('UPDATE students SET position=? WHERE id=?',(i,r['id']))
                conn.commit(); self.send(200, workbook(conn))
        except Exception as e: self.send(400, {'error':str(e)})

if __name__ == '__main__':
    db().close()
    print('ResultMaster running at http://127.0.0.1:8000')
    ThreadingHTTPServer(('127.0.0.1', 8000), Handler).serve_forever()
