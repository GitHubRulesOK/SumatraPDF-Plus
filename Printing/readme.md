A user wanted a simple 
Duplex printing script for a simplex printer (where you have turn the paper over to print on other side !)
For more info see https://github.com/sumatrapdfreader/sumatrapdf/issues/295#issuecomment-2744690669

The attached script says 2000 pages but in the past there have been lower or greater limits so chose what you  might need as a maximum.


IMPORTANT pages MUST BE FACE DOWN WITH 1 at top of stack to be used FIRST (NATURAL ORDER)
to print 1 to 5 of 9 pages then the number of pages does not matter it will be all as quick as all others

 "%SumatraPDF%" -print-to-default -print-settings "1-2000,odd" "%~1"

Now turn the paper over (1 was printed first) and press enter PAGE 2 will be printed on BACK of PAGE 1 
NOTE there may be a last sheet in hopper so don't forget to check and add to the final stack face down.
pause

To print 2 to 8 of 9 pages then the number of pages does not matter it will be all as quick as all others
page 9 without a 10 will be left in the input tray and need collection.

 "%SumatraPDF%" -print-to-default -print-settings "1-2000,even" "%~1"