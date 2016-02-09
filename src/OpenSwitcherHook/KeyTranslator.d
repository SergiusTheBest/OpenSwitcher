module KeyTranslator;

import core.sys.windows.windows;
import core.stdc.wchar_;
import Key;
import Input;
import Util;
import KeyboardState;

private
{
    enum State
    {
        Initial,
        TranslationInProgress,
        Translated,
        CopyInProgress,
        PasteInProgress,
    }

    Key[] g_typedKeys;
    Key[] g_selectedKeys;
    State g_state;
    bool g_space;

    void translateSelectedKeys2()
    {
        scope(exit)
        {
            SendInput(kMarkerKeys.length, cast(INPUT*)kMarkerKeys.ptr, INPUT.sizeof);
            g_state = State.PasteInProgress;
        }

        if (!IsClipboardFormatAvailable(CF_UNICODETEXT))
        {
            return;
        }

        if (!OpenClipboard(null))
        {
            return;
        }

        scope(exit) CloseClipboard();

        auto data = GetClipboardData(CF_UNICODETEXT);
        if (!data)
        {
            return;
        }

        auto str = cast(wchar*)GlobalLock(data);
        if (!str)
        {
            return;
        }

        scope(exit) GlobalUnlock(data);

        auto len = cast(int)wcslen(str);

        g_selectedKeys.length = 0;
        g_selectedKeys.reserve(len);

        HKL[] layouts = getKeyboardLayouts();

        foreach (int i; 0..len)
        {
            g_selectedKeys ~= Key.Key(str[i], layouts);
        }    

        ActivateKeyboardLayout(cast(HKL)HKL_NEXT, 0);

        wchar[] newStr;
        newStr.reserve(len + 1);

        foreach (Key key; g_selectedKeys)
        {
            newStr ~= key.toUnicode();
        }

        newStr ~= 0;

        EmptyClipboard();

        auto newData = GlobalAlloc(GMEM_MOVEABLE, newStr.length * wchar.sizeof);
        if (!newData)
        {
            return;
        }

        auto newDataPtr = cast(wchar*)GlobalLock(newData);
        if (!newDataPtr)
        {
            return;
        }

        scope(exit) GlobalUnlock(newDataPtr);

        wcscpy(newDataPtr, newStr.ptr);

        if (!SetClipboardData(CF_UNICODETEXT, newData))
        {
            GlobalFree(newData);
        }

        SendInput(kPasteKeys.length, cast(INPUT*)kPasteKeys.ptr, INPUT.sizeof);
    }
}

public
{
    void addToTypedKeys(LPMSG msg)
    {
        if (State.Translated == g_state)
        {
            g_state = State.Initial;
            clearTypedKeys();
        }

        if (isKeyPressed(VK_CONTROL) || isKeyPressed(VK_MENU))
        {
            return;
        }

        if (State.TranslationInProgress != g_state)
        {
            if (VK_SPACE == cast(byte)msg.wParam)
            {
                g_space = true;
            }
            else if (g_space)
            {
                clearTypedKeys();
            }
        }

        g_typedKeys ~= Key.Key(msg);
    }

    void clearTypedKeys()
    {
        g_typedKeys.length = 0;
        g_space = false;
    }

    void translateTypedKeys()
    {
        if (!g_typedKeys.length)
        {
            return;
        }

        {
            INPUT[] input;
            input.reserve(g_typedKeys.length * 2);

            foreach (Key key; g_typedKeys)
            {
                input ~= kBackKeyDown;
                input ~= kBackKeyUp;
            }

            SendInput(cast(int)input.length, input.ptr, cast(int)INPUT.sizeof);
        }

        {
            INPUT[] input;
            input.reserve(g_typedKeys.length * 4);

            foreach (Key key; g_typedKeys)
            {
                input ~= key.toInput();
            }

            ActivateKeyboardLayout(cast(HKL)HKL_NEXT, 0);
            SendInput(cast(int)input.length, input.ptr, cast(int)INPUT.sizeof);

            g_typedKeys.length = 0;
        }

        SendInput(kMarkerKeys.length, cast(INPUT*)kMarkerKeys.ptr, INPUT.sizeof);
        g_state = State.TranslationInProgress;
    }

    void translateSelectedKeys()
    {
        KeyboardState.clear();

        SendInput(kCopyKeys.length, cast(INPUT*)kCopyKeys.ptr, INPUT.sizeof);
        SendInput(kMarkerKeys.length, cast(INPUT*)kMarkerKeys.ptr, INPUT.sizeof);
        g_state = State.CopyInProgress;
    }

    void checkForMarkerKey(LPMSG msg)
    {
        if (!isMarkerKey(msg))
        {
            return;
        }

        switch (g_state)
        {
        case State.TranslationInProgress:
            g_state = State.Translated;
            break;

        case State.CopyInProgress:
            g_state = State.Initial;
            translateSelectedKeys2();
            break;

        case State.PasteInProgress:
            g_state = State.Translated;
            g_typedKeys = g_selectedKeys;

            KeyboardState.restore();

            if (IsClipboardFormatAvailable(CF_UNICODETEXT))
            {
                if (OpenClipboard(null))
                {
                    EmptyClipboard();
                    CloseClipboard();
                }
            }

            break;

        default:
            break;
        }
    }
}