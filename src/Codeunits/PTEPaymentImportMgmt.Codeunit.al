/// <summary>
/// Codeunit PTEPaymentImportMgmt (ID 50147).
/// </summary>
codeunit 50147 PTEPaymentImportMgmt
{
    procedure ImportPayments(TemplateName: Code[10]; BatchName: Code[10])
    var
        CSVBuffer: Record "CSV Buffer" temporary;
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        PTEFieldImportValidations: Codeunit PTEFieldImportValidations;
        GenJournalDocType: Enum "Gen. Journal Document Type";
        GenAccountType: Enum "Gen. Journal Account Type";
        InStr: InStream;
        ValDecimal: Decimal;
        LineNo: Integer;
        NextLineNo: Integer;
        EntryCount: Integer;
        ValDate: Date;
        FileName: Text;
        ValText: Text;
    begin
        if not UploadIntoStream('Select Payment CSV', '', 'CSV Files (*.csv)|*.csv', FileName, InStr) then
            exit;

        CSVBuffer.LoadDataFromStream(InStr, ',');

        GenJnlLine.SetRange("Journal Template Name", TemplateName);
        GenJnlLine.SetRange("Journal Batch Name", BatchName);
        if GenJnlLine.FindLast() then
            NextLineNo := GenJnlLine."Line No." + 10000
        else
            NextLineNo := 10000;

        for LineNo := 2 to CSVBuffer.GetNumberOfLines() do begin
            ValText := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 3);

            if ValText <> '' then begin
                Clear(GenJnlLine);
                GenJnlLine.Init();
                GenJnlLine.Validate("Journal Template Name", TemplateName);
                GenJnlLine.Validate("Journal Batch Name", BatchName);
                GenJnlLine.Validate("Line No.", NextLineNo);

                PTEFieldImportValidations.EvaluateDate(ValDate, PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 1), LineNo);
                GenJnlLine.Validate("Posting Date", ValDate);

                ValText := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 2);
                GenJournalDocType := PTEFieldImportValidations.ParseGenJournalDocType(LineNo, ValText);
                GenJnlLine.Validate("Document Type", GenJournalDocType);
                GenJnlLine.Validate("Document No.", PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 3));

                ValText := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 4);
                GenAccountType := PTEFieldImportValidations.ParseGenAccountType(LineNo, ValText);
                GenJnlLine.Validate("Account Type", GenAccountType);
                GenJnlLine.Validate("Account No.", PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 5));
                PTEFieldImportValidations.EvaluateDecimal(ValDecimal, PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 6));
                GenJnlLine.Validate(Amount, ValDecimal);

                ValText := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 7);
                GenAccountType := PTEFieldImportValidations.ParseGenAccountType(LineNo, ValText);
                GenJnlLine.Validate("Bal. Account Type", GenAccountType);
                GenJnlLine.Validate("Bal. Account No.", PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 10));
                GenJnlLine.Validate("External Document No.", PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 9));


                CustLedgerEntry.Reset();
                CustLedgerEntry.SetRange("Customer No.", GenJnlLine."Account No.");
                CustLedgerEntry.SetRange("Your Reference", GenJnlLine."External Document No.");
                CustLedgerEntry.SetRange("External Document No.", GenJnlLine."Document No.");
                if CustLedgerEntry.FindFirst() then begin
                    GenJnlLine.Validate("Applies-to Doc. Type", CustLedgerEntry."Document Type");
                    GenJnlLine.Validate("Applies-to Doc. No.", CustLedgerEntry."Document No.");
                    GenJnlLine.Validate("Dimension Set ID", CustLedgerEntry."Dimension Set ID");
                end;


                ValText := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 11);
                if ValText <> '' then
                    GenJnlLine.Validate("Payment Method Code", ValText);

                if Customer.Get(GenJnlLine."Account No.") then
                    GenJnlLine.Validate("Country/Region Code", Customer."Country/Region Code")
                else
                    GenJnlLine.Validate("Country/Region Code", PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 12));

                // TODO: Below commented lines are for future use.
                // During development, it was unclear where to map CSV cells in the Business Central.
                // GenJnlLine."Member Type" := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 13);
                // PTEFieldImportValidations.EvaluateBoolean(GenJnlLine."Cp Individual", PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 14), LineNo);
                // PTEFieldImportValidations.EvaluateBoolean(GenJnlLine."Cp Pays", PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 15), LineNo);

                GenJnlLine.Insert(true);
                Commit();

                NextLineNo += 10000;
                EntryCount += 1;
            end;
        end;

        Message('Import Complete. Created %1 lines in batch %2.', EntryCount, BatchName);
    end;
}