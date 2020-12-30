import arsd.image : loadImageFromMemory;
import core.stdc.stdlib : system;
import arsd.simpledisplay : Color, Image, MouseButton, MouseEvent, MouseEventType, OperatingSystemFont, Point, Rectangle, ScreenPainter, SimpleWindow,
                            TextAlignment;
import std.algorithm.searching : countUntil;
import std.algorithm.mutation : remove;
import std.array : join, replace;

void main()
{
    SimpleWindow window = new SimpleWindow(800, 600, "DMD");

    Image background = Image.fromMemoryImage(loadImageFromMemory(cast(immutable ubyte[]) import("background.jpeg")));
    // 'commandPhrase' is the phrase that will be sent to the system when you click "Compile", 'fileName' will contain the name of the source file
    string commandPhrase = "dmd fileName ", fileName = "";
    // here we will store the options you have selected
    string[] options;
    // where the cursor will be when you type the name of the file to be compiled
    Point cursorPosition = Point(245, 200);
    // here we create all of the Rectangles of the boxes you can click on
    Rectangle _32bits = Rectangle(200, 230, 220, 250), _64bits = Rectangle(200, 255, 220, 275), importingModules = Rectangle(200, 280, 220, 300),
              optimized = Rectangle(200, 305, 220, 325), compile = Rectangle(200, 350, 300, 390);
    // and finally we create the booleans which will guide the program telling what is happening
    bool cursorShowTime, selected32bits, selected64bits, selectedImportingModules, selectedOptimized;

    window.eventLoop(250,
    {
        // we set the painter and draw the background, cursor and what you've typed, "32 bit", "64 bits", "Importing modules" and "Optimized"
        ScreenPainter painter = window.draw();
        painter.fillColor = Color.blue(), painter.outlineColor = Color.black();

        // the Compile rectangle and the word "Name" are part of the background image, hence we aren't drawing them
        painter.drawImage(Point(0, 0), background);

        painter.setFont(new OperatingSystemFont("Ubuntu Mono", 14));
        if (cursorShowTime)
            painter.drawLine(cursorPosition, Point(cursorPosition.x, cursorPosition.y + 25));
        painter.drawText(Point(245, 203), fileName);

        painter.setFont(new OperatingSystemFont("Ubuntu", 13));

        painter.drawRectangle(Point(200, 230), 20, 20);
        painter.drawText(Point(_32bits.left + 22, _32bits.top), "32 bits", Point(_32bits.right + 30, _32bits.bottom),
                         TextAlignment.Left | TextAlignment.VerticalCenter);
        if (selected32bits)
        {
            painter.drawLine(Point(200, 230), Point(220, 250));
            painter.drawLine(Point(220, 230), Point(200, 250));
        }

        painter.drawRectangle(Point(200, 255), 20, 20);
        painter.drawText(Point(_64bits.left + 22, _64bits.top), "64 bits", Point(_64bits.right + 30, _64bits.bottom),
                         TextAlignment.Left | TextAlignment.VerticalCenter);
        if (selected64bits)
        {
            painter.drawLine(Point(200, 255), Point(220, 275));
            painter.drawLine(Point(220, 255), Point(200, 275));
        }

        painter.drawRectangle(Point(200, 280), 20, 20);
        painter.drawText(Point(importingModules.left + 22, importingModules.top), "Importing modules",
                         Point(importingModules.right + 30, importingModules.bottom), TextAlignment.Left | TextAlignment.VerticalCenter);
        if (selectedImportingModules)
        {
            painter.drawLine(Point(200, 280), Point(220, 300));
            painter.drawLine(Point(220, 280), Point(200, 300));
        }

        painter.drawRectangle(Point(200, 305), 20, 20);
        painter.drawText(Point(optimized.left + 22, optimized.top), "Optimized", Point(optimized.right + 30, optimized.bottom),
                         TextAlignment.Left | TextAlignment.VerticalCenter);
        if (selectedOptimized)
        {
            painter.drawLine(Point(200, 305), Point(220, 325));
            painter.drawLine(Point(220, 305), Point(200, 325));
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
            // this is when you click on Compile
            else if (compile.contains(Point(event.x, event.y)))
            {
                commandPhrase = commandPhrase.replace("fileName", fileName);
                // we must add the null terminator otherwise the pointer will go over the edge
                commandPhrase ~= options.join(' ') ~ '\0';
                // function system() only works with const char*
                system(cast(const char*) commandPhrase);
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
        else
        {
            fileName ~= character;
            cursorPosition.x += 9;
        }
    });
}
