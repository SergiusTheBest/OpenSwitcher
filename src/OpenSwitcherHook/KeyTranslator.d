private
{
    import std.c.windows.windows;
    import std.container;
    import core.stdc.wchar_;
    import WinApi;
    import Key;
    import Input;
    import Util;

    enum State
    {
        Initial,
        TranslationInProgress,
        Translated,
        CopyInProgress,
        PasteInProgress,
    }

    Array!Key g_typedKeys;
    Array!Key g_selectedKeys;
    State g_state;

    void translateSelectedKeys2()
    {
        if (!IsClipboardFormatAvailable(CF_UNICODETEXT))
        {
            return;
        }

        if (!OpenClipboard(null))
        {
            return;
        }

        scope(exit)
        {
            CloseClipboard();
        }

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

        scope(exit)
        {
            GlobalUnlock(data);
        }

        auto len = wcslen(str);

        g_selectedKeys.clear();
        g_selectedKeys.reserve(len);

        foreach (int i; 0..len)
        {
            g_selectedKeys.insertBack(Key.Key(str[i]));
        }    

        ActivateKeyboardLayout(HKL_NEXT, KLF_SETFORPROCESS);

        wchar[] newStr;
        newStr.reserve(len + 1);

        foreach (Key key; g_selectedKeys)
        {
            newStr[newStr.length++] = key.toUnicode();
        }

        newStr[newStr.length++] = 0;

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

        scope(exit)
        {
            GlobalUnlock(newDataPtr);
        }

        wcscpy(newDataPtr, newStr.ptr);

        if (!SetClipboardData(CF_UNICODETEXT, newData))
        {
            GlobalFree(newData);
        }

        SendInput(kPasteKeys.length, kPasteKeys.ptr, INPUT.sizeof);
        SendInput(kMarkerKeys.length, kMarkerKeys.ptr, INPUT.sizeof);
        g_state = State.PasteInProgress;
    }
}

public
{
    void addToTypedKeys(LPMSG msg)
    {
        if (State.Translated == g_state)
        {
            g_state = State.Initial;
            g_typedKeys.clear();
        }

        if (isKeyPressed(VK_CONTROL) || isKeyPressed(VK_MENU))
        {
            return;
        }

        g_typedKeys.insertBack(Key.Key(msg));
    }

    void clearTypedKeys()
    {
        g_typedKeys.clear();
    }

    void translateTypedKeys()
    {
        if (g_typedKeys.empty())
        {
            return;
        }

        {
            INPUT[] input;
            input.reserve(g_typedKeys.length * 2);

            foreach (Key key; g_typedKeys)
            {
                input[input.length++] = kBackKeyDown;
                input[input.length++] = kBackKeyUp;
            }

            SendInput(input.length, input.ptr, INPUT.sizeof);
        }

        {
            INPUT[] input;
            input.reserve(g_typedKeys.length * 4);

            foreach (Key key; g_typedKeys)
            {
                input ~= key.toInput();
            }

            ActivateKeyboardLayout(HKL_NEXT, KLF_SETFORPROCESS);
            SendInput(input.length, input.ptr, INPUT.sizeof);

            g_typedKeys.clear();
        }

        SendInput(kMarkerKeys.length, kMarkerKeys.ptr, INPUT.sizeof);
        g_state = State.TranslationInProgress;
    }

    void translateSelectedKeys()
    {
        SendInput(kCopyKeys.length, kCopyKeys.ptr, INPUT.sizeof);
        SendInput(kMarkerKeys.length, kMarkerKeys.ptr, INPUT.sizeof);
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
            break;

        default:
            break;
        }
    }
}