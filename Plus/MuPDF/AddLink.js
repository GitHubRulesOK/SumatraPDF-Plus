// AddLink.js
// Note this is a quick hack to provide text annotation with an overlaid Hyperlink to web URL. Far better would be coherent cpdf
//      see https://github.com/coherentgraphics/cpdf-binaries/issues/131#issuecomment-4442033419
//
// Usage:
// "C:\Program Files\SumatraPDF\SumatraPDF.exe" (or Mutool.exe)
//   run AddLink.js -x=10 -y=10 -w=45 -h=12 -t="example" -u="https://www.example.com" -p=1 -o="MyOutput.pdf" -i="input.pdf"
//   run AddLink.js -x=10 -y=10 -w=90 -h=24 -t="example" -u="https://www.example.com" -p=1 -i="input.pdf"
//
// NOTE a named output is optional it will default to "output.pdf" if not given, also note the USER must estimate 
//      correct width of text display based on font height so it is double long when font is double height.   
// ------
// 1. PARSE FLAGS
// ------
var args = {};
for (var i = 0; i < scriptArgs.length; i++) {
    var part = scriptArgs[i]; var eq = part.indexOf("=");
    if (eq > 0) { var key = part.substring(1, eq); var val = part.substring(eq + 1); args[key] = val; } // remove leading "-"
}
// ------
// 2. VALIDATE MANDATORY FLAGS
// ------
var required = ["x","y","w","h","t","u","p","i"];
for (var r = 0; r < required.length; r++) {
    var k = required[r];
    if (!(k in args)) { print("ERROR: Missing required flag: -" + k + "=value"); quit(); }
}
// ------
// 3. EXTRACT VALUES
// ------
var x = parseFloat(args["x"]); var y = parseFloat(args["y"]); var w = parseFloat(args["w"]); var h = parseFloat(args["h"]);
var text = args["t"]; var url  = args["u"]; var input = args["i"]; var output = args["o"] || "output.pdf";
var file  = mupdf.Document.openDocument(input); if (!file.isPDF()) throw new Error("Not a PDF");
var pageIndex = parseInt(args["p"], 10) - 1; var page = file.loadPage(pageIndex);
// ------
// 4. COMPUTE RECT (top-left coords)
// ------
var x2 = x + w; var y2 = y + h + 1; var rect = [x, y, x2, y2];
print("Adding:",text,", Using rect:",rect,"On Page",pageIndex + 1);
// ------
// 5. FREETEXT
// ------
var ft = page.createAnnotation("FreeText");
ft.setContents(text); ft.setDefaultAppearance("Helv", h, [0,0,1]); ft.setRect(rect);
// ------
// 6. LINK
// ------
page.createLink(rect, url);
page.update();
// ------
// 7. TRY SAVE
// ------
try {
    file.save(output);
} catch (e) {
    print("ERROR: Could not write output file:", output);
    print("Windows Explorer Preview may be holding the file open.");
    quit();
}
print("Saved to:", output);
