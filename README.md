# DMD-GUI
A GUI for you to use DMD more comfortably, it even makes sounds to tell if the compiling was successful or not. It is 100% written in D and uses only the arsd library.

Just download the DMD executable file (notice it is for the Windows version) into your project's folder, type the name of your source code file and then select the boxes and click on Compile. Then press Enter to run the program.

If you wanna compile it yourself then download the source code along with the 'dependencies' file, extract it and type in the terminal the command: dmd source -i -m64 -J. -O (notice there is a dot after J), maybe you will need to add -L/SUBSYSTEM:WINDOWS if you are on Windows.

The source code is written for Windows, you may need to adapt it if you wanna compile it on Linux.
