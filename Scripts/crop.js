// version 1.2 TODO: add a 32 GB guard and track the box relative to the original page.
//
// Note: it very simply alters the Page CropBox relative to the previous one.
// That means you can make a page visually larger by using -x and -y (minus) values
// So crop -10 -10 615 862 (595x842 +20) will be A4 plus 10 mm margins on all sides
//
// Can be runs standalone such as SumatraPDF RUN crop.js options
// You can add SumatraPDF as the real time viewer if you use a cmd file to monitor for the output and run sumatrapdf -reuse-instance "%1-cropped.pdf"
// Here modified for sending filename and -p=page via ExternalViewers e.g.
//
// ExternalViewers [
//	[
//		CommandLine = "path to\sumatrapdf-tool.exe" run "path to this \crop.js" -p=%p -o="%1-cropped.pdf" "%1"
//		Name = Crop Current Page
//		Filter = *.pdf
//		Key = Shift + C
//		ToolbarSvgIcon = <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" stroke="currentColor" stroke-linecap="round"><path stroke="none" d="M0 0h24v24H0z"/><path d="M2 19V4a2 2 0 0 1 2-2h15M22 5v15a2 2 0 0 1-2 2h-15 M4 4l1.25 1.25M18.75 18.75l1.25 1.25M5 7h10a2 2 0 0 1 2 2v10M7 5v10a2 2 0 0 0 2 2h10"/></svg>
//	]
// ]
// 
// Interactivity (REPL) is part work in progress but as a PoC asks for relative crop as xL yT wR dB = Xleft Ytop Width Height
//
// BLOCK WScript double-click
if (typeof WScript !== "undefined") { WScript.Echo( "Run using: \"SumatraPDF[-tool].exe\" run " + WScript.ScriptName +  " [options] \"infile.pdf\"" ); WScript.Quit(); }
print("\n Running       : " + scriptPath);
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
print(" Input         : " + infile);
if (outfile !== null) print(" Output        : " + outfile);

// Open document
var doc = mupdf.Document.openDocument(infile);
var pageCount = doc.countPages();
var pageNumber = 0;
var page = doc.loadPage(pageNumber);
print(" Pages         : " + pageCount);
print(" Current Page  : " + (pageNumber + 1));
var originalMedia = page.getBounds(); // save the source as a seperate var so we can reset
print(" Original Media: " +  originalMedia.join(", "));
print(" Page bounds   : " + page.getBounds()); // this is the starting page size that will be cropped but bounds changes
print("");
print(" Waiting for command (HINT: crop x y w h as points ?)");
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

function xsetCrop(x0, y0, x1, y1) {
    var box = [ Number(x0), Number(y0), Number(x1), Number(y1) ];
    page.setPageBox("CropBox", box); print( " CropBox = [" + box.join(", ") + "]" );
}

function setCrop(x0, y0, x1, y1) {
    page = doc.loadPage(pageNumber);
    print(" Boundary Box: " + page.getBounds());
    var box = [
        Number(x0),
        Number(y0),
        Number(x1),
        Number(y1)
    ];
    page.setPageBox("CropBox", box);
    print(" CropBox = [" + box.join(", ") + "]");
    print(" UNSAVED NOW IS: " + page.getBounds());
}

function saveDocument(filename) {
    if (!filename) filename = outfile;
    if (!filename) { print("ERROR: No output file specified."); print("Use: save FILE"); return false; }
    doc.save(filename); print(" Saved: " + filename);
    return true;
}

function showStatus() {
    print("");
    print(" Input   : " + infile);
    print(" Output  : " + outfile);
    print(" Pages   : " + pageCount);
    print(" Page    : " + (pageNumber + 1));
    print(" Page Box: " + page.getBounds());
    print("");
    print(" Remember to 'quit' without FURTHER changes or 'save' then quit.");
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
        print("Commands: (NOTE needs either Quit/Exit OR save progress and then Quit or Exit)");
        print("  page #           = Change to Page Number for action (1-base so starting with 1).");
        print("  crop X Y W H     = Set NEW CropBox on selected page using RELATIVE points.");
        print("  save [FILENAME]  = Save the document [with a new given name if not already given].");
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

// TODO: needs usual end game, this will be unseen as the console is closed by quit or exit
print("\n Done.");
