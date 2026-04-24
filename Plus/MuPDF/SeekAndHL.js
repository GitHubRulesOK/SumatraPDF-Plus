/*
 Add PDF highlight annotations over matching text, SeekAndHL can be any name. Works with MuPDF 1.27 or SumatraPDF 3.7+ Improved version 2026-04-24-v03

 Usage: mutool/SumatraPDF run SeekAndHL.js [-a=HLmode] [-c=RRGGBBAA] [-f=N] [-i] [-l=N] [-n] [-r=file.txt] -s="text" [-t | -t="custom"] [-q] file.pdf

 -a=             Default=HL (Highlight, Squiggly, StrikeOut, Underline)
 -c=RRGGBBAA     highlight colour (default FFFF00FF) AA=Highlight Opacity (FF=50% Blend)
 -f=# / -l=#     first/last page numbers, same # = one page
 -i              case-insensitive searching
 -n              count-only mode (no save, no annotations)
 -r=\"file.ext\"   Report File (Default is inputfile-hl.txt)
 -s="find text"  Required literal quoted search string (supports spaces) may not always match seen plain text (Not full UTF)
 -t              embed above search string into annotation
 -t="text"       embed a custom text comment
 -q              quite

Note: UL/SQ/ST annotations are full opacity yet may appear faint with light colours. E.g. default Yellow 1 pt may look invisible.

*/
// --- input handler ---
var inname = null; var firstPage = 1; var lastPage = null; var searchStr = null; var pokeText = null; var pokeGiven = false;var reportFile = "";
var colorHex = "FFFF00FF"; var ignoreCase = false; var countOnly = false; var silent = false; var annotType = "Highlight";   // default fallback
for (var i = 0; i < scriptArgs.length; i++) {
    var a = scriptArgs[i];
    if (a[0] !== "-") {
        inname = a;
        continue;
    }
    var key = a.slice(1, 2);
    var val = a.indexOf("=") > 0 ? a.slice(3) : null;
    switch (key) {
        case "a":
            var mode = val.toLowerCase();
            if (/^(hl|hi|highlight)$/.test(mode)) annotType = "Highlight";
            else if (/^(ul|un|underline)$/.test(mode)) annotType = "Underline";
            else if (/^(sq|squiggly)$/.test(mode)) annotType = "Squiggly";
            else if (/^(st|so|strikeout)$/.test(mode)) annotType = "StrikeOut";
            break;
        case "c": colorHex = val.toUpperCase(); break;
        case "f": firstPage = parseInt(val, 10); break;
        case "l": lastPage = parseInt(val, 10); break;
        case "i": ignoreCase = true; break;
        case "n": countOnly = true; break;
        case "q": silent = true; break;
        case "r": reportFile = val; break;
        case "s": searchStr = val; break;   // must use = form
        case "t": pokeGiven = true; if (val !== null) pokeText = val; break;
    }
}
if (!inname || !searchStr) { print("Usage: mutool run SeekAndHL.js [-a=HLmode] [-c=RRGGBBAA] [-f=N] [-i] [-l=N] [-n] -s=\"text\" [-t | -t=\"custom\"] [-q] file.pdf"); quit(); }
// --- check poke-in text (-t) ---
if (pokeGiven) {
    if (pokeText === null) pokeText = searchStr;
} else {
    pokeText = null;
}
// --- convert RRGGBBAA to RGB and 50% opacity/blend (A) ---
function hexToRGBA(hex) {
    hex = hex.toUpperCase();
    if (hex.length === 6) { var r = parseInt(hex.substring(0,2), 16) / 255; var g = parseInt(hex.substring(2,4), 16) / 255;
        var b = parseInt(hex.substring(4,6), 16) / 255; return [r, g, b, 1]; }
    if (hex.length === 8) { var r = parseInt(hex.substring(0,2), 16) / 255; var g = parseInt(hex.substring(2,4), 16) / 255;
        var b = parseInt(hex.substring(4,6), 16) / 255; var a = parseInt(hex.substring(6,8), 16) / 255; return [r, g, b, a]; }
    // Default Bright yellow
    return [1, 1, 0, 1];
}
var rgba = hexToRGBA(colorHex);
var doc = Document.openDocument(inname); var total = doc.countPages();
var txtOut = new Buffer();
var defaultReportFile = inname.replace(/\.pdf$/i, "") + "-hl.txt";

if (lastPage === null || lastPage > total)
    lastPage = total;
var startIndex = firstPage - 1; var endIndex   = lastPage - 1;
if (startIndex < 0) startIndex = 0;
if (endIndex >= total) endIndex = total - 1;
var totalMatches = 0;
// --- MAIN ---
for (var p = startIndex; p <= endIndex; p++) {
    var page = doc.loadPage(p); var sText = page.toStructuredText(); var searchKey = searchStr; var matches = [];
if (ignoreCase) {
    matches = sText.search(searchStr, StructuredText.SEARCH_IGNORE_CASE) || [];
} else {
    matches = sText.search(searchStr, StructuredText.SEARCH_EXACT) || [];
}
    totalMatches += matches.length;
    var out=("Page " + (p+1) + ": " + matches.length + " matches");
    txtOut.write(out + "\n");if (!silent) print(out);
    if (countOnly) continue;
    for (var i = 0; i < matches.length; i++) {
        var quads = matches[i]; var annot = page.createAnnotation(annotType);
        annot.setQuadPoints(quads); annot.setColor([rgba[0], rgba[1], rgba[2]]); annot.setOpacity(rgba[3]);
        if (pokeText !== null) annot.setContents(pokeText);
        annot.update();
    }
}
// --- save or report ---
if (countOnly) {
    var out=("Total matches: " + totalMatches);
    txtOut.write(out + "\n");if (!silent) print(out);
} else {
    var outname = inname.replace(/\.pdf$/i, "") + "-hl.pdf";
    doc.save(outname); if (!silent) print("Saved annotated PDF as: " + outname);
}
var finalReport = reportFile || defaultReportFile;
txtOut.save(finalReport);