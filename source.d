import arsd.image : loadImageFromMemory;
import arsd.simpleaudio : AudioOutputThread;
import arsd.simpledisplay : Color, Image, Key, KeyEvent, MouseButton, MouseEvent, MouseEventType, OperatingSystemFont, Point, Rectangle, ScreenPainter,
                            SimpleWindow, TextAlignment;
import core.stdc.stdlib : system;
import std.algorithm.searching : countUntil;
import std.algorithm.mutation : remove;
import std.array : join, replace;
import std.file : exists;

void main()
{
    SimpleWindow window = new SimpleWindow(800, 600, "DMD");
    AudioOutputThread music = AudioOutputThread(true);

    Image background = Image.fromMemoryImage(loadImageFromMemory(cast(immutable ubyte[]) import("background.jpeg")));
    // 'commandPhrase' is the phrase that will be sent to the system when you click "Compile", 'fileName' will contain the name of the source file
    string commandPhrase = "dmd fileName ", fileName = "";
    // here we will store the options you have selected
    string[] options;
    // where the cursor will be when you type the name of the file to be compiled
    Point cursorPosition = Point(245, 200);
    // here we create all of the Rectangles of the boxes you can click on
    Rectangle _32bits = Rectangle(200, 230, 220, 250), _64bits = Rectangle(200, 255, 220, 275), importingModules = Rectangle(200, 280, 220, 300),
              optimized = Rectangle(200, 305, 220, 325), importingFiles = Rectangle(200, 330, 220, 350), compile = Rectangle(200, 375, 300, 415);
    // and finally we create the booleans which will guide the program telling what is happening
    bool cursorShowTime, selected32bits, selected64bits, selectedImportingModules, selectedOptimized, selectedImportingFiles;

    window.eventLoop(250,
    {
        // we set the painter and draw the background, cursor and what you've typed, "32 bit", "64 bits", "Importing modules", "Optimized" and "Importing files"
        ScreenPainter painter = window.draw();
        painter.fillColor = Color.red(), painter.outlineColor = Color.black();

        // the Compile rectangle and the word "Name" are part of the background image, hence we aren't drawing them
        painter.drawImage(Point(0, 0), background);

        painter.setFont(new OperatingSystemFont("Ubuntu Mono", 14));
        if (cursorShowTime)
            painter.drawLine(cursorPosition, Point(cursorPosition.x, cursorPosition.y + 25));
        painter.drawText(Point(245, 203), fileName);

        painter.setFont(new OperatingSystemFont("Ubuntu", 13));

        painter.drawRectangle(_32bits.upperLeft(), 20, 20);
        painter.drawText(Point(_32bits.left + 22, _32bits.top), "32 bits", Point(_32bits.right + 30, _32bits.bottom),
                         TextAlignment.Left | TextAlignment.VerticalCenter);
        if (selected32bits)
        {
            painter.drawLine(_32bits.upperLeft(), _32bits.lowerRight());
            painter.drawLine(Point(_32bits.right, _32bits.top), Point(_32bits.left, _32bits.bottom));
        }

        painter.drawRectangle(_64bits.upperLeft(), 20, 20);
        painter.drawText(Point(_64bits.left + 22, _64bits.top), "64 bits", Point(_64bits.right + 30, _64bits.bottom),
                         TextAlignment.Left | TextAlignment.VerticalCenter);
        if (selected64bits)
        {
            painter.drawLine(_64bits.upperLeft(), _64bits.lowerRight());
            painter.drawLine(Point(_64bits.right, _64bits.top), Point(_64bits.left, _64bits.bottom));
        }

        painter.drawRectangle(importingModules.upperLeft(), 20, 20);
        painter.drawText(Point(importingModules.left + 22, importingModules.top), "Importing modules",
                         Point(importingModules.right + 30, importingModules.bottom), TextAlignment.Left | TextAlignment.VerticalCenter);
        if (selectedImportingModules)
        {
            painter.drawLine(importingModules.upperLeft(), importingModules.lowerRight());
            painter.drawLine(Point(importingModules.right, importingModules.top), Point(importingModules.left, importingModules.bottom));
        }

        painter.drawRectangle(optimized.upperLeft(), 20, 20);
        painter.drawText(Point(optimized.left + 22, optimized.top), "Optimized", Point(optimized.right + 30, optimized.bottom),
                         TextAlignment.Left | TextAlignment.VerticalCenter);
        if (selectedOptimized)
        {
            painter.drawLine(optimized.upperLeft(), optimized.lowerRight());
            painter.drawLine(Point(optimized.right, optimized.top), Point(optimized.left, optimized.bottom));
        }

        painter.drawRectangle(importingFiles.upperLeft(), 20, 20);
        painter.drawText(Point(importingFiles.left + 22, importingFiles.top), "Importing files", Point(importingFiles.right + 30, importingFiles.bottom),
                         TextAlignment.Left | TextAlignment.VerticalCenter);
        if (selectedImportingFiles)
        {
            painter.drawLine(importingFiles.upperLeft(), importingFiles.lowerRight());
            painter.drawLine(Point(importingFiles.right, importingFiles.top), Point(importingFiles.left, importingFiles.bottom));
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
                if (!selected32bits)
                {
                    selected32bits = true;
                    options ~= "-m32";
                }
                else
                {
                    selected32bits = false;
                    options = options.remove(options.countUntil("-m32"));
                }
            }
            else if (_64bits.contains(Point(event.x, event.y)))
            {
                if (!selected64bits)
                {
                    selected64bits = true;
                    options ~= "-m64";
                }
                else
                {
                    selected64bits = false;
                    options = options.remove(options.countUntil("-m64"));
                }
            }
            else if (importingModules.contains(Point(event.x, event.y)))
            {
                if (!selectedImportingModules)
                {
                    selectedImportingModules = true;
                    options ~= "-i";
                }
                else
                {
                    selectedImportingModules = false;
                    options = options.remove(options.countUntil("-i"));
                }
            }
            else if (optimized.contains(Point(event.x, event.y)))
            {
                if (!selectedOptimized)
                {
                    selectedOptimized = true;
                    options ~= "-O";
                }
                else
                {
                    selectedOptimized = false;
                    options = options.remove(options.countUntil("-O"));
                }
            }
            else if (importingFiles.contains(Point(event.x, event.y)))
            {
                if (!selectedImportingFiles)
                {
                    selectedImportingFiles = true;
                    options ~= "-J.";
                }
                else
                {
                    selectedImportingFiles = false;
                    options = options.remove(options.countUntil("-J."));
                }
            }
            // this is when you click on Compile
            else if (compile.contains(Point(event.x, event.y)))
            {
                commandPhrase = commandPhrase.replace("fileName", fileName);
                // we must add the null terminator otherwise the pointer will go over the edge
                commandPhrase ~= options.join(' ') ~ '\0';
                // we remove the file extension so it doesn't cause problems
                if (fileName[$ - 2 .. $] == ".d")
                    fileName = fileName[0 .. $ - 2];
                // function system() only works with const char* and we remove the previous executable before creating the new
                if (exists(fileName))
                    system(cast(const char*) ("rm " ~ fileName));
                system(cast(const char*) commandPhrase);
                // we play a sound to tell if the compiling worked
                if (exists(fileName))
                    music.playWav("success.wav");
                else
                    music.playWav("failure.wav");
                // we return it to default so it can be used again
                commandPhrase = "dmd fileName ";
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
        // we don't want to add Enter to the file name, and here it's \r and not \n
        else if (character != '\r')
        {
            fileName ~= character;
            cursorPosition.x += 9;
        }
    },
    // here you can run the executable after compiling(obviously) by hitting Enter
    (KeyEvent event)
    {
        if (event.pressed && event.key == Key.Enter)
            system(cast(const char*) ("./" ~ fileName ~ '\0'));
    });
}
