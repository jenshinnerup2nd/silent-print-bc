# App Request: [APP NAVN]

Her er den udfyldte specifikation:

```markdown
## Beskrivelse
En opsætningsside til "Silent Print" der giver mulighed for at definere regler per bruger eller sikkerhedsgruppe, 
som automatisk omdirigerer printjobs til en jobkø med en foruddefineret printer — uden brugerinteraktion.

## Formål / Forretningsbehov
Mange brugere printer rapporter manuelt og vælger printer selv, hvilket giver inkonsistente udskrifter og 
spildtid. Denne løsning sikrer at bestemte rapporter altid udskrives på den korrekte printer, 
automatisk via jobkø, når en bruger eller sikkerhedsgruppe initierer et printjob.
Målgruppe: Systemadministratorer (opsætning) og slutbrugere (transparent — de mærker det ikke).

## BC Område
- Rapportering / Print
- Jobkø (Job Queue)
- Brugerstyring / Sikkerhedsgrupper

## Ønsket Funktionalitet
- Opsætningsside hvor man kan oprette Silent Print-regler per bruger eller sikkerhedsgruppe
- Hvert linje indeholder: Rapport ID + Rapport Navn (lookup mod Report Metadata), Bruger eller Sikkerhedsgruppe (lookup), Printer (lookup mod Printer Selection / tilgængelige printere), Printer Navn (auto-udfyldt via lookup)
- Når en bruger starter et printjob, tjekkes om der findes en matchende regel — først på bruger, dernæst på sikkerhedsgruppe
- Ved match: overstyres den normale printdialog, og jobbet sendes automatisk via den indbyggede "Plan"-funktion (ScheduleReport / REPORT.RunRequestPage med Print action)
- Jobbet lander i Rapportindbakken (Report Inbox) og/eller Jobkø (Job Queue Entry)
- Printer sættes til den definerede printer fra reglen
- Feltet "Udskriv" (Print) på jobkøposten indsættes direkte (uden validering, da feltet ikke kan valideres)

## BC Objekter vi arbejder med
- Report Metadata (System tabel) — til lookup på rapport ID/navn
- Printer Selection (tabel 78) — til lookup på printere
- User (tabel 2000000120) — til bruger-lookup
- Permission Set / Security Group — til sikkerhedsgruppe-lookup
- Job Queue Entry (tabel 472) — destination for det planlagte printjob
- Report Inbox (tabel 77) — rapport indbakke
- REPORT.ScheduleReport / RunModal med PrintOnlyIfDetail — standard plan-funktion

## Nye objekter der skal oprettes
- **Tabel**: "Silent Print Setup" — gemmer reglerne (Rapport ID, Rapport Navn, Bruger/Sikkerhedsgruppe type, Bruger/Gruppe kode, Printer ID, Printer Navn)
- **Page**: "Silent Print Setup" (List page) — til administration af regler, med lookups
- **Codeunit**: "Silent Print Manager" — indeholder logik til at:
  - Slå regel op baseret på aktuel bruger/sikkerhedsgruppe
  - Kalde plan-funktionen (ScheduleReport) programmatisk
  - Indsætte Job Queue Entry med korrekt printer (RecordInsert uden validering af Print-felt)
- **Event Subscriber**: Hook på OnBeforePrintReport eller tilsvarende trigger for at fange printjobs og omdirigere dem

## Skærmbilleder / Mock-ups
**Silent Print Setup — listside:**

| Rapport ID | Rapport Navn         | Type            | Bruger/Gruppe     | Printer ID | Printer Navn       |
|------------|----------------------|-----------------|-------------------|------------|--------------------|
| 206        | Sales Invoice        | Bruger          | JENS              | PR-01      | Lager Printer      |
| 405        | Order Confirmation   | Sikkerhedsgruppe | SALG-GRP         | PR-02      | Salg Printer       |

- Rapport ID og Rapport Navn: lookup mod Report Metadata, navn auto-udfyldes
- Type: Option felt (Bruger / Sikkerhedsgruppe)
- Bruger/Gruppe: lookup afhænger af valgt type
- Printer ID og Printer Navn: lookup mod Printer Selection, navn auto-udfyldes
```

De vigtigste tekniske pointer jeg har fremhævet:
- **Event subscriber** er nøglen — du skal fange print-eventet *før* dialogen vises
- **RecordInsert uden validering** på `Print`-feltet i Job Queue Entry, da feltet ikke tillader `Validate`
- Opslag sker i prioriteret rækkefølge: bruger → sikkerhedsgruppe

## Prioritet
- [ ] Høj
- [ ] Mellem
- [ ] Lav

## Yderligere noter
<!-- Andet jeg bør vide -->
