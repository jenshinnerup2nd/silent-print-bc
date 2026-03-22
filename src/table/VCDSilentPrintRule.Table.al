table 73000 "VCD Silent Print Rule"
{
    Caption = 'Silent Print Rule';
    DataClassification = CustomerContent;
    DrillDownPageId = "VCD Silent Print Rules";
    LookupPageId = "VCD Silent Print Rules";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));

            trigger OnValidate()
            var
                AllObj: Record AllObjWithCaption;
            begin
                "Report Name" := '';
                if AllObj.Get(AllObj."Object Type"::Report, "Report ID") then
                    "Report Name" := AllObj."Object Caption";
            end;
        }
        field(3; "Report Name"; Text[250])
        {
            Caption = 'Report Name';
            Editable = false;
        }
        field(4; "Subject Type"; Enum "VCD Silent Print Subject Type")
        {
            Caption = 'Subject Type';

            trigger OnValidate()
            begin
                Validate("Subject Code", '');
            end;
        }
        field(5; "Subject Code"; Code[50])
        {
            Caption = 'User / Group';
            TableRelation =
                if ("Subject Type" = const(User)) User."User Name"
                else if ("Subject Type" = const("Security Group")) "Security Group".Code;

            trigger OnValidate()
            begin
                UpdateSubjectName();
            end;
        }
        field(6; "Subject Name"; Text[250])
        {
            Caption = 'Name';
            Editable = false;
        }
        field(7; "Printer Name"; Text[250])
        {
            Caption = 'Printer Name';
            TableRelation = Printer.ID;
        }
        field(8; Enabled; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
        }
        field(9; "Saved Request XML"; Blob)
        {
            Caption = 'Saved Request Parameters';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByReport; "Report ID", "Subject Type", "Subject Code", Enabled) { }
    }

    local procedure UpdateSubjectName()
    var
        User: Record User;
        SecurityGroup: Record "Security Group";
    begin
        "Subject Name" := '';
        case "Subject Type" of
            "VCD Silent Print Subject Type"::User:
                begin
                    User.SetRange("User Name", "Subject Code");
                    if User.FindFirst() then
                        "Subject Name" := User."Full Name";
                end;
            "VCD Silent Print Subject Type"::"Security Group":
                if SecurityGroup.Get("Subject Code") then
                    "Subject Name" := SecurityGroup.Name;
        end;
    end;

    procedure GetSavedRequestXML(): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        CalcFields("Saved Request XML");
        if not "Saved Request XML".HasValue() then
            exit('');
        "Saved Request XML".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.Read(Result);
        exit(Result);
    end;

    procedure SetSavedRequestXML(Xml: Text)
    var
        OutStr: OutStream;
    begin
        "Saved Request XML".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.Write(Xml);
    end;
}
