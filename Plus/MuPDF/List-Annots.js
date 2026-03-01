// ------------------------------------------------------------
// Temporary Flags (aligning towards annots.js)
// This version does not filter by mutiple range of pages or -a=subtype,S...S only ALL OR to limit to ONE type see // IF ANNOT below
// ------------------------------------------------------------
var BlockMode = false; var verbose = false; var Debug = false; var reportFile = ""; var inname = ""; var quieter = false; var pageSpec = null; var pageMap = null;
for (var i = 0; i < scriptArgs.length; i++) {
    var arg = scriptArgs[i];
    if (arg === "-b") BlockMode = true;
    else if (arg === "-d") Debug = true;
    else if (arg.indexOf("-p=") === 0) pageSpec = arg.slice(3);
    else if (arg === "-q") quieter = true;
    else if (arg === "-v") verbose = true;
   // do NOT use startsWith or substring  NOT else if (arg.startsWith("-r=")) reportFile = arg.substring(3);
    else if (arg.indexOf("-r=") === 0) reportFile = arg.slice(3);
    else if (arg[0] !== "-") inname = arg;   // filename
}
if (!inname) {
print("Usage: mutool run List-Annots.js [switches] <file.pdf>\nSwitches:\n  -b                  Block mode\n  -d                  Debug output\n  -p=r,a,n-g,e        Process page range."
+" Accepts odd or even (No -p= is All)\n  -q                  Quieter\n  -r=\"Reportfile.ext\" (Default is inputfile-list.txt)\n  -v                  More verbose information\n\n");
quit();
}
// ------------------------------------------------------------
// Main
// ------------------------------------------------------------
var doc = new PDFDocument(inname);
var pageCount = doc.countPages();
var txtOut = new Buffer();
var defaultReportFile = inname.replace(/\.pdf$/i, "") + "-list.txt";
/* ---------------
 Page selection
----------------*/
// If user gave no -p=, default to "1-total"
if (!pageSpec) pageSpec = "1-" + pageCount;
// parsePageS is a later function, thus as "hoisted" is available
var pageMap = parsePageS(pageSpec, pageCount);
var pageString = Object.keys(pageMap).join(",");
// BlockMode / Lines mode HEADERS
if (BlockMode) {
var out = ("=== Annotation Report for Page(s): " + pageSpec + " in File: " + inname + " ===\n"); txtOut.write(out + "\n"); if (!quieter) print(out);
} else {
// These differ LATER  9000, 10000, 1000,FileAttachment,#000000.., are the most common
if (!verbose) var out = ("\nPage,Index,Object,Annots-Subtype,Hex Color,BStyle,Width,Rectangle compact or trimmed as.## ,Comments,Action/Metadata/Other\n");
if (verbose)  var out = ("\nPage,Index,Object,Annots-Subtype,Hex Color,BStyle,Width,Rectangle (verbose) or Quads                     ,LinkHL,Comments,Action/Metadata/Other\n");
txtOut.write(out); if (!quieter) print(out);
}


var total = 0;
var lastPagePrinted = -1;

for (var p = 0; p < pageCount; p++) {
  var page = doc.loadPage(p); var showP = " (" + (p+1) +"/" + pageCount + ") ";
//    forEachPage(doc, pageMap, function(page, pg) {
  if (!pageMap[p + 1]) continue;
  var pageObj = page.getObject(); var annots = pageObj.get("Annots");
  if (Debug) print("DBG: annots " + annots);
  if (!annots) { var out = ("=== Page: " + (p+1) +  showP + "Object: " + getObjectNumber(pageObj) + " 0 Obj NO /Annot");txtOut.write(out + "\n"); if (!quieter) print(out); continue; }

// PAGE HAS ANNOTS If BlockMode then PAGE HEADER GOES HERE
  if (Debug) print("DBG: page " + page + " pageObj " + pageObj + " annots " + annots);
  if (BlockMode) {
    if (p !== lastPagePrinted) {
      lastPagePrinted = p;
    }
  var out = ("=== Page: " + (p+1) +  showP + "\n"); txtOut.write(out+ "\n"); if (!quieter) print(out);
  }
  if (Debug) print ("DBG: About to run for (var i = 0; i < annots.length; i++)")
  for (var i = 0; i < annots.length; i++) {
    if (Debug) print ("DBG: inside for loop i = " + i);
    var annotRefString = String(annots.get(i));  // "110 0 R"
    if (Debug) print ("DBG: annotRefString " + annotRefString);
    var annotObj = annots.get(i); // WORKING resolved dictionary
    if (Debug) print("DBG: annotObj " + annotObj);
      var subtype = annotObj.get("Subtype");
      var subtypeName = subtype ? subtype.toString().replace("/", "") : "Unknown";

// IF ANNOT change the // comment downwards to only get replies for say /Highlight
// var target = ("/Highlight"); if (!subtype || subtype.toString() !== target) {
     if (!subtype) {
// IF ANNOT and NOT target if BlockMode then Print it so
            if (BlockMode) {
            var out = ("Object: " + getObjectNumber(annotObj) + " 0 Obj is a " + subtypeName + " (not a match)\n"); txtOut.write(out); if (!quieter) print(out);
            }
            continue;
      }
if (Debug) print("DBG: subtype " + subtype);
// IF TARGET use BlockMode OR inLINE 
      var rec = makeR(p, i, annotRefString, annotObj);
      if (BlockMode) {
        if (rec.page !== lastPagePrinted) {
            lastPagePrinted = rec.page;
        }
        if (Debug) print("DBG: Calling asBlock with rec");
        var out = asBlock(rec); txtOut.write(out+"\n"); if (!quieter) print(out);
        if (Debug) print("DBG: Returned from asBlock with rec");
      } else {
        if (Debug) print("DBG: Calling asLines with rec");
        var out = asLines(rec);txtOut.write(out+"\n");if (!quieter) print(out);
        if (Debug) print("DBG: Returned from asLines with rec");
      }
    }
  var finalReport = reportFile || defaultReportFile;
  //var finalPdf = outname || defaultOutPdf;
  txtOut.save(finalReport);
}
// ------------------------------------------------------------
// Functions DO NOT USE includes or other ES6 structures
// ------------------------------------------------------------
function csvEsc(s) {
if (Debug) print ("DBG: Entered csvEsc with "+s); 
    if (s == null) return ""; s = String(s);
    if (s.indexOf(",") !== -1 || s.indexOf("\"") !== -1) return "\"" + s.replace(/"/g, "\"\"") + "\"";
if (Debug) print ("DBG: In csvEsc returning " +s);
    return s;
}
// annots.get(i) returns something like "110 0 R" (extract "110")
function getObjectNumber(refString) { if (!refString) return ""; return String(refString).split(" ")[0]; }
function r3(x) { return Math.round(x * 1000) / 1000; } //redundant but keep for now
function rectToCSV(rect, n) {
  // If n is null/undefined/negative = no trimming
  if (n == null || n < 0) { return "[" + rect.get(0) + "," + rect.get(1) + "," + rect.get(2) + "," + rect.get(3) + "]"; }
  var p = Math.pow(10, n); return "[" +  (Math.round(rect.get(0) * p) / p) + "," + (Math.round(rect.get(1) * p) / p) + ","
  + (Math.round(rect.get(2) * p) / p) + "," + (Math.round(rect.get(3) * p) / p) + "]";
}
function formatColor(c) {
    if (!c) return "";
    var r = Math.round(c.get(0) * 255); var g = Math.round(c.get(1) * 255); var b = Math.round(c.get(2) * 255);
    return "#" + ("0" + r.toString(16)).slice(-2) + ("0" + g.toString(16)).slice(-2) + ("0" + b.toString(16)).slice(-2);
}
function borderWidth(a) {
    var bs = a.get("BS");
    if (bs) { var w = bs.get("W"); if (w !== undefined) return w; }
    var b = a.get("Border");
    if (b && b.length >= 3) return b.get(2);
    return "";
}
function borderStyle(a) {
    var bs = a.get("BS");
    if (!bs) return "Solid";
    var s = bs.get("S");
    if (!s) return "Solid";
    return s.toString().replace("/", "");
}
function highlightType(a) {
    var subtype = a.get("Subtype");
    if (!subtype || subtype.toString() !== "/Link") return "";   // <-- no highlight mode for non-links
    var h = a.get("H"); if (!h) return "Invert";   // default for links only
    return h.toString().replace("/", "");
}
function dataToCSV(a) {
    if (!a) return "";
    var s = a.get("S");
    if (!s) return "";
    s = s.toString().replace("/", "");
    if (s === "URI") {
        return "URI(" + a.get("URI") + ")";
    }
    return s;
}
// ---------------------------------------------
// Assign output data used for asLines or asBlock
// ---------------------------------------------
function makeR(p, i, annotRefString, annotObj) {
    return {
        page:      p + 1,
        index:     i,
        obj:       getObjectNumber(annotRefString),
        subtype:   subtype.toString().replace("/", ""), // generic
        color:     formatColor(annotObj.get("C")),
        style:     borderStyle(annotObj),
        width:     borderWidth(annotObj),
        rect:      rectToCSV(annotObj.get("Rect"), verbose ? -1 : 2), // trim !verbose placements to allow for 9999.##
        highlight: highlightType(annotObj),  // this is /Link/Highlight action e.g. Invert
        author:    (annotObj.get("T")),
        modified:  (annotObj.get("M")),
        contents:  (annotObj.get("Contents")),
        data:      dataToCSV(annotObj.get("A")) // A=Action should /JS be included ?
    };
}
function setL(s,n){s=String(s); while(s.length<n) s+= " "; return s;}
function setR(s,n){s=String(s); while(s.length<n) s=" "+s; return s;}
function asLines(r) {
if (Debug) print ("DBG: entered asLines with "+r); 
    return (
        setR(r.page, 4) + "," +
        setR(r.index, 5) + "," +
        setR(r.obj, 6) + "," +
        setL(r.subtype, 14) + "," + // can be "FileAttachment"
        setL(r.color, 9) + "," +    // can be #00000000
        setL(r.style, 6) + "," +
        setR(r.width, 5) + "," +
        setL(csvEsc(r.rect), 35) + "," +  // This is just enough for more common ####.## usages but what about verbose could be different per above
        (verbose && r.subtype === "Link" ? setL(r.highlight, 9) + ","  : "" ) +  // Only add Link highlight column when verbose
        csvEsc(r.contents) + "," +  // probably not needed for /Links adds an empty column ?
        csvEsc(r.data)
    );
if (Debug) print ("DBG: Exit asLines"); 
}
function asBlock(r) {
if (Debug) print ("DBG: entered asBlock with "+r); // Note page # is already shown before asBlock
    return (
        "Index(base0): " + r.index     + "\n" +
        "Object:       " + r.obj       + "\n" +
        "Subtype:      " + r.subtype   + "\n" +
        "Color as Hex: " + r.color     + "\n" +
        "Border Style: " + r.style     + "\n" +
        "Width:        " + r.width     + "\n" +
        (verbose
      ? "Rectangle:    " + r.rect // verbose
      : "Rect(max.##): " + r.rect //!verbose
        ) + "\n" +
        (verbose && r.subtype === "Link" ? "Highlight:    " + r.highlight + "\n" : "" ) +
        "Contents:     " + csvEsc(r.contents)  + "\n" +
        "Data:         " + r.data      + "\n"  //do not add + on last entry
    );
if (Debug) print ("DBG: Exit asBlock"); 
}
/* ---------------
 Parse page-range
  Left-to-right:
- ranges add pages
- odd/even current set
- add single number
- "end" = maxPages
----------------*/
function parsePageS(spec, maxPages) {
    var map = {};
    if (!spec) {
        // default: all pages
        for (var p = 1; p <= maxPages; p++) map[p] = true;
        return map;
    }
    var parts = String(spec).split(",");
    // working set as a map
    var current = {};
    for (var i = 0; i < parts.length; i++) {
        var part = parts[i].trim();
        if (!part) continue;
        var low = part.toLowerCase();
        // odd / even refine current set if non-empty, otherwise global
        if (low === "odd" || low === "even") {
            var wantOdd = (low === "odd");
            // if current is empty, start from full range
            var base = current;
            var hasAny = false;
            for (var k in base) { hasAny = true; break; }
            if (!hasAny) {
                base = {};
                for (var p2 = 1; p2 <= maxPages; p2++) base[p2] = true;
            }
            var refined = {};
            for (var k2 in base) {
                var n = k2|0;
                if (n<1 || n>maxPages) continue;
                if (wantOdd && (n % 2 === 1)) refined[n] = true;
                if (!wantOdd && (n % 2 === 0)) refined[n] = true;
            }
            current = refined;
            continue;
        }
        // range or single
        var dash = part.indexOf("-");
        if (dash > 0) {
            var aStr = part.slice(0, dash).trim();
            var bStr = part.slice(dash + 1).trim().toLowerCase();
            var a = parseInt(aStr, 10);
            var b;
            if (bStr === "end") {
                b = maxPages;
            } else {
                b = parseInt(bStr, 10);
                if (isNaN(b)) b = maxPages;
            }
            if (isNaN(a)) continue;
            if (a > b) { var t=a; a=b; b=t; }
            for (var p = a; p <= b; p++) {
                if (p>=1 && p<=maxPages) current[p] = true;
            }
        } else {
            var n = parseInt(part, 10);
            if (!isNaN(n) && n>=1 && n<=maxPages) current[n] = true;
        }
    }
    // if nothing selected, default to all
    var has = false;
    for (var k3 in current) { has = true; break; }
    if (!has) {
        for (var p3 = 1; p3 <= maxPages; p3++) current[p3] = true;
    }
    return current;
}
