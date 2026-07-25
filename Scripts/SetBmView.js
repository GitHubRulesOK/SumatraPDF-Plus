// This file will attempt to set PDF Outline page zoom factor to null or a zoom Factor.
// It has only been tested on a few problem files so ensure you keep your source files.
// It does not garbage collect old indirect objects as that could affect other objects.
// NOTE this SetBmView variation adds -x= & -y= settings in addition to SetBmZoom -z=
//
// BLOCK WScript double-click
if (typeof WScript !== "undefined") { WScript.Echo("Run using: \"SumatraPDF[-tool].exe\" run " + WScript.ScriptName + " -o=\"out.pdf\" [-x=##] [-y=##] -z=##% \"infile.pdf\""); WScript.Quit(); }
print("\n Running " + scriptPath);
var outfile = null; var xArg = null; var yArg = null; var zoomArg = null; var infile = null;
function usage(msg) { throw msg + "\n Usage: sumatrapdf-tool run " + scriptPath + " -o=\"out.pdf\" [-x=##] [-y=##] -z=##% (for null use -z=0%) \"infile.pdf\""; }
for (var i = 0; i < scriptArgs.length; i++) {
    var part = scriptArgs[i];
    if (part.charAt(0) === "-") {
        var eq = part.indexOf("="); var key = (eq > 0) ? part.substring(1, eq) : part.substring(1); var val = (eq > 0) ? part.substring(eq + 1) : "";
        if (key === "o") { outfile = val; continue; }
if (key === "x") { var xv = Number(val); if (isNaN(xv)) usage("Invalid x offset: " + val); xArg = xv; continue; }
if (key === "y") { var yv = Number(val); if (isNaN(yv)) usage("Invalid y offset: " + val); yArg = yv; continue; }
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
    var doc = mupdf.Document.openDocument(infile); var it = doc.outlineIterator(); walk(it, function () { fixZoom(it, doc, zoomArg); });
    doc.save(outfile);
print (" Saved " + outfile);
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

function exfixZoom(it, doc, zoomArg) {
    var item = it.item(); if (!item || !item.uri) return;
    var dest = doc.resolveLinkDestination(item.uri); if (!dest) return;
    var norm = normalizeXYZ(dest);
    var x = (xArg !== null) ? xArg : norm.x; var y = (yArg !== null) ? yArg : norm.y; var z = (zoomArg !== null) ? zoomArg : norm.z;
    var pageN = dest.page + 1; var zoomStr = isNaN(z) ? "nan" : z;
    var newUri = "#page=" + pageN + "&zoom=" + zoomStr + "," + x + "," + y;
    var item2 = { b: item.b, g: item.g, r: item.r, flags: item.flags, open: item.open, title: cleanTitle(item.title), uri: newUri };
    it.update(item2);
}
function fixZoom(it, doc, zoomArg) {
    var item = it.item(); if (!item || !item.uri) return;
    var dest; try { dest = doc.resolveLinkDestination(item.uri); } catch (e) { dest = null; }
    // Resolve page number exactly like the lister
    var pageN = 1;
    if (dest && typeof dest.page === "number") { pageN = dest.page + 1; }
    else if (typeof item.page === "number") { pageN = item.page + 1; }
    else { pageN = 1; }
    var norm = normalizeXYZ(dest || {});
    var x = (xArg !== null) ? xArg : norm.x; var y = (yArg !== null) ? yArg : norm.y; var z = (zoomArg !== null) ? zoomArg : norm.z;
    var zoomStr = isNaN(z) ? "nan" : z;
    var newUri = "#page=" + pageN + "&zoom=" + zoomStr + "," + x + "," + y;
    var item2 = { b: item.b, g: item.g, r: item.r, flags: item.flags, open: item.open, title: cleanTitle(item.title), uri: newUri };
    it.update(item2);
}

// This should resolve basic view /FIT into zoom /XYZ 0 0 null and later apply any -x or -y or -z over-rides
function normalizeXYZ(dest) {
    var x = 0, y = 0, z = NaN;
    switch (dest.type) { 
    case "Fit": case "FitB": x = 0; y = 0; break;
    case "FitH": case "FitBH": x = 0; y = isNaN(dest.y) ? 0 : dest.y; break;
    case "FitV": case "FitBV": x = isNaN(dest.x) ? 0 : dest.x; y = 0; break;
    case "FitR": x = isNaN(dest.x) ? 0 : dest.x; y = isNaN(dest.y) ? 0 : dest.y; break;
    case "XYZ":  x = isNaN(dest.x) ? 0 : dest.x; y = isNaN(dest.y) ? 0 : dest.y; z = isNaN(dest.zoom) ? NaN : dest.zoom; break;
    }
    return { x:x, y:y, z:z };
}

// THis fixes only BAD title entries 
function cleanTitle(s) {
    if (!s) return "";
    return s
        .replace(/\u0000/g, "")   // remove null padding
        .replace(/\r/g, "")       // remove embedded CR
        .replace(/\n/g, "");      // remove embedded LF
}

main();
