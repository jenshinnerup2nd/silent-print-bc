codeunit 73003 "VCD Silent Print Subscriber"
{
    // Hooks into BC's printer resolution to override the printer
    // when a matching Silent Print rule exists for the current user/report.
    // This fires on every report run — no dialog bypass, but printer is forced.
    // For fully silent (no dialog) printing, use ScheduleSilentPrint() instead.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterGetPrinterName', '', false, false)]
    local procedure OnAfterGetPrinterName(ReportID: Integer; var PrinterName: Text[250]; PrinterSelection: Record "Printer Selection")
    var
        SilentPrintMgt: Codeunit "VCD Silent Print Mgt.";
        User: Record User;
        OverridePrinter: Text[250];
    begin
        if not User.Get(UserSecurityId()) then
            exit;

        OverridePrinter := SilentPrintMgt.FindPrinterForUser(ReportID, User."User Name", User."User Security ID");
        if OverridePrinter <> '' then
            PrinterName := OverridePrinter;
    end;
}
