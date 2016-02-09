module Install;

import core.sys.windows.windows;
import Hook;

__gshared HHOOK g_getMsgHook;
__gshared HHOOK g_callWndHook;

extern (Windows) nothrow void installHook()
{
    HMODULE hmodule;
    GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT, cast(const wchar*)&installHook, &hmodule);

    g_getMsgHook = SetWindowsHookExW(WH_GETMESSAGE, &getMsgProc, hmodule, 0);
    g_callWndHook = SetWindowsHookExW(WH_CALLWNDPROC, &callWndProc, hmodule, 0);
}

extern (Windows) nothrow void uninstallHook()
{
    UnhookWindowsHookEx(g_callWndHook);
    UnhookWindowsHookEx(g_getMsgHook);
}