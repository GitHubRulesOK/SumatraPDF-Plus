// TextInBox.js - parameterised FreeText Annotation placement per SINGLE page
// Run blind you never see printed errors but are included for console use or debugging
// Use SumatraPDF.exe or mutool.exe to run

var args = {};
for (var i = 0; i < scriptArgs.length; i++) {
    var token = scriptArgs[i];
    // Must start with "-"
    if (token.charAt(0) !== "-") {
        print("ERROR: Invalid argument: " + token); print("All arguments must start with '-' and use the form -key=value"); quit();
    }
    // Must contain "="
    if (token.indexOf("=") === -1) {
        print("ERROR: Argument missing '=': " + token); print("Arguments must be in the form -key=value"); quit();
    }
    // Split into key/value
    var a = token.split("="); var key = a[0]; var val = a[1];
    // Reject empty values
    if (!val || val === "-") {
        print("ERROR: Invalid value for " + key); quit();
    }
    args[key] = val;
}

// -----------------------------
// VERIFY PARAMS: -i and -o (There is no check if name is valid)
// -----------------------------
var input  = args["-i"];
var output = args["-o"];
// Reject missing, empty, or "-" values
if (!input || input === "-" || !output || output === "-") {
    print("ERROR: Missing or invalid -i or -o parameter.");
    print("Usage:");
    print("  run TextInBox.js -i=\"input.pdf\" -o=\"output.pdf\" -p=1 -t=\"Text\" -r=\"x,y,w,h\"");
    quit();
}
// Default params
var font     = args["-f"] || "TiRo";                // Times Roman use "Helv" for SansSerif (others are "Cour", "ZaDb")
var size     = parseFloat(args["-s"] || "14");		// Nominal height of text in points
var textRGB  = JSON.parse(args["-c"] || "[0,0,0]");	// black (R,G,B from 0.00 to 1.00)
var boxRGB   = JSON.parse(args["-b"] || "[1,0,0]");	// red (1=fully red) decimal not needed but 1.000000 is max
var bw       = parseFloat(args["-s"] || "2");		// border width (recommend not less than 1.00)
var p        = parseInt(args["-p"] || "1");		// Page number (default is set as human based Page 1)
var text     = args["-t"] || "Hello World!";		// Text WILL be VISUALLY CROPPED by the box but will wrap due to FreeStyling
var r        = args["-r"] || "50,50,50,40";		// default uses 1/72" from top left of page x,y,box width,box height
// var pad      = parseFloat(args["-pad"] || "2");		// This WAS padding to add a gap between box and text not needed for single object

// Calculations
var parts = r.split(",").map(function(n){ return parseFloat(n); });
if (parts.length !== 4 || parts.some(isNaN)) { print("ERROR: -r must be x,y,w,h (e.g. -r=\"50,50,100,40\")"); quit(); }
var ftRect = [parts[0], parts[1], parts[0] + parts[2], parts[1] + parts[3]];
var sqRect = ftRect.slice();				// Copy as same size box, it could be seperate, but we use margin padding !
// sqRect[0] -= pad; sqRect[1] -= pad; sqRect[2] += pad; sqRect[3] += pad; // Not needed for FreeText only
var hex = "#" + ("0" + Math.round(textRGB[0] * 255).toString(16)).slice(-2) + ("0" + Math.round(textRGB[1] * 255).toString(16)).slice(-2) + ("0" + Math.round(textRGB[2] * 255).toString(16)).slice(-2);

// Open file at given page number
var file = mupdf.Document.openDocument(input); if (!file.isPDF()) throw new Error("Not a PDF");
var page = file.loadPage(p -1); // PDF Page index are one less than human numbers (dont remove the -1)

// You can change order to text before square if you wish but in my testing this was best this way round

// --- Square (box only) --- commented out as we use a newer single method thus redundant
// var sq = page.createAnnotation("Square");
// sq.setRect(sqRect);
// sq.setColor(boxRGB);    // border colour
// sq.setBorderWidth(bw);  // border width

// --- FreeText (text only) --- partly commented out as we now use a newer single RichText method
var ft = page.createAnnotation("FreeText");
// ft.setContents(text);
// ft.setDefaultAppearance(font, size, textRGB);
ft.setDefaultAppearance(font, size, boxRGB); // NOW use box color
ft.setRect(ftRect);
ft.setRichContents(text, text);	// NOTE the first is real Times Roman as Content the second is shown as per below!
// this is where above text is set to black
ft.setRichDefaults("text-align:left;font-family:Times New Roman,Times,Serif;font-size:14pt;color:" + hex + ";");
// ft.setBorderWidth(0);   // WAS IMPORTANT: disable FreeText border and use the border as square
ft.setBorderWidth(2);							// Set border width = 2

page.update(); // IMPORTANT this should set appearance but there are other posibilities

// ------
// FINAL SAVE (always runs once)
// ------
try {
    file.save(output, "garbage,compress"); // Many options but these are the normal ones
} catch (e) {
    print("ERROR: Could not write output file:", output); 
    print("Windows Explorer Preview may be holding the file open.");
    quit();
}
print("Saved to:", output);
