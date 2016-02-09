module WinMain;

import core.sys.windows.windows;
import std.string;
import std.utf;
import core.stdc.wchar_;
import core.stdc.string;
import core.runtime;
import Main;

string[] getArguments()
{
    wchar*  cbuf = GetCommandLineW();
    int     argc = 0;
    wchar** argv = CommandLineToArgvW(cbuf, &argc);

    scope(exit) LocalFree(argv);
    
    string[] arguments;
    arguments.length = argc;

    for (int i = 0; i < argc; ++i)
    {
        wchar[] arg;
        arg.length = wcslen(argv[i]);
        memcpy(arg.ptr, argv[i], arg.length * wchar.sizeof);

        arguments[i] = toUTF8(arg);
    }

    return arguments;
}

extern(Windows) int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPCSTR lpCmdLine, int iCmdShow) 
{
    try
    {
        Runtime.initialize();

        mymain(getArguments());

        Runtime.terminate();
    }
    catch (Throwable o)     // catch any uncaught exceptions
    {
        MessageBoxA(null, toStringz(o.toString()), "Error", MB_ICONEXCLAMATION);
    }

    return 0;
}