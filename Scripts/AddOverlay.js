/*
 AddOverlay.js PDF Page overlay script for a RECT (box), IMAGE, TEXT or combination(s).

 PDFs can be very complex so this script does not "Overwrite" the source, but does try
 to use an optimised footprint via basic simple tests, thus may fail in some odd cases.

 TODO: Base Font are non embeded so NO Unicode etc. Adding a TTF file needs extra vars.
 Page ranges do not reject -p=3-1 but -p=1-3 works, as do most others.
 Image Types are untested but PNG seperation works well.

 Works with: "SumatraPDF[-tool].exe" (or mupdf\mutool.exe) run AddOverlay.js -p=# -t="Hi" -to=...

 Examples:  
   "SumatraPDF.exe" run AddOverlay.js -p=1 -t=" Hello,\nWorld!" input.pdf			NOTE: This is the minimal. Text accepts \n as newline
   "SumatraPDF.exe" run AddOverlay.js -p=3-5 -img="logo.png" -r=45 input.pdf			NOTE: .png can be transparent and -r=rotate in page ROT
   "SumatraPDF.exe" run AddOverlay.js -p=2,3 -img="image.jpg" -t="Fig. 1." -to=0,400 input.pdf  NOTE: -to=x,y is text offset +/- from top left anchor

*/
// Guard against running with WSHell
if (typeof WScript !== "undefined") { WScript.Echo("Run using: \"SumatraPDF[-tool].exe\" run " + WScript.ScriptName + " -options [-...] input.pdf"); WScript.Quit(); }
print("\n Running "+scriptPath);
/* --------
   ARGS
-------- */
var debug=false;
function usage() { print("\n Usage: \"SumatraPDF[-tool].exe\" run "+scriptPath+" -p=pages [options] [-t=\"text string\"] [-img=\"file name\"] [-b=\"x,y,w,h\" (area)] input.pdf")
print(" Extras -bf=[1,0,0] (box fill) -bc=[1,0,0] (box border needs -bs=over 0.4) -r=angle -to=x,y (text offset) -c=[0,0,1] (text color) -f=\"BaseFontName\" "); 
print(" For alpha (0.0-1.0) use -bfa=/-bsa=/-ia=/-ta=#.# NOTE: string can include \\n for newline -s=fontsize -ibox=allows image +/ text at seperate to box "); quit(); }
var args = {}; var positional = null;
for (var i = 0; i < scriptArgs.length; i++) {
    var token = scriptArgs[i];
    if (token.charAt(0) === "-") {
        var eq = token.indexOf("="); if (eq === -1) { print("\n ERROR: Missing '=' in " + token); usage(); }
        var key = token.substring(1, eq); var val = token.substring(eq + 1); if (!val || val === "-") { print("\n ERROR: Invalid value for -" + key); usage(); }
        args[key] = val;
    } else { positional = token; }
}
/* --------
 REQUIRED
-------- */
var input = args["i"] || positional;
if (!input) { print("\n ERROR: No input PDF"); usage(); }
if (!args["p"]) { print("\n ERROR: Missing -p=pages"); usage(); }
if (!args["t"] && !args["img"]) { print("\n ERROR: Need either -t=\"text string\" or -img=\"file name\""); usage(); }	//should we allow box only -b= for some cases
/* --------
 DEFAULTS
-------- */
// Text options
var fontName   = args["f"]  || "Helvetica";					// accepts the 14 PDF STD non embeded names see PDF 1.# SPEC's
var fontSize   = parseFloat(args["s"]  || "24");				// default Larger 24 pt but for a page diagonal consider 72 pt
var textRGB    = JSON.parse(args["c"]  || "[0,0,1]");				// default BLUE text
var textOffset = args["to"] ? args["to"].split(",").map(parseFloat) : [0, 0];	// +/- x,y from Top Left of anchor point
var tox        = textOffset[0]; var toy = textOffset[1];
var textAlpha  = args["ta"]  !== undefined ? parseFloat(args["ta"])  : 1.0;	// 0.00 to 1.00 (default = 100% opaque)

// BOX rectangle
var rect = (args["b"] || "150,150,144,144").split(",").map(parseFloat);	// default is simply a 2" square
var bx = rect[0], by = rect[1], bw = rect[2], bh = rect[3];		// BOX dimensions from lower left origin
//var boxRGB   = JSON.parse(args["bc"] || "[1,0,0]");
var boxRGB = [1,0,0]; if (args["bc"]) { var parts = args["bc"].split(","); if (parts.length === 3) { boxRGB = parts.map(parseFloat); } }	// default RED box
//var boxFill  = args["bf"] ? JSON.parse(args["bf"]) : null;
var boxFill = null; // null = no fill
if (args["bf"]) { var parts = args["bf"].split(","); if (parts.length === 3) { boxFill = parts.map(parseFloat); } }
var boxStroke = args["bs"] !== undefined ? parseFloat(args["bs"]) : 0; if (isNaN(boxStroke)) boxStroke = 0;	// default OFF to be visible use 0.4 or more
var fillAlpha   = args["bfa"] !== undefined ? parseFloat(args["bfa"]) : 1.0;
var strokeAlpha = args["bsa"] !== undefined ? parseFloat(args["bsa"]) : 1.0;

// IMAGE rectangle (optional) default is simply the 1" square box so will need changing. PNG can be transparent JPG cannot
var irect = args["ibox"] ? args["ibox"].split(",").map(parseFloat) : rect;	// default to box rect and also tempOrigin for place text
var ix = irect[0], iy = irect[1], iw = irect[2], ih = irect[3];
var imageAlpha  = args["ia"]  !== undefined ? parseFloat(args["ia"])  : 1.0;	// 0.00 to 1.00 (default = 100% opaque)

// Rotation consider a page is roughly 3w/4h ratio = 53.13°
var angle = args["r"] !== undefined ? parseFloat(args["r"]) : null;

// Globals
var globalImageRef = null; var globalMaskRef = null; var globalFontRef = null; var overlayRef = null;

var out = args["o"] || "output.pdf";
if (debug) print("\ndefaults are now set");

/* --------
 OPEN PDF
-------- */
var file = mupdf.Document.openDocument(input);
var pdf  = file;

//var overlay = makeOverlayOnce(pdf, args); // To be optimal we only want to add the image and font globally per run = not duplicated
var overlay;      // Keep this above the loop, as a global for the run
var imgName, fontId, fontName, gbName, gtName;
// Generate one random suffix per run
var runId = randomRunId();   // e.g. "JFHFY3"

// Build per-run resource Id's, this is unconventional but assures a random name for each run
imgName  = args["img"] ? ("I_"  + runId) : null;
// NOT fontName = args["t"]   ? ("F_"  + runId) : null;
fontId = args["t"] ? ("F_" + runId) : null;
// Create GlobalState names and objects ONCE per run
var gbName = "GB_" + runId; var gbObj = pdf.addObject({ Type: "ExtGState", ca: fillAlpha, CA: strokeAlpha }); // box fill and stroke alpha
var giName = "GI_" + runId; var giObj = pdf.addObject({ Type: "ExtGState", ca: imageAlpha, CA: imageAlpha }); // image alpha
var gtName = "GT_" + runId; var gtObj = pdf.addObject({ Type: "ExtGState", ca: textAlpha, CA: textAlpha });   // text alpha

// Build overlay ONCE using these names
overlay = makeOverlayOnce(pdf, args, imgName, fontId, fontName, gbName, giName, gtName);

if (debug) print("file is open entering page parser");
var pages = parsePages(args["p"], pdf.countPages());	// 1-based
for (var i = 0; i < pages.length; i++) {
    var page = pdf.loadPage(pages[i]-1);		// convert to PDF 0-based
    var pageObj = page.getObject();

if (debug) print("\npage parser page n0= "+ page + " Obj= " + pageObj + " args=img " + args["img"] + " text= " + args["t"] );

// Resolve resources
var res = pageObj.Resources ? pageObj.Resources.resolve() : pdf.newDictionary();
pageObj.Resources = res;

if (!res.XObject)   res.XObject   = pdf.newDictionary();
if (!res.Font)      res.Font      = pdf.newDictionary();
if (!res.ExtGState) res.ExtGState = pdf.newDictionary();

// Bind GS objects into this page
res.ExtGState[gbName] = gbObj;
res.ExtGState[giName] = giObj;
res.ExtGState[gtName] = gtObj;

// Bind per-run image/font names into this page
if (overlay.globalImageRef && imgName) {
    res.XObject[imgName] = overlay.globalImageRef;
}
if (overlay.globalFontRef && fontName) {
    res.Font[fontId] = overlay.globalFontRef;
}

// Try to get existing contents from the page object first
if (debug) print("Debug start var contents");
// Append overlayRef to /Contents
if (debug) {
    print("=== DEBUG: PAGE " + pages[i] + " CONTENTS CHECK ===");
    print("pageObj.Contents =", pageObj.Contents);
    if (pageObj.Contents && pageObj.Contents.resolve) {
        print("pageObj.Contents.resolve() =", pageObj.Contents.resolve());
    } else {
        print("pageObj.Contents.resolve() = <no resolve() method>");
    }
    if (pageObj.Contents) {
        print("typeof pageObj.Contents =", typeof pageObj.Contents);
    } else {
        print("pageObj.Contents is NULL/UNDEFINED");
    }
}
// THIS IS WORKING = KEEP THIS PATTERN
var contents = pageObj.Contents;
if (!contents) {
    pageObj.Contents = overlay.overlayRef;    // no /Contents at all
} else {
    var arr = pdf.newArray();
    if (contents.length !== undefined &&  typeof contents.get === "function") {
        for (var i2 = 0; i2 < contents.length; i2++) {
            var item = contents.get(i2);
            if (item) arr.push(item);
        }
        if (contents.length === 0) { arr.push(contents); }
    } else {
        arr.push(contents);
    }
    arr.push(overlay.overlayRef);           // NOT streamRef
    pageObj.Contents = arr;
}
if (debug) print("Debug end var contents\n");

page.update();

}
/* --------
 FINAL SAVE (always runs once)
-------- */
try {
    file.save(out, "garbage,compress"); // Many options but these are the normal ones
} catch (e) {
    print("ERROR: Could not write output file:", out); 
    print("Windows Explorer Preview may be holding the file open.");
    quit();
}
print("Saved to:", out);
/* --------
 HELPERS
-------- */
function makeOverlayOnce(pdf, args, imgName, fontId, fontName, gbName, giName, gtName) {
    var result = { overlayRef: null, globalImageRef: null, globalFontRef: null,
                   imgName: imgName, fontId: fontId, fontName: fontName, gbName: gbName, giName: giName, gtName: gtName };

    // Build ONE overlay stream (no pageObj allowed here) attempt to start with a clean current transform
    var s = []; s.push("Q q 1 0 0 1 0 0 cm");
    // Rotation we do not try to force upright view simply use as if Page relative so "move, spin, move back" whole overlay
    if (typeof angle === "number" && isFinite(angle)) {
        var rad = angle * Math.PI / 180; var c = Math.cos(rad).toFixed(6); var s_ = Math.sin(rad).toFixed(6); var cx = bx + bw/2; var cy = by + bh/2;
        s.push("1 0 0 1 " +cx+ " " +cy+ " cm " +c+ " " +s_+ " " +(-s_)+ " " +c+ " 0 0 cm 1 0 0 1 " +(-cx)+ " " +(-cy)+ " cm");
    }
    // BOX
    if (boxFill || boxStroke > 0) {
        s.push("/" +result.gbName+ " gs");
        if (boxFill) s.push(boxFill.join(" ") + " rg");
        if (boxStroke > 0) { var bs = boxStroke < 0.4 ? 0.4 : boxStroke; s.push(boxRGB.join(" ") + " RG " +bs+ " w"); }
        var op = (boxFill && boxStroke > 0) ? "B" : (boxFill ? "f" : "S");
        s.push(bx+ " " +by+ " " +bw+ " " +bh+ " re " +op);
    }
    // IMAGE
    if (args["img"]) {
        var imgObj = new mupdf.Image(args["img"]);
        result.globalImageRef = pdf.addImage(imgObj);
        s.push("/" + result.giName + " gs");
        s.push("q " +iw+ " 0 0 " +ih+ " " +ix+ " " +iy+ " cm /" +result.imgName+ " Do Q");
    }
    // TEXT
    if (args["t"]) {
        result.globalFontRef = pdf.addObject({
            Type: "Font",
            Subtype: "Type1",
            BaseFont: result.fontName,
            Encoding: "WinAnsiEncoding"
        });
        s.push("/" + result.gtName + " gs");
        s.push("BT /" + result.fontId + " " + fontSize + " Tf " + textRGB.join(" ") + " rg");
        var txt = args["t"].replace(/\\n/g, "\n");
        var lines = txt.split(/\r?\n/);
        var tx = ix + tox; var ty = iy + ih - fontSize - 2 + toy;
        s.push(tx + " " + ty + " Td");
        s.push("(" + lines[0] + ") Tj");
        for (var j = 1; j < lines.length; j++) {
            s.push("0 -" + (fontSize + 2) + " Td");
            s.push("(" + lines[j] + ") Tj");
        }
        s.push("ET");
    }
    s.push("Q q");
    // Create the overlay stream
    var textStream = s.join("\n") + "\n";
    var dict = pdf.newDictionary();
    dict.Length = textStream.length;
    result.overlayRef = pdf.addRawStream(textStream, dict);
    return result;
}

function randomRunId() {
    var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    var out = "";
    for (var i = 0; i < 6; i++)
        out += chars[Math.floor(Math.random() * chars.length)];
    return out; // e.g. "JFHFY3"
}

function parsePages(spec, max) {
    var out = [];
    var parts = spec.split(",");
    for (var i = 0; i < parts.length; i++) {
        var p = parts[i];
        if (p.indexOf("-") >= 0) {
            var range = p.split("-"); var a = parseInt(range[0], 10); var b = parseInt(range[1], 10);
            if (isNaN(a) || isNaN(b)) continue;
            if (a < 1) a = 1;
            if (b > max) b = max;
            for (var k = a; k <= b; k++) out.push(k);
        } else {
            var n = parseInt(p, 10);
            if (!isNaN(n) && n >= 1 && n <= max) out.push(n);
        }
    }
    return out;
}
