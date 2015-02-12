module Main;

import std.c.windows.windows;
import std.getopt;
import std.process;
import std.conv;
import std.exception;
import WinApi;
static import AppWnd;

extern(Windows) nothrow
{
    void installHook();
    void uninstallHook();
}

void mymain(string[] argv)
{   
    HANDLE parent;

    version(Win32)
    {
        uint ppid;
        getopt(argv, "ppid", &ppid);

        if (ppid)
        {
            parent = OpenProcess(SYNCHRONIZE, false, ppid);
        }
    }
    else
    {
        collectException(spawnProcess(["OpenSwitcherApp32.exe", "--ppid=" ~ to!string(thisProcessID())]));
    }

    installHook();

    if (parent)
    {
        AppWnd.runMessageLoop(parent);
    }
    else
    {
        AppWnd.run();
    }

    uninstallHook();
}
