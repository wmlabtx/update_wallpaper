# https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nn-shobjidl_core-idesktopwallpaper

$desktopWallpaperCode = @"
using System;
using System.Runtime.InteropServices;
namespace WinAPI
{
    public class DesktopWallpaper
    {
        [ComImport]
        [Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B")]
        [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        public interface IDesktopWallpaper
        {
            void SetWallpaper([MarshalAs(UnmanagedType.LPWStr)] [In] string monitorID, [MarshalAs(UnmanagedType.LPWStr)] [In] string wallpaper);
            void GetMonitorDevicePathCount([MarshalAs(UnmanagedType.U4)] [Out] out uint count);
            void GetMonitorDevicePathAt([MarshalAs(UnmanagedType.U4)] [In] uint monitorIndex, [MarshalAs(UnmanagedType.LPWStr)] [Out] out string monitorID);
        }

        public class WallpaperWrapper       
        {
            private static readonly Guid CLSID_DesktopWallpaper = new Guid("{C2CF3110-460E-4FC1-B9D0-8A1C0C9CC4BD}");
            public static IDesktopWallpaper GetWallpaper()
            {
                Type typeDesktopWallpaper = Type.GetTypeFromCLSID(CLSID_DesktopWallpaper);
                return (IDesktopWallpaper)Activator.CreateInstance(typeDesktopWallpaper);
            }
        }
    }
}
"@

Add-Type -TypeDefinition $desktopWallpaperCode -Language CSharp -ErrorAction Stop


#[WinAPI.WallpaperManager]::GetMonitorDevicePathCount()

#$manager = New-Object DesktopWallpaperWrapper.WallpaperManager
#$manager.GetMonitorIDs()