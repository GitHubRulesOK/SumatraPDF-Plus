// PDF extract text under HighLight Selections for MuPDf 1.27 Version 2026-02-01 
// Usage: mutool run HL2txt.js input.pdf
if (scriptArgs.length < 1) {
  print("Usage: mutool run highlight-extract-linear.js input.pdf"); quit();
}
var doc = Document.openDocument(scriptArgs[0]);
for (var p = 0; p < doc.countPages(); p++) {
  var page = doc.loadPage(p);
  var H = page.getBounds()[3];
  var sText = page.toStructuredText("preserve-whitespace,preserve-spans");
  var annots = page.getObject().get("Annots");
  if (!annots) continue;
  print("=== Page " + (p + 1) + " ===");
  for (var ai = 0; ai < annots.length; ai++) {
    var annot = annots.get(ai); var subtype = (annot.get("Subtype") || "").toString();
    if (subtype !== "/Highlight" && subtype !== "/Squiggly" && subtype !== "/Underline" && subtype !== "/Strikethrough")
      continue;
    var qp = null;
    try { qp = annot.get("QuadPoints"); } catch (e) {}
    if (!qp) {
      var r = annot.get("Rect");
      if (!r) continue;
      qp = [ r.get(0), r.get(3), r.get(2), r.get(3), r.get(0), r.get(1), r.get(2), r.get(1) ];
    }
    // flatten to plain array
    var quads = [];
    if (qp.get) {
      for (var i = 0; i < qp.length; i++) quads.push(qp.get(i));
    } else {
      for (var i = 0; i < qp.length; i++) quads.push(qp[i]);
    }
    var parts = [];
    for (var q = 0; q < quads.length; q += 8) {
      // PDF → text space: flip Y about H
      var x0 = quads[q+0], y0 = H - quads[q+1]; var x1 = quads[q+2], y1 = H - quads[q+3]; var x2 = quads[q+4], y2 = H - quads[q+5]; var x3 = quads[q+6], y3 = H - quads[q+7];
      var left = Math.min(x0, x1, x2, x3); var right = Math.max(x0, x1, x2, x3); var top = Math.min(y0, y1, y2, y3); var bottom = Math.max(y0, y1, y2, y3);
      // squiggly/underline may sit low: nudge box up a bit if required but not in this version
      if (subtype === "/Squiggly" || subtype === "/Underline") { top  -= 0.0; bottom -= 0.0; }
      // Ready to extract text
      var out = "";
      sText.walk({
        onChar: function(c, origin) {
          var ox = origin[0], oy = origin[1]; 
          if (ox >= left && ox <= right && oy >= top && oy <= bottom) {
            out += c;
          }
        }
      });
      parts.push(out);
    }
    var txt = parts.join(" ");
    print("ANNOT " + ai + " " + subtype + ": " + txt);
  }
}
