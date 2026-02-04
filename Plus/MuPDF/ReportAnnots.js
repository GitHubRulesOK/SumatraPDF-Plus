// List or Report or ShowAnnots.js can be any name Works with MuPDF 1.27 Improved version 2026-02-04-v02
//
// Usage: mutool run ListAnnots.js [-b] [-c] [-f=N] [-l=N] input.pdf
//       writes an output report filename: will be "input-annots.txt"
// -b is block mode -c is also write to console -f= to -l= are page ##'s
//
// example: mutool run listannots.js -b -c -f=2 SO79283524.pdf |findstr /i "rect"
// the full page 2 (of 2 pages) listing will be in a file but at console be something like
// Rect: [122.93577 665.1875 158.06423 679.8125]
// Rect: [92.93577 193.1875 128.06423 207.8125]
// ...
// --- argument parsing ---
var useBlocks = false; var toConsole = false; var inname = null; var firstPage = 1; var lastPage = null;
var i;
for (i = 0; i < scriptArgs.length; i++) {
  var a = scriptArgs[i];
  if (a === "-b") {
    useBlocks = true;
  } else if (a === "-c") {
    toConsole = true;
  } else if (a.indexOf("-f=") === 0) {
    firstPage = parseInt(a.substring(3), 10);
  } else if (a.indexOf("-l=") === 0) {
    lastPage = parseInt(a.substring(3), 10);
  } else if (a[0] !== "-") {
    inname = a;
  }
}
if (!inname) {
  print("Usage: mutool run ListAnnots.js [-b] [-c] [-f=N] [-l=N] file.pdf");
  quit();
}
var doc = Document.openDocument(inname); var outname = inname.replace(/\.pdf$/i, "") + "-annots.txt"; var out = new Buffer();
function padR(str, width) {
  // Preserve literal null
  if (str === null) {
    str = "null";
  } else {
    // Convert PDF string objects or arrays to plain text
    try {
      str = str.toString();
    } catch (e) {
      str = String(str);
    }
    // Remove PDF-style parentheses only when present
    if (str[0] === "(" && str[str.length - 1] === ")")
      str = str.substring(1, str.length - 1);
  }
  // Pad to fixed width
  while (str.length < width)
    str += " ";
  return str;
}
function writeAnnot(out, pageNum, annotObj, useBlocks, toConsole) {
  var author   = padR(annotObj.get("T"), 22); // 22 chars wide;
  var modified = padR(annotObj.get("M"), 22); // 22 chars wide;
  var subtype  = padR(annotObj.get("Subtype"), 10); // 10 chars wide
  var rect     = annotObj.get("Rect");
  var contents = annotObj.get("Contents");
  var line;
  if (useBlocks) {
    line = "Page: " + pageNum + "\nAuthor: " + author + "\nModified: " + modified + "\n";
    line += "Subtype: " + subtype + "\nRect: " + rect + "\nContents: " + contents + "\n";
    line += "----------------------------------------\n";
  } else {
    line = "page=" + pageNum + " author=" + author + " modified=" + modified + " subtype=" + subtype + " rect=" + rect + " contents=" + contents + "\n";
  }
  out.write(line);
  if (toConsole) { print(line.replace(/\n$/, "")); }
}
var total = doc.countPages();
// Use AdobePDF base 0 index and if lastPage not set, default to final page
if (lastPage === null || lastPage > total)
  lastPage = total;
var startIndex = firstPage - 1; var endIndex  = lastPage - 1;
if (startIndex < 0) startIndex = 0;
if (endIndex >= total) endIndex = total - 1;
// MAIN START
for (var i = startIndex; i <= endIndex; i++) {
  var page = doc.loadPage(i);
  var pageObj = page.getObject();
  var annots = pageObj.get("Annots");
  if (!annots || annots.length === 0)
    continue;
  for (var j = 0; j < annots.length; j++) {
    var annotObj = annots.get(j);
    // if (annotObj.get("Subtype") == "Popup") continue;
    writeAnnot(out, i + 1, annotObj, useBlocks, toConsole);
  }
}
out.save(outname);
print("Annotation report written to: " + outname);
