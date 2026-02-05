// Extract text under PDF HighLight HLZone2TXT.js can be any name Works with MuPDF 1.27 Improved version 2026-02-05-v02
//
// Usage: mutool run HL2Text.js [-f=N] [-l=N] [-o|-o=filename.txt] [-s] file.pdf
// -o writes an output filename: will be "input-annots.txt" unless specified
// -f= to -l= are page ##'s and -s is for no console stream (pointless without -o)
//
// you can modify the script to include or exclude annotation types as required for example /Square or /Circle
//
// --- input handler ---
var inname = null; var firstPage = 1; var lastPage = null; var outname = null; var silent = false; var writeFile = false;
for (var i = 0; i < scriptArgs.length; i++) {
  var a = scriptArgs[i];
  if (a.indexOf("-f=") === 0) {
    firstPage = parseInt(a.substring(3), 10);
  } else if (a.indexOf("-l=") === 0) {
    lastPage = parseInt(a.substring(3), 10);
  } else if (a === "-o") {
    writeFile = true;
  } else if (a.indexOf("-o=") === 0) {
    writeFile = true;
    outname = a.substring(3);
  } else if (a === "-s") {
    silent = true;
  } else if (a[0] !== "-") {
    inname = a;
  }
}
if (!inname) { print("Usage: mutool run HL2Text.js [-f=N] [-l=N] [-o|-o=filename.txt] [-s] file.pdf"); quit(); }
var doc = Document.openDocument(inname); var total = doc.countPages();
if (lastPage === null || lastPage > total) lastPage = total;
var startIndex = firstPage - 1; var endIndex  = lastPage - 1;
if (startIndex < 0) startIndex = 0; if (endIndex >= total) endIndex = total - 1;
// --- output handler ---
var out = null;
if (writeFile) {
  if (!outname) outname = inname.replace(/\.pdf$/i, "") + "-annots.txt";
  out = new Buffer();
}
// --- MAIN ---
for (var p = startIndex; p <= endIndex; p++) {
  var page = doc.loadPage(p); var H = page.getBounds()[3];
  var sText = page.toStructuredText("preserve-whitespace,preserve-spans");
  var annots = page.getObject().get("Annots");
  if (!silent) print("=== Page " + (p + 1) + " ==="); if (writeFile) out.write("=== Page " + (p + 1) + " ===\n");
  if (!annots) continue;
  var printedIndex = 0;
  for (var a = 0; a < annots.length; a++) {
    var annot = annots.get(a); var subtype = (annot.get("Subtype") || "").toString();
    if (subtype !== "/Highlight" && subtype !== "/Squiggly" && subtype !== "/Underline" &&
      subtype !== "/Strikethrough") {
      if (!silent) print("ANNOT " + a + " (N/A)"); if (writeFile) out.write("ANNOT " + a + " (N/A)\n");
      continue;
    }
    printedIndex++;
    // --- QuadPoints or Rect ---
    var qp = null;
    try { qp = annot.get("QuadPoints"); } catch (e) {}
    if (!qp) {
      var r = annot.get("Rect"); if (!r) continue;
      qp = [ r.get(0), r.get(3), r.get(2), r.get(3), r.get(0), r.get(1), r.get(2), r.get(1) ];
    }
    var quads = [];
    if (qp.get) {
      for (var i = 0; i < qp.length; i++) quads.push(qp.get(i));
    } else {
      for (var i = 0; i < qp.length; i++) quads.push(qp[i]);
    }
    var parts = [];
    for (var q = 0; q < quads.length; q += 8) {
      // PDF to text space: flip Y about H
      var x0 = quads[q+0], y0 = H - quads[q+1]; var x1 = quads[q+2], y1 = H - quads[q+3]; var x2 = quads[q+4], y2 = H - quads[q+5]; var x3 = quads[q+6], y3 = H - quads[q+7];
      var left  = Math.min(x0, x1, x2, x3); var right = Math.max(x0, x1, x2, x3); var top  = Math.min(y0, y1, y2, y3); var bottom = Math.max(y0, y1, y2, y3);
      // squiggly/underline may sit low: nudge box up a bit if required but not in this version
      if (subtype === "/Squiggly" || subtype === "/Underline") { top -= 0.0; bottom -= 0.0; }
      // Ready to extract text
      var textract = "";
      sText.walk({
        onChar: function(c, origin) {
          var ox = origin[0], oy = origin[1];
          if (ox >= left && ox <= right && oy >= top && oy <= bottom)
            textract += c;
        }
      });
      parts.push(textract);
    }
    var txt = parts.join(" ");
    if (!silent) print("ANNOT " + a + " (" + printedIndex + ") " + subtype + ": " + txt);
    if (writeFile) out.write("ANNOT " + a + " (" + printedIndex + ") " + subtype + ": " + txt + "\n");
  }
}
// --- save file output ---
if (writeFile) {
  out.save(outname);
  if (!silent) print("Annotation report written to: " + outname);
}
