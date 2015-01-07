module Input;

import std.c.windows.windows;
import WinApi;

immutable INPUT kBackKeyDown;
immutable INPUT kBackKeyUp;
immutable INPUT kShiftKeyDown;
immutable INPUT kShiftKeyUp;
immutable INPUT[4] kCopyKeys;
immutable INPUT[4] kPasteKeys;
immutable INPUT[2] kMarkerKeys;

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

nothrow INPUT makeINPUT(byte vk, bool up = false, bool marker = false)
{
    INPUT input;
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = vk;
    input.ki.time = marker ? -1 : 0;
    input.ki.dwFlags = up ? KEYEVENTF_KEYUP : 0;

    return input;
}