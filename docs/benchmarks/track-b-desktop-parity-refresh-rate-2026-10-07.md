# Track B desktop parity refresh-rate measurement

The desktop parity oracle now records the current refresh rate of the monitor hosting each client window. It obtains the monitor device associated with the HWND through `MonitorFromWindow` and `GetMonitorInfo`, then reads the active mode with the read-only `EnumDisplaySettingsEx` API.

The sanitized output contains only `refreshRateHz`; it does not retain the monitor device name. The comparison report now includes `refreshRateEqual` alongside DPI, window geometry, client-area, viewport, and device-pixel-ratio comparisons.

This is measurement only. It does not change display settings, zoom, client scaling, official Discord, or Track B behavior. A final parity run must still place both clients sequentially on the same physical monitor and record the untouched official result first.
