if (scriptArgs.length < 1) {
    print("usage: mutool run DelPdfAnnots.js input.pdf [output.pdf]");
    quit();
}

var inname  = scriptArgs[0];
// If no output name is given, auto-rename the file
var outname = scriptArgs[1] || (inname.replace(/\.pdf$/i, "") + "-cleaned.pdf");

var doc = Document.openDocument(inname);
for (var i = 0; i < doc.countPages(); i++) {
    var page = doc.loadPage(i);
    // --- REMOVAL (Like a Blunt ChainSaw) ---
    var annots = page.getAnnotations();
    if (annots) {
        for (var j = annots.length - 1; j >= 0; j--) {
            page.deleteAnnotation(annots[j]);
        }
    }
}

doc.save(outname, "garbage=4,deflate");
