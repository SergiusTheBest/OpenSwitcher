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
    }

    Array!Key g_storedKeys;
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

        Key[] keys;
        keys.reserve(len);

        foreach (int i; 0..len)
        {
            keys[keys.length++] = Key.Key(str[i]);
        }    

        ActivateKeyboardLayout(HKL_NEXT, KLF_SETFORPROCESS);

        wchar[] newStr;
        newStr.reserve(len + 1);

        foreach (Key key; keys)
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
    }
}

public
{
    void addToStoredKeys(LPMSG msg)
    {
        if (State.Translated == g_state)
        {
            g_state = State.Initial;
            g_storedKeys.clear();
        }

        if (isKeyPressed(VK_CONTROL) || isKeyPressed(VK_MENU))
        {
            return;
        }

        g_storedKeys.insertBack(Key.Key(msg));
    }

    void clearStoredKeys()
    {
        g_storedKeys.clear();
    }

    void translateStoredKeys()
    {
        if (g_storedKeys.empty())
        {
            return;
        }

        {
            INPUT[] input;
            input.reserve(g_storedKeys.length * 2);

            foreach (Key key; g_storedKeys)
            {
                input[input.length++] = kBackKeyDown;
                input[input.length++] = kBackKeyUp;
            }

            SendInput(input.length, input.ptr, INPUT.sizeof);
        }

        {
            INPUT[] input;
            input.reserve(g_storedKeys.length * 4);

            foreach (Key key; g_storedKeys)
            {
                input ~= key.toInput();
            }

            ActivateKeyboardLayout(HKL_NEXT, KLF_SETFORPROCESS);
            SendInput(input.length, input.ptr, INPUT.sizeof);

            g_storedKeys.clear();
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

        default:
            break;
        }
    }
}