This folder contains SumatraPDF Browser Plugins

The Filename should simply be npPdfViewer.dll and registered in the corrrect folder with SumatraPDF installed DLLS

The filename may need to be changed to the above name for normal use. 
So for that reason and simplest to download the **UNOFFICIAL xhmikosr** X64 builds 2.5 version is that named file in this folder. 
For those that like hashes the VirusTotal ref is https://www.virustotal.com/gui/file/fefbab60c2af039909776001ad52c76b7e53164d131a5f8e1d2c5d72d0cda172/details
Extracted from https://web.archive.org/web/20140225191751/http://xhmikosr.1f0.de/sumatrapdf/SumatraPDF-2.5-x64-install.exe

![npPdfViewer.png](https://github.com/GitHubRulesOK/SumatraPDF-Plus/blob/master/2.5%20Legacy%20Browser%20Plugin/npPdfViewer.png)

Anewer build is also included as2.5.2 and das the file name npPdfViewer_x64.dll (This is the one I prefer to use)  [0e30f15a6bd33c3f4133b716ac018ef12b4190d6ff587c268a29885c07ab82bf](https://www.virustotal.com/gui/file/0e30f15a6bd33c3f4133b716ac018ef12b4190d6ff587c268a29885c07ab82bf/details)

How to use with Pale Moon x64 is easy. Simply register with a recent SumatraPDF (Yes 3.7 with annotation, Brotlie PDF, PDF as p7m etc.) and you can read online XPS DjVu and PDF (even Brotlie encode) OR offline other formats.

So for example register AS ADMIN above 64bit file as 
```
%WINDIR%\System32\regsvr32.exe "%PROGRAMFILES%\SumatraPDF\npPdfViewer.dll"
```
OR
```
%WINDIR%\System32\regsvr32.exe "%PROGRAMFILES%\SumatraPDF\npPdfViewer_x64.dll"
```
You should see a confirmation msg box saying succeeded.
```
---------------------------
RegSvr32
---------------------------
DllRegisterServer in C:\Program Files\SumatraPDF\npPdfViewer_x64.dll succeeded.
---------------------------
OK   
---------------------------
```
When checking in any Suitable browser it should Automatically see the registered dll. Here the 64 bit older 2.5.0 version in most recent 2026 PaleMoon Portable (Others may also work but this is the most reliable and frequently updated). For 32 bit Pale Moon use the SumatraPDF 2.5 official installer version.

![Plug-in.png](https://github.com/GitHubRulesOK/SumatraPDF-Plus/blob/master/2.5%20Legacy%20Browser%20Plugin/Plug-in.png)

Once active the browser can load web based PDF's (and XPS or DjVu)
![PaleMoon](https://github.com/GitHubRulesOK/SumatraPDF-Plus/blob/master/2.5%20Legacy%20Browser%20Plugin/Pale%20Moon.png)


Note it can also support simple goto page so click here 
https://pdfobject.com/pdf/sample-3pp.pdf#page=2 will automatically goto page 2

![goto.png](https://github.com/GitHubRulesOK/SumatraPDF-Plus/blob/master/2.5%20Legacy%20Browser%20Plugin/goto.png)





If you have a HEIC decoder installed in Windows you can view them as Local Files as well as other formats SumatraPDF supports.
