/*
 Add PDF highlight annotations over matching text, SeekAndHL can be any name. Works with MuPDF 1.27 Improved version 2026-02-05-v02

 Usage: mutool run SeekAndHL.js [-a=HLmode] [-c=RRGGBBAA] [-f=N] [-i] [-l=N] [-n] -s="text" [-t | -t="custom"] [-q] file.pdf

 -a=             Default=HL (Highlight, Squiggly, StrikeOut, Underline)
 -c=RRGGBBAA     highlight colour (default FFFF00FF) AA=Highlight Opacity (FF=50% Blend)
 -f=# / -l=#     first/last page numbers, same # = one page
 -i              case-insensitive searching
 -n              count-only mode (no save, no annotations)
 -s="find text"  Required literal quoted search string (supports spaces) may not always match seen plain text (Not full UTF)
 -t              embed above search string into annotation
 -t="text"       embed a custom text comment
 -q              quite

Note: UL/SQ/ST annotations are full opacity yet may appear faint with light colours. E.g. default Yellow 1 pt may look invisible.

*/
// --- input handler ---
var inname = null; var firstPage = 1; var lastPage = null; var searchStr = null; var pokeText = null; var pokeGiven = false;
var colorHex = "FFFF00FF"; var ignoreCase = false; var countOnly = false; var silent = false; var annotType = "Highlight";   // default fallback
for (var i = 0; i < scriptArgs.length; i++) {
    var a = scriptArgs[i];
    if (a.indexOf("-f=") === 0) {
        firstPage = parseInt(a.substring(3), 10);
    } else if (a.indexOf("-l=") === 0) {
        lastPage = parseInt(a.substring(3), 10);
    } else if (a.indexOf("-c=") === 0) {
        colorHex = a.substring(3).toUpperCase();
    } else if (a.indexOf("-s=") === 0) {
        searchStr = a.substring(3);
    } else if (a.indexOf("-a=") === 0) {
    var mode = a.substring(3).toLowerCase();
    if (mode === "hl" || mode === "hi" || mode === "highlight")
        annotType = "Highlight";
    else if (mode === "ul" || mode === "un" || mode === "underline")
        annotType = "Underline";
    else if (mode === "sq" || mode === "squiggly")
        annotType = "Squiggly";
    else if (mode === "st" || mode === "so" || mode === "strikeout")
        annotType = "StrikeOut";
    } else if (a === "-s") {
        searchStr = scriptArgs[++i];
    } else if (a === "-q") {
        silent = true;
    } else if (a.indexOf("-t=") === 0) {
        pokeText = a.substring(3);
        pokeGiven = true;
    } else if (a === "-t") {
        pokeGiven = true;
    } else if (a === "-i") {
        ignoreCase = true;
    } else if (a === "-n") {
        countOnly = true;
    } else if (a[0] !== "-") {
        inname = a;
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
    if (!silent) print("Page " + (p+1) + ": " + matches.length + " matches");
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
    if (!silent) print("Total matches: " + totalMatches);
} else {
    var outname = inname.replace(/\.pdf$/i, "") + "-hl.pdf";
    doc.save(outname); if (!silent) print("Saved annotated PDF as: " + outname);
}
