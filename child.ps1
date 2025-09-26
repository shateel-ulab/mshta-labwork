$LogFile = Join-Path $env:USERPROFILE "Desktop\lab_child.log"
function Log { param($m) $ts=(Get-Date).ToString("o"); Add-Content -Path $LogFile -Value ("{0} {1}" -f $ts,$m) }
Write-Host "PowerShell Launched via mshta.exe -> Inline JS -> PowerShell" -ForegroundColor Green
try {
    $parentPid = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId
    Log "Child started. PID=$PID Parent=$parentPid"
} catch {
    Log "Child start: error getting parent PID: $_"
    Write-Host "Error getting parent PID: $_" -ForegroundColor Red
}
Log "User: $env:USERNAME  PSVersion: $($PSVersionTable.PSVersion)  WorkingDir: $(Get-Location)"
$taskUrl = "https://raw.githubusercontent.com/shateel-ulab/mshta-labwork/refs/heads/main/task.json"
Write-Host "Attempting download: $taskUrl" -ForegroundColor Cyan
Log "Attempting download: $taskUrl"
try {
    $raw = (New-Object System.Net.WebClient).DownloadString($taskUrl)
    $len = $raw.Length
    Write-Host "Download OK. Bytes=$len" -ForegroundColor Green
    Log "Download OK. bytes=$len"
} catch {
    Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
    Log "Download failed: $($_.Exception.Message)"
    exit
}
try {
    $job = $raw | ConvertFrom-Json -ErrorAction Stop
    Write-Host "Parsed JSON id: $($job.id)" -ForegroundColor Green
    Log "Parsed JSON id: $($job.id)"
} catch {
    Write-Host "JSON parse failed: $($_.Exception.Message)" -ForegroundColor Red
    Log "JSON parse failed: $($_.Exception.Message)"
    exit
}
$allowed = @('print','list_dir','fetch_info')
foreach ($t in $job.tasks) {
    $act = ("" + $t.action).ToLower()
    if ($allowed -notcontains $act) { 
        Write-Host "Skipping unallowed action: $act" -ForegroundColor Yellow
        Log "Skipping unallowed: $act"
        continue 
    }
    switch ($act) {
        'print' {
            $msg = $t.message -as [string]
            Write-Host "PRINT: $msg" -ForegroundColor White
            Log "PRINT: $msg"
        }
        'list_dir' {
            $p = $t.path -as [string]; $m=[int]($t.max_items -as [int]); if ($m -le 0){$m=25}
            try {
                $items = Get-ChildItem -Path $p -ErrorAction Stop | Select-Object -First $m
                Write-Host "LIST_DIR: $p ($($items.Count) items)" -ForegroundColor White
                Log "LIST_DIR: $p ($($items.Count) items)"
                foreach ($i in $items) { 
                    Write-Host " - $($i.Mode) $($i.Length) $($i.Name)" -ForegroundColor White
                    Log " - $($i.Mode) $($i.Length) $($i.Name)"
                }
            } catch { 
                Write-Host "LIST_DIR error: $($_.Exception.Message)" -ForegroundColor Red
                Log "LIST_DIR error: $($_.Exception.Message)"
            }
        }
        'fetch_info' {
            $u = $t.url -as [string]
            if ($u -eq "https://raw.githubusercontent.com/your-org/lab-files/main/sample.txt") {
                $u = "https://raw.githubusercontent.com/shateel-ulab/mshta-labwork/refs/heads/main/task.json"
                Write-Host "FETCH_INFO: Replaced invalid URL with $u" -ForegroundColor Yellow
                Log "FETCH_INFO: Replaced invalid URL with $u"
            }
            try {
                $wc = New-Object System.Net.WebClient; $wc.Encoding = [System.Text.Encoding]::UTF8
                $c = $wc.DownloadString($u); $n = $c.Length
                $preview = if ($n -gt 300) { $c.Substring(0,300) + '...[truncated]' } else { $c }
                Write-Host "FETCH_INFO: $u len=$n" -ForegroundColor White
                Log "FETCH_INFO: $u len=$n"
                Log "Preview: $preview"
            } catch { 
                Write-Host "FETCH_INFO error: $($_.Exception.Message)" -ForegroundColor Red
                Log "FETCH_INFO error: $($_.Exception.Message)"
            }
        }
    }
}
Write-Host "Child finished normally." -ForegroundColor Green
Log "Child finished normally."
