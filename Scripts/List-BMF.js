// List-BMF.js - MuPDF 1.28 / SumatraPDF 3.7 run JS bookmark extractor
//
// To automatically export a bookmark file from current pdf in view add an external viewer command similar to this for the X key
// Note it is set to pause to avoid a simple flash of the black console running so currently press enter to exit once seen it working!
// To see the full list in the console add -c between js and file like `.....List-BMF.js -c "%1"`
//
// ExternalViewers [
//  [
//    CommandLine = "C:\Program Files\SumatraPDF\sumatrapdf-tool.exe" run "C:\Users\ path to your \Scripts\List-BMF.js "%1"
//    Name = e&Xport filename-BMF.txt
//    Key = x
//    Filter = *.pdf
//  ]
// ]
//
// BLOCK WScript double-click
if (typeof WScript !== "undefined") { WScript.Echo("Run using: \"SumatraPDF[-tool].exe\" run " + WScript.ScriptName + " [-c] [-n | -o=\"out.txt\"] \"infile.pdf\""); WScript.Quit(); }
print("\n Running " + scriptPath);
var infile = null; var outfile = null; var conOut = false; var noOutfile = false;
for (var i = 0; i < scriptArgs.length; i++) {
    var part = scriptArgs[i];
    if (part.charAt(0) === "-") {
        var eq  = part.indexOf("=");
        var key = (eq > 0) ? part.substring(1, eq) : part.substring(1); var val = (eq > 0) ? part.substring(eq + 1) : "";
        if (key === "c") { conOut = true; continue; } if (key === "n") { noOutfile = true; conOut = true; continue; }
        if (key === "o") { outfile = val; continue; } 
        print("Unknown switch: " + part);
        quit();
    }
    if (!infile) { infile = part; continue; } print("Unexpected argument: " + part); quit();
}
if (!infile) { print(" List Bookmarks\n Usage: sumatrapdf-tool run " + scriptPath + " [-c] [-n | -o=\"out.txt\"] \"infile.pdf\""); quit(); }
if (!noOutfile && (outfile === null || outfile === "")) { var base = infile.replace(/\.pdf$/i, ""); outfile = base + "-BMF.txt"; }

// Main
var doc = mupdf.Document.openDocument(infile); var txtOut = new Buffer();
var out = " Mode= " + mode + " FILENAME: " + infile; print(out);
var outline = doc.loadOutline();
if (!outline || outline.length === 0) { out = "\n No outline in document: " + infile; print(out); } // no dump() because nothing to dump
else { out = " Top level entries: " + outline.length; if (conOut) print(out+"\n");

print ("Lv open Page    MuPDF/Adobe .pdf# open parameters        Title")
// ---------- helpers ----------
function pad(s, n) { s = s || ""; while (s.length < n) s += " "; return s; }

var openMap = (function () {
    var it = doc.outlineIterator(); var map = {};
    while (true) {
        var item = it.item(); if (!item) break; map[item.title || ""] = !!item.open; var r = it.next(); if (r < 0 || r !== 0) break;
    }
    return map;
})();

dump(outline, 0); }
function dump(items, level) {
    for (var i = 0; i < items.length; i++) {
        var it = items[i]; var title = '"' + (it.title || "").replace(/\u0000|\r|\n/g, "") + '"'; 
        var pageOut = (it.uri && doc.resolveLinkDestination(it.uri) || it).page + 1;
        var openFlag = ""; if (it.title in openMap && openMap[it.title]) { openFlag = "open "; }
        var out = pad(level + "", 3) + pad(openFlag,5) + pad(pageOut + "",6) + ' ' + pad(it.uri,40) + ' ' + title ;
        if (conOut) print(out); if (!noOutfile) txtOut.write(out + "\n");
        if (it.down && it.down.length > 0) { dump(it.down, level + 1); }
    }
}

// DONE
if (!noOutfile) { txtOut.save(outfile); print("\n Saved " + outfile); }
print("\n Press enter to exit ...");
var line = readline(); 
