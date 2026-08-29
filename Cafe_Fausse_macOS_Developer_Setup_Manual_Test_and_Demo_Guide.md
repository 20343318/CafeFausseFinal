# Cafe Fausse macOS Developer Setup, Manual Test, and Demo Guide

## Purpose and platform status

This guide gives a developer one practical path for cloning, provisioning, and running Cafe Fausse locally on macOS using the default `zsh` shell. It consolidates the setup, manual-test, rehearsal, and demonstration workflow so a macOS developer does not have to search through every Markdown file.

The application runs as three layers:

```text
Browser / React (normally :5173)
        -> Flask REST API (normally :5000)
        -> PostgreSQL 18 (normally :5432)
```

The project's approved compatibility and performance evidence was collected on Windows with PostgreSQL 18.3. This macOS guide is a local developer adaptation. It does not claim new frozen macOS, Safari, PostgreSQL patch-level, or performance evidence, and it does not replace the SRS, Rubric, Project Requirements Addendum, frozen API/database contracts, or guarded test instructions.

Homebrew installs the current patch release within each requested major/minor line. Consequently, `postgresql@18`, `python@3.14`, and `node@24` may be newer patch releases than those recorded in the Windows evidence. Do not describe a successful local macOS run as reproduction of the frozen Windows environment.

### How to interpret expected output

- Output labelled **Expected** is the success condition to verify before continuing.
- Output labelled **Representative** may differ slightly by macOS, Homebrew, PostgreSQL, Python, npm, PowerShell, Flask, or Vite patch version. Match the meaning, not incidental spacing, timing, or dependency counts.
- A command that returns to the `zsh` prompt without an error may legitimately produce no output. Such steps explicitly say **no output on success**.
- `$?` must be `0` whenever this guide checks a command's exit status.
- Stop at the first failed success condition. Do not continue and hope a later layer repairs an earlier one.

## 1. Important safety rules

- Use only a local, disposable, nonproduction database.
- This guide uses `cafe_fausse_dev`. The database scripts accept only names beginning with `cafe_fausse_dev`, `cafe_fausse_test`, or `cafe_fausse_demo`.
- Never point `rebuild.ps1` at production or production-like data.
- `rebuild.ps1` drops and recreates the fixed `cafe_fausse` schema. It deletes Cafe Fausse data in the selected database.
- Do not put passwords, passfiles, connection strings, `.env` files, shell-history secrets, or environment-variable dumps in Git.
- Use the PostgreSQL administrator only for provisioning, rebuilds, and controlled evidence work. Flask must use the separate app-only login.
- Do not manually edit individual rows to prepare or repair a demo. Use the approved guarded preparation/reset workflow.
- Use fictional names, emails, and phone numbers for tests and demonstrations.
- Do not use `sudo` with Homebrew, PostgreSQL, npm, the Python virtual environment, or repository scripts.

## 2. Install and verify the macOS developer environment

This guide uses:

- a Homebrew-supported macOS release;
- Apple Command Line Tools and Git;
- Homebrew;
- PostgreSQL 18 with `pgcrypto`, `psql`, `createdb`, `dropdb`, and `pg_isready`;
- 64-bit CPython 3.14.x;
- Node.js 24.15.0 or newer;
- npm with support for lockfile version 3; and
- PowerShell 7 (`pwsh`) for the repository's committed `.ps1` workflows.

### Step 2.1 - Verify or install Apple Command Line Tools

Run:

```zsh
sw_vers
uname -m
xcode-select --print-path
git --version
```

Expected results:

- `sw_vers` identifies macOS;
- `uname -m` normally reports `arm64` on Apple Silicon or `x86_64` on an Intel Mac;
- `xcode-select --print-path` displays an installed developer-tools directory; and
- `git --version` reports a Git version.

If `xcode-select --print-path` reports that developer tools are unavailable, request Apple's installer:

```zsh
xcode-select --install
```

Complete the macOS installation dialog, open a new Terminal window, and rerun all four verification commands.

**Continue when:** all four commands succeed.

**Stop when:** Command Line Tools installation is incomplete, Git is unavailable, or the active developer directory is invalid.

### Step 2.2 - Verify or install Homebrew

Check for Homebrew:

```zsh
brew --version
brew --prefix
```

Representative prefix:

```text
/opt/homebrew
```

Apple Silicon normally uses `/opt/homebrew`; Intel macOS normally uses `/usr/local`. This guide discovers the prefix with `brew --prefix` and does not hard-code either location.

If `brew` is not found, install it using the command published on the official Homebrew site:

```zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Read the installer output and complete its displayed **Next steps** so `brew` is available to new `zsh` sessions. Open a new Terminal window, then rerun `brew --version` and `brew --prefix`.

**Continue when:** both commands succeed and the prefix is the intended Homebrew installation.

**Stop when:** the installer fails or `brew` remains unavailable in a new Terminal session.

### Step 2.3 - Install the required toolchain

Install the supported version lines:

```zsh
brew update
brew install postgresql@18 python@3.14 node@24 powershell
```

Expected progress: Homebrew resolves and installs the formulae without an `Error:` ending. Already-installed formulae may be reported as installed or current.

Homebrew's versioned PostgreSQL and Node formulae are keg-only. In each new Terminal session used for Cafe Fausse, initialize their command paths with:

```zsh
POSTGRES_BIN="$(brew --prefix postgresql@18)/bin"
NODE_BIN="$(brew --prefix node@24)/bin"

[[ -d "$POSTGRES_BIN" ]] || {
  print -u2 "PostgreSQL 18 bin directory not found: $POSTGRES_BIN"
  return 1 2>/dev/null || exit 1
}
[[ -d "$NODE_BIN" ]] || {
  print -u2 "Node 24 bin directory not found: $NODE_BIN"
  return 1 2>/dev/null || exit 1
}

export PATH="$POSTGRES_BIN:$NODE_BIN:$PATH"
```

Expected result: the block produces no output and returns to the prompt.

This changes only the current Terminal session. Repeat it in each new Terminal that needs the PostgreSQL or Node command-line tools.

Verify the tools:

```zsh
git --version
psql --version
createdb --version
dropdb --version
pg_isready --version
python3.14 --version
node --version
npm --version
pwsh --version
```

Required results:

- every command is recognized;
- PostgreSQL reports major version 18;
- Python reports 3.14.x;
- Node reports 24.15.0 or newer; and
- PowerShell reports version 7.x.

Representative output:

```text
git version 2.x.x
psql (PostgreSQL) 18.x
createdb (PostgreSQL) 18.x
dropdb (PostgreSQL) 18.x
pg_isready (PostgreSQL) 18.x
Python 3.14.x
v24.x.x
11.x/12.x or another npm version compatible with lockfile version 3
PowerShell 7.x.x
```

**Continue when:** all required results pass.

**Stop when:** a command is unavailable or the PostgreSQL, Python, Node, or PowerShell version line is incorrect.

The database scripts can also locate `psql` through this session variable:

```zsh
export CAFE_FAUSSE_PSQL="$POSTGRES_BIN/psql"
```

This variable helps only repository scripts find `psql`; it does not place `createdb`, `dropdb`, or `pg_isready` on `PATH`. The session-level `PATH` initialization remains required.

## 3. Clone or update the repository

### Step 3.1 - Clone a new local copy

Replace `<repository-url>` with the repository's actual HTTPS or SSH clone URL:

```zsh
mkdir -p "$HOME/source"
cd "$HOME/source"
git clone <repository-url> CafeFausse
cd CafeFausse
```

Expected progress: Git downloads the repository and the prompt ends in the `CafeFausse` directory.

If the repository is already cloned, update it instead:

```zsh
cd "$HOME/source/CafeFausse"
git status --short
git pull --ff-only
```

Expected result: `git status --short` produces no output before the pull, and the pull reports either `Already up to date.` or a successful fast-forward.

**Stop when:** the repository has unexpected local changes, authentication fails, cloning/pulling fails, or Git requires a merge. Do not discard local work to force an update.

### Step 3.2 - Confirm the repository root

```zsh
CAFE_REPO="$HOME/source/CafeFausse"
cd "$CAFE_REPO"
pwd
for required_path in database backend frontend README.md; do
  [[ -e "$required_path" ]] || {
    print -u2 "Missing repository path: $required_path"
    return 1 2>/dev/null || exit 1
  }
done
print 'Repository structure: PASS'
```

Expected result resembles:

```text
/Users/<UserName>/source/CafeFausse
Repository structure: PASS
```

All later commands assume the repository root unless a step explicitly changes directory.

## 4. One-time database provisioning

### Step 4.1 - Start PostgreSQL

Start and register the Homebrew PostgreSQL 18 service for the current macOS user:

```zsh
brew services start postgresql@18
```

Expected result: Homebrew reports that `postgresql@18` started successfully. Confirm service state and connectivity:

```zsh
brew services list
pg_isready -h localhost -p 5432
```

Expected connectivity result:

```text
localhost:5432 - accepting connections
```

**Continue when:** `postgresql@18` is started and `pg_isready` says `accepting connections`.

**Stop when:** the service reports an error, another PostgreSQL instance owns port 5432, or `pg_isready` reports `no response` or `rejecting connections`.

### Step 4.2 - Select the PostgreSQL administrator

A fresh Homebrew PostgreSQL cluster normally creates a local administrator role matching the macOS account. If the installation uses another administrator, replace `$(id -un)` below with that role name.

```zsh
CAFE_ADMIN_LOGIN="$(id -un)"
export PGHOST='localhost'
export PGPORT='5432'
export PGDATABASE='cafe_fausse_dev'
export PGUSER="$CAFE_ADMIN_LOGIN"
export CAFE_FAUSSE_ENVIRONMENT='development'
export CAFE_FAUSSE_ALLOW_RESET='YES'

printf '%s\n' \
  "PGHOST=$PGHOST" \
  "PGPORT=$PGPORT" \
  "PGDATABASE=$PGDATABASE" \
  "PGUSER=$PGUSER" \
  "CAFE_FAUSSE_ENVIRONMENT=$CAFE_FAUSSE_ENVIRONMENT" \
  "CAFE_FAUSSE_ALLOW_RESET=$CAFE_FAUSSE_ALLOW_RESET"
```

Expected values:

```text
PGHOST=localhost
PGPORT=5432
PGDATABASE=cafe_fausse_dev
PGUSER=<selected local administrator>
CAFE_FAUSSE_ENVIRONMENT=development
CAFE_FAUSSE_ALLOW_RESET=YES
```

**Stop when:** any value is not the intended local development value.

If the administrator requires password authentication, use a hidden prompt:

```zsh
unset PGPASSFILE
read -s "CAFE_ADMIN_PASSWORD?Password for $CAFE_ADMIN_LOGIN: "
print
export PGPASSWORD="$CAFE_ADMIN_PASSWORD"
unset CAFE_ADMIN_PASSWORD
```

Expected result: `zsh` does not echo the password and returns to the prompt without error. Do not print `PGPASSWORD`.

If the local administrator authenticates without a password, leave both `PGPASSWORD` and `PGPASSFILE` unset. Never configure both.

Verify the running server major version:

```zsh
POSTGRES_SERVER_VERSION="$(psql -X -tA -v ON_ERROR_STOP=1 \
  -h "$PGHOST" \
  -p "$PGPORT" \
  -U "$PGUSER" \
  -d postgres \
  -c 'SHOW server_version;')" || return 1 2>/dev/null || exit 1

print "$POSTGRES_SERVER_VERSION"
[[ "$POSTGRES_SERVER_VERSION" == 18.* ]] || {
  print -u2 "Expected PostgreSQL 18.x; received $POSTGRES_SERVER_VERSION"
  return 1 2>/dev/null || exit 1
}
```

Expected result: a version beginning with `18.`.

**Stop when:** authentication fails, the server cannot be reached, or the server major version is not 18.

### Optional Step 4.2A - Delete an existing development database for a complete provisioning retest

Skip this step for an initial setup or ordinary clean-baseline rebuild. It permanently deletes the entire local `cafe_fausse_dev` database and all data inside it. Stop Flask and close any `psql` session connected to the database before continuing.

Validate and explicitly confirm the fixed target:

```zsh
CAFE_DATABASE_TO_DROP='cafe_fausse_dev'
[[ "${PGDATABASE:-}" == "$CAFE_DATABASE_TO_DROP" ]] || {
  print -u2 "Refusing to drop '${PGDATABASE:-}'; expected '$CAFE_DATABASE_TO_DROP'."
  return 1 2>/dev/null || exit 1
}

read "DROP_CONFIRMATION?Type DROP cafe_fausse_dev to permanently delete the database: "
[[ "$DROP_CONFIRMATION" == 'DROP cafe_fausse_dev' ]] || {
  print -u2 'Database deletion was not confirmed.'
  return 1 2>/dev/null || exit 1
}
unset DROP_CONFIRMATION
```

Expected result: the block continues only after the complete exact text `DROP cafe_fausse_dev` is entered.

Delete and verify only the validated database:

```zsh
dropdb \
  --if-exists \
  --force \
  -h "$PGHOST" \
  -p "$PGPORT" \
  -U "$PGUSER" \
  "$CAFE_DATABASE_TO_DROP" || return 1 2>/dev/null || exit 1

DROPPED_DATABASE_CHECK="$(psql -X -tA -v ON_ERROR_STOP=1 \
  -h "$PGHOST" \
  -p "$PGPORT" \
  -U "$PGUSER" \
  -d postgres \
  -c "SELECT datname FROM pg_database WHERE datname = 'cafe_fausse_dev';")" \
  || return 1 2>/dev/null || exit 1

[[ -z "$DROPPED_DATABASE_CHECK" ]] || {
  print -u2 'cafe_fausse_dev still exists.'
  return 1 2>/dev/null || exit 1
}
print 'Confirmed: cafe_fausse_dev does not exist.'
```

Expected result:

```text
Confirmed: cafe_fausse_dev does not exist.
```

Deleting a database does not delete PostgreSQL cluster roles. The passwordless group roles and `cafe_fausse_local_app` may still exist. Follow the existing-login path in Step 4.5 if necessary.

### Step 4.3 - Create the empty development database

```zsh
createdb \
  -h "$PGHOST" \
  -p "$PGPORT" \
  -U "$PGUSER" \
  "$PGDATABASE" || return 1 2>/dev/null || exit 1
```

Expected result: `createdb` produces no output and returns exit code `0`.

Verify it:

```zsh
psql -X -tA -v ON_ERROR_STOP=1 \
  -h "$PGHOST" \
  -p "$PGPORT" \
  -U "$PGUSER" \
  -d postgres \
  -c "SELECT datname FROM pg_database WHERE datname = 'cafe_fausse_dev';"
```

Expected result:

```text
cafe_fausse_dev
```

**Stop when:** creation fails, or verification does not return exactly `cafe_fausse_dev`.

### Step 4.4 - Build and verify the Cafe Fausse schema

From the repository root:

```zsh
cd "$CAFE_REPO"
export CAFE_FAUSSE_PSQL="$POSTGRES_BIN/psql"

pwsh -NoProfile -File database/scripts/rebuild.ps1
[[ $? -eq 0 ]] || return 1 2>/dev/null || exit 1

pwsh -NoProfile -File database/scripts/verify.ps1
[[ $? -eq 0 ]] || return 1 2>/dev/null || exit 1
```

Expected progress: the guarded scripts validate the nonproduction target, provision/validate roles, recreate only the fixed `cafe_fausse` schema, apply migrations `001` through `011`, restore the approved seed, run all database verifiers, and return exit code `0`.

**Continue when:** both scripts complete successfully without an unhandled error, failed guard, failed migration, or failed verifier.

**Stop when:** PowerShell reports a platform/path incompatibility, either script returns nonzero, or any guard or verifier fails. Do not continue with a partially provisioned database and do not weaken a guard.

### Step 4.5 - Create the app-only login

Flask must not use the PostgreSQL administrator, schema owner, or test role. Start an administrator session:

```zsh
psql -X -v ON_ERROR_STOP=1 \
  -h "$PGHOST" \
  -p "$PGPORT" \
  -U "$CAFE_ADMIN_LOGIN" \
  -d "$PGDATABASE"
```

Representative banner:

```text
psql (18.x)
Type "help" for help.

cafe_fausse_dev=#
```

For a new cluster login, run at the `psql` prompt:

```sql
CREATE ROLE cafe_fausse_local_app
    LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION
    NOBYPASSRLS NOINHERIT;
GRANT cafe_fausse_app TO cafe_fausse_local_app;
GRANT CONNECT ON DATABASE cafe_fausse_dev TO cafe_fausse_local_app;
\password cafe_fausse_local_app
```

Expected progress:

```text
CREATE ROLE
GRANT ROLE
GRANT
Enter new password for user "cafe_fausse_local_app":
Enter it again:
ALTER ROLE
```

Enter the app password twice; it must differ from the administrator password. Exit with:

```sql
\q
```

If `cafe_fausse_local_app` already exists, do not rerun `CREATE ROLE`. In an administrator `psql` session, run only:

```sql
GRANT cafe_fausse_app TO cafe_fausse_local_app;
GRANT CONNECT ON DATABASE cafe_fausse_dev TO cafe_fausse_local_app;
\password cafe_fausse_local_app
\q
```

**Continue when:** the login exists, can connect to `cafe_fausse_dev`, holds membership in `cafe_fausse_app`, and has a known local password.

**Stop when:** any SQL command reports an unexpected `ERROR`.

### Step 4.6 - Verify the role boundary

```zsh
unset PGPASSWORD PGPASSFILE
read -s 'CAFE_APP_PASSWORD?Password for cafe_fausse_local_app: '
print
export PGPASSWORD="$CAFE_APP_PASSWORD"
unset CAFE_APP_PASSWORD

psql -X -tA -v ON_ERROR_STOP=1 \
  -h 127.0.0.1 \
  -p 5432 \
  -U cafe_fausse_local_app \
  -d cafe_fausse_dev \
  -c "SET ROLE cafe_fausse_app; SELECT session_user || '|' || current_user; RESET ROLE;"
```

Expected identity row:

```text
cafe_fausse_local_app|cafe_fausse_app
```

The command may also print `SET` and `RESET` status lines.

**Continue when:** authentication succeeds, the identity row is exact, and the command exits `0`.

**Stop when:** authentication fails or the current role is not `cafe_fausse_app`.

Clear the credential:

```zsh
unset PGPASSWORD
```

Expected result: no output on success.

## 5. One-time backend provisioning

From the repository root:

```zsh
cd "$CAFE_REPO"
python3.14 -m venv backend/.venv
source backend/.venv/bin/activate
python -m pip install -e 'backend[test]'
```

Expected progress:

- virtual-environment creation normally produces no output;
- activation changes the prompt to include `(.venv)`;
- pip installs the editable Cafe Fausse backend and test dependencies; and
- pip finishes without an `ERROR` or failed build.

Confirm the package import:

```zsh
python -c "import cafe_fausse; print('Backend import: PASS')"
```

Expected result:

```text
Backend import: PASS
```

**Continue when:** the environment is active, installation succeeds, and the import prints the exact PASS line.

**Stop when:** Python reports an unsupported version, dependency failure, `ModuleNotFoundError`, or another traceback.

Deactivate after installation:

```zsh
deactivate
```

Expected result: no output and `(.venv)` disappears from the prompt.

## 6. One-time frontend provisioning

From the repository root:

```zsh
cd "$CAFE_REPO/frontend"
npm ci
npm run build
cd "$CAFE_REPO"
```

Expected progress:

- `npm ci` removes any existing `node_modules`, installs exactly from the committed lockfile, and exits `0`;
- approved dependency install scripts run according to the committed `allowScripts` policy;
- Vite transforms the application and writes `frontend/dist`; and
- neither command prints an `npm ERR!` ending.

Representative build ending:

```text
vite ... building for production...
... modules transformed.
dist/... generated
... built in ...
```

**Continue when:** both commands exit `0` and `frontend/dist` exists.

**Stop when:** npm reports a lockfile, install-script, dependency, asset, test/build, or compilation failure. Do not use `npm update` as setup or recovery.

## 7. Start Cafe Fausse for each manual-test or demo session

Use three macOS Terminal windows or tabs. Start them in the order below. Each new Terminal begins with its own environment, so run the complete block shown for that Terminal.

### Terminal 1 - Flask backend

```zsh
CAFE_REPO="$HOME/source/CafeFausse"
cd "$CAFE_REPO"

POSTGRES_BIN="$(brew --prefix postgresql@18)/bin"
[[ -d "$POSTGRES_BIN" ]] || {
  print -u2 "PostgreSQL 18 bin directory not found: $POSTGRES_BIN"
  return 1 2>/dev/null || exit 1
}
export PATH="$POSTGRES_BIN:$PATH"

unset CAFE_FAUSSE_ALLOW_RESET CAFE_FAUSSE_PSQL PGPASSFILE
export CAFE_FAUSSE_ENVIRONMENT='development'
export PGHOST='127.0.0.1'
export PGPORT='5432'
export PGDATABASE='cafe_fausse_dev'
export PGUSER='cafe_fausse_local_app'

read -s 'CAFE_APP_PASSWORD?Password for cafe_fausse_local_app: '
print
export PGPASSWORD="$CAFE_APP_PASSWORD"
unset CAFE_APP_PASSWORD

[[ -n "${PGPASSWORD:-}" ]] || {
  print -u2 'PGPASSWORD is missing; Flask cannot authenticate to PostgreSQL.'
  return 1 2>/dev/null || exit 1
}
print 'PGPASSWORD is set for the Flask process.'

source backend/.venv/bin/activate
cd backend
python -m flask --app cafe_fausse run
```

Expected progress:

```text
PGPASSWORD is set for the Flask process.
* Serving Flask app 'cafe_fausse'
* Debug mode: off
* Running on http://127.0.0.1:5000
```

Flask may include its standard development-server warning.

**Continue when:** Flask remains running at `http://127.0.0.1:5000` without a traceback or configuration error.

**Stop when:** the PostgreSQL path or password check fails, Flask exits, port 5000 is occupied, an unknown `CAFE_FAUSSE_*` variable is reported, or application/database configuration is invalid.

Leave Terminal 1 open. Flask performs no migration or schema change at startup.

### Terminal 2 - React/Vite frontend

```zsh
CAFE_REPO="$HOME/source/CafeFausse"
cd "$CAFE_REPO"

NODE_BIN="$(brew --prefix node@24)/bin"
[[ -d "$NODE_BIN" ]] || {
  print -u2 "Node 24 bin directory not found: $NODE_BIN"
  return 1 2>/dev/null || exit 1
}
export PATH="$NODE_BIN:$PATH"

export CAFE_FAUSSE_FLASK_PROXY_TARGET='http://127.0.0.1:5000'
cd frontend
npm run dev
```

Expected progress:

```text
VITE ... ready in ...
Local: http://localhost:5173/
```

**Continue when:** Vite remains running and displays exactly port 5173.

**Stop when:** Vite exits, reports a missing dependency/asset, or selects a port other than 5173. Resolve the port conflict before continuing.

Open `http://localhost:5173/`. Use the Vite development URL because it proxies relative `/api` requests to Flask. Do not use `npm run preview` for the normal full-stack manual test.

### Terminal 3 - Health checks and database evidence

```zsh
POSTGRES_BIN="$(brew --prefix postgresql@18)/bin"
[[ -d "$POSTGRES_BIN" ]] || {
  print -u2 "PostgreSQL 18 bin directory not found: $POSTGRES_BIN"
  return 1 2>/dev/null || exit 1
}
export PATH="$POSTGRES_BIN:$PATH"

DIRECT_LIVENESS="$(curl -fsS http://127.0.0.1:5000/api/v1/health/liveness)" \
  || return 1 2>/dev/null || exit 1
DIRECT_READINESS="$(curl -fsS http://127.0.0.1:5000/api/v1/health/readiness)" \
  || return 1 2>/dev/null || exit 1
PROXIED_READINESS="$(curl -fsS http://localhost:5173/api/v1/health/readiness)" \
  || return 1 2>/dev/null || exit 1

printf '%s\n' "$DIRECT_LIVENESS" "$DIRECT_READINESS" "$PROXIED_READINESS"
```

Expected output:

```text
{"status":"live"}
{"status":"ready"}
{"status":"ready"}
```

JSON whitespace or key ordering may differ, but the three statuses must be `live`, `ready`, and `ready` in that order.

**Stop when:** `curl` fails, an HTTP error occurs, a response reports `service_not_ready`, an unexpected body is returned, or the proxied request cannot reach Flask.

Do not begin manual testing or rehearsal unless all three checks succeed.

## 8. Quick manual smoke test

Use the application through `http://localhost:5173/`.

### Step 8.1 - Five pages and navigation

1. Open Home.
2. Verify the restaurant name, address, phone, hours, hero content, and shared navigation.
3. Open Menu and verify Starters, Main Courses, Desserts, and Beverages show descriptions and prices.
4. Open Reservations and confirm the availability and customer form workflow is present.
5. Open About Us and verify the history, founders, mission, and commitments.
6. Open Gallery and verify restaurant, dish, special-event, and behind-the-scenes imagery plus awards and reviews.
7. Use the shared navigation to return to Home.

Expected result:

- every navigation action changes to the intended route without an error page;
- all five required pages render their expected content;
- shared navigation remains visible and usable; and
- returning to Home succeeds without a full-stack error.

**Stop when:** any page is missing, blank, visibly broken, routed incorrectly, or shows a browser, React, or API error.

### Step 8.2 - Gallery and keyboard behavior

1. Open Gallery.
2. Select a middle image and verify the lightbox opens.
3. Use Next or Previous and verify the image/counter changes.
4. Close the lightbox.
5. Repeat with keyboard navigation where applicable, including `Tab`, `Enter` or `Space`, arrow keys, and `Escape`.

Expected result:

- the selected image opens in a dialog/lightbox;
- navigation changes the displayed image and counter;
- keyboard focus remains usable;
- `Escape` or Close dismisses the lightbox; and
- focus returns predictably to Gallery content.

**Stop when:** the dialog cannot open/close, navigation escapes the bounded collection, focus becomes trapped incorrectly, or an image fails to render.

### Step 8.3 - Responsive behavior

1. Open Chrome DevTools.
2. Enable the device toolbar.
3. Set the viewport to 390 x 844.
4. Check Home, Gallery, and Reservations.
5. Verify navigation and content reflow without horizontal page scrolling.
6. Restore desktop width and close DevTools.

Expected result:

- content reflows to 390 x 844;
- text and controls remain readable and operable;
- no horizontal document scrollbar appears; and
- desktop layout returns without a reload error.

**Stop when:** content is clipped, controls overlap, the page scrolls horizontally, or navigation becomes unusable.

This local check does not replace the retained Firefox and Safari manual compatibility evidence. A macOS run must not be presented as new approved Safari evidence unless that evidence is separately reviewed and approved.

### Step 8.4 - Newsletter persistence

Create a unique fictional identity in Terminal 3:

```zsh
CAFE_STAMP="$(date '+%Y%m%d%H%M%S')"
CAFE_NEWSLETTER_EMAIL="newsletter.${CAFE_STAMP}@example.com"
print "$CAFE_NEWSLETTER_EMAIL"
```

Expected output resembles:

```text
newsletter.20260829153045@example.com
```

1. Copy the displayed email.
2. On Home, enter a fictional first and last name.
3. Enter and confirm the email if requested.
4. Select Subscribe and save.
5. Verify the browser reports that the newsletter preference was saved and its authoritative state is subscribed.
6. For an official demo, show the matching PostgreSQL before/after evidence using the approved Prompt-28 queries.

Expected result:

- the form accepts the unique fictional identity;
- the browser displays `Newsletter preference saved` or the committed equivalent;
- authoritative state is subscribed; and
- official PostgreSQL evidence changes from zero matches to one matching subscribed customer.

**Stop when:** the UI reports failure, state is not subscribed, or browser and database evidence disagree.

### Step 8.5 - Successful reservation

Create a different unique fictional email:

```zsh
CAFE_STAMP="$(date '+%Y%m%d%H%M%S')"
CAFE_RESERVATION_EMAIL="reservation.${CAFE_STAMP}@example.com"
print "$CAFE_RESERVATION_EMAIL"
```

Expected output resembles:

```text
reservation.20260829153110@example.com
```

1. Open Reservations.
2. Select a date inside the displayed booking window, respecting the same-day lead time.
3. Enter party size 6.
4. Select Check availability.
5. Verify the displayed slots came from the server and unavailable slots cannot be selected.
6. Select an available slot.
7. Enter fictional customer details with matching email and confirmation.
8. Submit once.
9. Verify `Reservation confirmed` appears.
10. Record the confirmation reference, interval, party size, and assigned table numbers.
11. For an official demo, show the matching PostgreSQL customer, reservation, and assignment evidence using the approved Prompt-28 queries.

Expected result:

- the server returns the date range, policy, and complete slot list;
- only available slots are selectable;
- one submit produces one confirmation;
- confirmation includes a decimal reference, party size 6, interval, assigned table number(s), and newsletter state; and
- PostgreSQL evidence matches the browser confirmation.

**Stop when:** no valid slots appear for a valid date, an unavailable slot is selectable, submission fails, confirmation data is missing, or PostgreSQL disagrees.

### Step 8.6 - Representative safe failures

Without changing the database directly, verify:

- mismatched email confirmation;
- omitted required name or email;
- invalid party size;
- no selected server-returned slot;
- repeated submit remains controlled; and
- an unavailable slot cannot be selected.

Expected result: the form remains available for correction, no rejected request creates a confirmation, duplicate submission is prevented, and no stack trace, SQL, credential, or internal exception detail appears.

**Stop when:** invalid input creates data, duplicate submit creates duplicate records, or internal details are exposed.

## 9. Prepare the environment for the official demo

Ordinary startup is covered above. The official demonstration adds controlled evidence and deterministic data.

### Step 9.1 - Return to the clean baseline

This deletes current Cafe Fausse application data in `cafe_fausse_dev`. Stop Flask before rebuilding.

In an administrator Terminal:

```zsh
CAFE_REPO="$HOME/source/CafeFausse"
cd "$CAFE_REPO"

POSTGRES_BIN="$(brew --prefix postgresql@18)/bin"
export PATH="$POSTGRES_BIN:$PATH"
export CAFE_FAUSSE_PSQL="$POSTGRES_BIN/psql"

CAFE_ADMIN_LOGIN="$(id -un)" # Replace if the administrator differs.
export PGHOST='localhost'
export PGPORT='5432'
export PGDATABASE='cafe_fausse_dev'
export PGUSER="$CAFE_ADMIN_LOGIN"
export CAFE_FAUSSE_ENVIRONMENT='development'
export CAFE_FAUSSE_ALLOW_RESET='YES'

unset PGPASSFILE
read -s "CAFE_ADMIN_PASSWORD?Password for $PGUSER (press Return if none): "
print
if [[ -n "$CAFE_ADMIN_PASSWORD" ]]; then
  export PGPASSWORD="$CAFE_ADMIN_PASSWORD"
else
  unset PGPASSWORD
fi
unset CAFE_ADMIN_PASSWORD

pwsh -NoProfile -File database/scripts/rebuild.ps1
[[ $? -eq 0 ]] || return 1 2>/dev/null || exit 1
pwsh -NoProfile -File database/scripts/verify.ps1
[[ $? -eq 0 ]] || return 1 2>/dev/null || exit 1

unset PGPASSWORD
```

Expected progress: both guarded scripts pass, the approved schema/seed returns, verification succeeds, and the credential is cleared.

**Continue when:** the final verifier succeeds and old customer/reservation data is absent.

**Stop when:** a guard, platform assumption, migration, or verifier fails, the wrong database is selected, or the clean baseline is not restored.

### Step 9.2 - Start and verify all three layers

1. Start Flask using Section 7, Terminal 1.
2. Start React/Vite using Section 7, Terminal 2.
3. Run all health checks using Section 7, Terminal 3.
4. Keep clean health results visible.

Expected result: Flask and Vite remain running, and direct liveness, direct readiness, and proxied readiness are healthy.

### Step 9.3 - Prepare demo-only data and evidence

Use only:

- `docs/demo/Cafe_Fausse_Prompt28_Demonstration_Plan.md`, especially guarded preparation, cleanup, and Section 5 PostgreSQL evidence queries; and
- `Cafe_Fausse_10_Minute_Three_Person_Demo_Runbook.md` for P1/P2/P3 timing, narrative, and handoffs.

Prepare:

- one unique fictional newsletter identity;
- a different fictional reservation identity;
- the guarded rehearsed full-capacity date/time;
- a different allowed party-of-6 date; and
- a blank place for the confirmation reference.

The baseline is 120 seats: 30 tables of four. Use only the approved guarded preparation workflow for the full/unavailable scenario; do not manually edit individual rows.

Expected before rehearsal:

- both identities have zero matching records;
- the full-capacity party-120 target is unavailable and nonselectable;
- the separate party-of-6 scenario has capacity; and
- the confirmation-reference field is blank.

### Step 9.4 - Arrange the windows

1. Open the application on Home.
2. Open a prepared `psql` evidence session.
3. Keep clean health results available.
4. Prepare Chrome DevTools for 390 x 844 but leave it closed.
5. Increase terminal text size.
6. Hide passwords, tokens, environment dumps, personal information, notifications, and unrelated windows.
7. Confirm P1/P2/P3 cameras, microphones, IDs, and handoffs.
8. Run the complete 10-minute rehearsal.

Expected result: windows are readable without secrets, browser and PostgreSQL evidence match, handoffs work, health remains good, and rehearsal finishes by 10:00, preferably between 9:40 and 9:50.

Stop and reset when any expected browser and PostgreSQL result disagree.

## 10. Stop the application safely

### Stop React/Vite

In Terminal 2, press `Ctrl+C`, then run:

```zsh
unset CAFE_FAUSSE_FLASK_PROXY_TARGET
```

Expected result: Vite stops, the prompt returns, the variable is cleared without output, and port 5173 no longer responds.

### Stop Flask

In Terminal 1, press `Ctrl+C`, then run:

```zsh
deactivate
unset PGPASSWORD PGPASSFILE PGHOST PGPORT PGDATABASE PGUSER
unset CAFE_FAUSSE_ENVIRONMENT
```

Expected result: Flask stops, `(.venv)` disappears, variables are cleared without output, and port 5000 no longer responds.

Confirm from a separate Terminal if needed:

```zsh
for URL in \
  'http://127.0.0.1:5000/api/v1/health/liveness' \
  'http://localhost:5173/'
do
  if curl -fs --max-time 2 "$URL" >/dev/null 2>&1; then
    print "STILL RESPONDING: $URL"
  else
    print "STOPPED: $URL"
  fi
done
```

Expected result:

```text
STOPPED: http://127.0.0.1:5000/api/v1/health/liveness
STOPPED: http://localhost:5173/
```

**Stop and investigate when:** either address still responds.

For a later clean baseline, rerun Step 9.1. Do not repair data manually. PostgreSQL may remain running as a Homebrew service. If the machine should not retain it as a login service, stop it with the Homebrew service-management command documented in Section 12.

## 11. Fast restart checklist

After one-time provisioning:

1. Start PostgreSQL 18.
2. Start Flask in Terminal 1.
3. Start Vite in Terminal 2.
4. Run the three health checks in Terminal 3.
5. Open `http://localhost:5173/`.
6. Use unique fictional identities.
7. Run the smoke test or approved rehearsal.
8. Stop Vite and Flask and clear credentials.
9. Guarded-rebuild only for a clean baseline.

| Checkpoint | Required observation |
|---|---|
| PostgreSQL | `pg_isready` says `accepting connections` |
| Flask | Terminal remains running on `127.0.0.1:5000` |
| Vite | Terminal remains running on `localhost:5173` |
| Direct liveness | `live` |
| Direct readiness | `ready` |
| Proxied readiness | `ready` |
| Browser smoke test | Five pages, Gallery, responsive layout, and forms work |
| Persistence | Browser success matches PostgreSQL evidence when required |
| Shutdown | Ports 5000 and 5173 no longer respond |

## 12. Troubleshooting

### Homebrew command is unavailable in a new Terminal

Rerun the Homebrew installer's displayed **Next steps** for `zsh`, open another Terminal, and verify `brew --prefix`. Do not hard-code `/opt/homebrew` on Intel or `/usr/local` on Apple Silicon.

### PostgreSQL or Node commands are unavailable

Rerun the session-level `POSTGRES_BIN`, `NODE_BIN`, and `PATH` block from Step 2.3. Confirm that each discovered directory exists and that version checks pass.

### PostgreSQL is not accepting connections

Inspect:

```zsh
brew services list
pg_isready -h localhost -p 5432
```

Start or restart the intended service:

```zsh
brew services restart postgresql@18
```

Do not start a second PostgreSQL distribution on the same port.

To stop and unregister the Homebrew service:

```zsh
brew services stop postgresql@18
```

### `rebuild.ps1` refuses to run or fails on macOS

Check:

- `pwsh --version` succeeds;
- `CAFE_FAUSSE_PSQL` names the Homebrew PostgreSQL 18 `psql` executable;
- the selected database is truly nonproduction;
- `PGDATABASE` uses an approved prefix;
- `CAFE_FAUSSE_ENVIRONMENT` is `development`, `test`, or `demo`;
- `CAFE_FAUSSE_ALLOW_RESET` is exactly `YES`; and
- the actual database matches `PGDATABASE`.

Do not weaken a guard. If the script assumes a Windows-only path or command, stop and record the exact output as a portability defect; do not improvise an unreviewed replacement migration sequence.

### Flask reports not ready

Check that PostgreSQL is running, the schema was rebuilt and verified, `PGUSER` is `cafe_fausse_local_app`, the login can assume `cafe_fausse_app`, exactly one credential source is configured, and the host/port/database are correct.

### Frontend opens but API calls fail

Confirm Flask is on `127.0.0.1:5000`, Terminal 2 set the proxy target before Vite started, the browser uses `localhost:5173`, and proxied readiness succeeds. Restart Vite after changing its proxy target.

### Python cannot import `cafe_fausse`

```zsh
cd "$HOME/source/CafeFausse"
source backend/.venv/bin/activate
python -m pip install -e 'backend[test]'
```

### Frontend dependency or build problems

```zsh
cd "$HOME/source/CafeFausse/frontend"
npm ci
npm run build
```

Do not substitute `npm update`.

### No valid reservation date or slot appears

Confirm the browser shows the server-provided booking window. The baseline uses restaurant timezone `America/New_York`, a 60-day advance window, 120-minute same-day lead time, 30-minute intervals, 90-minute duration, Monday-Saturday 17:00-23:00, and Sunday 17:00-21:00. The latest start is derived from closing time and duration.

## 13. Sources and scope

This guide adapts the current Windows developer guide and root `README.md` for macOS. It preserves the application-layer order, database safety rules, role boundary, manual smoke tests, and approved demo-document routing.

Current installation and service commands were checked against:

- [Apple Command Line Tools installation](https://developer.apple.com/documentation/xcode/installing-the-command-line-tools)
- [Homebrew installation](https://brew.sh/)
- [Homebrew PostgreSQL 18 formula](https://formulae.brew.sh/formula/postgresql@18)
- [Homebrew Python 3.14 formula](https://formulae.brew.sh/formula/python@3.14)
- [Homebrew Node 24 formula](https://formulae.brew.sh/formula/node@24)
- [Homebrew service commands](https://docs.brew.sh/Manpage)
- [PowerShell installation alternatives for macOS](https://learn.microsoft.com/powershell/scripting/install/alternate-install-methods)

The guide intentionally references the committed Prompt-28 demonstration plan for guarded demo preparation and exact PostgreSQL evidence SQL rather than duplicating those drift-prone procedures.
