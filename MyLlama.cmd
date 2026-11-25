REM <# NOTE: DO NOT remove this REM line. It tells PowerShell to skip the CMD section and find its own code later in this file.

@echo off & mode con: cols=50 lines=6 & cls & echo Llama Starting ... & setlocal & goto MAIN
NOTE: The guidance below is optional. You can delete everything between here and :MAIN once you understand how to use this file.

MyLlama - Local AI Document Processing (Like Google translate and MORE offline) NOT just translate
-------

THIS is a single-file CMD launcher that runs a local Llama.cpp server and uses PowerShell to send plain-text documents and AI prompts to Gemma.
On first use, it downloads the required model and runtime files. Subsequent runs re-use those downloads. All data is local = no uploads.

Getting started
----------------
1. Choose a prompt
Place prompt instructions in the prompts subfolder as ordinary .txt files.

 Note the structure will be this file in a folder then subfolders alongside this file 
of |-\models
   |-\output
   |-\prompts
and -\runtime

For example, TransLite2fr.txt instructs Gemma to translate supplied text into French so copy, paste and save with notepad something like this
 as Prompts\TransLite2fr.txt from between the two ---- lines
----
You are a translator.
Translate ALL the text supplied below after "TEXT TO TRANSLATE:" into French.
The input may be a single word, a short sentence, several sentences, or a long document.
Instructions:
Automatically identify the source language.
Translate every word and sentence. Never omit the supplied text.
Return ONLY the translation.
Translate all supplied content, including short inputs. Never return an empty response or only a document-ending marker.
TEXT TO TRANSLATE:
----

Creating your own prompts
There is online guidance at https://ollama.com/library/translategemma
Create another .txt file in prompts for a different task or language.
For example:
TransLite2en.txt - Any to English translation
Summarise.txt - Document summaries

Adding an optional tail.txt file in the prompts folder can provides additional instructions appended after the input document.

2. Choose your input
The incoming document can be as simple as Hello, World! or a complete page of extracted text.

3. Run THIS.cmd 
e.g.	MyLlama TransLite2fr "hello.txt"
The output is saved in the output folder.

Changing the local AI model
--------------------------------
The initial configuration uses the lightweight Gemma 3 1B model.
More powerful GGUF models can be used by placing them in models and changing the MODEL reference in THIS.cmd.
Suggestion is to try the translate gemma 4B model at https://huggingface.co/42ailab/TranslateGemma-4B-GGUF

For SumatraPDF users the newest NG and 3.7 pre-release have local AI support but is not as simple as call this file (no subscription key needed)
Call with legacy ExternalViewers by Icon or use as Selection Handler by add a selection command something like this using your own base folder.

SelectionHandlers [
	[
		Name = Translate To French
		Key = t
		Exe = C:\Users\WDAGUtilityAccount\Downloads\MyLlama.cmd TransLite2fr  "$${selectionfile}"
		Method = GET
		SelectToolbarNameOrSvg = <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none"><rect x="0" y="0" width="24" height="24" stroke="none"></rect><circle fill="#888" cx="12" cy="5" r="4"></circle><circle fill="#fc0" cx="12" cy="5" r="3"></circle><path fill="#fd0" d="M12 11.54 C9.64 9.35 6.5 8 3 8v11 c3.5 0 6.64 1.35 9 3.54 2.36-2.19 5.5-3.54 9-3.54V8 c-3.5 0-6.64 1.35-9 3.54"></path></svg></svg>
	]
]


At the end of processing you can return the output to SumatraPDF so for example lower down where it says
:DONE
pause
exit /b

change that pause line to 
start "" SumatraPDF -reuse-instance "%OUTPUT%"


:MAIN
if "%~1"=="" goto Usage
if "%~2"=="" goto Usage
set "OUTPUT=%~dp0output\%~n2.%~1.txt"
set "prompt=%~dp0prompts\%~1.txt"
if not exist "%prompt%" echo prompt file "%~dp0prompts\%~1.txt" not found & pause & exit /b 1
set "incoming=%~2"
if not exist "%incoming%" echo incoming text file not found & pause & exit /b 1

set "MODEL=%~dp0models\gemma-3-1b-it-Q4_K_M.gguf"
if not exist "%MODEL%" (
    md "%~dp0models" 2>nul
    curl.exe -fL -o "%MODEL%" "https://huggingface.co/ggml-org/gemma-3-1b-it-GGUF/resolve/main/gemma-3-1b-it-Q4_K_M.gguf"
)
if not exist "%MODEL%"  echo ERROR: Model "%MODEL%" not downloaded & pause & exit /b 1

REM Check for existing server
set "LLAMA=%~dp0runtime\llama-server.exe"
set "SERVER=http://127.0.0.1:9931"
curl.exe -fsS "%SERVER%/health" >nul 2>&1
if not errorlevel 1 goto READY

REM we have to test prior dependencies are available first or lauching Llama will fail
REM you can delete this section if you know the dependency is already present
:CHECKMSVC
REM Check local MSVC runtime dependency first
if exist "%~dp0runtime\VCRUNTIME140_1.dll" goto CHECKLLAMA
REM Ensure runtime folder exists for subsequent downloads
if not exist "%~dp0runtime" md "%~dp0runtime"
REM Check Windows MSVC runtime dependency
if exist "%WINDIR%\System32\VCRUNTIME140_1.dll" goto CHECKLLAMA
echo MSVC runtime missing. Downloading...
curl.exe -fL -o "%~dp0runtime\64bitDependencies.zip" https://github.com/GitHubRulesOK/SumatraPDF-Plus/raw/refs/heads/master/Plus/MuPDF/64bitDependencies.zip
if errorlevel 1 echo ERROR: Download failed. & pause & exit /b 1
tar -xf "%~dp0runtime\64bitDependencies.zip" -C "%~dp0runtime"
if errorlevel 1 echo ERROR: MSVC runtime installation failed. & pause & exit /b 1
goto CHECKMSVC

:CHECKLLAMA
REM Download server executable if missing
REM you can delete this section if you know the ".\runtime\llama-server.exe" is already present
if not exist "%LLAMA%" (
    md "%~dp0runtime" 2>nul
    curl.exe -fL -o "%~dp0runtime\llama-b12644-bin-win-cpu-x64.zip" "https://github.com/ggml-org/llama.cpp/releases/download/b12644/llama-b12644-bin-win-cpu-x64.zip"
    if errorlevel 1 echo ERROR: Llama server executable download failed. & pause & exit /b 1
    tar -xf "%~dp0runtime\llama-b12644-bin-win-cpu-x64.zip" -C "%~dp0runtime"
    if not exist "%LLAMA%" echo ERROR: Llama server executable missing. & pause & exit /b 1
)

REM Start server
start "Llama Server" /min "%LLAMA%" --model "%MODEL%" --host 127.0.0.1 --port 9931
REM Wait for server readiness
for /L %%i in (1,1,60) do (
    curl.exe -fsS "%SERVER%/health" >nul 2>&1 && goto READY
    timeout /t 2 /nobreak >nul
)
echo ERROR: Llama server failed to start. & pause & exit /b 1

:READY
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((Get-Content -Raw -LiteralPath '%~f0').Substring((Get-Content -Raw -LiteralPath '%~f0').LastIndexOf('#PS#')+5))) '%~1' '%~2' '%OUTPUT%' '%~dp0' "

:DONE
pause
exit /b

:Usage
echo Usage: "%~0" "prompt" "incoming text filename"
pause & exit /b

REM it is important we keep a fallback CMD EXIT before the hybrid PS marker
exit /b 1
This is the marker that the above Powershell will consider as the start of its own section
#PS#>
param(
    [string]$PromptName,
    [string]$InputFile,
    [string]$OutputFile,
    [string]$Root
)
$ErrorActionPreference = "Stop"
$Server = "http://127.0.0.1:9931"
$Utf8 = [Text.UTF8Encoding]::new($false)
$RequestFile = $ResponseFile = $null
try {
    # Read and assemble prompt
    $PromptFile = Join-Path $Root "prompts\$PromptName.txt"; $TailFile = Join-Path $Root "prompts\tail.txt"
    $Head = [IO.File]::ReadAllText($PromptFile)
    $Document = [IO.File]::ReadAllText($InputFile)
    $Tail = if (Test-Path $TailFile) { [IO.File]::ReadAllText($TailFile) } else { "" }
    $Prompt = $Head.TrimEnd() + "`r`n`r`n" + $Document + "`r`n`r`n" + $Tail.TrimStart()
    # Build request
    $Request = @{ messages = @(@{ role = "user"; content = $Prompt }); max_tokens = 4096; temperature = 0.2; stream = $false } | ConvertTo-Json -Depth 8 -Compress
    # Create temporary files
    $Id = [guid]::NewGuid().ToString()
    $RequestFile = Join-Path $env:TEMP "$Id.json"; $ResponseFile = Join-Path $env:TEMP "$Id.response"
    [IO.File]::WriteAllText($RequestFile, $Request, $Utf8)
    # Wait for server
    Write-Host "Checking Llama server..."
    $Ready = $false
    for ($i = 0; $i -lt 180; $i++) {
        try { if ((Invoke-RestMethod "$Server/health" -TimeoutSec 3).status -eq "ok") { $Ready = $true; break } }
        catch { }
        Start-Sleep -Seconds 2
    }
    if (!$Ready) { throw "Llama server did not become ready." }
    # Send request
    Write-Host "Sending document to Gemma..."
    $HttpCode = & curl.exe -sS -o $ResponseFile -w "%{http_code}" -H "Content-Type: application/json" --data-binary "@$RequestFile" "$Server/v1/chat/completions"
    if ($LASTEXITCODE -ne 0) { throw "curl request failed." }
    if ($HttpCode -ne "200") { throw "Server returned HTTP $HttpCode : $([IO.File]::ReadAllText($ResponseFile))" }
    # Extract response
    $Response = [IO.File]::ReadAllText($ResponseFile, [Text.Encoding]::UTF8) | ConvertFrom-Json
    $Result = $Response.choices[0].message.content
    if ([string]::IsNullOrWhiteSpace($Result)) { throw "Empty response from model." }
    # Save output
    $OutputDir = Split-Path $OutputFile
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    [IO.File]::WriteAllText($OutputFile, $Result, $Utf8)
    Write-Host "Complete."; Write-Host "Output: $OutputFile"
}
catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}
finally {
    Remove-Item $RequestFile, $ResponseFile -Force -ErrorAction SilentlyContinue
}
