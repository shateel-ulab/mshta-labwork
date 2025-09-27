Write-Host "PowerShell Launched via mshta.exe → Inline JS → PowerShell" -ForegroundColor Green
try{$p=(Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId;Write-Host "Child started. PID=$PID Parent=$p" -ForegroundColor Green}catch{Write-Host "Error: $_" -ForegroundColor Red}
$u="https://raw.githubusercontent.com/shateel-ulab/mshta-labwork/refs/heads/main/task.json"
Write-Host "Download: $u" -ForegroundColor Cyan
try{$r=(New-Object System.Net.WebClient).DownloadString($u);$n=$r.Length;Write-Host "Download OK. Bytes=$n" -ForegroundColor Green}catch{Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red;exit}
try{$j=$r|ConvertFrom-Json -ErrorAction Stop;Write-Host "Parsed JSON id: $($j.id)" -ForegroundColor Green}catch{Write-Host "JSON parse failed: $($_.Exception.Message)" -ForegroundColor Red;exit}
$a=@('print','list_dir','fetch_info')
foreach($t in $j.tasks){$c=(""+$t.action).ToLower()
if($a-notcontains$c){Write-Host "Skip unallowed: $c" -ForegroundColor Yellow;continue}
switch($c){
'print'{$m=$t.message -as[string];Write-Host "PRINT: $m" -ForegroundColor White}
'list_dir'{$p=$t.path -as[string];$m=[int]($t.max_items -as[int]);if($m-le0){$m=25}
try{$i=Get-ChildItem -Path $p -ErrorAction Stop|Select-Object -First $m;Write-Host "LIST_DIR: $p ($($i.Count) items)" -ForegroundColor White;foreach($x in $i){Write-Host " - $($x.Mode) $($x.Length) $($x.Name)" -ForegroundColor White}}catch{Write-Host "LIST_DIR error: $($_.Exception.Message)" -ForegroundColor Red}} 
'fetch_info'{$u=$t.url -as[string]
if($u-eq"https://raw.githubusercontent.com/your-org/lab-files/main/sample.txt"){$u="https://raw.githubusercontent.com/shateel-ulab/mshta-labwork/refs/heads/main/task.json";Write-Host "FETCH_INFO: Replaced URL with $u" -ForegroundColor Yellow}
try{$w=New-Object System.Net.WebClient;$w.Encoding=[System.Text.Encoding]::UTF8;$d=$w.DownloadString($u);$n=$d.Length;Write-Host "FETCH_INFO: $u len=$n" -ForegroundColor White}catch{Write-Host "FETCH_INFO error: $($_.Exception.Message)" -ForegroundColor Red}}}}
Write-Host "Child finished." -ForegroundColor Green
