module Install;

import DllMain;
import Hook;
import WinApi;

__gshared HHOOK g_getMsgHook;
__gshared HHOOK g_callWndHook;

extern (Windows) nothrow void installHook()
{
    g_getMsgHook = SetWindowsHookExW(WH_GETMESSAGE, &getMsgProc, g_instance, 0);
    g_callWndHook = SetWindowsHookExW(WH_CALLWNDPROC, &callWndProc, g_instance, 0);
}

extern (Windows) nothrow void uninstallHook()
{
    UnhookWindowsHookEx(g_callWndHook);
    UnhookWindowsHookEx(g_getMsgHook);
}