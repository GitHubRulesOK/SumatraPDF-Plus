"use strict";
/*
Usage:
  mutool run annots.js [-m=MODE] [-a=Subtype] [-b] [-v] [-c=RRGGBBAA] [-d] [-e] [-f=N] [-l=N] [-n]
                       [-o="FILE"] [-p=l,i-s,t] [-q] [-r="FILE"] [-s="text"] [-i] [-t | -t="text"] input.pdf
see defaults below for use of switches
*/
// --- Argument parsing ---
var mode = "report"; var annotSubtype = "Highlight"; var blockMode = false; var verbose = false; var colorHex = "FFFF00FF";
var flateSave = false; var decomSave = false; var outname = null; var reportFile = null; var firstPage = 1; var lastPage = null;
var noSave = false; var silent = false; var searchStr = null; var ignoreCase = false; var totalMatches = 0;
var pokeGiven = false; var pokeText = null; var inname = null; var countOnly = false; var pageSpec = null; var pageFilter = null; var pdfDirty = false;
for (var i = 0; i < scriptArgs.length; i++) {
  var arg = scriptArgs[i];
  if (arg.indexOf("-m=") === 0) mode = arg.slice(3);
  else if (arg === "-#") countOnly = true;
  else if (arg.indexOf("-a=") === 0) annotSubtype = arg.slice(3).replace(/^\//, "");
  else if (arg === "-b") blockMode = true;
  else if (arg === "-v") verbose = true;
  else if (arg.indexOf("-c=") === 0) colorHex = arg.slice(3);  //corection required
  else if (arg === "-d") flateSave = true;
  else if (arg === "-e") decomSave = true;
  else if (arg.indexOf("-f=") === 0) firstPage = parseInt(arg.slice(3), 10);
  else if (arg.indexOf("-l=") === 0) lastPage = parseInt(arg.slice(3), 10);
  else if (arg === "-n") noSave = true;
  else if (arg.indexOf("-o=") === 0) outname = arg.slice(3);
  else if (arg.indexOf("-p=") === 0) pageSpec = arg.slice(3);   // NEW
  else if (arg === "-q") silent = true;
  else if (arg.indexOf("-r=") === 0) reportFile = arg.slice(3);
  else if (arg.indexOf("-s=") === 0) searchStr = arg.slice(3);
  else if (arg === "-i") ignoreCase = true;
  else if (arg === "-t") pokeGiven = true;
  else if (arg.indexOf("-t=") === 0) pokeText = arg.slice(3);
  else if (arg[0] !== "-") inname = arg;
}
if (!inname) { print(" Usage: mutool run annots.js [-m=MODE] [-a=Subtype] [-b] [-v] [-c=RRGGBBAA] [-d] [-e] [-f=N] [-l=N] [-n]\n" +
"                             [-o=\"FILE\"] [-p=l,i-s,t] [-q] [-r=\"FILE\"] [-s=\"text\"] [-i] [-t | -t=\"text\"]  input.pdf\n" +
" Modes:\n" +
"   -m=         report mode (Default) | delAnnots | delLinks \n" +
"   -a=         subtype single filter (e.g. Highlight, Link) no leading slash. Adds only one / Reports all in group\n" +
"   -b          use block mode for report and/or console output (single lines for grepping)\n" +
"   -v          verbose debugging outputs, use with caution on large files (limit page range)\n" +
" Flags:\n" +
"   -c=RRGGBBAA colour for added annot (default FFFF00FF) AA=Highlight Opacity (FF=100% for lines or HL 50% Blend*)\n" +
"   -d          save deflated objects in file outputs (images and fonts will be compacted)\n" +
"   -e          save expanded objects in file outputs (images and fonts will be compacted)\n" +
"   -f=##       first (default 1-based) page to process from\n" +
"   -l=##       last (default to final) page to process upto\n" +
"   -n          no-save (don't save cleaned PDF nor a list TXT)\n" +
"   -o=\"FILE\"   output PDF (default: input-changed.pdf)\n" +
"   -p=\"LIST\"   Process Pages Range (default: All see -f= -l= for simpler ranges)\n" +
"   -q          silent (no console output except errors)\n" +
"   -r=\"FILE\"   write report to TXT (default: input-list.txt)\n" +
"   -s=\"text\"   \"find text\" Required literal quoted search string, may not always match seen plain text (Not full UTF)\n" +
"   -i          case-insensitive searching\n" +
"   -t          embed above search string into annotation\n" +
"   -t=\"text\"   embed a custom text as comment (annots do not support all UTF characters)\n" +
"\n" +
"  * Note: UL/SQ/ST annotations are full opacity yet may appear faint with light colours. E.g. default Yellow 1 pt may look invisible.\n"
); quit(); }
/* ---------------
     LOAD PDF
----------------*/
var doc = mupdf.PDFDocument(inname);
if (!doc.isPDF()) throw new Error("Not a PDF"); if (doc.needsPassword()) throw new Error("Encrypted PDF");
// PDF active NOW we can collect results
var txtOut = new Buffer(); var defaultReportFile;
var defaultReportFile = inname.replace(/\.pdf$/i, "") + "-list.txt";
if (mode === "addAnnot") defaultReportFile = inname.replace(/\.pdf$/i, "") + "-added.txt";
if (mode === "delAnnots") defaultReportFile = inname.replace(/\.pdf$/i, "") + "-changes.txt";
var defaultOutPdf     = inname.replace(/\.pdf$/i, "") + "-changed.pdf";
/* ---------------
 Helper functions
----------------*/   
var hexToBytes = function(hex){ var H='0123456789ABCDEF'; var b=[]; hex=String(hex||'').toUpperCase(); for(var i=0;i<hex.length;i+=2){ var hi=H.indexOf(hex.charAt(i)); var lo=H.indexOf(hex.charAt(i+1)); if(hi<0) hi=0; if(lo<0) lo=0; b.push(((hi<<4)|lo)&0xFF); } return b; };
var hexTXTtoUTF = function(rawOrHex){ var literal=String(rawOrHex||''); var hex = (literal.indexOf('<')!==-1) ? literal.replace(/^[\s<]+|[\s>]+$/g,'').replace(/\s+/g,'').toUpperCase() : String(rawOrHex||'').toUpperCase(); if(hex.slice(0,4)==='FEFF') hex=hex.slice(4); var bytes=hexToBytes(hex); var utf16=''; for(var j=0;j+1<bytes.length;j+=2) utf16+=String.fromCharCode((bytes[j]<<8)|bytes[j+1]); utf16=utf16.replace(/^\uFEFF+/,''); var low=''; for(var j2=0;j2+1<bytes.length;j2+=2) low+=String.fromCharCode(bytes[j2+1]); return { hex: hex, bytes: bytes, utf16: utf16, low: low }; };
var unescapePdfString = function(s){ s=String(s||''); var out=''; for(var i=0;i<s.length;i++){ var ch=s.charAt(i); if(ch.charCodeAt(0)!==92){ out+=ch; continue; } i++; if(i>=s.length){ out+=String.fromCharCode(92); break; } var esc=s.charAt(i); var ec=esc.charCodeAt(0); if(ec===110){ out+=String.fromCharCode(10); continue; } if(ec===114){ out+=String.fromCharCode(13); continue; } if(ec===116){ out+=String.fromCharCode(9); continue; } if(ec===98){ out+=String.fromCharCode(8); continue; } if(ec===102){ out+=String.fromCharCode(12); continue; } if(ec===40){ out+='('; continue; } if(ec===41){ out+=')'; continue; } if(ec===92){ out+=String.fromCharCode(92); continue; } if(ec>=48 && ec<=55){ var oct=esc; for(var k=0;k<2;k++){ if(i+1<s.length){ var nx=s.charAt(i+1); var nc=nx.charCodeAt(0); if(nc>=48 && nc<=55){ i++; oct+=nx; continue; } } break; } var code=0; for(var m=0;m<oct.length;m++) code=(code<<3)+(oct.charCodeAt(m)-48); out+=String.fromCharCode(code&0xFF); continue; } out+=esc; } return out; };
var csvEsc = function(s){ return '"' + String(s||'').replace(/"/g,'""') + '"'; };
var classifyLiteral = function(raw){ var lit=String(raw||''); var first=lit.replace(/^\s+/,'').charAt(0); if(first==='<'){ var r=hexTXTtoUTF(lit); if(r.utf16 && r.utf16.length) return { type:'HEX_UTF16', decoded:r.utf16, hex:r.hex, low:r.low }; if(r.low && r.low.length) return { type:'ANSI_LOWBYTE', decoded:r.low, hex:r.hex, low:r.low }; return { type:'OTHER_HEX', decoded:r.hex, hex:r.hex }; } var plain=unescapePdfString(lit); var isAscii=true; for(var i=0;i<plain.length;i++){ var c=plain.charCodeAt(i); if(c===0 || c<9){ isAscii=false; break; } } return { type: isAscii ? 'PLAIN_ASCII' : 'UNKNOWN', decoded: plain }; };
var padL = function(s,w){ s=(s===null?"null":String(s)); while(s.length<w) s=" "+s; return s; };
var padR = function(s,w){ s=(s===null?"null":String(s)); while(s.length<w) s+=" "; return s; };
function safePDF(v) { return (v === null || v === undefined) ? "null" : ("" + v); }
function safePageCount(doc){ if(!doc) return 1; if(typeof doc.countPages==='function') return doc.countPages(); return 1; }
var pages = safePageCount(doc);
/* ---------------
 Page-range parser
   (-p=1,2,5-7) 
----------------*/
function parsePageSpec(spec, maxPages) {
    if (!spec) return null;
    var map = {}; var parts = spec.split(",");
    for (var i = 0; i < parts.length; i++) {
        var part = parts[i].trim();
        if (!part) continue;
        var dash = part.indexOf("-");
        if (dash > 0) {
            var a = parseInt(part.slice(0, dash), 10);
            var b = parseInt(part.slice(dash + 1), 10);
            if (isNaN(a)) continue;
            if (isNaN(b)) b = maxPages;
            if (a > b) { var t=a; a=b; b=t; }
            for (var p = a; p <= b; p++) {
                if (p>=1 && p<=maxPages) map[p] = true;
            }
        } else {
            var p = parseInt(part, 10);
            if (!isNaN(p) && p>=1 && p<=maxPages) map[p] = true;
        }
    }
    return map;
}
/* ---------------
   Page walker
----------------*/
function forEachPage(doc, fn) {
    var n = safePageCount(doc);
    for (var p = 0; p < n; p++) {
        var pageNum = p + 1;
        if (pageFilter && !pageFilter[pageNum]) continue;
        if (pageNum < firstPage) continue;
        if (lastPage && pageNum > lastPage) continue;
        var page = null;
        try { page = doc.loadPage(p); } catch(e) { continue; }
        if (!page) continue;
        fn(page, p);
        if (page.free) page.free();
    }
}
/* ---------------
 Annotation walker
----------------*/
function forEachAnnot(page, fn) {
    var ann = null;
    try { ann = page.getAnnotations(); } catch(e) { return; }
    if (!ann || !ann.length) return;
    for (var i = ann.length - 1; i >= 0; i--) { fn(ann[i], i); }
}
/* ---------------
  Subtype filter
----------------*/
function subtypeMatches(obj, filter) {
    if (!filter) return true;
    var st = obj.get('Subtype');
    if (!st) return false;
    st = String(st).replace(/^\//, "").toLowerCase();
    return st === filter.toLowerCase();
}
/* ---------------
   MAIN Loop
----------------*/
if (pageSpec) {
    var map = parsePageSpec(pageSpec, pages);
    var arr = [];
    for (var k in map) {
        var n = Number(k);
        if (!isNaN(n)) arr.push(n - 1);   // convert to 0‑based
    }
    pageFilter = arr.length ? arr : null;
}
if (verbose) print("DEBUG: pageFilter = " + pageFilter);
/* ---------------
   PREP DEFAULT
   MODE = Report 
----------------*/
function runReportMode(doc, pageFilter, verbose) {
    var total = 0;
    forEachPage(doc, function(page, pg) {
        var pg0 = pg - 1;
        if (pageFilter && pageFilter.indexOf(pg0) === -1) return;
        var pageObj = page.getObject(); var annots = pageObj.get("Annots");
        if (!annots || annots.length === 0) return;
        var header = verbose
            ? "page,indx,  Author  , Sub-TYPE ,  Date/Time  Modified  ,Rect / Bounding Box                         , Comment DECODED ... ,HtEXt Entry"
            : "page,indx, Sub-TYPE ,  Date/Time  Modified  ,Rect / Bounding Box                         , Comment DECODED ...";
        if (!silent) print(header);
        txtOut.write(header + "\n");
        for (var j = 0; j < annots.length; j++) {
            var annotObj = annots.get(j);
            var subtype  = annotObj.get("Subtype");
            var rect     = annotObj.get("Rect");
            var author   = annotObj.get("T");
            var modified = annotObj.get("M");
            var raw      = annotObj.get("Contents");
            var info     = classifyLiteral(raw);
            // force decoded text to be single-line
            var decoded = info.decoded; if (decoded) decoded = decoded.replace(/\r?\n/g, "\\n");
            var line = verbose
                ? [ padL(pg,4), padL(j+1,4), padR(safePDF(author),10), padR(safePDF(subtype),10),
                    padR(safePDF(modified),23), padR(safePDF(rect),44), csvEsc(decoded),
                    csvEsc(info.hex || '') ].join(',')
                : [ padL(pg,4), padL(j+1,4), padR(safePDF(subtype),10), padR(safePDF(modified),23),
                    padR(safePDF(rect),44), csvEsc(decoded) ].join(',');
            if (!silent) print(line);
            txtOut.write(line + "\n");
            total++;
        }
    });
    if (!silent) print("Total matches: " + total);
    txtOut.write("Total matches: " + total + "\n");
    return total;
}
/* ---------------
   MODE: DELETE
 ANNOTS OR LINKS
----------------*/
function runDeleteMode(doc, pageFilter, itemGetter, itemDeleter, label) {
    var removed = 0;
    var perPage = {};
    forEachPage(doc, function(page, pg) {
        var pg0 = pg - 1;
        if (pageFilter && pageFilter.indexOf(pg0) === -1)
            return;
        var items = itemGetter(page);
        if (!items || !items.length)
            return;
        for (var i = items.length - 1; i >= 0; i--) {
            try {
                itemDeleter(page, items[i]);
                removed++;
                perPage[pg0] = (perPage[pg0] || 0) + 1;
                pdfDirty = true;
            } catch (e) {}
        }
    });
    if (!silent) {
        for (var p in perPage)
            print("Page " + p + ": removed " + perPage[p] + " " + label);
        print("Total " + label + " removed: " + removed);
    }
    for (var p in perPage)
        txtOut.write("Page " + p + ": removed " + perPage[p] + " " + label + "\n");
    txtOut.write("Total " + label + " removed: " + removed + "\n");
    return removed;
}

/* ---------------
 EXECUTE MODE USE
 FUNCTIONS above
----------------*/
if (mode === "report") {
    runReportMode(doc, pageFilter, verbose);
    if (countOnly) {
        if (doc.close) doc.close();
        quit();
    }
}
/* ---------------
 MODE: DEL ANNOTS
----------------*/
if (mode === "delAnnots") {
    runDeleteMode(
        doc,
        pageFilter,
        function(page) {
            var ann = page.getAnnotations();
            if (!ann) return [];
            var out = [];
            for (var i = 0; i < ann.length; i++) {
                var obj = ann[i].getObject ? ann[i].getObject() : ann[i];
                if (subtypeMatches(obj, annotSubtype))
                    out.push(ann[i]);
            }
            return out;
        },
        function(page, annot) {
            if (page.deleteAnnotation)
                page.deleteAnnotation(annot);
            else if (annot.remove)
                annot.remove();
        },
        "annotations"
    );
}
/* ---------------
MODE: DELETE LINKS
----------------*/
if (mode === "delLinks") {
    runDeleteMode(
        doc,
        pageFilter,
        function(page) {
            return page.getLinks() || [];
        },
        function(page, link) {
            page.deleteLink(link);
        },
        "links"
    );
}

/* ---------------
MODE:  reserved
----------------*/ 
/* ---------------
below need resolving to types like above
if (mode === "delRaw") {
    runDeleteMode(
        doc,
        pageFilter,
        page => getRawObjects(page),   // function
        (page, raw) => raw.delete("Key"),
        "raw objects"
    );
}
runDeleteMode(doc, pageFilter,
    page => page.getAnnotations().filter(a => subtype == "Widget"),
    (page, a) => page.deleteAnnotation(a),
    "widgets"
);
above need resolving to types
----------------*/ 

/* ------------------------------
   FINAL SAVE
--------------------------------*/
if (verbose) print("Debug now at saving")
  // Determine final output filenames
  var finalReport = reportFile || defaultReportFile;
  var finalPdf = outname || defaultOutPdf;
if (verbose) { print("Resolved finalReport = " + finalReport); print("Resolved finalPdf = " + finalPdf); }
  // Write report file
if (verbose) print("at final save / close inname= " + inname + " outname= " + outname);
try {
    txtOut.save(finalReport);
    if (!silent) print("Annotation report written to: " + finalReport);
} catch(e) {
    print("Failed to write report: " + e);
}
// Write PDF only if modified
if (!noSave && pdfDirty) {
    try {
        if (flateSave)      doc.save(finalPdf, "appearance=all,garbage=deduplicate,decrypt,sanitize,compress-effort=100");
        else if (decomSave) doc.save(finalPdf, "appearance=all,garbage=deduplicate,decrypt,sanitize,decompress");
        else                doc.save(finalPdf, "appearance=all,garbage=deduplicate,decrypt,sanitize");
        if (!silent) print("Saved PDF as: " + finalPdf);
    } catch(e) {
        print("Save failed: " + e);
    }
}

if (verbose) print("at final close")

