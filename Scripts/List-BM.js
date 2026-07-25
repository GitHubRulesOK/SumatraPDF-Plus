// List-BM.js - MuPDF 1.28 / SumatraPDF 3.7 run JS bookmark extractor
//
// To automatically export a bookmark file from current pdf in view add an external viewer command similar to this for the X key
// Note it is set to pause to avoid a simple flash of the black console running so currently press enter to exit obe seen it worked!
// To see the full list in the console add -c between js and file like `.....List-BM.js -c "%1"`
//
// ExternalViewers [
//  [
//    CommandLine = "C:\Program Files\SumatraPDF\sumatrapdf-tool.exe" run "C:\Users\ path to your \Scripts\List-BM.js "%1"
//    Name = e&Xport filename-BM.txt
//    Key = x
//    Filter = *.pdf
//  ]
// ]
//
// BLOCK WScript double-click
if (typeof WScript !== "undefined") { WScript.Echo("Run using: \"SumatraPDF[-tool].exe\" run " + WScript.ScriptName + " [-c] [-d | -p] [-n | -o=\"out.txt\"] \"infile.pdf\""); WScript.Quit(); }
print("\n Running " + scriptPath);
var infile = null; var outfile = null; var conOut = false; var noOutfile = false; var mode = "pdfMode"; 
for (var i = 0; i < scriptArgs.length; i++) {
    var part = scriptArgs[i];
    if (part.charAt(0) === "-") {
        var eq  = part.indexOf("=");
        var key = (eq > 0) ? part.substring(1, eq) : part.substring(1); var val = (eq > 0) ? part.substring(eq + 1) : "";
        if (key === "c") { conOut = true; continue; } if (key === "n") { noOutfile = true; conOut = true; continue; }
        if (key === "o") { outfile = val; continue; }
        if (key === "p") { continue; } if (key === "d") { mode="docMode"; continue; }
        print("Unknown switch: " + part);
        quit();
    }
    if (!infile) { infile = part; continue; } print("Unexpected argument: " + part); quit();
}
if (!infile) { print(" List Bookmarks\n Usage: sumatrapdf-tool run " + scriptPath + " [-c] [-d | -p] [-n | -o=\"out.txt\"] \"infile.pdf\""); quit(); }
if (!noOutfile && (outfile === null || outfile === "")) { var base = infile.replace(/\.pdf$/i, ""); outfile = base + "-BM.txt"; }
// Main
var doc = mupdf.Document.openDocument(infile); var txtOut = new Buffer();
var out = " Mode= " + mode + " FILENAME: " + infile; print(out);
var outline = doc.loadOutline();
if (!outline || outline.length === 0) { out = " No outline in document: " + infile; print(out);
    // no dump() because nothing to dump
} else {
    out = "Top level entries: " + outline.length; if (conOut) print(out); 
    var openMap = buildOpenMap(doc);
    dump(outline, 0);
}
// DONE
if (!noOutfile) { txtOut.save(outfile); print(" Saved " + outfile); }
print("Press enter to exit ...");
var line = readline(); 

// ---------- helpers ----------
function fmt(n) { if (typeof n !== "number" || isNaN(n)) return "null"; return Math.round(n * 1000) / 1000; }  // 3 decimal places

function buildOpenMap(document) {
    var it = document.outlineIterator(); var map = {};
    while (true) {
        var item = it.item();
        if (!item) break;
        var key = item.title || ""; map[key] = !!item.open; var r = it.next();
        if (r < 0 || r !== 0) break;
    }
    return map;
}

function formatDestination(doc, item) {
    // URI-based destination
    if (item.uri) {
        try {
            var dest = doc.resolveLinkDestination(item.uri);
            if (dest && typeof dest.page === "number") {
                var pageIndex = dest.page; var pageObj   = doc.loadPage(pageIndex);
                var bbox = pageObj.getBounds(); var pageHeight = bbox[3] - bbox[1];
                var page = pageIndex + 1; var type = dest.type || "XYZ";
                if (/^Fit$/.test(type)) { return page + ' "[' + page + '/' + type + ']"'; } // FIT-style destinations (no co-ords)
                var x    = fmt(dest.x);  // was var y = fmt(pageHeight - dest.y);
                var y = (mode === "pdfMode") ? fmt(pageHeight - dest.y) : fmt(dest.y); // Default should be pdfMode else docMode
                var z = fmt(fmt(dest.zoom) / 100); return page + ' "[' + page + '/' + type + ' ' + x + ' ' + y + ' ' + z + ']"';
            }
        } catch (e) {}
    }
    if (typeof item.page === "number") { var p = item.page + 1; return p + ' "[' + p + '/Fit]"'; }    // Fallback: page only, treat as Fit
    return '0 "null"';
}

function dump(items, level) {
    for (var i = 0; i < items.length; i++) {
        var it = items[i]; var title = '"' + (it.title || "").replace(/\u0000|\r|\n/g, "") + '"'
        var destStr = formatDestination(doc, it); var parts = destStr.split(" ");
        var pageOut = parts[0]; var destOut  = parts.slice(1).join(" "); var openFlag = "";
        if (title in openMap && openMap[title]) { openFlag = "open "; }
        var out = level + ' ' + title + ' ' + pageOut + ' ' + openFlag + destOut;
        if (conOut) print(out); if (!noOutfile) txtOut.write(out + "\n");
        if (it.down && it.down.length > 0) { dump(it.down, level + 1); }
    }
}
