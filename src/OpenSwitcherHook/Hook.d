module Hook;

import std.c.windows.windows;
import std.utf;
import WinApi;
import KeyTranslator;
import Util;

extern (Windows) nothrow LRESULT getMsgProc(int code, WPARAM wParam, LPARAM lParam)
{
    if (HC_ACTION == code && PM_REMOVE == wParam)
    {
        mixin exceptionSafeCall!(internalGetMsgProc);
        call();
    }

    return CallNextHookEx(null, code, wParam, lParam);
}

extern (Windows) nothrow LRESULT callWndProc(int code, WPARAM wParam, LPARAM lParam)
{
    if (HC_ACTION == code)
    {
        mixin exceptionSafeCall!(internalCallWndProc);
        call();
    }

    return CallNextHookEx(null, code, wParam, lParam);
}

mixin template exceptionSafeCall(alias func)
{
    nothrow void call()
    {
        try
        {
            func(wParam, lParam);
        }
        catch (Throwable e)
        {
            try
            {
                MessageBoxW(null, toUTF16z(e.toString()), "OpenSwitcher Error", MB_ICONERROR);
            }
            catch (Throwable e)
            {
            }
        }
    }
}

void internalGetMsgProc(WPARAM wParam, LPARAM lParam)
{
    auto msg = cast(LPMSG)lParam;

    switch (msg.message)
    {
        case WM_KEYDOWN:
            switch (msg.wParam)
            {
                case VK_PAUSE:
                    if (isKeyPressed(VK_SHIFT) && !isKeyPressed(VK_MENU) && !isKeyPressed(VK_CONTROL))
                    {
                        KeyTranslator.translateSelectedKeys();
                    }
                    else
                    {
                        KeyTranslator.translateTypedKeys();
                    }
                    break;

                case VK_BACK, VK_TAB, VK_CLEAR, VK_RETURN, VK_MENU, VK_ESCAPE, VK_PRIOR, VK_NEXT, VK_END, VK_HOME, VK_LEFT, VK_UP, VK_RIGHT, VK_DOWN, VK_SELECT, VK_PRINT, VK_EXECUTE, VK_SNAPSHOT, 
                    VK_INSERT, VK_DELETE, VK_HELP, VK_LWIN, VK_RWIN, VK_APPS, VK_F1, VK_F2, VK_F3, VK_F4, VK_F5, VK_F6, VK_F7, VK_F8, VK_F9, VK_F10, VK_F11, VK_F12,
                    VK_LCONTROL, VK_RCONTROL, VK_LMENU, VK_RMENU:
                    KeyTranslator.clearTypedKeys();
                    break;

                case VK_CONTROL:
                    KeyTranslator.checkForMarkerKey(msg);
                    break;

                case VK_SHIFT, VK_CAPITAL, VK_NUMLOCK, VK_SCROLL, VK_LSHIFT, VK_RSHIFT:
                    break;

                default:
                    KeyTranslator.addToTypedKeys(msg);
                    break;
            }
            break;

        default:
            break;
    }
}

void internalCallWndProc(WPARAM wParam, LPARAM lParam)
{
    auto cwpStruct = cast(LPCWPSTRUCT)lParam;

    switch (cwpStruct.message)
    {
        case WM_SETFOCUS:
            KeyTranslator.clearTypedKeys();
            break;

        default:
            break;
    }
}