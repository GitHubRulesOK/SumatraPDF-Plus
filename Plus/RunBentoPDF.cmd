rem @echo off
REM point to the current testing BentoPDF SAAS location
set "SAAS=C:\Users\WDAGUtilityAccount\Downloads\dist-1.16.0"
set "Server=miniserve.exe"
REM this must be less than 25 characters
set "TaskName=miniserve"
if not exist "%SAAS%\%Server%" echo Server not found use from Fetch to download & Pause & exit /b

REM --- Check if TaskName is running or any port 8080 is already listening ---
tasklist | find /i "%TaskName%" >nul
if %errorlevel%==0 (
    echo %Server% already running.
) else (
    netstat -ano | find ":8080" | find "LISTENING" >nul
    if %errorlevel%==0 (
        echo Port 8080 is in use by another process.
    ) else (
        echo Starting %Server%...
        REM avoid missing pyodide map warning messages
        if not exist "%SAAS%\pymupdf-wasm\pyodide.mjs.map" echo - > "%SAAS%\pymupdf-wasm\pyodide.mjs.map"
        pushd "%SAAS%"
        start "Server" /MIN "%SAAS%\%Server%" --index index.html
        popd
    )
)

REM --- Launch Edge --- TODO resolve passing files to page e.g. start=msedge --app="file://%~1#page=%2"
rem Do we need a --profile-directory or simply use the new default ?
rem We do not need --app= if using a default profile as "%temp%\server"

REM The following will start a NEW TAB in the target EDGE session thus on second run there will be a second tab etc.
start=msedge --user-data-dir="%temp%\server" --no-first-run --disable-first-run-ui "http://127.0.0.1:8080/index.html"

REM Uncomment the following line to open an additional File Explorer window where the current SumatraPDF file directory "%d" exists.
REM  This is as close as we can currently get for drag and drop into the server window.
rem if exist "%~1\*.*" Explorer "%~1"

pause
