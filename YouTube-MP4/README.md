# YouTube → MP4

Jednostavan Windows program s prozorom za preuzimanje YouTube videa u **MP4** (ili samo zvuka u **MP3**).
Zalijepiš link, klikneš **Preuzmi**, i video završi u mapi Preuzimanja.

Ispod haube koristi [yt-dlp](https://github.com/yt-dlp/yt-dlp) i FFmpeg.

## Mogućnosti

- **MP4 – najbolja kompatibilnost** (H.264, do 1080p): radi na svakom playeru, mobitelu i u programima za montažu
- **MP4 – najviša kvaliteta** (do 4K)
- **MP4 – 720p**: manje datoteke
- **MP3 – samo zvuk**
- preuzimanje cijele playliste
- traka napretka i ispis tijeka preuzimanja
- odabir mape za spremanje

## Instalacija

Potreban je Windows 10/11. Python **nije** potreban.

1. Instaliraj yt-dlp (FFmpeg se instalira automatski uz njega):

   ```powershell
   winget install yt-dlp.yt-dlp
   ```

2. Preuzmi ovaj repozitorij (**Code → Download ZIP**) i raspakiraj ga.

## Pokretanje

Dvaput klikni na **`YouTube-MP4.bat`**.

Ili iz PowerShella:

```powershell
powershell -ExecutionPolicy Bypass -File .\YouTube-MP4.ps1
```

## Ako preuzimanje prestane raditi

YouTube često mijenja stvari, pa yt-dlp treba povremeno ažurirati:

```powershell
winget upgrade yt-dlp.yt-dlp
```

## Datoteke

| Datoteka          | Opis                                   |
|-------------------|----------------------------------------|
| `YouTube-MP4.bat` | pokretač (dvoklik)                     |
| `YouTube-MP4.ps1` | program (PowerShell + Windows Forms)   |

## Napomena

Koristi samo za sadržaj koji smiješ preuzeti (vlastiti videi, Creative Commons, osobna upotreba).
Preuzimanje može biti protivno YouTubeovim uvjetima korištenja.

## Licenca

[MIT](LICENSE)
