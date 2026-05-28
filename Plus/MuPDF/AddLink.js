// AddLink.js
// Quick hack to overlay desired page content with a hyperlink to another location, color is set to blue.
// For more advanced PDF editing, see coherentpdf (cpdf). https://github.com/coherentgraphics/cpdf-binaries
//
// Usage examples: "Path to \SumatraPDF.exe" (or mutool.exe) followed by
//       run AddLink.js -x=10 -y=10 -w=45 -h=12  -t="example" -d="2,Fit" -p=1 -o="MyOutput.pdf" -i="input.pdf"
//       run AddLink.js -x=10 -y=10 -w=90 -h=24  -d="2,XYZ[100,100,200]" -p=1 -i="input.pdf"
//       run AddLink.js -x=10 -y=10 -w=90 -h=24  -d="3,XYZ[50,100,0]" -p=2 -i="input.pdf"
//       run AddLink.js -x=10 -y=10 -w=90 -h=24 -t="example" -u="https://www.example.com" -p=1 -i="input.pdf"
//
// Notes:
// - -h is the driven height of the font, it will have one point added to ensure good decender
// - User must provide placement width and height plus input file.pdf and either a valid destination or URL.
// - Output file defaults to "output.pdf" if -o is not given, -t="text" to be placed first is optional
// - Coordinates are in points or zoom%, origin is top-left, and text will be top left of given -w= -h=.

// ------
// 1. PARSE FLAGS
// ------
var args = {};
for (var i = 0; i < scriptArgs.length; i++) {
    var part = scriptArgs[i];
    if (part.charAt(0) === "-") {
        var eq = part.indexOf("=");
        if (eq > 0) { var key = part.substring(1, eq); var val = part.substring(eq + 1); args[key] = val; }
    }
}
// ------
// 2. VALIDATE MANDATORY FLAGS
// ------
var required = ["x", "y", "w", "h", "p", "i"];
for (var r = 0; r < required.length; r++) {
    var k = required[r];
    if (!(k in args)) { print("ERROR: Missing required flag: -" + k + "=value"); quit(); }
}
var hasU = ("u" in args); var hasD = ("d" in args); var hasT = ("t" in args);
var flatten = true; // Important we flatten the text as a freetext on a page. Thus will in MsEdge mask the overlaid link
// Illegal: both URL and destination
if (hasU && hasD) { throw new Error("Cannot use -u (URL) and -d (destination) together."); }
// Illegal: no link type provided (Text-only mode is allowed, but at least one of the three must exist)
if (!hasU && !hasD && !hasT) { throw new Error("Must provide either -u (URL), -d (destination), or -t (text)."); }
// No further guards needed at this stage.
// ------
// 3. EXTRACT VALUES load file and page
// ------
var x = parseFloat(args["x"]); var y = parseFloat(args["y"]); var w = parseFloat(args["w"]); var h = parseFloat(args["h"]);
var input = args["i"]; var output = args["o"] || "output.pdf";
var file  = mupdf.Document.openDocument(input); if (!file.isPDF()) throw new Error("Not a PDF");
var pageIndex = parseInt(args["p"], 10) - 1;
if (pageIndex < 0 || pageIndex >= file.countPages()) { throw new Error("Invalid page number"); }
var page = file.loadPage(pageIndex);
// ------
// 4. COMPUTE RECT (top-left coords)
// ------
var x2 = x + w; var y2 = y + h + 1; var rect = [x, y, x2, y2]; print("Using rect:", rect, "On Page", pageIndex + 1);
// ------
// 5. OPTIONAL TEXT (-t)
// ------
if (hasT) {
    var text = args["t"]; print("Adding FreeText:", text);
    var ft = page.createAnnotation("FreeText"); ft.setContents(text); ft.setDefaultAppearance("Helv", h, [0,0,1]); ft.setRect(rect);
    page.update();
    if (flatten) {
        var annots = page.getAnnotations();
        for (var i = 0; i < annots.length; ++i)
            annots[i].requestSynthesis();
        page.update();
        var pg = page.getObject(); var list = pg.Annots;
        if (!pg.Resources) pg.Resources = {};
        if (!pg.Resources.XObject) pg.Resources.XObject = {};
        if (!pg.Contents) pg.Contents = [];
        else if (!Array.isArray(pg.Contents))
            pg.Contents = [ pg.Contents ];
        if (list && list.length) {
            var keep = []; var buf  = "";
            for (var i = 0; i < list.length; ++i) {
                var annot = list[i];
                if (annot.Subtype == "FreeText" && annot.Contents == text) {
                    var ap     = annot.AP.N; var name = "Annot" + annot.asIndirect();
                    pg.Resources.XObject[name] = ap;
                    ap.Type = "XObject"; ap.Subtype = "Form";
                    // ⭐ Correct overlay isolation (Q q … Q q) close page CTM start with clean identity CTM
                    buf += " Q q 1 0 0 1 0 0 cm /" + name + " Do Q q \n";
                } else {
                    keep.push(annot);
                }
            }
            pg.Annots = keep;
            if (buf) pg.Contents.push(file.addStream(buf));
        }
        page.update();
    }
}
// ------
// EXTERNAL URL (-u)
// ------
if (hasU) { var url = args["u"]; print("Adding URL link:", url); page.createLink(rect, url); page.update(); }
// ------
// INTERNAL DESTINATION (-d)
// ------
if (hasD) {
    var uri = args["d"]; var firstComma = uri.indexOf(",");  // Split only at first comma
    if (firstComma < 0) throw new Error("Destination must be in form Page,Type[...]");
    var pagePart = uri.substring(0, firstComma).trim();
    var typePart = uri.substring(firstComma + 1).trim();
    var destPage = parseInt(pagePart, 10) - 1;
    if (isNaN(destPage) || destPage < 0 || destPage >= file.countPages()) throw new Error("Invalid page number");
    var m = typePart.match(/^([A-Za-z]+)(?:\[(.*)\])?$/);
    if (!m) throw new Error("Invalid destination format");
    var destType = m[1]; var paramString = m[2] || "";
    var params = paramString ? paramString.split(/\s*,\s*/) : [];
    var destObj = { type: destType, page: destPage };
    // XYZ[x,y,zoom]
    if (destType === "XYZ") {
        if (params.length !== 3) throw new Error("XYZ requires 3 parameters");
        destObj.x = parseFloat(params[0]); destObj.y = parseFloat(params[1]); destObj.zoom = parseFloat(params[2]);
    }
    // FitH[top]
    if (destType === "FitH") {
        if (params.length !== 1) throw new Error("FitH requires 1 parameter");
        destObj.y = parseFloat(params[0]);
    }
    // FitV[left]
    if (destType === "FitV") {
        if (params.length !== 1) throw new Error("FitV requires 1 parameter");
        destObj.x = parseFloat(params[0]);
    }
    // FitR[left,bottom,right,top]
    if (destType === "FitR") {
        if (params.length !== 4) throw new Error("FitR requires 4 parameters");
        destObj.x      = parseFloat(params[0]); destObj.y      = parseFloat(params[1]);
        destObj.width  = parseFloat(params[2]); destObj.height = parseFloat(params[3]);
    }
    // Fit, FitB have no params
    if (destType === "Fit" || destType === "FitB") {
        if (params.length !== 0) throw new Error(destType + " takes no parameters");
    }
    var dest = file.formatLinkURI(destObj);
    page.createLink(rect, dest);
    page.update();
}
// ------
// FINAL SAVE (always runs once)
// ------
try {
    file.save(output, "garbage,compress");
} catch (e) {
    print("ERROR: Could not write output file:", output);
    print("Windows Explorer Preview may be holding the file open.");
    quit();
}
print("Saved to:", output);
