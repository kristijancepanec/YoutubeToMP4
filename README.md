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

Ništa se ne instalira. Potreban je samo Windows 10/11.

1. Preuzmi ovaj repozitorij (**Code → Download ZIP**) i raspakiraj ga.
2. Dvaput klikni na **`YouTube-MP4.bat`**.

Pri **prvom pokretanju** program sam preuzme potrebne alate sa službenih GitHub stranica
u podmapu `bin\` (oko 120 MB za preuzeti, traje minutu-dvije):

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) – preuzima videe
- [FFmpeg](https://github.com/yt-dlp/FFmpeg-Builds) – spaja sliku i zvuk u MP4, radi MP3
- [Deno](https://github.com/denoland/deno) – rješava YouTubeove JavaScript zaštite

Poslije toga sve radi odmah, a yt-dlp se **sam ažurira** pri svakom pokretanju.

> **Windows upozorenje pri prvom pokretanju?** Windows za datoteke skinute s interneta može pitati
> želiš li ih pokrenuti. Klikni **Pokreni** (ili **Više informacija → Svejedno pokreni**).
> Da se to uopće ne pojavi: prije raspakiravanja desni klik na ZIP → **Svojstva** → kvačica **Deblokiraj** → **U redu**.

Mapu nemoj stavljati u `C:\Program Files`, jer program u nju mora moći spremiti alate. Desktop ili Dokumenti su u redu.

Za pokretanje iz PowerShella:

```powershell
powershell -ExecutionPolicy Bypass -File .\YouTube-MP4.ps1
```

## Ako nešto ne radi

Obriši mapu `bin\` i ponovno pokreni program, pa će sve alate preuzeti iznova.

## Datoteke

| Datoteka          | Opis                                              |
|-------------------|---------------------------------------------------|
| `YouTube-MP4.bat` | pokretač (dvoklik)                                |
| `YouTube-MP4.ps1` | program (PowerShell + Windows Forms)              |
| `bin\`            | alati, nastaju pri prvom pokretanju (nisu u gitu) |

## Napomena

Koristi samo za sadržaj koji smiješ preuzeti (vlastiti videi, Creative Commons, osobna upotreba).
Preuzimanje može biti protivno YouTubeovim uvjetima korištenja.

## Licenca

[MIT](LICENSE)
