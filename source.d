// This software will be a GUI for the DMD compiler.

import arsd.image : loadImageFromMemory;
import arsd.simpleaudio : AudioOutputThread;
import arsd.simpledisplay : Color, Image, Key, KeyEvent, MouseButton, MouseEvent, MouseEventType, OperatingSystemFont, Point, Rectangle, ScreenPainter,
                            SimpleWindow;
import core.stdc.stdlib : system;
import std.algorithm.mutation : remove;
import std.algorithm.searching : countUntil;
import std.array : join, replace;
import std.file : exists;
import std.stdio : writeln;

// this is the data type for files we will be embedding into the executable, it has to be immutable because the arsd library demands it
alias memory = immutable ubyte[];

// this function will draw the box along with its option phrase
void drawBox(Rectangle box, string optionText, bool selected, ScreenPainter painter)
{
    // draw the box
    painter.drawRectangle(box.upperLeft(), 20, 20);
    // draw the text of the option
    painter.drawText(Point(box.left + 22, box.top - 1), optionText);

    // if you've selected the box
    if (selected)
    {
        // draw the first line to start the X
        painter.drawLine(box.upperLeft(), box.lowerRight());
        // draw the second line to complete the X
        painter.drawLine(Point(box.right, box.top), Point(box.left, box.bottom));
    }
}

// this function will allow you to select or undo the selection of a box
void interactWithBox(string optionText, ref bool selected, ref string[] options, AudioOutputThread music, memory click)
{
    // play the click sound
    music.playOgg(click);

    // if it wasn't previously selected
    if (!selected)
    {
        // add it to the array of options
        options ~= optionText;
        // set its boolean to true
        selected = true;
    }
    // if it was already selected
    else
    {
        // remove it from the array of options
        options = remove(options, countUntil(options, optionText));
        // set its boolean to false
        selected = false;
    }
}

void main()
{
    // create the GUI
    SimpleWindow window = new SimpleWindow(800, 600, "DMD");
    // create the audio thread
    AudioOutputThread music = AudioOutputThread(true);
    // create the 2 fonts we will use in the software
    OperatingSystemFont commandFont, optionsFont;

    // if you are on Windows
    version (Windows)
        // use these fonts
        commandFont = new OperatingSystemFont("Noto Mono", 20), optionsFont = new OperatingSystemFont("Calibri", 22);
    // if you are on Linux
    else
        // use these fonts
        commandFont = new OperatingSystemFont("Ubuntu Mono", 15), optionsFont = new OperatingSystemFont("Ubuntu", 13);

    // load the background image
    Image background = Image.fromMemoryImage(loadImageFromMemory(cast(memory) import("background.jpeg")));
    // 'commandPhrase' is the phrase that will be sent to the system when you click on "Compile", 'fileName' will contain the name of the source file
    string commandPhrase = "dmd fileName ", fileName;
    // this array will store the options you have selected
    string[] options;
    // this will store the place where the cursor will be when you type the name of the file to be compiled
    Point cursorPosition = Point(245, 200);
    // load the sounds the GUI will play
    memory click = cast(memory) import("click.ogg"), failure = cast(memory) import("failure.ogg"), success = cast(memory) import("success.ogg");
    // create the booleans which will tell the event loop what is happening
    bool cursorShowTime, selected32bits, selected64bits, selectedAddDebugInfo, selectedDisableBoundsCheck, selectedImportFiles,
         selectedImportModules, selectedInline, selectedGenerateJson, selectedOptimize, selectedRelease;

    // create all the Rectangles of the boxes you can click on, they are written here in the same order you see them when you run the software
    Rectangle _64bits = Rectangle(200, 240, 220, 260),          _32bits = Rectangle(400, 240, 420, 260),
              importModules = Rectangle(200, 265, 220, 285),    release = Rectangle(400, 265, 420, 285),
              importFiles = Rectangle(200, 290, 220, 310),      inline = Rectangle(400, 290, 420, 310),
              optimized = Rectangle(200, 315, 220, 335),        disableBoundsCheck = Rectangle(400, 315, 420, 335),
              addDebugInfo = Rectangle(200, 340, 220, 360),     generateJson = Rectangle(400, 340, 420, 360),
              compile = Rectangle(200, 385, 300, 425),          rdmd = Rectangle(304, 387, 361, 425);

    // start the event loop
    window.eventLoop(250,
    {
        // create the painter
        ScreenPainter painter = window.draw();
        // choose the colors
        painter.fillColor = Color.red(), painter.outlineColor = Color.black();
        // draw the background image, which already contains the "Compile" rectangle and the word "Name"
        painter.drawImage(Point(0, 0), background);
        // choose the font to draw the name of the file, we use a monospace font to make it easy to move the cursor around
        painter.setFont(commandFont);

        // if it is time to show the cursor (remember it blinks, therefore it will be displayed and omitted repeatedly)
        if (cursorShowTime)
            // draw the cursor
            painter.drawLine(cursorPosition, Point(cursorPosition.x, cursorPosition.y + 25));

        // draw what you've typed
        painter.drawText(Point(245, 200), fileName);

        // choose another font to draw the options of the boxes
        painter.setFont(optionsFont);

        // draw the 64 bits box
        drawBox(_64bits, "64 bits (-m64)", selected64bits, painter);
        // draw the Import modules box
        drawBox(importModules, "Import modules (-i)", selectedImportModules, painter);
        // draw the Import files box
        drawBox(importFiles, "Import files (-J.)", selectedImportFiles, painter);
        // draw the Optimize box
        drawBox(optimized, "Optimize (-O)", selectedOptimize, painter);
        // draw the Add debug info box
        drawBox(addDebugInfo, "Add debug info (-g)", selectedAddDebugInfo, painter);
        // draw the 32 bits box
        drawBox(_32bits, "32 bits (-m32)", selected32bits, painter);
        // draw the Release box
        drawBox(release, "Release (-release)", selectedRelease, painter);
        // draw Inline box
        drawBox(inline, "Inline (-inline)", selectedInline, painter);
        // draw the Disable bounds check box
        drawBox(disableBoundsCheck, "Disable bounds check (-boundscheck=off)", selectedDisableBoundsCheck, painter);
        // draw the Generate JSON box
        drawBox(generateJson, "Generate JSON (-X)", selectedGenerateJson, painter);

        // update if the cursor will blink (true) or not (false)
        cursorShowTime = !cursorShowTime;
    },
    // register mouse events
    (MouseEvent event)
    {
        // if you left-click
        if (event.type == MouseEventType.buttonPressed && event.button == MouseButton.left)
            // if you click on the 64 bits box
            if (_64bits.contains(Point(event.x, event.y)))
                interactWithBox("-m64", selected64bits, options, music, click);
            // if you click on the Import modules box
            else if (importModules.contains(Point(event.x, event.y)))
                interactWithBox("-i", selectedImportModules, options, music, click);
            // if you click on the Import files box
            else if (importFiles.contains(Point(event.x, event.y)))
                interactWithBox("-J.", selectedImportFiles, options, music, click);
            // if you click on the Optimize box
            else if (optimized.contains(Point(event.x, event.y)))
                interactWithBox("-O", selectedOptimize, options, music, click);
            // if you click on the Add debug info box
            else if (addDebugInfo.contains(Point(event.x, event.y)))
                interactWithBox("-g", selectedAddDebugInfo, options, music, click);
            // if you click on the 32 bits box
            else if (_32bits.contains(Point(event.x, event.y)))
                interactWithBox("-m32", selected32bits, options, music, click);
            // if you click on the Release box
            else if (release.contains(Point(event.x, event.y)))
                interactWithBox("-release", selectedRelease, options, music, click);
            // if you click on the Inline box
            else if (inline.contains(Point(event.x, event.y)))
                interactWithBox("-inline", selectedInline, options, music, click);
            // if you click on the Disable bounds check box
            else if (disableBoundsCheck.contains(Point(event.x, event.y)))
                interactWithBox("-boundscheck=off", selectedDisableBoundsCheck, options, music, click);
            // if you click on the Generate JSON box
            else if (generateJson.contains(Point(event.x, event.y)))
                interactWithBox("-X", selectedGenerateJson, options, music, click);
            // if you click on the Compile button and you've typed the name of the file to be compiled
            else if (compile.contains(Point(event.x, event.y)) && fileName != "")
            {
                // if the file name is more than 2 letters long and you've typed the extension ".d" in the file name
                if (fileName.length > 2 && fileName[$ - 2 .. $] == ".d")
                {
                    // remove the file extension, so it doesn't cause problems
                    fileName = fileName[0 .. $ - 2];
                    // update the position of the cursor
                    cursorPosition.x -= 20;
                }

                // play the click sound
                music.playOgg(click);
                // add the file name to the command phrase, notice we put it between "" to work in case of a compound name, such as "source 1.d"
                commandPhrase = replace(commandPhrase, "fileName", '\"' ~ fileName ~ '\"');
                // build the complete phrase
                commandPhrase ~= join(options, ' ');

                // if you are on Windows
                version (Windows)
                {
                    // clear the terminal, the 'system()' function only takes 'const char*'
                    system(cast(const char*) ("cls"));

                    // if there is already an executable with the name of your source code file
                    if (exists(fileName ~ ".exe"))
                        // remove the previous executable before creating the new, the 'system()' function only takes 'const char*',
                        // notice the file name must be between "" to work properly, it also requires the null character at the end
                        system(cast(const char*) ("del \"" ~ fileName ~ ".exe\"\0"));
                }
                // if you are on Linux
                else
                {
                    // clear the terminal, the 'system()' function only takes 'const char*'
                    system(cast(const char*) ("clear"));

                    // if there is already an executable with the name of your source code file
                    if (exists(fileName))
                    {
                        // remove the previous executable before creating the new, the 'system()' function only takes 'const char*',
                        // notice the file name must be between "" to work properly, it also requires the null character at the end
                        system(cast(const char*) ("rm \"" ~ fileName ~ "\"\0"));
                    }
                }

                // compile the source code file, the 'system()' function only takes 'const char*', it requires the null character at the end, to prevent bugs
                system(cast(const char*) (commandPhrase ~ '\0'));

                // if you are on Windows
                version (Windows)
                {
                    // if the executable was created successfully
                    if (exists(fileName ~ ".exe"))
                    {
                        // play the success sound
                        music.playOgg(success);
                        // write in the terminal a phrase telling the user it was successful
                        writeln("Compiled successfully.");
                    }
                    // if the executable failed to be created
                    else
                        // play the failure sound
                        music.playOgg(failure);
                }
                // if you are on Linux
                else
                    // if the executable was created successfully
                    if (exists(fileName))
                    {
                        // play the success sound
                        music.playOgg(success);
                        // write in the terminal a phrase telling the user it was successful
                        writeln("Compiled successfully.");
                    }
                    // if the executable failed to be created
                    else
                        // play the failure sound
                        music.playOgg(failure);

                // return the command phrase to the initial value, so it can be used again
                commandPhrase = "dmd fileName ";
            }
            // if you click on the rdmd button and you've typed the name of the file to be compiled
            else if (rdmd.contains(Point(event.x, event.y)) && fileName != "")
            {
                // play the click sound
                music.playOgg(click);

                // if you are on Windows
                version (Windows)
                {
                    // clear the terminal, the 'system()' function only takes 'const char*'
                    system(cast(const char*) ("cls"));
                    // compile and run the source code file, flags don't work with rdmd, the 'system()' function only takes 'const char*', notice
                    // we put the file name between "" to work, it also requires the null character at the end
                    system(cast(const char*) ("rdmd \"" ~ fileName ~ "\"\0"));
                }
                // if you are on Linux
                else
                {
                    // clear the terminal, the 'system()' function only takes 'const char*'
                    system(cast(const char*) ("clear"));
                    // compile and run the source code file, flags don't work with rdmd, the 'system()' function only takes 'const char*', notice
                    // we put the file name between "" to work, it also requires the null character at the end
                    system(cast(const char*) ("rdmd \"" ~ fileName ~ "\"\0"));
                }
            }
    },
    // register key events
    (KeyEvent event)
    {
        // if you press Enter and you've typed the name of the file to be compiled
        if (event.pressed && event.key == Key.Enter && fileName != "")
            // if you are on Windows
            version (Windows)
                // run the executable (after you've compiled it), the 'system()' function only takes 'const char*', notice the name must
                // be between "" to make it work, it also requires the null character at the end
                system(cast(const char*) ('\"' ~ fileName ~ "\"\0"));
            // if you are on Linux
            else
                // run the executable (after you've compiled it), the 'system()' function only takes 'const char*', notice the name must
                // be between "" to make it work, it also requires the null character at the end
                system(cast(const char*) ("./\"" ~ fileName ~ "\"\0"));
    },
    // register what you've typed
    (dchar character)
    {
        // if you press Backspace
        if (character == '\b')
        {
            // if there is anything to be erased
            if (fileName != "")
            {
                // erase the last character of the file name
                fileName = fileName[0 .. $ - 1];
                // update the position of the cursor
                cursorPosition.x -= 10;
            }
        }
        // if you press any key apart from Enter and Tab
        else if (character != '\r' && character != '\n' && character != '\t')
        {
            // add the letter to the name of the file
            fileName ~= character;
            // update the position of the cursor
            cursorPosition.x += 10;
        }
    });
}
