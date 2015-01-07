module Main;

import std.stdio;
import std.c.windows.windows;
import WinApi;
import AppWnd;

int main(string[] argv)
{   
    auto dllModule = LoadLibraryW("OpenSwitcherHook.dll");
    auto callWndProc = cast(HOOKPROC)GetProcAddress(dllModule, "callWndProc");
    auto getMsgProc = cast(HOOKPROC)GetProcAddress(dllModule, "getMsgProc");
    
    auto getMsgHook = SetWindowsHookExW(WH_GETMESSAGE, getMsgProc, dllModule, 0);
    auto callWndHook = SetWindowsHookExW(WH_CALLWNDPROC, callWndProc, dllModule, 0);

    AppWnd.run();

    UnhookWindowsHookEx(callWndHook);
    UnhookWindowsHookEx(getMsgHook);

    return 0;
}
