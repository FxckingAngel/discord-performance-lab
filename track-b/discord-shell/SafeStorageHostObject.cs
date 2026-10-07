using System;
using System.Runtime.InteropServices;

namespace KoroneDiscordShell;

[ComVisible(true)]
[ClassInterface(ClassInterfaceType.AutoDual)]
public sealed class SafeStorageHostObject
{
    private const uint CryptProtectUiForbidden = 0x1;

    public bool IsEncryptionAvailable() => OperatingSystem.IsWindows();

    public string EncryptString(string plainText)
    {
        ArgumentNullException.ThrowIfNull(plainText);
        return Convert.ToBase64String(CryptProtect(System.Text.Encoding.UTF8.GetBytes(plainText)));
    }

    public string DecryptString(string encrypted)
    {
        ArgumentNullException.ThrowIfNull(encrypted);
        var plainBytes = CryptUnprotect(Convert.FromBase64String(encrypted));
        return System.Text.Encoding.UTF8.GetString(plainBytes);
    }

    private static byte[] CryptProtect(byte[] input)
    {
        return InvokeCrypt(CryptProtectData, input);
    }

    private static byte[] CryptUnprotect(byte[] input)
    {
        return InvokeCrypt(CryptUnprotectData, input);
    }

    private delegate bool CryptOperation(ref DataBlob input, IntPtr description, IntPtr entropy, IntPtr reserved, IntPtr prompt, uint flags, out DataBlob output);

    private static byte[] InvokeCrypt(CryptOperation operation, byte[] input)
    {
        var inputHandle = Marshal.AllocHGlobal(input.Length);
        try
        {
            Marshal.Copy(input, 0, inputHandle, input.Length);
            var inputBlob = new DataBlob { cbData = input.Length, pbData = inputHandle };
            if (!operation(ref inputBlob, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, CryptProtectUiForbidden, out var outputBlob))
            {
                throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
            }

            try
            {
                var output = new byte[outputBlob.cbData];
                Marshal.Copy(outputBlob.pbData, output, 0, output.Length);
                return output;
            }
            finally
            {
                LocalFree(outputBlob.pbData);
            }
        }
        finally
        {
            Marshal.FreeHGlobal(inputHandle);
        }
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct DataBlob
    {
        public int cbData;
        public IntPtr pbData;
    }

    [DllImport("crypt32.dll", SetLastError = true)]
    private static extern bool CryptProtectData(ref DataBlob dataIn, IntPtr description, IntPtr optionalEntropy, IntPtr reserved, IntPtr prompt, uint flags, out DataBlob dataOut);

    [DllImport("crypt32.dll", SetLastError = true)]
    private static extern bool CryptUnprotectData(ref DataBlob dataIn, IntPtr description, IntPtr optionalEntropy, IntPtr reserved, IntPtr prompt, uint flags, out DataBlob dataOut);

    [DllImport("kernel32.dll")]
    private static extern IntPtr LocalFree(IntPtr handle);
}
