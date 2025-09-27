try {
    $parentPid = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId
} catch {
    exit
}
Write-Host "PowerShell Launched via mshta.exe → Inline JS → PowerShell" -ForegroundColor Green
$taskUrl = "https://raw.githubusercontent.com/shateel-ulab/mshta-labwork/refs/heads/main/task.json"
Write-Host "Attempting download: $taskUrl" -ForegroundColor Cyan
try {
    $raw = (New-Object System.Net.WebClient).DownloadString($taskUrl)
    $len = $raw.Length
    Write-Host "Download OK. Bytes=$len" -ForegroundColor Green
} catch {
    Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
    exit
}
try {
    $job = $raw | ConvertFrom-Json -ErrorAction Stop
    Write-Host "Parsed JSON id: $($job.id)" -ForegroundColor Green
} catch {
    Write-Host "JSON parse failed: $($_.Exception.Message)" -ForegroundColor Red
    exit
}
$allowed = @('print','list_dir','fetch_info')
foreach ($t in $job.tasks) {
    $act = ("" + $t.action).ToLower()
    if ($allowed -notcontains $act) { 
        continue 
    }
    switch ($act) {
        'print' {
            $msg = $t.message -as [string]
            Write-Output "PRINT: $msg"
        }
        'list_dir' {
            $p = $t.path -as [string]; $m=[int]($t.max_items -as [int]); if ($m -le 0){$m=25}
            try {
                $items = Get-ChildItem -Path $p -ErrorAction Stop | Select-Object -First $m
                Write-Output "LIST_DIR: $p ($($items.Count) items)"
                foreach ($i in $items) { 
                    Write-Output " - $($i.Mode) $($i.Length) $($i.Name)"
                }
            } catch { 
                Write-Output "LIST_DIR error: $($_.Exception.Message)"
            }
        }
        'fetch_info' {
            $u = $t.url -as [string]
            if ($u -eq "https://raw.githubusercontent.com/your-org/lab-files/main/sample.txt") {
                $u = "https://raw.githubusercontent.com/shateel-ulab/mshta-labwork/refs/heads/main/task.json"
            }
            try {
                $wc = New-Object System.Net.WebClient; $wc.Encoding = [System.Text.Encoding]::UTF8
                $c = $wc.DownloadString($u); $n = $c.Length
                Write-Output "FETCH_INFO: $u len=$n"
            } catch { 
                Write-Output "FETCH_INFO error: $($_.Exception.Message)"
            }
        }
    }
}
