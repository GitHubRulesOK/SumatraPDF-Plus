REM To use Coherent cpdf to place a Signature Box on a pdf (read the manual for pages other than 1) 

REM IMPORTANT the following are both adjustable 3 character point sizes to not change the validity of PDF
set "Wide=150" & set "High=050"
REM the following are more free format but need to be set per page position where signature is desired
set "Xpos=10" & set "Ypos=20"

(
echo %%PDF-1.0
echo 1 0 obj^<^</Type/Catalog/AcroForm null/Pages 4 0 R^>^>endobj
echo 2 0 obj^<^</Type/Page/Annots[3 0 R]/MediaBox[0 0 %Wide% %High%]/Parent 4 0 R/Resources^<^<^>^>/Contents 5 0 R^>^>endobj
echo 3 0 obj^<^</Type/Annot/Subtype/Widget/AP^<^</N null^>^>/DA(0 g /Helv 0 Tf^)/F 4/FT/Sig/P 2 0 R/Rect[0 0 %Wide% %High%]/T(Signature1^)^>^>endobj
echo 4 0 obj^<^</Type/Pages/Count 1/Kids[2 0 R]^>^>endobj
echo 5 0 obj^<^</Length 0^>^>stream endstream endobj
echo xref
echo 0 6
echo 0000000000 65535 f
echo 0000000010 00000 n
echo 0000000068 00000 n
echo 0000000175 00000 n
echo 0000000304 00000 n
echo 0000000354 00000 n
echo trailer
echo ^<^</Size 6/Root 1 0 R^>^>
echo startxref
echo 399
echo %%%%EOF
) >SignBox.pdf
REM cpdf -stamp-on SignBox.pdf -topleft "%Xpos %Ypos" -relative-to-cropbox "%~dpn1.pdf" -o "%~dpn1.-WithSignBox.pdf"
cpdf -stamp-on SignBox.pdf -topleft "%Xpos %Ypos" "%~dpn1.pdf" -o "%~dpn1.-WithSignBox.pdf"
