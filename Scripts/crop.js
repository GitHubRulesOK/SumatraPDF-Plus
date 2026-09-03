// version 1.0
// SumatraPDF RUN crop.js options
// modified for sending filename and -p=page e.g. SumatraPDF[-tool].exe run -p=2 folder\fred.pdf
// interactive is part work in progress but needs / should ask for crop as UXL UYT LXR LYB = Xleft Ytop Xright Ybottom
//
// BLOCK WScript double-click
if (typeof WScript !== "undefined") { WScript.Echo( "Run using: \"SumatraPDF[-tool].exe\" run " + WScript.ScriptName +  " [options] \"infile.pdf\"" ); WScript.Quit(); }
print("\n Running " + scriptPath);
var infile = null;
var outfile = null;
var pageArg = null;
for (var i = 0; i < scriptArgs.length; i++) {
    var part = scriptArgs[i];
    if (part.charAt(0) === "-") {
        var eq = part.indexOf("=");
        var opt = eq >= 0
            ? part.substring(0, eq)
            : part;
        var val = eq >= 0
            ? part.substring(eq + 1)
            : null;
        if (opt === "-o" ) { if (val === null) { print("ERROR: " + opt + " requires a value."); quit(); } outfile = val; }
        else if (opt === "-p" ) { if (val === null) { print("ERROR: " + opt + " requires a value."); quit(); } pageArg = val; }
        else { print("ERROR: Unknown option: " + part); quit(); }
    }
    else { if (infile !== null) { print("ERROR: Multiple / unknown input files."); quit(); } infile = part; }
}
// Validate CLI
if (infile === null) { print( " Usage: \"SumatraPDF[-tool].exe\" run " + scriptPath + " [-o=\"out.pdf\"] \"infile.pdf\"" ); quit(); }
print(" Input : " + infile);
if (outfile !== null) print(" Output: " + outfile);

// Open document
var doc = mupdf.Document.openDocument(infile);
var pageCount = doc.countPages();
var pageNumber = 0;
var page = doc.loadPage(pageNumber);
print(" Pages : " + pageCount);
print(" Page  : " + (pageNumber + 1));
print("");
print(" Waiting for command (HINT: crop ## ## ## ## ?)");
print(" Type 'help' for commands.");
print("");

// Helpers
function selectPage(n) {
    n = Number(n);
    if (isNaN(n) || n % 1 !== 0) { print("ERROR: Page must be an integer."); return; }
    if (n < 1 || n > pageCount) { print( "ERROR: Page must be between 1 and " +  pageCount + "." ); return; }
    pageNumber = n - 1;
    page = doc.loadPage(pageNumber);
    print(" Page selected: " + n);
}

function setCrop(x0, y0, x1, y1) {
    var box = [ Number(x0), Number(y0), Number(x1), Number(y1) ];
    page.setPageBox("CropBox", box); print( " CropBox = [" + box.join(", ") + "]" );
}

function saveDocument(filename) {
    if (!filename) filename = outfile;
    if (!filename) { print("ERROR: No output file specified."); print("Use: save FILE"); return false; }
    doc.save(filename); print(" Saved: " + filename);
    return true;
}

function showStatus() {
    print("");
    print(" Input : " + infile);
    print(" Pages : " + pageCount);
    print(" Page  : " + (pageNumber + 1));
    print("");
}

// -----
// REPL
// -----

while (true) {
    write(" Enter instruction> ");
    var line = readline();
    if (line === null)
        break;
    line = line.trim();
    if (line === "")
        continue;
    var parts = line.split(/\s+/);
    var command = parts[0].toLowerCase();
    if (command === "quit" || command === "exit")
        break;
    if (command === "help") {
        print("");
        print("Commands: (NOTE use lower case)");
        print("  page #           = Change to Page Number for action (1-base so starting with 1).");
        print("  crop X0 Y0 X1 Y1 = Set NEW CropBox on selected page.");
        print("  save FILENAME    = Save the document with a new given name.");
        print("  status           = Show current document / page details.");
        print("");
        print("  quit or exit     = Abort OR Exit script.");
        print("");
        continue;
    }
    if (command === "page") { if (parts.length !== 2) { print("Usage: page Number"); continue; }
        selectPage(parts[1]);
        continue;
    }
    if (command === "crop") { if (parts.length !== 5) { print("Usage: crop X0 Y0 X1 Y1");
            continue;
        }
        setCrop( parts[1], parts[2], parts[3], parts[4] );
        continue;
    }
    if (command === "save") { if (parts.length > 2) { print("Usage: save [FILE]"); continue; }
        var filename = parts.length === 2 ? parts[1] : outfile;
        if (!saveDocument(filename)) continue;
        // break; // dont exit so user can try again then manually exit
        continue;
    }
    if (command === "status") {
        showStatus();
        continue;
    }
    print("Unknown command: " + command);
}

print("\n Done.");
