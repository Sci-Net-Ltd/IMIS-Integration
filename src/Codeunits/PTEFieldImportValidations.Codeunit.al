/// <summary>
/// Codeunit PTEFieldImportValidations (ID 50146).
/// </summary>
codeunit 50146 PTEFieldImportValidations
{
    /// <summary>
    /// GetCellValue.
    /// </summary>
    /// <param name="CSVBuffer">VAR Record "CSV Buffer".</param>
    /// <param name="RowNo">Integer.</param>
    /// <param name="ColNo">Integer.</param>
    /// <returns>Text.</returns>
    procedure GetCellValue(var CSVBuffer: Record "CSV Buffer"; RowNo: Integer; ColNo: Integer): Text
    var
        Value: Text;
    begin
        if CSVBuffer.Get(RowNo, ColNo) then
            value := CSVBuffer.Value;

        if (Value.StartsWith('"')) and (Value.EndsWith('"')) then begin
            Value := DelChr(Value, '<>', '"');
            exit(Value);
        end else
            exit('');
    end;

    /// <summary>
    /// EvaluateBoolean.
    /// </summary>
    /// <param name="BoolField">VAR Boolean.</param>
    /// <param name="Val">Text.</param>
    /// <param name="LineNo">Integer.</param>
    procedure EvaluateBoolean(var BoolField: Boolean; Val: Text; LineNo: Integer)
    var
        InvalidBoolean: Label 'Invalid boolean value on line %1. Please use TRUE or FALSE.';
    begin
        if Val = '' then
            Error(InvalidBoolean, LineNo);

        if not Evaluate(BoolField, Val) then begin
            if UpperCase(Val) = 'TRUE' then
                BoolField := true
            else
                if UpperCase(Val) = 'FALSE' then
                    BoolField := false;
        end;
    end;

    /// <summary>
    /// EvaluateDate.
    /// </summary>
    /// <param name="DateField">VAR Date.</param>
    /// <param name="Val">Text.</param>
    procedure EvaluateDate(var DateField: Date; Val: Text; LineNo: Integer)
    var
        Day: Integer;
        Month: Integer;
        Year: Integer;
        DateParts: List of [Text];
        DateFormatError: Label 'Line %1 is having invalid date format: %2. Please use DD/MM/YYYY, DD-MM-YYYY or DD.MM.YYYY.';
    begin
        DateField := 0D;
        if Val = '' then
            exit;

        if Val.Contains('/') then
            DateParts := Val.Split('/')
        else if Val.Contains('-') then
            DateParts := Val.Split('-')
        else if Val.Contains('.') then
            DateParts := Val.Split('.');

        if DateParts.Count() = 3 then begin
            if not Evaluate(Day, DateParts.Get(1)) then
                exit;
            if not Evaluate(Month, DateParts.Get(2)) then
                exit;
            if not Evaluate(Year, DateParts.Get(3)) then
                exit;
        end;

        if Month > 12 then
            Error(DateFormatError, LineNo, Val);

        DateField := DMY2Date(Day, Month, Year);
    end;

    /// <summary>
    /// EvaluateDecimal.
    /// </summary>
    /// <param name="DecField">VAR Decimal.</param>
    /// <param name="Val">Text.</param>
    procedure EvaluateDecimal(var DecField: Decimal; Val: Text)
    begin
        if Val = '' then
            DecField := 0
        else
            Evaluate(DecField, Val);
    end;

    /// <summary>
    /// ParseAndSetDimensions.
    /// </summary>
    /// <param name="SalesLine">VAR Record "Sales Line".</param>
    /// <param name="DimStr">Text.</param>
    /// <param name="LineNo">Integer.</param>
    procedure ParseAndSetDimensions(var SalesLine: Record "Sales Line"; var CSVBuffer: Record "CSV Buffer"; DimStr: Text; LineNo: Integer)
    var
        GLSetup: Record "General Ledger Setup";
        DimMgt: Codeunit "DimensionManagement";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimParts: List of [Text];
        PartVal: Text;
        ResolvedDimVal: Text;
        DimensionMissing: Label 'Dimension value in CSV is missing for Line: %1.';
    begin
        if DimStr = '' then
            Error(DimensionMissing, LineNo);

        GLSetup.Get();
        DimParts := DimStr.Split('|');

        if DimParts.Count() >= 1 then begin
            PartVal := DimParts.Get(1);
            SalesLine.Validate("No.", PartVal);
        end;

        if DimParts.Count() >= 2 then begin
            PartVal := DimParts.Get(2);
            if (PartVal <> '') and (PartVal <> '#') then
                SalesLine.Validate("Shortcut Dimension 1 Code", CopyStr(PartVal, 1, 20));
        end;

        if DimParts.Count() >= 3 then begin
            PartVal := DimParts.Get(3);
            if (PartVal <> '') and (PartVal <> '#') then
                SalesLine.Validate("Shortcut Dimension 2 Code", CopyStr(PartVal, 1, 20));
        end;

        DimMgt.GetDimensionSet(TempDimSetEntry, SalesLine."Dimension Set ID");

        // Process Index 4 from "Dimensions" cell in CSV
        if DimParts.Count() >= 4 then begin
            ResolvedDimVal := DimParts.Get(4);
            if ResolveValue(ResolvedDimVal, CSVBuffer, LineNo, 0) then
                AutoAssignDimension(TempDimSetEntry, ResolvedDimVal, GLSetup);
        end;

        // Process Index 5 from "Dimensions" cell in CSV
        if DimParts.Count() >= 5 then begin
            ResolvedDimVal := DimParts.Get(5);
            if ResolveValue(ResolvedDimVal, CSVBuffer, LineNo, 0) then
                AutoAssignDimension(TempDimSetEntry, DimParts.Get(5), GLSetup);
        end;

        // Process Index 6 from "Dimensions" cell in CSV
        if DimParts.Count() >= 6 then begin
            ResolvedDimVal := DimParts.Get(6);
            if ResolveValue(ResolvedDimVal, CSVBuffer, LineNo, 0) then
                AutoAssignDimension(TempDimSetEntry, ResolvedDimVal, GLSetup);
        end;

        // Process Index 7 from "Dimensions" cell in CSV, if this is '#'
        if DimParts.Count() >= 7 then begin
            ResolvedDimVal := DimParts.Get(7);
            if ResolveValue(ResolvedDimVal, CSVBuffer, LineNo, 0) then
                AutoAssignDimension(TempDimSetEntry, ResolvedDimVal, GLSetup);
        end;

        // Process Index 8+ (Standard Values)
        if DimParts.Count() >= 8 then begin
            ResolvedDimVal := DimParts.Get(8);
            if ResolveValue(ResolvedDimVal, CSVBuffer, LineNo, 0) then
                AutoAssignDimension(TempDimSetEntry, ResolvedDimVal, GLSetup);
        end;
        if DimParts.Count() >= 9 then begin
            ResolvedDimVal := DimParts.Get(9);
            if ResolveValue(ResolvedDimVal, CSVBuffer, LineNo, 0) then
                AutoAssignDimension(TempDimSetEntry, ResolvedDimVal, GLSetup);
        end;

        // Revalidate specific dimensions based on CSV columns
        if ResolveValue(ResolvedDimVal, CSVBuffer, LineNo, 19) then
            AutoAssignDimension(TempDimSetEntry, ResolvedDimVal, GLSetup);
        if ResolveValue(ResolvedDimVal, CSVBuffer, LineNo, 20) then
            AutoAssignDimension(TempDimSetEntry, ResolvedDimVal, GLSetup);
        if ResolveValue(ResolvedDimVal, CSVBuffer, LineNo, 13) then
            AutoAssignDimension(TempDimSetEntry, ResolvedDimVal, GLSetup);

        SalesLine."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
    end;

    /// <summary>
    /// ResolveValue.
    /// </summary>
    /// <param name="Val">VAR Text.</param>
    /// <param name="CSVBuffer">VAR Record "CSV Buffer".</param>
    /// <param name="RowNo">Integer.</param>
    /// <param name="ColNo">Integer.</param>
    /// <returns>Boolean.</returns>
    // Helper: Returns either the explicit value OR the value from the CSV column if '#'
    local procedure ResolveValue(var Val: Text; var CSVBuffer: Record "CSV Buffer"; RowNo: Integer; ColNo: Integer): Boolean
    begin
        if ColNo <> 0 then // If column number is provided, fetch value from CSV
            Val := GetCellValue(CSVBuffer, RowNo, ColNo);

        if (Val = '') or (Val = '#') or (UpperCase(Val) = 'N/A') then
            exit(false);

        exit(true);
    end;

    /// <summary>
    /// AutoAssignDimension.
    /// </summary>
    /// <param name="TempDimSetEntry">VAR Record "Dimension Set Entry" temporary.</param>
    /// <param name="DimVal">Text.</param>
    /// <param name="GLSetup">VAR Record "General Ledger Setup"</param>
    // Helper: Checks valid dimensions and assigns the value to the correct one
    local procedure AutoAssignDimension(var TempDimSetEntry: Record "Dimension Set Entry" temporary; DimVal: Text; var GLSetup: Record "General Ledger Setup")
    begin
        if (DimVal = '') or (DimVal = '#') or (UpperCase(DimVal) = 'N/A') then
            exit;

        if IsValidDimensionValue(GLSetup."Shortcut Dimension 3 Code", DimVal) then begin
            UpdateDimSet(TempDimSetEntry, GLSetup."Shortcut Dimension 3 Code", DimVal);
            exit;
        end;

        if IsValidDimensionValue(GLSetup."Shortcut Dimension 4 Code", DimVal) then begin
            UpdateDimSet(TempDimSetEntry, GLSetup."Shortcut Dimension 4 Code", DimVal);
            exit;
        end;

        if IsValidDimensionValue(GLSetup."Shortcut Dimension 5 Code", DimVal) then begin
            UpdateDimSet(TempDimSetEntry, GLSetup."Shortcut Dimension 5 Code", DimVal);
            exit;
        end;

        if IsValidDimensionValue(GLSetup."Shortcut Dimension 6 Code", DimVal) then begin
            UpdateDimSet(TempDimSetEntry, GLSetup."Shortcut Dimension 6 Code", DimVal);
            exit;
        end;

        if IsValidDimensionValue(GLSetup."Shortcut Dimension 7 Code", DimVal) then begin
            UpdateDimSet(TempDimSetEntry, GLSetup."Shortcut Dimension 7 Code", DimVal);
            exit;
        end;

        if IsValidDimensionValue(GLSetup."Shortcut Dimension 8 Code", DimVal) then begin
            UpdateDimSet(TempDimSetEntry, GLSetup."Shortcut Dimension 8 Code", DimVal);
            exit;
        end;
    end;

    /// <summary>
    /// IsValidDimensionValue.
    /// </summary>
    /// <param name="DimCode">Code[20].</param>
    /// <param name="DimVal">Code[20].</param>
    /// <returns>Boolean.</returns>
    local procedure IsValidDimensionValue(DimCode: Code[20]; DimVal: Code[20]): Boolean
    var
        DimValue: Record "Dimension Value";
    begin
        if DimCode = '' then
            exit(false);
        if DimVal = '' then
            exit(false);

        exit(DimValue.Get(DimCode, DimVal));
    end;

    /// <summary>
    /// UpdateDimSet.
    /// </summary>
    /// <param name="TempDimSetEntry">VAR Record "Dimension Set Entry" temporary.</param>
    /// <param name="DimCode">Code[20].</param>
    /// <param name="DimVal">Text.</param>
    local procedure UpdateDimSet(var TempDimSetEntry: Record "Dimension Set Entry" temporary; DimCode: Code[20]; DimVal: Text)
    begin
        TempDimSetEntry.SetRange("Dimension Code", DimCode);
        if TempDimSetEntry.FindFirst() then begin
            TempDimSetEntry.Validate("Dimension Value Code", CopyStr(DimVal, 1, 20));
            TempDimSetEntry.Modify();
        end else begin
            TempDimSetEntry.Init();
            TempDimSetEntry.Validate("Dimension Set ID", TempDimSetEntry."Dimension Set ID");
            TempDimSetEntry.Validate("Dimension Code", DimCode);
            TempDimSetEntry.Validate("Dimension Value Code", CopyStr(DimVal, 1, 20));
            TempDimSetEntry.Insert();
        end;
    end;

    /// <summary>
    /// ParseDocumentType.
    /// </summary>
    /// <param name="LineNo">Integer.</param>
    /// <param name="TypeTxt">Text.</param>
    /// <returns>Enum "Sales Document Type".</returns>
    procedure ParseDocumentType(LineNo: Integer; TypeTxt: Text): Enum "Sales Document Type"
    var
        IncorrectDocType: Label 'Incorrect Sales Document Type on line %1: %2';
    begin
        case UpperCase(TypeTxt) of
            'QUOTE':
                exit("Sales Document Type"::Quote);
            'ORDER':
                exit("Sales Document Type"::Order);
            'INVOICE':
                exit("Sales Document Type"::Invoice);
            'CREDIT MEMO':
                exit("Sales Document Type"::"Credit Memo");
            'BLANKET ORDER':
                exit("Sales Document Type"::"Blanket Order");
            'RETURN ORDER':
                exit("Sales Document Type"::"Return Order");
            else
                Error(IncorrectDocType, LineNo, TypeTxt);
        end;
    end;

    /// <summary>
    /// ParseGenJournalDocType.
    /// </summary>
    /// <param name="LineNo">Integer.</param>
    /// <param name="TypeTxt">Text.</param>
    /// <returns>Enum "Gen. Journal Document Type"</returns>
    procedure ParseGenJournalDocType(LineNo: Integer; TypeTxt: Text): Enum "Gen. Journal Document Type"
    var
        IncorrectDocType: Label 'Incorrect General Journal Document Type on line %1: %2';
    begin
        case UpperCase(TypeTxt) of
            '', ' ':
                exit("Gen. Journal Document Type"::" ");
            'PAYMENT':
                exit("Gen. Journal Document Type"::Payment);
            'INVOICE':
                exit("Gen. Journal Document Type"::Invoice);
            'CREDIT MEMO':
                exit("Gen. Journal Document Type"::"Credit Memo");
            'FINANCE CHARGE MEMO':
                exit("Gen. Journal Document Type"::"Finance Charge Memo");
            'REMINDER':
                exit("Gen. Journal Document Type"::Reminder);
            'REFUND':
                exit("Gen. Journal Document Type"::Refund);
            else
                Error(IncorrectDocType, LineNo, TypeTxt);
        end;
    end;

    /// <summary>
    /// ParseGenAccountType.
    /// </summary>
    /// <param name="LineNo">Integer.</param>
    /// <param name="TypeTxt">Text.</param>
    /// <returns>Enum "Gen. Journal Account Type"</returns>
    procedure ParseGenAccountType(LineNo: Integer; TypeTxt: Text): Enum "Gen. Journal Account Type"
    var
        IncorrectAccType: Label 'Incorrect Gen. Journal Account Type on line %1: %2';
    begin
        case UpperCase(TypeTxt) of
            'G/L ACCOUNT':
                exit("Gen. Journal Account Type"::"G/L Account");
            'CUSTOMER':
                exit("Gen. Journal Account Type"::Customer);
            'VENDOR':
                exit("Gen. Journal Account Type"::Vendor);
            'BANK ACCOUNT':
                exit("Gen. Journal Account Type"::"Bank Account");
            'FIXED ASSET':
                exit("Gen. Journal Account Type"::"Fixed Asset");
            'IC PARTNER':
                exit("Gen. Journal Account Type"::"IC Partner");
            'EMPLOYEE':
                exit("Gen. Journal Account Type"::Employee);
            'ALLOCATION ACCOUNT':
                exit("Gen. Journal Account Type"::"Allocation Account");
            else
                Error(IncorrectAccType, LineNo, TypeTxt);
        end;
    end;
}