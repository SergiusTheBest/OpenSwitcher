private
{    
    import std.c.windows.windows;
    import TrayIcon;
    import Resource;
    import WinApi;

    immutable uint kTrayMessage = WM_USER + 10;
    immutable uint kTrayId = 1;
    immutable uint IDABOUT = 100;

    HMODULE g_appInstance;
    TrayIcon g_trayIcon;

    void runMessageLoop()
    {
        MSG msg;
        while (GetMessageW(&msg, null, 0, 0) > 0)
        {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }

    extern(Windows) nothrow LRESULT myWndProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) 
    {
        switch(msg)
        {
            case WM_COMMAND:
                switch (wparam)
                {
                case IDCLOSE:
                    DestroyWindow(hwnd);
                    break;

                case IDABOUT:
                    MSGBOXPARAMS params;
                    params.cbSize = MSGBOXPARAMS.sizeof;
                    params.hwndOwner = hwnd;
                    params.hInstance = g_appInstance;
                    params.lpszText = "OpenSwitcher, alpha version.";
                    params.lpszCaption = "About OpenSwitcher";
                    params.dwStyle = MB_USERICON;
                    params.lpszIcon = cast(LPCWSTR)IDI_ICON1;

                    MessageBoxIndirectW(&params);
                    break;

                default:
                    break;
                }
                break;

            case WM_TASKBAR_CREATED:
                g_trayIcon.show();
                break;

            case kTrayMessage:
                switch (wparam)
                {
				case kTrayId:
                    switch(lparam)
                    {
                    case WM_RBUTTONUP:
                        auto menu = CreatePopupMenu();

                        scope(exit) 
                        {
                            DestroyMenu(menu);
                        }

                        AppendMenuW(menu, 0, IDABOUT, "&About");
                        AppendMenuW(menu, 0, IDCLOSE, "E&xit");                        

                        POINT pt;
                        GetCursorPos(&pt);

                        SetForegroundWindow(hwnd);
                        TrackPopupMenu(menu, 0, pt.x, pt.y, 0, hwnd, null);
                        PostMessageW(hwnd, WM_NULL, 0, 0);
                        break;

                    default:
                        break;
                    }
                    break;

				default:
                    break;
                }
                break;

            case WM_DESTROY:
                g_trayIcon.hide();
                PostQuitMessage(0);
                break;

            default:
    		    return DefWindowProcW(hwnd, msg, wparam, lparam);
        }

        return 0;
    }
}

public
{
    void run()
    {
        g_appInstance = GetModuleHandleW(null);

        const wchar* kClassName = "HiddenWnd";

        WNDCLASSW wc;
        wc.lpszClassName = kClassName;
        wc.lpfnWndProc = &myWndProc;
        wc.hInstance = g_appInstance;
        
        RegisterClassW(&wc);

        auto appWnd = CreateWindowW(kClassName, "", 0, 0, 0, 0, 0, null, null, g_appInstance, null);
        
        auto icon = cast(HICON)LoadImageW(g_appInstance, cast(LPCWSTR)(IDI_ICON1), IMAGE_ICON, 0, 0, LR_DEFAULTSIZE);
        g_trayIcon = new TrayIcon(appWnd, kTrayId, kTrayMessage, icon);
        g_trayIcon.tip = "OpenSwitcher";
        g_trayIcon.show();

        runMessageLoop();
    }
}