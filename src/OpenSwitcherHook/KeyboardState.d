module KeyboardState;

import core.sys.windows.windows;
import Util;

void clear()
{
    ubyte[256] state = 0;
    SetKeyboardState(state.ptr);
}

void restore()
{
    ubyte[256] state = 0;

    foreach (int vk; [VK_SHIFT, VK_MENU, VK_CONTROL])
    {
        if (isKeyPressedAsync(vk))
        {
            state[vk] = 0x80;
        }
    }

    SetKeyboardState(state.ptr);
}