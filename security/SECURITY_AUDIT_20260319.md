# CFL Security Audit — greenvic-control-fletes

**Date:** 2026-03-19
**Auditor:** Automated SAST + Manual Code Review
**Standard:** OWASP Top 10 2021, CWE, SANS Top 25
**Scope:** `cfl-back`, `cfl-front-ng`, `cfl-infra` (full monorepo)

---

## Executive Summary

**Overall Risk Rating: CRITICAL**

The audit identified **30 findings** across the entire stack:

| Severity | Count |
|----------|-------|
| CRITICAL | 5     |
| HIGH     | 10    |
| MEDIUM   | 10    |
| LOW      | 5     |

The most urgent issues are:
1. **Privilege escalation** via client-supplied HTTP headers in the authorization middleware
2. **Hardcoded JWT fallback secret** that allows token forgery if env var is unset
3. **SQL Server port exposed to all network interfaces** with known default credentials
4. **SA password visible in process arguments** inside containers
5. **Database connection encryption disabled** — credentials and data travel in plaintext

---

## Findings

---

### CRITICAL-01 — Authorization Bypass via Client-Supplied Headers

**Category:** OWASP A01 (Broken Access Control) / CWE-285 (Improper Authorization)
**Location:** `cfl-back/src/authz.js:165-201`

**Description:** The `resolveAuthzContext()` function first attempts to resolve authorization from JWT claims (lines 166-171). If the JWT-authenticated user has no matching role/user in the database, it **falls through** to reading `x-cfl-role`, `x-cfl-user-id`, and `x-cfl-username` from request headers and query parameters. An attacker with a valid low-privilege JWT can inject `x-cfl-role: Administrador` to escalate to any role.

**Evidence:**
```javascript
// authz.js:174-186 — Fallback after JWT lookup fails
const roleName = normalizeText(
  req.header("x-cfl-role") || req.header("x-user-role") || req.query.role
);
const userId = normalizeText(
  req.header("x-cfl-user-id") || req.header("x-user-id") || req.query.user_id
);
```

The frontend interceptor (`authn.interceptor.ts:19`) actively sends this header:
```typescript
if (user?.role) {
  headers['x-cfl-role'] = user.role;
}
```

**Remediation:**
1. Remove the header/query fallback entirely from `resolveAuthzContext()`. Authorization context must come exclusively from the verified JWT claims.
2. Remove `x-cfl-role` header injection from the frontend interceptor.
3. If a JWT-authenticated user has no DB record, return `null` (deny access) — never fall through to untrusted inputs.

**Effort:** Low

---

### CRITICAL-02 — Hardcoded Default JWT Secret

**Category:** OWASP A02 (Cryptographic Failures) / CWE-798 (Use of Hard-coded Credentials)
**Location:** `cfl-back/src/config.js:5, 72`

**Description:** A default JWT secret `"cfl-dev-secret"` is hardcoded. If `AUTHN_JWT_SECRET` env var is unset, the app uses this value. In production, only a `console.error` is emitted — the process does not crash.

**Evidence:**
```javascript
const DEFAULT_AUTHN_JWT_SECRET = "cfl-dev-secret";
// ...
jwtSecret: process.env.AUTHN_JWT_SECRET || DEFAULT_AUTHN_JWT_SECRET,
```

**Remediation:**
1. Replace fallback with a hard crash: `process.env.AUTHN_JWT_SECRET || (process.exit(1))` or throw an error.
2. Use a cryptographically random secret of at least 256 bits (64 hex chars).
3. Rotate the current production secret since the source code is the de facto documentation of the fallback.

**Effort:** Low

---

### CRITICAL-03 — SQL Server Port Exposed to All Network Interfaces

**Category:** OWASP A05 (Security Misconfiguration) / CWE-668 (Exposure of Resource to Wrong Sphere)
**Location:** `cfl-infra/docker-compose.yml:114-115`

**Description:** SQL Server port 1433 is bound to `0.0.0.0`, making it accessible from any network interface. Combined with known default credentials (`ChangeThisStrongPass!123`), this allows direct database access from the network.

**Evidence:**
```yaml
ports:
  - "${MSSQL_PORT:-1433}:1433"
```

**Remediation:**
1. Bind to localhost only: `"127.0.0.1:${MSSQL_PORT:-1433}:1433"`
2. For inter-container access, use Docker networks (already configured) without port mapping.

**Effort:** Low

---

### CRITICAL-04 — SA Password Exposed in Process Arguments

**Category:** OWASP A02 (Cryptographic Failures) / CWE-214 (Invocation of Process Using Visible Sensitive Information)
**Location:** `cfl-infra/scripts/init-db.sh:45,51,57,62,65` and `cfl-infra/docker-compose.yml:129`

**Description:** The SQL Server SA password is passed via the `-P` command-line flag to `sqlcmd`. Anyone with access to `ps aux` or `docker top` can see the password in process arguments. The healthcheck also embeds the password.

**Evidence:**
```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" ...
```
```yaml
healthcheck:
  test: /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$$MSSQL_SA_PASSWORD" ...
```

**Remediation:**
1. Use `SQLCMDPASSWORD` environment variable instead of the `-P` flag.
2. For healthcheck, use a dedicated low-privilege health user or TCP connect check.

**Effort:** Low

---

### CRITICAL-05 — Hardcoded Default Credentials in Docker Compose

**Category:** OWASP A07 (Identification and Authentication Failures) / CWE-798
**Location:** `cfl-infra/docker-compose.yml:79,83` and `cfl-infra/.env.example:4,13,23`

**Description:** Docker Compose uses `${VAR:-default}` syntax with real-looking passwords as defaults. If `.env` is missing, services start with known weak credentials.

**Evidence:**
```yaml
AUTHN_JWT_SECRET: ${AUTHN_JWT_SECRET:-replace-with-a-long-random-dev-secret}
DB_PASSWORD: ${DB_PASSWORD:-ChangeThisStrongPass!123}
```

**Remediation:**
1. Use `${VAR:?error_message}` syntax to force the variable to be set.
2. Remove all default fallback values for secrets.

**Effort:** Low

---

### HIGH-01 — Database Connection Encryption Disabled

**Category:** OWASP A02 (Cryptographic Failures) / CWE-319 (Cleartext Transmission)
**Location:** `cfl-back/src/db.js:85-88`

**Description:** Database connection encryption is explicitly disabled and certificate validation is bypassed. All DB traffic — including credentials and query data containing PII — travels in plaintext.

**Evidence:**
```javascript
options: {
  encrypt: false,
  trustServerCertificate: true,
}
```

**Remediation:**
1. Set `encrypt: true` and configure a valid TLS certificate for SQL Server.
2. Remove `trustServerCertificate: true` in production.

**Effort:** Medium

---

### HIGH-02 — CORS Defaults to Wildcard Origin

**Category:** OWASP A05 (Security Misconfiguration) / CWE-942 (Overly Permissive Cross-domain Whitelist)
**Location:** `cfl-back/src/config.js:69` and `cfl-back/src/app.js:26-30`

**Description:** If `CORS_ORIGIN` env var is not set, CORS allows all origins (`*`). Any website can make cross-origin requests to the API.

**Evidence:**
```javascript
corsOrigin: process.env.CORS_ORIGIN || "*"
// ...
cors({ origin: config.app.corsOrigin })
```

**Remediation:**
1. Remove the `*` default. Fail closed: if `CORS_ORIGIN` is unset, deny all cross-origin requests.
2. In production, set `CORS_ORIGIN` to the exact frontend origin.

**Effort:** Low

---

### HIGH-03 — Database Error Messages Exposed to Clients

**Category:** OWASP A04 (Insecure Design) / CWE-209 (Information Exposure Through an Error Message)
**Location:** `cfl-back/src/app.js:91-117`

**Description:** Raw `error.message` from database errors (mssql driver) is sent directly to API consumers. These messages contain table names, column names, constraint names, and SQL snippets.

**Evidence:**
```javascript
const message = error && error.message ? error.message : "Error interno del servidor";
res.status(code).json({ error: message });
```

**Remediation:**
1. Log the full error server-side.
2. Return generic error messages to clients: `"Error procesando la solicitud"`.
3. Map known DB error codes (2627, 2601, 547) to user-friendly messages without internal details.

**Effort:** Low

---

### HIGH-04 — cfl-back Container Runs as Root

**Category:** OWASP A05 (Security Misconfiguration) / CWE-250 (Execution with Unnecessary Privileges)
**Location:** `cfl-back/Dockerfile`

**Description:** No `USER` directive is set. The container runs as root by default. An attacker exploiting a vulnerability in the Node.js app gains root privileges in the container.

**Evidence:**
```dockerfile
FROM node:20-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 4000
CMD ["node", "src/index.js"]
```

**Remediation:**
```dockerfile
RUN groupadd -r app && useradd -r -g app -d /app app
RUN chown -R app:app /app
USER app
```

**Effort:** Low

---

### HIGH-05 — Base Images Not Pinned to Digests

**Category:** OWASP A08 (Software and Data Integrity Failures) / CWE-829 (Inclusion of Functionality from Untrusted Control Sphere)
**Location:** `cfl-back/Dockerfile:1`, `cfl-front-ng/Dockerfile:7,20`, `cfl-infra/Dockerfile:1`

**Description:** All Dockerfiles use floating tags (`node:20-slim`, `node:20-alpine`, `nginx:1.27-alpine`, `mssql/server:2022-latest`). A supply-chain attack on the tag could inject malicious code.

**Remediation:** Pin to specific SHA256 digests:
```dockerfile
FROM node:20-slim@sha256:<specific-digest>
```

**Effort:** Low

---

### HIGH-06 — No Resource Limits on Any Docker Service

**Category:** OWASP A05 (Security Misconfiguration) / CWE-770 (Allocation Without Limits)
**Location:** `cfl-infra/docker-compose.yml` (all services)

**Description:** None of the services have `deploy.resources.limits` for CPU or memory. A memory leak or denial-of-service could consume all host resources.

**Remediation:**
```yaml
deploy:
  resources:
    limits:
      memory: 512M
      cpus: '1.0'
```

**Effort:** Low

---

### HIGH-07 — Frontend Nginx Missing All Security Headers

**Category:** OWASP A05 (Security Misconfiguration) / CWE-693 (Protection Mechanism Failure)
**Location:** `cfl-front-ng/nginx.conf`

**Description:** The frontend nginx config has no security headers (`X-Content-Type-Options`, `X-Frame-Options`, `Content-Security-Policy`, `Referrer-Policy`, `Strict-Transport-Security`). Also `server_tokens` is not disabled, exposing the nginx version.

**Remediation:**
```nginx
server_tokens off;
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self'" always;
```

**Effort:** Low

---

### HIGH-08 — Client-Derived Role Header Sent to Backend

**Category:** OWASP A01 (Broken Access Control) / CWE-807 (Reliance on Untrusted Inputs)
**Location:** `cfl-front-ng/src/app/core/interceptors/authn.interceptor.ts:15-21`

**Description:** The frontend interceptor extracts the role from the client-decoded JWT and sends it as `x-cfl-role` header. Combined with CRITICAL-01, this creates a complete privilege escalation chain.

**Evidence:**
```typescript
if (user?.role) {
  headers['x-cfl-role'] = user.role;
}
```

**Remediation:** Remove the `x-cfl-role` header from the interceptor entirely. The backend must extract roles only from the verified JWT.

**Effort:** Low

---

### HIGH-09 — cfl-back dev docker-compose Mounts Entire Source Including Secrets

**Category:** OWASP A05 (Security Misconfiguration) / CWE-538 (Insertion of Sensitive Information into Externally-Accessible File)
**Location:** `cfl-back/docker-compose.yml:8-10`

**Description:** The entire cfl-back directory (including `.env`, `.git`) is mounted into the container. Port 4000 bound to all interfaces.

**Remediation:**
1. Use selective volume mounts (only `src/` and `package*.json`).
2. Bind port to `127.0.0.1:4000:4000`.

**Effort:** Low

---

### HIGH-10 — No TLS/HTTPS Configuration

**Category:** OWASP A02 (Cryptographic Failures) / CWE-319 (Cleartext Transmission)
**Location:** `cfl-infra/nginx/dev-gateway.conf:8`, `cfl-front-ng/nginx.conf:16`

**Description:** All traffic is served over plain HTTP. JWT tokens, credentials, and PII are transmitted in cleartext.

**Remediation:** Add TLS termination at the gateway level. Use Let's Encrypt or internal CA certificates. Required for any non-localhost deployment.

**Effort:** Medium

---

### MEDIUM-01 — JWT Algorithm Not Explicitly Specified

**Category:** OWASP A02 (Cryptographic Failures) / CWE-327 (Use of Broken Crypto Algorithm)
**Location:** `cfl-back/src/routes/authn.routes.js:96-98` and `cfl-back/src/middleware/authn.middleware.js:19`

**Description:** Neither `jwt.sign()` nor `jwt.verify()` specifies the `algorithm`/`algorithms` option. While jsonwebtoken v9 defaults to HS256 and mitigates `alg:none`, explicit pinning is defense-in-depth against algorithm confusion attacks.

**Remediation:**
```javascript
jwt.sign(payload, secret, { algorithm: 'HS256', expiresIn: '8h' });
jwt.verify(token, secret, { algorithms: ['HS256'] });
```

**Effort:** Low

---

### MEDIUM-02 — No Input Validation Library

**Category:** OWASP A03 (Injection) / CWE-20 (Improper Input Validation)
**Location:** All route files in `cfl-back/src/routes/`

**Description:** The project does not use `express-validator`, `joi`, `zod`, or any formal input validation library. All validation is manual inline checks, which is error-prone and inconsistent.

**Remediation:** Adopt `zod` or `express-validator` for all route inputs with centralized validation middleware.

**Effort:** Medium

---

### MEDIUM-03 — Rate Limiting Only on Login (In-Memory)

**Category:** OWASP A07 (Identification and Authentication Failures) / CWE-307 (Improper Restriction of Excessive Auth Attempts)
**Location:** `cfl-back/src/middleware/authn-login-rate-limit.middleware.js`

**Description:** Rate limiting exists only on `POST /api/authn/login` (10 attempts / 15 min). Implementation is in-memory (resets on restart, doesn't work across instances). No rate limiting on other API endpoints.

**Remediation:**
1. Use `express-rate-limit` with a Redis or DB-backed store.
2. Add rate limiting to all write endpoints.

**Effort:** Medium

---

### MEDIUM-04 — No Token Revocation Mechanism

**Category:** OWASP A07 / CWE-613 (Insufficient Session Expiration)
**Location:** System-wide

**Description:** There is no way to invalidate a JWT before its 8-hour expiration. No refresh token, no token blocklist. A stolen token or a deactivated user retains access for up to 8 hours.

**Remediation:**
1. Implement a token blocklist in Redis or DB.
2. Add refresh token rotation with short-lived access tokens (15-30 min).

**Effort:** High

---

### MEDIUM-05 — Health Endpoint Exposes Internal Error Details

**Category:** OWASP A04 (Insecure Design) / CWE-209
**Location:** `cfl-back/src/app.js:64`

**Description:** The `/health` endpoint is publicly accessible (no auth) and exposes the DB connection error message, potentially revealing connection strings, host names, or driver versions.

**Remediation:** Return only `{ status: "unhealthy" }` — log the full error server-side.

**Effort:** Low

---

### MEDIUM-06 — Missing Security Headers on Backend

**Category:** OWASP A05 (Security Misconfiguration) / CWE-693
**Location:** `cfl-back/src/app.js:18-24`

**Description:** Four security headers are set manually, but `Strict-Transport-Security`, `Content-Security-Policy`, `Permissions-Policy`, and `Cache-Control` are missing.

**Remediation:** Install and configure `helmet` middleware.

**Effort:** Low

---

### MEDIUM-07 — JWT Token Stored in localStorage

**Category:** OWASP A02 / CWE-922 (Insecure Storage of Sensitive Information)
**Location:** `cfl-front-ng/src/app/core/services/authn.service.ts:34,41,47`

**Description:** The JWT is stored in `localStorage`, which is accessible to any JavaScript on the page. If an XSS vulnerability is introduced, the token can be exfiltrated.

**Remediation:** Store the JWT in an HttpOnly, Secure, SameSite=Strict cookie set by the backend.

**Effort:** Medium

---

### MEDIUM-08 — No Role-Based Frontend Route Guards

**Category:** OWASP A01 / CWE-862 (Missing Authorization)
**Location:** `cfl-front-ng/src/app/core/guards/authn.guard.ts`

**Description:** The guard only checks if a token exists. Any authenticated user can navigate to any route including admin areas (`/mantenedores`, `/auditoria`).

**Remediation:** Add role-based guards that check the user's role before allowing access to sensitive routes.

**Effort:** Low

---

### MEDIUM-09 — Incomplete .dockerignore Files

**Category:** OWASP A05 / CWE-538
**Location:** `cfl-back/.dockerignore`, `cfl-infra/.dockerignore` (missing)

**Description:** `cfl-back/.dockerignore` only excludes `node_modules` and `npm-debug.log` — `.env`, `.git`, and `tests/` are not excluded. `cfl-infra` has no `.dockerignore` at all, so `.env` with secrets is sent to the Docker build context.

**Remediation:** Add comprehensive `.dockerignore` files:
```
.env*
.git/
docker-compose.yml
Dockerfile
*.md
tests/
.vscode/
```

**Effort:** Low

---

### MEDIUM-10 — Gateway Missing CSP and Rate Limiting

**Category:** OWASP A05 / CWE-693
**Location:** `cfl-infra/nginx/dev-gateway.conf`

**Description:** The gateway nginx sets `X-Content-Type-Options`, `X-Frame-Options`, and `Referrer-Policy` but is missing `Content-Security-Policy`, `Strict-Transport-Security`, and rate limiting (`limit_req`).

**Remediation:** Add CSP and `limit_req_zone`/`limit_req` directives.

**Effort:** Medium

---

### LOW-01 — Minimum Password Length Only 8 Characters, No Complexity

**Category:** OWASP A07 / CWE-521 (Weak Password Requirements)
**Location:** `cfl-back/src/routes/mantenedores.routes.js:991,1072`

**Description:** Only minimum length (8 chars) is enforced. No complexity requirements.

**Remediation:** Enforce minimum 12 characters with at least one uppercase, one number, and one special character. Consider checking against common password lists.

**Effort:** Low

---

### LOW-02 — cfl-back Dockerfile Sets NODE_ENV=development

**Category:** OWASP A05 / CWE-489 (Active Debug Code)
**Location:** `cfl-back/Dockerfile:10`

**Description:** `ENV NODE_ENV=development` baked into the image enables development-mode error verbosity.

**Remediation:** Remove `NODE_ENV` from the Dockerfile; pass it at runtime.

**Effort:** Low

---

### LOW-03 — Angular npm audit: 11 HIGH Vulnerabilities

**Category:** OWASP A06 (Vulnerable and Outdated Components) / CWE-1035
**Location:** `cfl-front-ng/package.json`

**Description:**
- `@angular/compiler` 21.2.2: XSS in i18n attribute bindings (GHSA-g93w-mfhg-p222)
- `undici` 7.x: Multiple CVEs (GHSA-f269-vfmq-vjvj, GHSA-2mjp-6q6p-2qxm, GHSA-vrm6-8vpv-qv8q, GHSA-v9p9-hfj2-hcw8, GHSA-4992-7rv2-5pvq, GHSA-phc3-fgpg-7m6h)

**Remediation:** Run `npm audit fix` to patch Angular and undici.

**Effort:** Low

---

### LOW-04 — Token Attached to All Outgoing HTTP Requests

**Category:** OWASP A01 / CWE-598 (Use of GET Request Method With Sensitive Query Strings)
**Location:** `cfl-front-ng/src/app/core/interceptors/authn.interceptor.ts`

**Description:** The interceptor attaches the Bearer token to every request without checking the URL. If external API calls are ever added, the JWT would leak.

**Remediation:** Add a URL whitelist check in the interceptor.

**Effort:** Low

---

### LOW-05 — No Read-Only Root Filesystem on Containers

**Category:** CWE-276 (Incorrect Default Permissions)
**Location:** `cfl-infra/docker-compose.yml`

**Description:** No services use `read_only: true` to limit container filesystem writes.

**Remediation:** Add `read_only: true` with explicit `tmpfs` mounts for writable paths.

**Effort:** Low

---

## Remediation Priority Matrix

| Priority | ID | Finding | Effort | Impact |
|----------|-----|---------|--------|--------|
| 1 | CRITICAL-01 | Authz bypass via client headers | Low | Privilege escalation |
| 2 | CRITICAL-02 | Hardcoded JWT secret fallback | Low | Token forgery |
| 3 | CRITICAL-03 | SQL Server port exposed to all interfaces | Low | Direct DB access |
| 4 | CRITICAL-04 | SA password in process args | Low | Credential theft |
| 5 | CRITICAL-05 | Default credentials in docker-compose | Low | Full system compromise |
| 6 | HIGH-02 | CORS wildcard default | Low | Cross-origin attacks |
| 7 | HIGH-03 | DB errors exposed to clients | Low | Information disclosure |
| 8 | HIGH-08 | Client-derived role header | Low | Escalation chain |
| 9 | HIGH-04 | Container runs as root | Low | Container escape |
| 10 | HIGH-05 | Unpinned base images | Low | Supply chain attack |
| 11 | HIGH-07 | Frontend nginx no security headers | Low | XSS/clickjacking |
| 12 | HIGH-01 | DB encryption disabled | Medium | Data interception |
| 13 | HIGH-06 | No container resource limits | Low | DoS |
| 14 | HIGH-09 | Source mount exposes secrets | Low | Secret leakage |
| 15 | HIGH-10 | No TLS/HTTPS | Medium | Cleartext credentials |
| 16 | MEDIUM-01 | JWT algorithm not pinned | Low | Algorithm confusion |
| 17 | MEDIUM-06 | Missing helmet/headers on backend | Low | Header-based attacks |
| 18 | MEDIUM-05 | Health endpoint info leak | Low | Reconnaissance |
| 19 | MEDIUM-08 | No role-based route guards | Low | UX/attack surface |
| 20 | MEDIUM-09 | Incomplete .dockerignore | Low | Secret in build context |
| 21 | MEDIUM-07 | JWT in localStorage | Medium | XSS token theft |
| 22 | MEDIUM-02 | No input validation library | Medium | Input-related bugs |
| 23 | MEDIUM-03 | In-memory rate limiting only | Medium | Brute force |
| 24 | MEDIUM-10 | Gateway missing CSP/rate limit | Medium | Various |
| 25 | MEDIUM-04 | No token revocation | High | Stolen token abuse |
| 26 | LOW-03 | Angular npm vulnerabilities | Low | Known CVEs |
| 27 | LOW-01 | Weak password policy | Low | Credential guessing |
| 28 | LOW-02 | NODE_ENV=development in image | Low | Verbose errors |
| 29 | LOW-04 | Token on all requests | Low | Token leakage |
| 30 | LOW-05 | No read-only filesystem | Low | Container hardening |

---

## Positive Findings (What's Done Right)

- All SQL queries use parameterized inputs via mssql `.input()` — **no SQL injection found**.
- bcryptjs with 12 rounds for password hashing.
- No `bypassSecurityTrust*`, `innerHTML`, `eval`, or `DomSanitizer` in the Angular frontend.
- `.env` files are properly gitignored and never committed to version control.
- Express JSON body limit set to 1MB.
- No file upload endpoints (reduced attack surface).
- Rate limiting present on login endpoint (even if basic).
- 4 security headers set manually on the backend.
- Angular frontend uses relative API URLs (no hardcoded endpoints).

---

## Tools Used

| Tool | Version | Purpose |
|------|---------|---------|
| npm audit | npm 10.x | Dependency vulnerability scan |
| license-checker | 25.0.1 | License compliance check |
| Manual SAST | — | Source code review of all .js/.ts files |
| Git history analysis | git 2.x | Check for committed secrets |
| .gitignore review | — | Verify secret exclusion |
| Dockerfile review | — | Container hardening assessment |
| nginx config review | — | Reverse proxy security |
| OWASP Top 10 2021 | — | Checklist framework |
| CWE/SANS Top 25 | — | Vulnerability classification |

---

## Appendix A: npm audit Results

### cfl-back
```
found 0 vulnerabilities
```

### cfl-front-ng
```
11 high severity vulnerabilities
- @angular/compiler 21.2.2: XSS in i18n (GHSA-g93w-mfhg-p222)
- undici 7.x: 6 CVEs (DoS, smuggling, CRLF injection)
```

## Appendix B: License Summary

### cfl-back
```
MIT: 244, ISC: 15, BSD-3-Clause: 6, Apache-2.0: 3, UNLICENSED: 1
```
Note: 1 package is UNLICENSED — review for compliance.

### cfl-front-ng
Same distribution as cfl-back (shared tooling dependencies).

---

*Report generated 2026-03-19. All findings based on static analysis and code review. Dynamic testing (DAST) was not performed.*
