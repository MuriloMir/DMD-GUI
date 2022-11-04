pragma(linkerDirective, "/subsystem:windows");
pragma(linkerDirective, "/entry:mainCRTStartup");

import arsd.image : loadImageFromMemory;
import arsd.simpleaudio : AudioOutputThread;
import arsd.simpledisplay : Color, Image, Key, KeyEvent, MouseButton, MouseEvent, MouseEventType, OperatingSystemFont, Point, Rectangle, ScreenPainter,
                            SimpleWindow;
import core.stdc.stdlib : system;
import std.algorithm.mutation : remove;
import std.algorithm.searching : countUntil;
import std.array : join, replace;
import std.file : exists;

void main()
{
    // here we start the GUI and the audio thread
    SimpleWindow window = new SimpleWindow(800, 600, "DMD");
    AudioOutputThread music = AudioOutputThread(true);

    // here we load the background image
    Image background = Image.fromMemoryImage(loadImageFromMemory(cast(immutable ubyte[]) import("background.jpeg")));
    // 'commandPhrase' is the phrase that will be sent to the system when you click "Compile", 'fileName' will contain the name of the source file
    string commandPhrase = "dmd fileName ", fileName = "";
    // here we will store the options you have selected
    string[] options;
    // where the cursor will be when you type the name of the file to be compiled
    Point cursorPosition = Point(245, 200);
    // here we create all of the Rectangles of the boxes you can click on
    Rectangle _32bits = Rectangle(200, 230, 220, 250), _64bits = Rectangle(200, 255, 220, 275), importingModules = Rectangle(200, 280, 220, 300),
              optimized = Rectangle(400, 305, 420, 325), importingFiles = Rectangle(200, 305, 220, 325), compile = Rectangle(200, 375, 300, 415),
              release = Rectangle(400, 230, 420, 250), inline = Rectangle(400, 255, 420, 275), disableBoundsCheck = Rectangle(400, 280, 420, 300),
              rdmd = Rectangle(304, 377, 361, 415);
    // here we load the sounds the GUI will play
    immutable ubyte[] click = cast(immutable ubyte[]) import("click.ogg"), failure = cast(immutable ubyte[]) import("failure.ogg"),
                      success = cast(immutable ubyte[]) import("success.ogg");
    // and finally we create the booleans which will guide the program telling what is happening
    bool cursorShowTime, selected32bits, selected64bits, selectedImportingModules, selectedOptimized, selectedImportingFiles, selectedInline, selectedRelease,
         selectedDisableBoundsCheck;

    window.eventLoop(250,
    {
        // we set the painter and draw the background
        ScreenPainter painter = window.draw();
        painter.fillColor = Color.red(), painter.outlineColor = Color.black();

        // the Compile rectangle and the word "Name" are part of the background image, hence we aren't drawing them
        painter.drawImage(Point(0, 0), background);

        // now we draw the cursor and what you've typed
        painter.setFont(new OperatingSystemFont("Calibri", 25));
        if (cursorShowTime)
            painter.drawLine(cursorPosition, Point(cursorPosition.x, cursorPosition.y + 25));
        painter.drawText(Point(245, 200), fileName);

        // now we draw the boxes and their options
        painter.setFont(new OperatingSystemFont("Calibri", 22));

        painter.drawRectangle(_32bits.upperLeft(), 20, 20);
        painter.drawText(Point(_32bits.left + 22, _32bits.top - 1), "32 bits (-m32)");
        if (selected32bits)
        {
            painter.drawLine(_32bits.upperLeft(), _32bits.lowerRight());
            painter.drawLine(Point(_32bits.right, _32bits.top), Point(_32bits.left, _32bits.bottom));
        }

        painter.drawRectangle(_64bits.upperLeft(), 20, 20);
        painter.drawText(Point(_64bits.left + 22, _64bits.top - 1), "64 bits (-m64)");
        if (selected64bits)
        {
            painter.drawLine(_64bits.upperLeft(), _64bits.lowerRight());
            painter.drawLine(Point(_64bits.right, _64bits.top), Point(_64bits.left, _64bits.bottom));
        }

        painter.drawRectangle(importingModules.upperLeft(), 20, 20);
        painter.drawText(Point(importingModules.left + 22, importingModules.top - 1), "Importing modules (-i)");
        if (selectedImportingModules)
        {
            painter.drawLine(importingModules.upperLeft(), importingModules.lowerRight());
            painter.drawLine(Point(importingModules.right, importingModules.top), Point(importingModules.left, importingModules.bottom));
        }

        painter.drawRectangle(optimized.upperLeft(), 20, 20);
        painter.drawText(Point(optimized.left + 22, optimized.top - 1), "Optimized (-O)");
        if (selectedOptimized)
        {
            painter.drawLine(optimized.upperLeft(), optimized.lowerRight());
            painter.drawLine(Point(optimized.right, optimized.top), Point(optimized.left, optimized.bottom));
        }

        painter.drawRectangle(importingFiles.upperLeft(), 20, 20);
        painter.drawText(Point(importingFiles.left + 22, importingFiles.top - 1), "Importing files (-J.)");
        if (selectedImportingFiles)
        {
            painter.drawLine(importingFiles.upperLeft(), importingFiles.lowerRight());
            painter.drawLine(Point(importingFiles.right, importingFiles.top), Point(importingFiles.left, importingFiles.bottom));
        }

        painter.drawRectangle(release.upperLeft(), 20, 20);
        painter.drawText(Point(release.left + 22, release.top - 1), "Release (-release)");
        if (selectedRelease)
        {
            painter.drawLine(release.upperLeft(), release.lowerRight());
            painter.drawLine(Point(release.right, release.top), Point(release.left, release.bottom));
        }

        painter.drawRectangle(inline.upperLeft(), 20, 20);
        painter.drawText(Point(inline.left + 22, inline.top - 1), "Inline (-inline)");
        if (selectedInline)
        {
            painter.drawLine(inline.upperLeft(), inline.lowerRight());
            painter.drawLine(Point(inline.right, inline.top), Point(inline.left, inline.bottom));
        }

        painter.drawRectangle(disableBoundsCheck.upperLeft(), 20, 20);
        painter.drawText(Point(disableBoundsCheck.left + 22, disableBoundsCheck.top - 1), "Disable bounds check (-boundscheck=off)");
        if (selectedDisableBoundsCheck)
        {
            painter.drawLine(disableBoundsCheck.upperLeft(), disableBoundsCheck.lowerRight());
            painter.drawLine(Point(disableBoundsCheck.right, disableBoundsCheck.top), Point(disableBoundsCheck.left, disableBoundsCheck.bottom));
        }

        // we update if the cursor will blink(true) or not(false)
        cursorShowTime = !cursorShowTime;
    },
    // this allows you to click on the boxes, the order is the same as above
    (MouseEvent event)
    {
        // notice we update the value of the boolean variable which tells if they are selected or not
        if (event.type == MouseEventType.buttonPressed && event.button == MouseButton.left)
            if (_32bits.contains(Point(event.x, event.y)))
            {
                music.playOgg(click);
                if (!selected32bits)
                {
                    options ~= "-m32";
                    selected32bits = true;
                }
                else
                {
                    options = remove(options, countUntil(options, "-m32"));
                    selected32bits = false;
                }
            }
            else if (_64bits.contains(Point(event.x, event.y)))
            {
                music.playOgg(click);
                if (!selected64bits)
                {
                    options ~= "-m64";
                    selected64bits = true;
                }
                else
                {
                    options = remove(options, countUntil(options, "-m64"));
                    selected64bits = false;
                }
            }
            else if (importingModules.contains(Point(event.x, event.y)))
            {
                music.playOgg(click);
                if (!selectedImportingModules)
                {
                    options ~= "-i";
                    selectedImportingModules = true;
                }
                else
                {
                    options = remove(options, countUntil(options, "-i"));
                    selectedImportingModules = false;
                }
            }
            else if (optimized.contains(Point(event.x, event.y)))
            {
                music.playOgg(click);
                if (!selectedOptimized)
                {
                    options ~= "-O";
                    selectedOptimized = true;
                }
                else
                {
                    options = remove(options, countUntil(options, "-O"));
                    selectedOptimized = false;
                }
            }
            else if (importingFiles.contains(Point(event.x, event.y)))
            {
                music.playOgg(click);
                if (!selectedImportingFiles)
                {
                    options ~= "-J.";
                    selectedImportingFiles = true;
                }
                else
                {
                    options = remove(options, countUntil(options, "-J."));
                    selectedImportingFiles = false;
                }
            }
            else if (release.contains(Point(event.x, event.y)))
            {
                music.playOgg(click);
                if (!selectedRelease)
                {
                    options ~= "-release";
                    selectedRelease = true;
                }
                else
                {
                    options = remove(options, countUntil(options, "-release"));
                    selectedRelease = false;
                }
            }
            else if (inline.contains(Point(event.x, event.y)))
            {
                music.playOgg(click);
                if (!selectedInline)
                {
                    options ~= "-inline";
                    selectedInline = true;
                }
                else
                {
                    options = remove(options, countUntil(options, "-inline"));
                    selectedInline = false;
                }
            }
            else if (disableBoundsCheck.contains(Point(event.x, event.y)))
            {
                music.playOgg(click);
                if (!selectedDisableBoundsCheck)
                {
                    options ~= "-boundscheck=off";
                    selectedDisableBoundsCheck = true;
                }
                else
                {
                    options = remove(options, countUntil(options, "-boundscheck=off"));
                    selectedDisableBoundsCheck = false;
                }
            }
            // this is when you click on Compile
            else if (compile.contains(Point(event.x, event.y)))
            {
                music.playOgg(click);
                commandPhrase = replace(commandPhrase, "fileName", fileName);
                // we must add the null terminator otherwise the pointer will go over the edge
                commandPhrase ~= join(options, ' ') ~ '\0';
                // we remove the file extension so it doesn't cause problems
                if (fileName[$ - 2 .. $] == ".d")
                {
                    fileName = fileName[0 .. $ - 2];
                    cursorPosition.x -= 18;
                }
                // function system() only works with const char* and we remove the previous executable before creating the new
                if (exists(fileName))
                    system(cast(const char*) ("rm " ~ fileName));
                system(cast(const char*) commandPhrase);
                // we play a sound to tell if the compiling worked
                if (exists(fileName ~ ".exe"))
                    music.playOgg(success);
                else
                    music.playOgg(failure);
                // we return it to default so it can be used again
                commandPhrase = "dmd fileName ";
            }
            else if (rdmd.contains(Point(event.x, event.y)))
            {
                music.playOgg(click);
                system(cast(const char*) ("rdmd " ~ fileName ~ '\0'));
            }
    },
    // here is when you type the name of the file
    (dchar character)
    {
        // we allow you to erase it if you hit Backspace and we update the position of the cursor as you type
        if (character == '\b')
        {
            // you can't erase if it's empty
            if (fileName.length > 0)
            {
                fileName = fileName[0 .. $ - 1];
                cursorPosition.x -= 9;
            }
        }
        // we don't want to add Enter to the file name
        else if (character != '\r' && character != '\n')
        {
            fileName ~= character;
            cursorPosition.x += 9;
        }
    },
    // here you can run the executable after compiling by hitting Enter
    (KeyEvent event)
    {
        if (event.pressed && event.key == Key.Enter)
            system(cast(const char*) (fileName ~ ".exe"));
    });
}
