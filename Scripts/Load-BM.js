// This file will attempt to load a PDF Outline textfile and replace the Bookmarks tree.
// It has only been tested on a few problem files so ensure you keep your source files.
// It does not garbage collect old indirect objects as that could affect other objects.
// NOTE this LoadBkmS uses GOTO Y based on PDF upwards distance (NOT MuPDF down values).
//
// The aim is to autoload a PDF-BM.txt file and use it to replace the existing bookmarks.
// This means you must have exported existing bookmarks list using List-BM.js in pdfMode.
// That file can be edited to add or remove PDF Outline (bookmark) entries. They will be 
// based on "bottoms-up" so beware the need to subtract target y value from page height.
//
//
print("\n Running " + scriptPath);
var outfile = null; var textfile = null; var infile = null;
function usage(msg) { throw msg + "\n Usage: sumatrapdf-tool run " + scriptPath + " -o=\"out.pdf\" OR defaults \"infile-BM.pdf\" [-t= OR -b=\"bookmarks.txt\" OR defaults \"infile-BM.txt\"] \"infile.pdf\""; };
function pdfToViewY(pdfY, pageHeight) { return pageHeight - pdfY; }
for (var i = 0; i < scriptArgs.length; i++) {
    var part = scriptArgs[i];
    if (part.charAt(0) === "-") {
        var eq = part.indexOf("="); var key = (eq > 0) ? part.substring(1, eq) : part.substring(1); var val = (eq > 0) ? part.substring(eq + 1) : "";
        if (key === "o") { outfile = val; continue; }
        if (key === "t" || key === "b") { textfile = val; continue; }        // text file: -t= or -b=
        usage(" Unknown switch: " + part);
    }
    if (!infile) { infile = part; continue; }
    usage(" Unexpected argument: " + part);
}
if (!infile) { usage(" Missing input PDF file "); }
if (textfile) { } else { var base = infile.replace(/\.pdf$/i, ""); var bmFile = base + "-BM.txt"; textfile = bmFile; }
var text = read(textfile);
if (!outfile) { var base = infile.replace(/\.pdf$/i, ""); outfile = base + "-BM.pdf"; }
var lines = text.split(/\r?\n/);
var doc = mupdf.Document.openDocument(infile); var cursor = doc.outlineIterator();
while (cursor.item()) cursor.delete(); // clear existing outline
var flat = [];
for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();
      if (line === "") continue;
      var level = parseInt(line.split(/\s+/)[0], 10); var t1 = line.indexOf('"') + 1; var t2 = line.indexOf('"', t1); var title = line.substring(t1, t2);
      var rest = line.substring(t2 + 1).trim(); var pageMatch = rest.match(/^\d+/);
      if (!pageMatch) continue;
      var pnum = parseInt(pageMatch[0], 10); rest = rest.substring(pageMatch[0].length).trim(); rest = rest.replace(/\bopen\b/i, "").trim();
      var d1 = rest.indexOf('"') + 1; var d2 = rest.lastIndexOf('"'); var inner = rest.substring(d1, d2).trim();
      if (inner.charAt(0) === "[" && inner.charAt(inner.length - 1) === "]") inner = inner.substring(1, inner.length - 1).trim();
      // --- Destination parsing
      inner = inner.replace(/^\d+\s*/, "").trim(); // remove leading page number if present
      var view = null; var viewrect = null; var args = []; var x = null, y = null, z = null;
      if (inner.indexOf("/FitR") === 0) { view = null; viewrect = inner.substring(5).trim() .match(/[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?|null/g) || []; }
      else if (inner.indexOf("/FitH") === 0) { view = "FitH"; args = inner.substring(5).trim() .match(/[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?|null/g) || []; }
      else if (inner.indexOf("/FitBH") === 0) { view = "FitBH"; args = inner.substring(6).trim() .match(/[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?|null/g) || []; }
      else if (inner.indexOf("/FitV") === 0) { view = "FitV"; args = inner.substring(5).trim() .match(/[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?|null/g) || []; }
      else if (inner.indexOf("/FitBV") === 0) { view = "FitBV"; args = inner.substring(6).trim() .match(/[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?|null/g) || []; }
      else if (inner.indexOf("/FitB") === 0) { view = "FitB"; args = []; }
      else if (inner.indexOf("/Fit") === 0) { view = "Fit"; args = []; }
      else if (inner.indexOf("/XYZ") === 0) {
          var nums = inner.substring(4).trim() .match(/[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?|null/g);
          if (nums && nums.length >= 3) { x = nums[0]; y = nums[1]; z = nums[2]; }
      }
      flat.push({ level: level, title: title, page: pnum, view: view, args: args, viewrect: viewrect, x: x, y: y, z: z, down: [] });
}
var root = []; var stack = [{ level: -1, children: root }];
for (var i = 0; i < flat.length; i++) {
    var node = flat[i];
    while (stack[stack.length - 1].level >= node.level)
        stack.pop();
    stack[stack.length - 1].children.push(node); stack.push({ level: node.level, children: node.down });
}
var stack2 = [{ cursor: cursor, list: root, index: 0 }];
while (stack2.length > 0) {
    var frame = stack2[stack2.length - 1];
    if (frame.index >= frame.list.length) {
        stack2.pop();
        if (stack2.length > 0) { cursor.up(); cursor.next(); }
        continue;
    }
    var node = frame.list[frame.index++]; var pageObj = doc.loadPage(node.page - 1); var rect = pageObj.getBounds();
    var pageHeight = rect[3] - rect[1]; var yDOC = pageHeight - node.y;
var uri;
    // For DEBUG 
//print (node.view + yDOC);
// XYZ
if (node.view === null && node.viewrect === null && node.x !== null) {
    var scaleVal; var pdfY = parseFloat(node.y); var viewerY = pageHeight - pdfY; // convert to top-down
    if (node.z === "null") { scaleVal = "nan"; }
    else { scaleVal = (parseFloat(node.z) * 100).toString(); }
    uri = "#page=" + node.page + "&zoom=" + scaleVal + "," + node.x + "," + viewerY;
//print (uri);
}
// FitR (x,y,w,h)
else if (node.viewrect) {
    var viewerX = parseFloat(node.viewrect[0]);
    var viewerY = pageHeight - parseFloat(node.viewrect[3]);
    var width  = parseFloat(node.viewrect[2]) - parseFloat(node.viewrect[0]);
    var height = parseFloat(node.viewrect[3]) - parseFloat(node.viewrect[1]);
    uri = "#page=" + node.page + "&viewrect=" + viewerX + "," + viewerY + "," + width + "," + height;
}
else if (node.view === "Fit") { uri = "#page=" + node.page + "&view=Fit"; }
else if (node.view === "FitB") { uri = "#page=" + node.page + "&view=FitB"; }
else if (node.view === "FitH" || node.view === "FitBH") {
    //var pdfTop = parseFloat(node.args[0]);     // PDF bottom-up
    var viewerTop = pageHeight - parseFloat(node.args[0]);       // convert to top-down
    uri = "#page=" + node.page + "&view=" + node.view + "," + viewerTop;
//print (uri);
}
else if (node.view === "FitV" || node.view === "FitBV") { uri = "#page=" + node.page + "&view=" + node.view + "," + node.args[0]; }

  cursor.insert({ title: node.title, uri: uri, open: true });
    if (node.down.length > 0) {
        cursor.prev();
        cursor.down();
        stack2.push({ cursor: cursor, list: node.down, index: 0 });
    }
}

doc.save(outfile);
print (" Saved " + outfile);
