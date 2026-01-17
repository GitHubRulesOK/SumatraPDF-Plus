// ReportAnnots.js
// Usage: mutool run ReportAnnots.js "input.pdf"
//    OR: mutool run ReportAnnots.js "input.pdf" --lines
// output report filename: will be "input-annots.txt"
if (scriptArgs.length < 1) {
    print("\nUsage: mutool run ReportAnnots.js input.pdf [--lines]\n");
    quit();
}
var inname = scriptArgs[0];
var doc = Document.openDocument(inname);
var minified = scriptArgs.indexOf("--lines") >= 0;
var outname = inname.replace(/\.pdf$/i, "") + "-annots.txt";
var out = new Buffer();

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

function writeAnnot(out, pageNum, annotObj, minified) {
    var author   = padR(annotObj.get("T"), 22); // 22 chars wide;
    var modified = padR(annotObj.get("M"), 22); // 22 chars wide;
    var subtype  = padR(annotObj.get("Subtype"), 10); // 10 chars wide
    var rect     = annotObj.get("Rect");
    var contents = annotObj.get("Contents");
    if (minified) {
        out.write( "page=" + pageNum + " author=" + author + " modified=" + modified + " subtype=" + subtype + " rect=" + rect + " contents=" + contents + "\n"
        );
    } else {
        out.write("Page: " + pageNum + "\n");
        out.write("Author: " + author + "\n");
        out.write("Modified: " + modified + "\n");
        out.write("Subtype: " + subtype + "\n");
        out.write("Rect: " + rect + "\n");
        out.write("Contents: " + contents + "\n");
        out.write("----------------------------------------\n");
    }
}
for (var i = 0; i < doc.countPages(); i++) {
    var page = doc.loadPage(i);
    var pageObj = page.getObject();
    var annots = pageObj.get("Annots");
    if (!annots || annots.length === 0)
        continue;
    for (var j = 0; j < annots.length; j++) {
        var annotObj = annots.get(j);
//          if (annotObj.get("Subtype") == "Popup") continue;
        writeAnnot(out, i + 1, annotObj, minified);
    }
}
out.save(outname);
print("Annotation report written to: " + outname);

