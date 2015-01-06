private
{
    import std.c.windows.windows;
    import std.container;
    import core.stdc.wchar_;
    import my.winhook;

    Array!Key g_storedKeys;
    bool g_translated;
    bool g_copy;
    bool g_clear;

    immutable INPUT kBackKeyDown;
    immutable INPUT kBackKeyUp;
    immutable INPUT kShiftKeyDown;
    immutable INPUT kShiftKeyUp;
    immutable INPUT[4] kCopyKeys;
    immutable INPUT[4] kPasteKeys;
    immutable INPUT[2] kMarkerKeys;

    struct Key
    {
        byte vk;
        bool shift;
    }

    shared static this()
    {
        kBackKeyDown = makeINPUT(VK_BACK);
        kBackKeyUp = makeINPUT(VK_BACK, true);

        kShiftKeyDown = makeINPUT(VK_SHIFT);
        kShiftKeyUp = makeINPUT(VK_SHIFT, true);

        kCopyKeys[0] = makeINPUT(VK_CONTROL);
        kCopyKeys[1] = makeINPUT(0x43);
        kCopyKeys[2] = makeINPUT(0x43, true);
        kCopyKeys[3] = makeINPUT(VK_CONTROL, true);

        kPasteKeys[0] = makeINPUT(VK_CONTROL);
        kPasteKeys[1] = makeINPUT(0x56);
        kPasteKeys[2] = makeINPUT(0x56, true);
        kPasteKeys[3] = makeINPUT(VK_CONTROL, true);

        kMarkerKeys[0] = makeINPUT(VK_CONTROL, false, true);
        kMarkerKeys[1] = makeINPUT(VK_CONTROL, true, true);
    }

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

        byte[] keys;
        keys.reserve(len);

        foreach (int i; 0..len)
        {
            auto vk = cast(byte)VkKeyScanW(str[i]);

            keys[keys.length++] = vk;
        }    

        ActivateKeyboardLayout(cast(HKL)HKL_NEXT, KLF_SETFORPROCESS);

        wchar[KL_NAMELENGTH] keyboardName;
        GetKeyboardLayoutNameW(keyboardName.ptr);

        //MessageBoxW(null, keyboardName.ptr, "keyboard", 0);

        wchar[] newStr;
        newStr.reserve(len + 1);

        immutable ubyte[256] state = 0;

        foreach (int i; 0..len)
        {
            wchar wch;
            ToUnicode(keys[i], 0, state.ptr, &wch, 1, 0);

            newStr[newStr.length++] = wch;
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

    INPUT makeINPUT(byte vk, bool up = false, bool marker = false)
    {
        INPUT input;
        input.type = INPUT_KEYBOARD;
        input.ki.wVk = vk;
        input.ki.time = marker ? -1 : 0;
        input.ki.dwFlags = up ? KEYEVENTF_KEYUP : 0;

        return input;
    }
}

public
{
    void addToStoredKeys(LPMSG msg)
    {
        if (g_clear)
        {
            g_storedKeys.clear();
            g_clear = false;
        }

        if (GetKeyState(VK_CONTROL) & 0x8000 || GetKeyState(VK_MENU) & 0x8000)
        {
            return;
        }

        Key key = { cast(byte)msg.wParam, cast(bool)(GetKeyState(VK_SHIFT) & 0x8000) };

        g_storedKeys.insertBack(key);
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
            INPUT[] keys;
            keys.reserve(g_storedKeys.length * 2);

            foreach (Key key; g_storedKeys)
            {
                keys[keys.length++] = kBackKeyDown;
                keys[keys.length++] = kBackKeyUp;
            }

            SendInput(keys.length, keys.ptr, INPUT.sizeof);
        }

        {
            INPUT[] keys;
            keys.reserve(g_storedKeys.length * 4);

            foreach (Key key; g_storedKeys)
            {
                if (key.shift)
                {
                    keys[keys.length++] = kShiftKeyDown;
                }

                keys[keys.length++] = makeINPUT(key.vk);
                keys[keys.length++] = makeINPUT(key.vk, true);

                if (key.shift)
                {
                    keys[keys.length++] = kShiftKeyUp;
                }
            }

            ActivateKeyboardLayout(cast(HKL)HKL_NEXT, KLF_SETFORPROCESS);
            SendInput(keys.length, keys.ptr, INPUT.sizeof);            
        }

        SendInput(kMarkerKeys.length, kMarkerKeys.ptr, INPUT.sizeof);
        g_storedKeys.clear();
        g_translated = true;
    }

    void translateSelectedKeys()
    {
        SendInput(kCopyKeys.length, kCopyKeys.ptr, INPUT.sizeof);
        SendInput(kMarkerKeys.length, kMarkerKeys.ptr, INPUT.sizeof);
        g_copy = true;
    }

    void checkForMarkerKey(LPMSG msg)
    {
        if (-1 == msg.time)
        {
            if (g_translated)
            {
                g_translated = false;
                g_clear = true;
            }

            if (g_copy)
            {
                translateSelectedKeys2();
                g_copy = false;
            }
        }
    }
}