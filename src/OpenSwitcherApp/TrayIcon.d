module TrayIcon;

import core.sys.windows.windows;
import std.algorithm : min;

class TrayIcon
{
    nothrow this(HWND hwnd, UINT id, UINT callbackMessage, HICON icon)
    {
        m_nid.cbSize = NOTIFYICONDATAW.sizeof;
        m_nid.hWnd = hwnd;
        m_nid.uID = id;
        m_nid.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
        m_nid.uCallbackMessage = callbackMessage;
        m_nid.hIcon = icon;
        m_nid.szTip[0] = 0;

        m_visible = false;
    }

    ~this()
    {
        hide();
    }

    nothrow void show()
    {
        hide();
        Shell_NotifyIconW(NIM_ADD, &m_nid);
        m_visible = true;
    }

    nothrow void hide()
    {
        if (m_visible)
        {
            Shell_NotifyIconW(NIM_DELETE, &m_nid);
            m_visible = false;
        }
    }

    @property void tip(const wchar[] newTip)
    {
        auto tipLen = min(newTip.length, m_nid.szTip.length - 1);
        m_nid.szTip[0 .. tipLen] = newTip[0 .. tipLen];
        m_nid.szTip[tipLen] = 0;

        modify();
    }

    void icon(HICON newIcon)
    {
        m_nid.hIcon = newIcon;
        modify();
    }

private:
    void modify()
    {
        if (m_visible)
        {
            Shell_NotifyIconW(NIM_MODIFY, &m_nid);
        }
    }

private:
    NOTIFYICONDATAW m_nid;
    bool m_visible;
}

shared static this()
{
    WM_TASKBAR_CREATED = RegisterWindowMessageW("TaskbarCreated");
}

immutable uint WM_TASKBAR_CREATED;
