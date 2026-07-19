// This file will attempt to set PDF Outline page zoom factor to null or a zoom Factor.
// It has only been tested on a few problem files so ensure you keep your source files.
// It does not garbage collect old indirect obj as that could affect other objects.
//
// BLOCK WScript double-click
if (typeof WScript !== "undefined") { WScript.Echo("Run using: \"SumatraPDF[-tool].exe\" run " + WScript.ScriptName + " -o=\"out.pdf\" -z=##% \"infile.pdf\""); WScript.Quit(); }
print("\n Running " + scriptPath);
var outfile = null; var zoomArg = null; var infile= null;
function usage(msg) { throw msg + "\n Usage: sumatrapdf-tool run " + scriptPath + " -o=\"out.pdf\" -z=##% (for null use -z=0%) \"infile.pdf\""; }
for (var i = 0; i < scriptArgs.length; i++) {
    var part = scriptArgs[i];
    if (part.charAt(0) === "-") {
        var eq = part.indexOf("="); var key = (eq > 0) ? part.substring(1, eq) : part.substring(1); var val = (eq > 0) ? part.substring(eq + 1) : "";
        if (key === "o") { outfile = val; continue; }
        if (key === "z") { if (val.indexOf("%") < 0) usage("Zoom must be percent, e.g. -z=150%");
            var z = Number(val.replace("%", "")); if (isNaN(z)) usage("Invalid zoom percent: " + val); zoomArg = (z === 0) ? NaN : z; continue;
        }
        usage(" Unknown switch: " + part);
    }
    if (!infile) { infile = part; continue; }
    usage(" Unexpected argument: " + part);
}
if (zoomArg === null) usage(" Missing -z=#% zoom argument (use -z=0% for null) ");
if (!outfile) { var base = infile.replace(/\.pdf$/i, ""); var ztxt = (isNaN(zoomArg)) ? "null" : zoomArg; outfile = base + "-zoom-" + ztxt + ".pdf"; }

function main() {
    var doc = mupdf.Document.openDocument(infile); var it  = doc.outlineIterator(); walk(it, function () { fixZoom(it, doc, zoomArg); });
    doc.save(outfile);
print (" Saved " +outfile);
}

function walk(it, fn) {
    while (true) {
        var item = it.item();
        if (item) { fn(); }
        if (it.down() === 0) continue; if (it.next() === 0) continue;
        while (true) {
            if (it.up() < 0) return; if (it.next() === 0) break;
        }
    }
}

function fixZoom(it, doc, zoomArg) {
    var item = it.item(); if (!item || !item.uri) return;
    var dest = doc.resolveLinkDestination(item.uri); if (!dest || dest.type !== "XYZ") return;
    var pageN = dest.page + 1; var zoomStr = (zoomArg === "nan") ? "nan" : zoomArg; var x = dest.x; var y = dest.y;
    var newUri = "#page=" + pageN + "&zoom=" + zoomStr + "," + x + "," + y;
    var item2 = { b: item.b, g: item.g, r: item.r, flags: item.flags, open: item.open, title: item.title, uri: newUri };
    it.update(item2);
}

main();
