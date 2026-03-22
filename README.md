# [APP NAVN]

Publisher: Vibrant Color Development
BC Version: 26.0.0.0
Prefix: VCD

## Kom i gang

1. Udfyld `APP_REQUEST.md` med beskrivelse af hvad appen skal gøre
2. Giv Claude adgang til repoet
3. Claude læser request, stiller afklarende spørgsmål og udfylder `PROJECT.md`
4. Koding begynder

## Struktur

```
src/           AL kode
.github/       AL-Go CI/CD workflows
app.json       App manifest
APP_REQUEST.md Beskriv hvad du ønsker
PROJECT.md     Teknisk spec (udfyldes af Claude)
```

## Publish til BC

```powershell
# Via VS Code: F5
# Via PowerShell:
Publish-NAVApp -ServerInstance BC -Path *.app -SkipVerification
```
