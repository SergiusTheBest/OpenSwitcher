import std.c.windows.windows;

extern(Windows) nothrow
{
    HHOOK SetWindowsHookExW(int idHook, HOOKPROC lpfn, HINSTANCE hMod, DWORD dwThreadId);

    BOOL UnhookWindowsHookEx(HHOOK hhk);

    LRESULT CallNextHookEx(HANDLE hhk, int nCode, WPARAM wParam, LPARAM lParam);

    void keybd_event(byte bVk, byte bScan, DWORD dwFlags, ULONG_PTR dwExtraInfo);

    UINT MapVirtualKeyW(UINT uCode, UINT uMapType);

    UINT MapVirtualKeyExW(UINT uCode, UINT uMapType, HKL dwhkl);

    int GetKeyboardLayoutList(int nBuff, HKL *lpList);

    HKL GetKeyboardLayout(DWORD idThread);

    BOOL GetKeyboardLayoutNameW(LPWSTR pwszKLID);

    int ToUnicode(UINT wVirtKey, UINT wScanCode, const BYTE *lpKeyState, LPWSTR pwszBuff, int cchBuff, UINT wFlags);

    int ToUnicodeEx(UINT wVirtKey, UINT wScanCode, const BYTE *lpKeyState, LPWSTR pwszBuff, int cchBuff, UINT wFlags, HKL dwhkl);

    SHORT VkKeyScanW(WCHAR ch);

    void OutputDebugStringW(LPCWSTR lpOutputString);

    UINT SendInput(UINT nInputs, const LPINPUT pInputs, int cbSize);

    HKL ActivateKeyboardLayout(HKL hkl, UINT Flags);

    BOOL IsClipboardFormatAvailable(UINT format);

    BOOL OpenClipboard(HWND hWndNewOwner);

    BOOL CloseClipboard();

    HANDLE GetClipboardData(UINT uFormat);

    BOOL EmptyClipboard();

    HANDLE SetClipboardData(UINT uFormat, HANDLE hMem);

    LPVOID GlobalLock(HGLOBAL hMem);

    HGLOBAL GlobalAlloc(UINT uFlags, SIZE_T dwBytes);

    BOOL PostMessageW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);

    BOOL Shell_NotifyIconW(DWORD dwMessage, NOTIFYICONDATAW* lpdata);

	UINT RegisterWindowMessageW(LPCWSTR lpString);

    HMENU CreatePopupMenu();

    BOOL DestroyMenu(HMENU hMenu);

    BOOL AppendMenuW(HMENU hMenu, UINT uFlags, UINT_PTR uIDNewItem, LPCWSTR lpNewItem);

    HANDLE LoadImageW(HINSTANCE hinst, LPCWSTR lpszName, UINT uType, int cxDesired, int cyDesired, UINT fuLoad);

    int MessageBoxIndirectW(const LPMSGBOXPARAMS lpMsgBoxParams);
}

struct MSGBOXPARAMS
{
    UINT           cbSize;
    HWND           hwndOwner;
    HINSTANCE      hInstance;
    LPCWSTR        lpszText;
    LPCWSTR        lpszCaption;
    DWORD          dwStyle;
    LPCWSTR        lpszIcon;
    DWORD_PTR      dwContextHelpId;
    void*          lpfnMsgBoxCallback;
    DWORD          dwLanguageId;
}

alias MSGBOXPARAMS* LPMSGBOXPARAMS;

alias HANDLE HHOOK;

enum
{
    IMAGE_ICON = 1
}

enum
{
    LR_DEFAULTSIZE = 0x00000040
}

struct GUID
{
    uint     Data1;
    ushort   Data2;
    ushort   Data3;
    ubyte[8] Data4;
}

enum
{
    KL_NAMELENGTH = 9
}

enum
{
    GMEM_MOVEABLE = 2
}

enum
{
    CF_TEXT = 1,
    CF_UNICODETEXT = 13
}

immutable HKL HKL_NEXT = cast(HKL)1;

enum
{
    KLF_SETFORPROCESS = 0x00000100
}

enum
{
    WH_GETMESSAGE = 3,
    WH_CALLWNDPROC = 4
}

enum
{
    HC_ACTION = 0
}

enum
{
    KEYEVENTF_KEYUP = 2
}

struct CWPSTRUCT
{
    LPARAM lParam;
    WPARAM wParam;
    UINT   message;
    HWND   hwnd;
}

alias CWPSTRUCT* LPCWPSTRUCT;

struct INPUT 
{
    DWORD type;
    union 
    {
        MOUSEINPUT      mi;
        KEYBDINPUT      ki;
        HARDWAREINPUT   hi;
    }
}

alias INPUT* LPINPUT;

enum
{
    INPUT_KEYBOARD = 1
}

struct MOUSEINPUT 
{
    LONG    dx;
    LONG    dy;
    DWORD   mouseData;
    DWORD   dwFlags;
    DWORD   time;
    ULONG_PTR dwExtraInfo;
}

struct KEYBDINPUT 
{
    WORD      wVk;
    WORD      wScan;
    DWORD     dwFlags;
    DWORD     time;
    ULONG_PTR dwExtraInfo;
}

struct HARDWAREINPUT 
{
    DWORD   uMsg;
    WORD    wParamL;
    WORD    wParamH;
}

struct NOTIFYICONDATAW
{
    DWORD cbSize;
    HWND  hWnd;
    UINT  uID;
    UINT  uFlags;
    UINT  uCallbackMessage;
    HICON hIcon;
    WCHAR szTip[64];
    DWORD dwState;
    DWORD dwStateMask;
    WCHAR szInfo[256];
    union 
    {
        UINT uTimeout;
        UINT uVersion;
    }
    WCHAR szInfoTitle[64];
    DWORD dwInfoFlags;
    GUID  guidItem;
    HICON hBalloonIcon;
}

enum
{
    NIF_MESSAGE = 0x00000001,
    NIF_ICON = 0x00000002,
    NIF_TIP = 0x00000004
}

enum
{
    NIM_ADD = 0,
    NIM_MODIFY = 1,
    NIM_DELETE  = 2
}

enum
{
    WM_USER = 0x400
}