# Introduction #

This tool intended for use as a command-line version dde\_client
for forward searching with SumatraPDF when use Notepad++
as an editor for (La)TeX.  cl-2-dde.exe is small utility written
entirely in assembly language.


# Details #
```
versions:
-------------
cl-2-dde.exe        --  clean & simple. Use it.
cl-2-dde_dbg.exe    --  if something does go wrong you can use it to
                        prints out log to the stdout.


USAGE:
------
make sure a DDE server, i.e.
Excel.exe, SumutraPDF.exe, gsview32.exe, ... is launched and running.


usage examples:
--------------

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

'at' sign in full paths to the cl-2-dde.exe is not allowed.
Example:
'C:\MyFolder\Proj@home\dde\'
                 ^
                 |_ is not allowed.


```
Links:

---


http://code.google.com/p/sumatrapdf/wiki/DDEcommands

https://partners.adobe.com/asn/acrobat/sdk/reg/Documentation/Core_API/CoreAPIReference.pdf
(http://sourceforge.net/projects/notepad-plus/forums/forum/331753/topic/3085267)

http://william.famille-blum.org/blog/static.php?page=static081010-000413

http://sourceforge.net/projects/npp-plugins/forums/forum/672146/topic/3914253