page 73001 "VCD Silent Print Rules"
{
    ApplicationArea = All;
    Caption = 'Silent Print Rules';
    PageType = List;
    SourceTable = "VCD Silent Print Rule";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Rules)
            {
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'The report ID to intercept and redirect silently.';
                }
                field("Report Name"; Rec."Report Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Name of the report (auto-filled).';
                }
                field("Subject Type"; Rec."Subject Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Whether the rule applies to a specific user or a security group.';
                }
                field("Subject Code"; Rec."Subject Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'The user name or security group code the rule applies to.';
                }
                field("Subject Name"; Rec."Subject Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Full name of the user or security group (auto-filled).';
                }
                field("Printer Name"; Rec."Printer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Printer to use. If blank, falls back to Printer Selection setup.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable or disable this rule without deleting it.';
                }
                field(HasSavedXML; Rec.GetSavedRequestXML() <> '')
                {
                    ApplicationArea = All;
                    Caption = 'Parameters Saved';
                    Editable = false;
                    ToolTip = 'Indicates whether request page parameters have been saved for silent scheduling.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SaveRequestParams)
            {
                ApplicationArea = All;
                Caption = 'Save Request Parameters';
                ToolTip = 'Opens the report request page once so you can configure and save parameters for future silent prints.';
                Image = Setup;

                trigger OnAction()
                var
                    SilentPrintMgt: Codeunit "VCD Silent Print Mgt.";
                begin
                    SilentPrintMgt.CaptureRequestXML(Rec);
                end;
            }
            action(ScheduleNow)
            {
                ApplicationArea = All;
                Caption = 'Schedule Silent Print Now';
                ToolTip = 'Immediately schedules this report to print silently via the job queue using saved parameters.';
                Image = PrintReport;

                trigger OnAction()
                var
                    SilentPrintMgt: Codeunit "VCD Silent Print Mgt.";
                begin
                    SilentPrintMgt.ScheduleSilentPrint(Rec);
                end;
            }
            action(ShowPrinterSelection)
            {
                ApplicationArea = All;
                Caption = 'View Printer Selection';
                ToolTip = 'Opens the standard Printer Selection setup to see existing printer assignments.';
                Image = Print;
                RunObject = Page "Printer Selections";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(SaveRequestParams_Promoted; SaveRequestParams) { }
                actionref(ScheduleNow_Promoted; ScheduleNow) { }
            }
        }
    }
}
