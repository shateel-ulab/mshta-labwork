$L=@()
function Log($m){$L+="$(Get-Date -Format o) $m"}
Write-Host "PowerShell Launched via mshta.exe → Inline JS → PowerShell" -ForegroundColor Green
try{$p=(Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId;Log "Child started. PID=$PID Parent=$p"}catch{Log "Child start error: $_";Write-Host "Error: $_" -ForegroundColor Red}
Log "User:$env:USERNAME PS:$($PSVersionTable.PSVersion) Dir:$(Get-Location)"
$u="https://raw.githubusercontent.com/shateel-ulab/mshta-labwork/refs/heads/main/task.json"
Write-Host "Download: $u" -ForegroundColor Cyan
Log "Download: $u"
try{$r=(New-Object System.Net.WebClient).DownloadString($u);$n=$r.Length;Write-Host "Download OK. Bytes=$n" -ForegroundColor Green;Log "Download OK. bytes=$n"}catch{Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red;Log "Download failed: $($_.Exception.Message)";$L|% {Write-Host $_ -ForegroundColor Magenta};exit}
try{$j=$r|ConvertFrom-Json -ErrorAction Stop;Write-Host "Parsed JSON id: $($j.id)" -ForegroundColor Green;Log "Parsed JSON id: $($j.id)"}catch{Write-Host "JSON parse failed: $($_.Exception.Message)" -ForegroundColor Red;Log "JSON parse failed: $($_.Exception.Message)";$L|% {Write-Host $_ -ForegroundColor Magenta};exit}
$a=@('print','list_dir','fetch_info')
foreach($t in $j.tasks){$c=(""+$t.action).ToLower()
if($a-notcontains$c){Write-Host "Skip unallowed: $c" -ForegroundColor Yellow;Log "Skip unallowed: $c";continue}
switch($c){
'print'{$m=$t.message -as[string];Write-Host "PRINT: $m" -ForegroundColor White;Log "PRINT: $m"}
'list_dir'{$p=$t.path -as[string];$m=[int]($t.max_items -as[int]);if($m-le0){$m=25}
try{$i=Get-ChildItem -Path $p -ErrorAction Stop|Select-Object -First $m;Write-Host "LIST_DIR: $p ($($i.Count) items)" -ForegroundColor White;Log "LIST_DIR: $p ($($i.Count) items)";foreach($x in $i){Write-Host " - $($x.Mode) $($x.Length) $($x.Name)" -ForegroundColor White;Log " - $($x.Mode) $($x.Length) $($x.Name)"}}catch{Write-Host "LIST_DIR error: $($_.Exception.Message)" -ForegroundColor Red;Log "LIST_DIR error: $($_.Exception.Message)"}} 
'fetch_info'{$u=$t.url -as[string]
if($u-eq"https://raw.githubusercontent.com/your-org/lab-files/main/sample.txt"){$u="https://raw.githubusercontent.com/shateel-ulab/mshta-labwork/refs/heads/main/task.json";Write-Host "FETCH_INFO: Replaced URL with $u" -ForegroundColor Yellow;Log "FETCH_INFO: Replaced URL with $u"}
try{$w=New-Object System.Net.WebClient;$w.Encoding=[System.Text.Encoding]::UTF8;$d=$w.DownloadString($u);$n=$d.Length;$v=if($n-gt300){$d.Substring(0,300)+'...[truncated]'}else{$d};Write-Host "FETCH_INFO: $u len=$n" -ForegroundColor White;Log "FETCH_INFO: $u len=$n";Log "Preview: $v"}catch{Write-Host "FETCH_INFO error: $($_.Exception.Message)" -ForegroundColor Red;Log "FETCH_INFO error: $($_.Exception.Message)"}}}}
Write-Host "Child finished." -ForegroundColor Green
Log "Child finished."
Write-Host "=== Log ===" -ForegroundColor Magenta
$L|% {Write-Host $_ -ForegroundColor Magenta}
