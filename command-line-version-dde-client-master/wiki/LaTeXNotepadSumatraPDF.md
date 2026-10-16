## SumatraPDF —> Notepad++ ##

  1. In the `Notepad++` environment, go to the main menu’s `Plugins -> NPPExec -> Execute`, or press `F6`
  1. Enter  in the window that pops-up
```
NPP_SAVE
cd "$(CURRENT_DIRECTORY)"
pdflatex --synctex=-1 "$(FULL_CURRENT_PATH)"
```
  1. Save it with name about something.
  1. n the SumatraPDF go to the menu `Settings -> Options...`
enter stroke for inverse search:
```
"<path to>\notepad++.exe" -n%l "%f"
```
You now setting up inverse search. I.e. dbl-click  in `SumatraPDF` bring up `Notepad++` and highlight line in sourse `.tex` file's.

---


## Notepad++ —> SumatraPDF ##
  1. In the `Notepad++` environment, go to the main menu’s `Plugins -> NPPExec -> Execute`, or press `F6`
  1. Enter  in the window that pops-up
```
cd "$(CURRENT_DIRECTORY)"
<path to>\cl-2-dde.exe @' 'SUMATRA' 'control' '[ForwardSearch("$(CURRENT_DIRECTORY)\$(NAME_PART).pdf","$(CURRENT_DIRECTORY)\$(NAME_PART)$(EXT_PART)",$(CURRENT_LINE),0,0,0)]'
```
  1. Save it with name about something.
You now setting up `Forward Search`.

You can assign shortcuts for these scripts in Notepad++.