cd /d "%~dp0"

bin\cl-2-dde-1.0.exe @' 'SUMATRA' 'control' '[Open("%cd%\README.md", 0, 1, 0)]'
pause
