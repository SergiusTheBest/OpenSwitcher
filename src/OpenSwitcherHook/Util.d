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