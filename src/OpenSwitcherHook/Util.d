module Util;

import std.c.windows.windows;
import WinApi;

nothrow bool isMarkerKey(LPMSG msg)
{
    return -1 == msg.time;
}

nothrow bool isKeyPressed(int vk)
{
    return cast(bool)(GetKeyState(vk) & 0x8000);
}

nothrow bool isKeyPressedAsync(int vk)
{
    return cast(bool)(GetAsyncKeyState(vk) & 0x8000);
}

nothrow HKL[] getKeyboardLayouts()
{
    HKL[100] layouts;
    auto returned = GetKeyboardLayoutList(layouts.length, layouts.ptr);
    
    return layouts[0..returned];
}