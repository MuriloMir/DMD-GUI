# DMD-GUI
A GUI for you to use DMD more comfortably, it even makes sounds to tell if the compiling was successful or not. It is 100% written in D and uses only the arsd library.

Just download the DMD executable file (check if it's the Linux or the Windows version) into your project's folder, type the name of your source code file and then select the boxes and click on Compile. Then presse Enter to run the program.

If you wanna compile it yourself, download the source code along with the Dependencies file, extract it and type in the terminal the command: dmd source -i -m64 -J. -O (notice there is a dot after J), MAYBE you will need to add -L/SUBSYSTEM:WINDOWS if you are on Windows.
