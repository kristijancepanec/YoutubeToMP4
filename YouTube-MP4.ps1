# YouTube -> MP4 downloader (graficko sucelje oko yt-dlp)
# Sve potrebne alate (yt-dlp, FFmpeg, Deno) sam preuzima u .\bin pri prvom pokretanju.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Izlaz procesa i preuzimanje alata rade na pozadinskim nitima; C# to sigurno odraduje
Add-Type -ReferencedAssemblies System.IO.Compression, System.IO.Compression.FileSystem -TypeDefinition @'
using System;
using System.IO;
using System.IO.Compression;
using System.Net;
using System.Threading;
using System.Diagnostics;
using System.Collections.Concurrent;

public static class OutputPump {
    public static void Attach(Process p, ConcurrentQueue<string> q) {
        p.OutputDataReceived += (s, e) => { if (e.Data != null) q.Enqueue(e.Data); };
        p.ErrorDataReceived  += (s, e) => { if (e.Data != null) q.Enqueue(e.Data); };
    }
}

public class ToolSetup {
    public volatile string Status = "";
    public volatile int Percent;
    public volatile bool Done;
    public volatile string Error;
    readonly string bin;

    public ToolSetup(string bin) { this.bin = bin; }

    string P(string name) { return Path.Combine(bin, name); }

    public static bool IsReady(string bin) {
        foreach (var n in new[] { "yt-dlp.exe", "ffmpeg.exe", "ffprobe.exe", "deno.exe" })
            if (!File.Exists(Path.Combine(bin, n))) return false;
        return true;
    }

    public void Start() {
        var t = new Thread(Run);
        t.IsBackground = true;
        t.Start();
    }

    void Run() {
        try {
            Directory.CreateDirectory(bin);
            if (!File.Exists(P("yt-dlp.exe")))
                Download("yt-dlp", "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe", P("yt-dlp.exe"));
            if (!File.Exists(P("ffmpeg.exe")) || !File.Exists(P("ffprobe.exe"))) {
                Download("FFmpeg", "https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip", P("ffmpeg.zip"));
                Extract(P("ffmpeg.zip"), new[] { "ffmpeg.exe", "ffprobe.exe" });
            }
            if (!File.Exists(P("deno.exe"))) {
                Download("Deno", "https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip", P("deno.zip"));
                Extract(P("deno.zip"), new[] { "deno.exe" });
            }
            Status = "Alati su spremni.";
        } catch (Exception e) {
            Error = e.Message;
        }
        Done = true;
    }

    void Download(string name, string url, string dest) {
        var req = (HttpWebRequest)WebRequest.Create(url);
        req.UserAgent = "YouTube-MP4";
        string part = dest + ".part";
        using (var resp = req.GetResponse())
        using (var src = resp.GetResponseStream())
        using (var dst = File.Create(part)) {
            long total = resp.ContentLength, got = 0;
            var buf = new byte[81920];
            int n;
            while ((n = src.Read(buf, 0, buf.Length)) > 0) {
                dst.Write(buf, 0, n);
                got += n;
                Percent = total > 0 ? (int)(got * 100 / total) : 0;
                Status = String.Format("Preuzimam {0}: {1:0.0} / {2:0.0} MB", name, got / 1048576.0, total / 1048576.0);
            }
        }
        if (File.Exists(dest)) File.Delete(dest);
        File.Move(part, dest);
    }

    void Extract(string zip, string[] names) {
        Status = "Raspakiravam " + Path.GetFileName(zip) + "...";
        using (var archive = ZipFile.OpenRead(zip))
            foreach (var entry in archive.Entries)
                if (Array.IndexOf(names, entry.Name) >= 0)
                    entry.ExtractToFile(P(entry.Name), true);
        File.Delete(zip);
    }
}
'@

$bin = Join-Path $PSScriptRoot 'bin'
$ytdlp = Join-Path $bin 'yt-dlp.exe'

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

# Pokrece yt-dlp u pozadini; izlaz ide u red koji timer prazni u log
$script:queue = New-Object System.Collections.Concurrent.ConcurrentQueue[string]
$script:proc = $null
$script:updating = $false

function Start-YtDlp([string[]]$ytArgs) {
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
    [void]$p.Start()
    $p.BeginOutputReadLine(); $p.BeginErrorReadLine()
    $script:proc = $p
    $btnGo.Enabled = $false
    $timer.Start()
}

# Pri svakom pokretanju yt-dlp provjeri ima li novu verziju (YouTube se cesto mijenja)
function Start-Update {
    $log.AppendText("Provjeravam ažuriranja…`r`n")
    $script:updating = $true
    Start-YtDlp @('-U')
}

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
        if ($script:updating) {
            $log.AppendText("Spremno. Zalijepi link i klikni Preuzmi.`r`n")
        } elseif ($script:proc.ExitCode -eq 0) {
            $progress.Value = 100
            $log.AppendText("`r`n✔ Gotovo! Datoteka je u: $($txtDir.Text)`r`n")
        } else {
            $log.AppendText("`r`n✖ Greška (kod $($script:proc.ExitCode)). Provjeri link pa pokušaj ponovno.`r`n")
        }
        $script:proc = $null
        $script:updating = $false
        $btnGo.Enabled = $true
        $timer.Stop()
    }
})

# Prvo pokretanje: preuzmi alate u .\bin
$setupTimer = New-Object System.Windows.Forms.Timer
$setupTimer.Interval = 200
$setupTimer.Add_Tick({
    $progress.Value = [math]::Min(100, $script:setup.Percent)
    if ($script:setup.Status -ne $script:lastStatus -and $script:setup.Status -notmatch '^Preuzimam') {
        $log.AppendText($script:setup.Status + "`r`n")
    }
    $script:lastStatus = $script:setup.Status
    if ($script:setup.Status -match '^Preuzimam') { $form.Text = 'YouTube → MP4 — ' + $script:setup.Status }
    if ($script:setup.Done) {
        $setupTimer.Stop()
        $form.Text = 'YouTube → MP4'
        if ($script:setup.Error) {
            $log.AppendText("`r`n✖ Preuzimanje alata nije uspjelo: $($script:setup.Error)`r`nProvjeri internetsku vezu i ponovno pokreni program.`r`n")
        } else {
            $progress.Value = 0
            Start-Update
        }
    }
})

$form.Add_Shown({
    if ([ToolSetup]::IsReady($bin)) {
        Start-Update
    } else {
        $btnGo.Enabled = $false
        $log.AppendText("Prvo pokretanje: preuzimam potrebne alate (yt-dlp, FFmpeg, Deno) u mapu bin.`r`nTo se radi samo jednom i traje minutu-dvije…`r`n")
        $script:lastStatus = ''
        $script:setup = New-Object ToolSetup $bin
        $script:setup.Start()
        $setupTimer.Start()
    }
})

$btnGo.Add_Click({
    $url = $txtUrl.Text.Trim()
    if (-not $url) { [System.Windows.Forms.MessageBox]::Show('Zalijepi link na video.', 'YouTube → MP4') | Out-Null; return }
    if (-not (Test-Path $txtDir.Text)) { New-Item -ItemType Directory -Path $txtDir.Text -Force | Out-Null }

    $ytArgs = @('--newline', '--no-mtime', '--ffmpeg-location', $bin, '--js-runtimes', "deno:$(Join-Path $bin 'deno.exe')",
                '-P', $txtDir.Text, '-o', '%(title)s.%(ext)s')
    $ytArgs += $formats[$cmbFmt.SelectedItem]
    if (-not $chkPlaylist.Checked) { $ytArgs += '--no-playlist' }
    $ytArgs += $url

    $log.Clear(); $progress.Value = 0
    Start-YtDlp $ytArgs
})

$form.Add_FormClosing({ if ($script:proc -and -not $script:proc.HasExited) { $script:proc.Kill() } })

[void]$form.ShowDialog()
