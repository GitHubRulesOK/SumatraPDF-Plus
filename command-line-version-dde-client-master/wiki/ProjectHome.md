
```
DDE is used to issue commands and data into an server DDE, e.g.
MS Excel, MS Word, Sumatra PDF, ...

In this particular one way process this programm work.

Using the CMD.EXE command processor, a server DDE, and this programm, you can
send through DDE the 8192 character command line, where length limit imposed
by CMD.EXE. If you use ShellExecute/Ex then these functions limits command
line around 2048 length.
```

### Source code ###
Just disassemble it. The utility written entirely in assembly language.
### Settings up ###
see Wiki pages
### e.g.: ###
```
with Excel, please make sure that it is running.
Make chart:
C:\cl-2-dde.exe @' 'excel'  'system'  '[Select("R1C1:R1C10")][New(2,2)]'

with Opera:
C:\cl-2-dde.exe @' 'opera' 'WWW_OpenURL' '"http://code.google.com/p/command-line-version-dde-client/"'

with GSview32.exe
C:\cl-2-dde.exe  @' 'GSview' 'GSview' '[FileOpen("filename.ps")]'

```