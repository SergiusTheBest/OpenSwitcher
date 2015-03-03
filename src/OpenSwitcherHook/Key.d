module Key;

import std.c.windows.windows;
import WinApi;
import Input;
import Util;

struct Key
{
public:
    nothrow this(wchar wch)
    {
        auto res = VkKeyScanW(wch);

        m_vk = cast(byte)res;
        m_shift = cast(bool)(res & 0x100);
    }

    nothrow this(wchar wch, const HKL[] layouts)
    {
        short res;

        foreach (const HKL layout; layouts)
        {
            res = VkKeyScanExW(wch, layout);

            if (-1 != res)
            {
                break;
            }
        }

        if (-1 == res)
        {
            res = 0;
        }

        m_vk = cast(byte)res;
        m_shift = cast(bool)(res & 0x100);
    }

    nothrow this(LPMSG msg)
    {
        m_vk = cast(byte)msg.wParam;
        m_shift = isKeyPressed(VK_SHIFT);
    }

    nothrow wchar toUnicode()
    {
        wchar wch;
        ToUnicode(m_vk, 0, m_shift ? m_kShiftState.ptr : m_kNormalState.ptr, &wch, 1, 0);

        return wch;
    }

    INPUT[] toInput()
    {
        INPUT[] input;
        input.reserve(4);

        if (m_shift)
        {
            input ~= kShiftKeyDown;
        }

        input ~= makeINPUT(m_vk);
        input ~= makeINPUT(m_vk, true);

        if (m_shift)
        {
            input ~= kShiftKeyUp;
        }

        return input;
    }

private:
    immutable static ubyte[256] m_kNormalState;
    immutable static ubyte[256] m_kShiftState = [ VK_SHIFT: 0x80 ];
    byte m_vk;
    bool m_shift;
}
