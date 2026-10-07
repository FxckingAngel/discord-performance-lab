# Track B minimized-state checkpoint

`tools/Invoke-TrackBMinimizedCheckpoint.ps1` measures the existing Track B process tree while its main window is minimized, then restores the window and verifies that the root remains responsive.

It records the same process-tree fields as the normal checkpoint, including total and private working set, derived shareable working set, private bytes, CPU, handles, threads, and per-PID roles. It does not change process priority, trim working sets, disable hardware acceleration, alter Discord state, or automate account actions.

Example:

```powershell
.\tools\Invoke-TrackBMinimizedCheckpoint.ps1 -DurationSeconds 600 -IntervalSeconds 10
```

The minimized result is diagnostic evidence for visibility/compositor effects. It must not be substituted for the foreground settled-idle acceptance benchmark.
