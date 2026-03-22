codeunit 73002 "VCD Silent Print Mgt."
{
    /// <summary>
    /// Returns the printer name to use for a given report and user.
    /// Priority: 1) Printer Selection (table 78), 2) our Silent Print Rule.
    /// Returns '' if no rule matches (no override).
    /// </summary>
    procedure FindPrinterForUser(ReportID: Integer; UserName: Code[50]; UserSecurityID: Guid): Text[250]
    var
        SilentPrintRule: Record "VCD Silent Print Rule";
        PrinterName: Text[250];
    begin
        // Priority 1: user-specific rule
        SilentPrintRule.SetRange("Report ID", ReportID);
        SilentPrintRule.SetRange("Subject Type", "VCD Silent Print Subject Type"::User);
        SilentPrintRule.SetRange("Subject Code", UserName);
        SilentPrintRule.SetRange(Enabled, true);
        if SilentPrintRule.FindFirst() then
            exit(ResolveEffectivePrinter(SilentPrintRule."Printer Name", ReportID, UserName));

        // Priority 2: security group rule
        PrinterName := FindPrinterBySecurityGroup(ReportID, UserSecurityID, UserName);
        exit(PrinterName);
    end;

    local procedure FindPrinterBySecurityGroup(ReportID: Integer; UserSecurityID: Guid; UserName: Code[50]): Text[250]
    var
        SilentPrintRule: Record "VCD Silent Print Rule";
        SecurityGroupMemberBuffer: Record "Security Group Member Buffer" temporary;
        SecurityGroupCU: Codeunit "Security Group";
    begin
        // GetMembers calls Microsoft Graph — result is cached by the platform per session
        SecurityGroupCU.GetMembers(SecurityGroupMemberBuffer);
        SecurityGroupMemberBuffer.SetRange("User Security ID", UserSecurityID);
        if not SecurityGroupMemberBuffer.FindSet() then
            exit('');

        repeat
            SilentPrintRule.SetRange("Report ID", ReportID);
            SilentPrintRule.SetRange("Subject Type", "VCD Silent Print Subject Type"::"Security Group");
            SilentPrintRule.SetRange("Subject Code", SecurityGroupMemberBuffer."Security Group Code");
            SilentPrintRule.SetRange(Enabled, true);
            if SilentPrintRule.FindFirst() then
                exit(ResolveEffectivePrinter(SilentPrintRule."Printer Name", ReportID, UserName));
        until SecurityGroupMemberBuffer.Next() = 0;

        exit('');
    end;

    /// <summary>
    /// Resolves effective printer: Printer Selection (table 78) first, then the rule's printer.
    /// </summary>
    local procedure ResolveEffectivePrinter(RulePrinterName: Text[250]; ReportID: Integer; UserName: Code[50]): Text[250]
    var
        PrinterSelection: Record "Printer Selection";
    begin
        // Check Printer Selection for user + report combination
        PrinterSelection.SetRange("User ID", UserName);
        PrinterSelection.SetRange("Report ID", ReportID);
        if PrinterSelection.FindFirst() then
            exit(PrinterSelection."Printer Name");

        // Fall back to printer defined in our rule
        exit(RulePrinterName);
    end;

    /// <summary>
    /// Schedules the report to run silently via Job Queue using saved request XML.
    /// No print dialog is shown when the job runs.
    /// </summary>
    procedure ScheduleSilentPrint(SilentPrintRule: Record "VCD Silent Print Rule")
    var
        JobQueueEntry: Record "Job Queue Entry";
        RequestXML: Text;
    begin
        RequestXML := SilentPrintRule.GetSavedRequestXML();
        if RequestXML = '' then
            Error('No saved request parameters found.\Use the "Save Request Parameters" action first.');

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := SilentPrintRule."Report ID";
        JobQueueEntry."Report Request Page Options" := false;
        JobQueueEntry."Printer Name" := CopyStr(SilentPrintRule."Printer Name", 1, MaxStrLen(JobQueueEntry."Printer Name"));
        JobQueueEntry."Report Output Type" := JobQueueEntry."Report Output Type"::Print;
        JobQueueEntry.SetReportParameters(RequestXML);
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime();
        JobQueueEntry.Description :=
            CopyStr(StrSubstNo('Silent Print: %1', SilentPrintRule."Report Name"), 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry.Insert(true);
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);

        Message('Report "%1" has been scheduled for silent printing.', SilentPrintRule."Report Name");
    end;

    /// <summary>
    /// Opens the report request page so the user can configure and save parameters.
    /// The saved XML is used for future silent prints — no dialog shown during actual silent print.
    /// </summary>
    procedure CaptureRequestXML(var SilentPrintRule: Record "VCD Silent Print Rule")
    var
        RequestXML: Text;
    begin
        if SilentPrintRule."Report ID" = 0 then
            Error('Select a Report ID before saving parameters.');

        RequestXML := Report.RunRequestPage(SilentPrintRule."Report ID");
        if RequestXML = '' then
            exit; // user cancelled the dialog

        SilentPrintRule.SetSavedRequestXML(RequestXML);
        SilentPrintRule.Modify();

        Message('Parameters saved. Silent prints for "%1" will use these settings.', SilentPrintRule."Report Name");
    end;
}
