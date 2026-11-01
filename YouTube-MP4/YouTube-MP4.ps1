# YouTube -> MP4 downloader (graficko sucelje oko yt-dlp)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Izlaz procesa stize na pozadinskim nitima; C# ga sigurno prebacuje u red
Add-Type -TypeDefinition @'
using System.Diagnostics;
using System.Collections.Concurrent;
public static class OutputPump {
    public static void Attach(Process p, ConcurrentQueue<string> q) {
        p.OutputDataReceived += (s, e) => { if (e.Data != null) q.Enqueue(e.Data); };
        p.ErrorDataReceived  += (s, e) => { if (e.Data != null) q.Enqueue(e.Data); };
    }
}
'@

function Find-YtDlp {
    $cmd = Get-Command yt-dlp -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @(
        "$env:LOCALAPPDATA\Microsoft\WinGet\Links\yt-dlp.exe",
        (Join-Path $PSScriptRoot 'yt-dlp.exe')
    )
    $candidates += Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\yt-dlp.yt-dlp*" -Filter yt-dlp.exe -Recurse -ErrorAction SilentlyContinue | ForEach-Object FullName
    foreach ($c in $candidates) { if ($c -and (Test-Path $c)) { return $c } }
    return $null
}

$ytdlp = Find-YtDlp
if (-not $ytdlp) {
    [System.Windows.Forms.MessageBox]::Show("yt-dlp nije pronađen.`nInstaliraj ga naredbom:`nwinget install yt-dlp.yt-dlp", "YouTube → MP4", 'OK', 'Error') | Out-Null
    exit 1
}

$formats = [ordered]@{
    'MP4 – najbolja kompatibilnost (H.264, do 1080p)' = @('-S', 'vcodec:h264,res,acodec:m4a', '--merge-output-format', 'mp4')
    'MP4 – najviša kvaliteta (do 4K)'                 = @('-S', 'res,ext:mp4:m4a', '--merge-output-format', 'mp4')
    'MP4 – 720p'                                      = @('-S', 'vcodec:h264,res:720,acodec:m4a', '--merge-output-format', 'mp4')
    'MP3 – samo zvuk'                                 = @('-x', '--audio-format', 'mp3', '--audio-quality', '0')
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'YouTube → MP4'
$form.Size = New-Object System.Drawing.Size(640, 480)
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$form.MinimumSize = $form.Size

$lblUrl = New-Object System.Windows.Forms.Label
$lblUrl.Text = 'Link na YouTube video:'
$lblUrl.Location = '12,12'; $lblUrl.AutoSize = $true

$txtUrl = New-Object System.Windows.Forms.TextBox
$txtUrl.Location = '12,36'; $txtUrl.Size = '600,26'; $txtUrl.Anchor = 'Top,Left,Right'

$lblFmt = New-Object System.Windows.Forms.Label
$lblFmt.Text = 'Format:'
$lblFmt.Location = '12,72'; $lblFmt.AutoSize = $true

$cmbFmt = New-Object System.Windows.Forms.ComboBox
$cmbFmt.Location = '12,96'; $cmbFmt.Size = '400,26'; $cmbFmt.DropDownStyle = 'DropDownList'
$formats.Keys | ForEach-Object { [void]$cmbFmt.Items.Add($_) }
$cmbFmt.SelectedIndex = 0

$chkPlaylist = New-Object System.Windows.Forms.CheckBox
$chkPlaylist.Text = 'Cijela playlista'
$chkPlaylist.Location = '430,98'; $chkPlaylist.AutoSize = $true

$lblDir = New-Object System.Windows.Forms.Label
$lblDir.Text = 'Spremi u:'
$lblDir.Location = '12,132'; $lblDir.AutoSize = $true

$txtDir = New-Object System.Windows.Forms.TextBox
$txtDir.Location = '12,156'; $txtDir.Size = '500,26'; $txtDir.Anchor = 'Top,Left,Right'
$txtDir.Text = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = 'Odaberi…'
$btnBrowse.Location = '520,155'; $btnBrowse.Size = '92,28'; $btnBrowse.Anchor = 'Top,Right'

$btnGo = New-Object System.Windows.Forms.Button
$btnGo.Text = 'Preuzmi'
$btnGo.Location = '12,196'; $btnGo.Size = '120,34'
$btnGo.BackColor = [System.Drawing.Color]::FromArgb(220, 38, 38); $btnGo.ForeColor = 'White'; $btnGo.FlatStyle = 'Flat'

$btnOpen = New-Object System.Windows.Forms.Button
$btnOpen.Text = 'Otvori mapu'
$btnOpen.Location = '140,196'; $btnOpen.Size = '120,34'

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = '272,202'; $progress.Size = '340,22'; $progress.Anchor = 'Top,Left,Right'

$log = New-Object System.Windows.Forms.TextBox
$log.Location = '12,242'; $log.Size = '600,186'; $log.Anchor = 'Top,Bottom,Left,Right'
$log.Multiline = $true; $log.ReadOnly = $true; $log.ScrollBars = 'Vertical'
$log.Font = New-Object System.Drawing.Font('Consolas', 9)

$form.Controls.AddRange(@($lblUrl, $txtUrl, $lblFmt, $cmbFmt, $chkPlaylist, $lblDir, $txtDir, $btnBrowse, $btnGo, $btnOpen, $progress, $log))
$form.AcceptButton = $btnGo

$btnBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.SelectedPath = $txtDir.Text
    if ($dlg.ShowDialog() -eq 'OK') { $txtDir.Text = $dlg.SelectedPath }
})

$btnOpen.Add_Click({ if (Test-Path $txtDir.Text) { Start-Process explorer.exe $txtDir.Text } })

# yt-dlp radi u pozadini; izlaz ide u red koji timer prazni u log
$script:queue = New-Object System.Collections.Concurrent.ConcurrentQueue[string]
$script:proc = $null

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 150
$timer.Add_Tick({
    $line = $null
    while ($script:queue.TryDequeue([ref]$line)) {
        if ($line -match '\[download\]\s+([\d\.]+)%') {
            $progress.Value = [math]::Min(100, [int][double]$Matches[1])
        }
        $log.AppendText($line + "`r`n")
    }
    if ($script:proc -and $script:proc.HasExited) {
        if ($script:proc.ExitCode -eq 0) {
            $progress.Value = 100
            $log.AppendText("`r`n✔ Gotovo! Datoteka je u: $($txtDir.Text)`r`n")
        } else {
            $log.AppendText("`r`n✖ Greška (kod $($script:proc.ExitCode)). Provjeri link ili pokušaj ažurirati yt-dlp: winget upgrade yt-dlp.yt-dlp`r`n")
        }
        $script:proc = $null
        $btnGo.Enabled = $true
        $timer.Stop()
    }
})

$btnGo.Add_Click({
    $url = $txtUrl.Text.Trim()
    if (-not $url) { [System.Windows.Forms.MessageBox]::Show('Zalijepi link na video.', 'YouTube → MP4') | Out-Null; return }
    if (-not (Test-Path $txtDir.Text)) { New-Item -ItemType Directory -Path $txtDir.Text -Force | Out-Null }

    $ytArgs = @('--newline', '--no-mtime', '-P', $txtDir.Text, '-o', '%(title)s.%(ext)s')
    $ytArgs += $formats[$cmbFmt.SelectedItem]
    if (-not $chkPlaylist.Checked) { $ytArgs += '--no-playlist' }
    $ytArgs += $url

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ytdlp
    $psi.Arguments = ($ytArgs | ForEach-Object { '"' + ($_ -replace '"', '\"') + '"' }) -join ' '
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $psi.EnvironmentVariables['PYTHONIOENCODING'] = 'utf-8'

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [OutputPump]::Attach($p, $script:queue)

    $log.Clear(); $progress.Value = 0
    $btnGo.Enabled = $false
    [void]$p.Start()
    $p.BeginOutputReadLine(); $p.BeginErrorReadLine()
    $script:proc = $p
    $timer.Start()
})

$form.Add_FormClosing({ if ($script:proc -and -not $script:proc.HasExited) { $script:proc.Kill() } })

[void]$form.ShowDialog()
