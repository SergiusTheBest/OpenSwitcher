module Main;

import std.stdio;
import std.c.windows.windows;
import AppWnd;

extern(Windows) nothrow
{
    void installHook();
    void uninstallHook();
}

int main(string[] argv)
{   
    installHook();

    AppWnd.run();

    uninstallHook();

    return 0;
}
