# Project: Silent Print BC

## Status
- [x] APP_REQUEST modtaget
- [x] Afklaring gennemført
- [x] Teknisk spec godkendt
- [x] Koding startet
- [ ] Klar til test
- [ ] Leveret

## Teknisk Spec

### Nye objekter

| Type     | ID    | Navn                          | Formål                                      |
|----------|-------|-------------------------------|---------------------------------------------|
| Enum     | 73000 | VCD Silent Print Subject Type | User / Security Group valg                  |
| Table    | 73000 | VCD Silent Print Rule         | Gemmer reglerne                             |
| Page     | 73001 | VCD Silent Print Rules        | Admin-listeside til at administrere regler  |
| Codeunit | 73002 | VCD Silent Print Mgt.         | Forretningslogik: opslag, schedule, capture |
| Codeunit | 73003 | VCD Silent Print Subscriber   | Event hook på OnAfterGetPrinterName         |

### ID Range: 73000–73049 (blok 01)

### BC Objekter vi arbejder med

| Objekt                       | ID         | Brug                                       |
|------------------------------|------------|--------------------------------------------|
| AllObjWithCaption            | (virtual)  | Lookup rapport navn fra rapport ID         |
| User                         | 2000000120 | Bruger lookup + UserSecurityId             |
| Security Group               | 9020       | Sikkerhedsgruppe lookup                    |
| Codeunit "Security Group"    | 9031       | GetMembers() — tjek gruppemedlemskab       |
| Security Group Member Buffer | 9021       | Temp buffer fra GetMembers()               |
| Printer Selection            | 78         | Tjekkes først ved printer opslag           |
| Printer (virtual)            | 2000000039 | Lookup på tilgængelige printere            |
| Job Queue Entry              | 472        | Silent print via jobkø                     |
| ReportManagement             | 44         | Event: OnAfterGetPrinterName               |
| Job Queue - Enqueue          | 452        | Enqueue job queue entry                    |

### Datamodel

**VCD Silent Print Rule (73000)**
- Entry No. (AutoIncrement PK)
- Report ID → AllObjWithCaption lookup
- Report Name (auto-udfyldt)
- Subject Type (Enum: User / Security Group)
- Subject Code → betinget TableRelation: User.UserName eller Security Group.Code
- Subject Name (auto-udfyldt)
- Printer Name → Printer.ID lookup (virtual table 2000000039)
- Enabled (Boolean)
- Saved Request XML (Blob — gemt request page XML til silent scheduling)

### Print-flow

**Printer override (automatisk — printer forudvalgt, dialog vises stadig):**
```
Bruger starter rapport
  → BC kalder ReportManagement.GetPrinterName
  → OnAfterGetPrinterName fires
  → VCDSilentPrintSubscriber tjekker regler (bruger → sikkerhedsgruppe)
  → Printer resolved: 1) Printer Selection (78) 2) vores regel
  → PrinterName overrides → bruger ser dialog men printer er forudvalgt
```

**Fuldt silent (ingen dialog — via jobkø):**
```
Admin: klikker "Gem Request Parameters" (kører request page én gang, gemmer XML)
  → Efterfølgende: "Schedule Silent Print" opretter Job Queue Entry
  → Report Request Page Options = false → ingen dialog når job køres
  → Printer sættes direkte på job queue posten
```

### Åbne spørgsmål
- Ingen pt.

## Læringsnoter
- OnBeforeGetPrinterName eksisterer IKKE — brug OnAfterGetPrinterName (Codeunit 44)
- Security Group (AAD/Entra): Codeunit 9031 GetMembers() kalder Microsoft Graph (cached per session)
- Universal Print printere: virtual table 2000000039 Printer.ID
- Job Queue silent run: SetReportParameters(xml) + "Report Request Page Options" = false
- Printer Selection (78) er user+report→printer mapping, ikke en liste over printere
