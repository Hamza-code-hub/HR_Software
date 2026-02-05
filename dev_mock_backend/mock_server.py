from wsgiref.simple_server import make_server
from urllib.parse import parse_qs, urlparse
import json
import uuid
from datetime import datetime, timedelta

EMPLOYEES = {}
PAYROLL_RUNS = {}

def json_response(start_response, data, status='200 OK', content_type='application/json'):
    body = json.dumps(data).encode('utf-8')
    start_response(status, [('Content-Type', content_type), ('Content-Length', str(len(body)) )])
    return [body]

def pdf_response(start_response, data_bytes, status='200 OK'):
    start_response(status, [('Content-Type', 'application/pdf'), ('Content-Length', str(len(data_bytes)) )])
    return [data_bytes]

def now_plus_minutes(m=15):
    return (datetime.utcnow() + timedelta(minutes=m)).isoformat() + 'Z'

def handle_auth(environ, start_response):
    method = environ['REQUEST_METHOD']
    if method != 'POST':
        return json_response(start_response, {'error': 'method not allowed'}, '405 Method Not Allowed')
    length = int(environ.get('CONTENT_LENGTH') or 0)
    body = environ['wsgi.input'].read(length) if length else b'{}'
    try:
        data = json.loads(body.decode('utf-8'))
    except Exception:
        data = {}
    resp = {
        'access_token': 'mock-access-token',
        'refresh_token': 'mock-refresh-token',
        'expires_at': now_plus_minutes(60),
    }
    return json_response(start_response, resp)

def parse_path(path):
    parts = [p for p in path.split('/') if p]
    return parts

def application(environ, start_response):
    path = environ.get('PATH_INFO', '/')
    method = environ['REQUEST_METHOD']
    parts = parse_path(path)

    # Auth endpoints
    if path.startswith('/auth/'):
        return handle_auth(environ, start_response)

    # Simple permissive auth: accept any Bearer token
    # Employees
    if path == '/api/employees' and method == 'GET':
        return json_response(start_response, list(EMPLOYEES.values()))

    if path.startswith('/api/employees') and method == 'POST':
        length = int(environ.get('CONTENT_LENGTH') or 0)
        body = environ['wsgi.input'].read(length) if length else b'{}'
        data = json.loads(body.decode('utf-8')) if body else {}
        eid = str(uuid.uuid4())
        now = datetime.utcnow().isoformat() + 'Z'
        emp = {
            'id': eid,
            'tenant_id': 'mock-tenant',
            'name': data.get('name','Test Employee'),
            'email': data.get('email', None),
            'status': data.get('status','active'),
            'basic_salary': data.get('basic_salary', 1000.0),
            'created_at': now,
        }
        EMPLOYEES[eid] = emp
        return json_response(start_response, emp, '201 Created')

    # employee detail
    if len(parts) >= 2 and parts[0] == 'api' and parts[1] == 'employees':
        if len(parts) == 3:
            eid = parts[2]
            if method == 'GET':
                emp = EMPLOYEES.get(eid)
                if emp:
                    return json_response(start_response, emp)
                return json_response(start_response, {'error': 'not found'}, '404 Not Found')
            if method == 'PUT':
                length = int(environ.get('CONTENT_LENGTH') or 0)
                body = environ['wsgi.input'].read(length) if length else b'{}'
                data = json.loads(body.decode('utf-8')) if body else {}
                emp = EMPLOYEES.get(eid)
                if not emp:
                    return json_response(start_response, {'error':'not found'}, '404 Not Found')
                emp.update(data)
                EMPLOYEES[eid] = emp
                return json_response(start_response, emp)
            if method == 'DELETE':
                EMPLOYEES.pop(eid, None)
                return json_response(start_response, {}, '204 No Content')

    # Attendance
    if path == '/api/attendance' and method == 'GET':
        return json_response(start_response, [])
    if path == '/api/attendance/checkin' and method == 'POST':
        return json_response(start_response, {}, '200 OK')
    if path == '/api/attendance/checkout' and method == 'POST':
        return json_response(start_response, {}, '200 OK')

    # Payroll
    if path == '/api/payroll' and method == 'GET':
        return json_response(start_response, list(PAYROLL_RUNS.values()))
    if path == '/api/payroll/run' and method == 'POST':
        length = int(environ.get('CONTENT_LENGTH') or 0)
        body = environ['wsgi.input'].read(length) if length else b'{}'
        data = json.loads(body.decode('utf-8')) if body else {}
        rid = str(uuid.uuid4())
        run = {
            'id': rid,
            'tenant_id': 'mock-tenant',
            'month': data.get('month', 1),
            'year': data.get('year', 2025),
            'status': 'completed',
            'created_at': datetime.utcnow().isoformat() + 'Z',
        }
        PAYROLL_RUNS[rid] = run
        return json_response(start_response, run, '201 Created')
    if path == '/api/payroll/lock' and method == 'POST':
        return json_response(start_response, {}, '200 OK')
    # list payslips
    if len(parts) >= 3 and parts[0] == 'api' and parts[1] == 'payroll' and parts[-1] == 'payslips':
        # return a sample payslip list
        run_id = parts[2]
        payslip = {
            'id': str(uuid.uuid4()),
            'tenant_id': 'mock-tenant',
            'payroll_run_id': run_id,
            'employee_id': next(iter(EMPLOYEES.keys()), 'emp-1'),
            'basic_salary': 1000.0,
            'gross_salary': 1200.0,
            'tax': 100.0,
            'net_salary': 1100.0,
        }
        return json_response(start_response, [payslip])

    # payslip pdf
    if len(parts) == 2 and parts[0] == 'payslips' and parts[1] and path.endswith('/pdf'):
        # return minimal PDF bytes (not a valid PDF but enough for testing)
        pdf_bytes = b'%PDF-1.4\n%Mock PDF\n'
        return pdf_response(start_response, pdf_bytes)

    return json_response(start_response, {'error': 'not implemented'}, '404 Not Found')

if __name__ == '__main__':
    # seed a couple employees
    for i in range(1,3):
        eid = str(uuid.uuid4())
        EMPLOYEES[eid] = {
            'id': eid,
            'tenant_id': 'mock-tenant',
            'name': f'Test Employee {i}',
            'email': f'employee{i}@example.com',
            'status': 'active',
            'basic_salary': 1000.0 * i,
            'created_at': datetime.utcnow().isoformat() + 'Z',
        }

    port = 3000
    print(f"Mock backend listening on http://localhost:{port}")
    with make_server('', port, application) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print('Shutting down')
