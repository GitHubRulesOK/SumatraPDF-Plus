# command-line-version-dde-client
Automatically exported from code.google.com/p/command-line-version-dde-client

##  Introduction ##
This tool intended for use as a command-line version `dde_client` for forward searching with  `SumatraPDF` when use `Notepad++` as an editor for (La)TeX.     

`cl-2-dde.exe` is a small 2.50 KB (2,560 bytes) utility written entirely in assembly language.

DDE is used to issue commands and data into an server DDE, e.g.
MS Excel, MS Word, Sumatra PDF, ...

In this particular **one way** process this programm work.

Using the CMD.EXE command processor, a server DDE, and this programm, you can
send through DDE the 8192 character command line, where length limit imposed
by CMD.EXE. If you use ShellExecute/Ex then these functions limits command
line around 2048 length.

## Details ##

<pre>
versions:
-------------

cl-2-dde.exe        --  clean & simple. Use it.
cl-2-dde_dbg.exe    --  if something does go wrong you can use it
                        to prints out log to the stdout.
                        
USAGE:
------

make sure a DDE server, i.e. Excel.exe, 
SumutraPDF.exe, gsview32.exe, ... 
is launched and running.

usage examples:
--------------

with Excel, please make sure that it is running.
Make chart:
C:\cl-2-dde.exe @' 'excel'  'system'  '[Select("R1C1:R1C10")][New(2,2)]'

with Opera:
C:\cl-2-dde.exe @' 'opera' 'WWW_OpenURL' '"http://code.google.com/p/command-line-version-dde-client/"'

with GSview32.exe
C:\cl-2-dde.exe  @' 'GSview' 'GSview' '[FileOpen("filename.ps")]'

cl-2-dde.exe  @= =SUMATRA=    =control=   =[Open("E:\sample.pdf", 0, 1, 0)]=
cl-2-dde.exe  @' 'SUMATRA' 'control' '[ForwardSearch("E:\sample.pdf","E:\sample.tex",305,0)]'
cl-2-dde.exe  @- -SUMATRA-    -control-   -[GotoPage("D:\sample2e.pdf",3)]-
cl-2-dde.exe  @' 'GSview' 'GSview' '[FileOpen("C:\filename.ps")]'

SYNTAX
---------

Options: (all options are required)
     (The order of the options is important!)

        C:\>cl-2-dde @" "service" "topic" "commands"
                      ^     ^        ^         ^
                      |     |        |         |_ commands
                      |     |        |_ topic
                      |     |_ service
                      |
                      |
                      |_  sets your delimiter following by '@' sign.
                          Warning: CMD.EXE have a dozen special chars,
                          e.g. <,>,\,|,&,... do not use them as a delimiter.

                          see: http://ss64.com/nt/syntax-esc.html#escape


this works too:
C:\>cl-2-dde.exe    @, ,service, ,topic, ...abc ignored ...  ,commands, ignored


Restrictions:
-------------
The only exception is that the @ character is not permitted as the character 
of a string path to the cl-2-dde.exe. That is,

Example:
'C:\MyFolder\Proj@home\dde\'
                 ^
                  \_ is not permitted.

</pre>

Links:
---------


[DEAD as at 2026] http://code.google.com/p/sumatrapdf/wiki/DDEcommands
[DEAD as at 2026] https://partners.adobe.com/asn/acrobat/sdk/reg/Documentation/Core_API/CoreAPIReference.pdf
[RECENT status] https://github.com/AdobeDocs/acrobat-pdfl-sdk/blob/main/src/pages/guides/interapp/iac-devapp-dde-support.md

[Source Discussion] https://sourceforge.net/p/npp-plugins/discussion/672146/thread/ef53cbf2/?limit=25#64b3
http://sourceforge.net/projects/npp-plugins/forums/forum/672146/topic/3914253
https://william.famille-blum.org/software/sumatra/
http://sourceforge.net/projects/notepad-plus/forums/forum/331753/topic/3085267
