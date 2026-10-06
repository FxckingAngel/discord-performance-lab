# Decision 0008: do not trim the WinForms shell

## Decision

Track B will not enable `PublishTrimmed` for the normal shell.

## Evidence

Microsoft's current .NET trimming guidance lists Windows Forms as unsupported for trimming because the framework relies heavily on built-in COM marshalling. The Track B shell also depends on the WebView2 WinForms bridge, so a trimmed candidate would create a native-functionality and startup risk in exchange for an unmeasured shell-only memory change.

The current shell's native process is a small part of the complete tree. The recent full settled capture measured approximately 12 MiB private bytes for the native shell, while WebView2 browser, GPU, renderer, network, storage, and crashpad processes accounted for the rest. Trimming the shell would not address the dominant allocations and would not be accepted without feature and memory evidence.

## Consequence

The normal publish path remains untrimmed. Further reductions must come from measured WebView2/Discord allocation ownership or a separately validated shell architecture, not from unsupported framework trimming.

Source: [Microsoft .NET trimming incompatibilities](https://learn.microsoft.com/dotnet/core/deploying/trimming/incompatibilities)
