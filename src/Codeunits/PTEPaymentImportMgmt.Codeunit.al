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
        NextPayLineNo: Integer;
        NextRefundLineNo: Integer;
        PayEntryCount: Integer;
        RefundEntryCount: Integer;
        ValDate: Date;
        FileName: Text;
        ValText: Text;
    begin
        if not UploadIntoStream('Select Payment CSV', '', 'CSV Files (*.csv)|*.csv', FileName, InStr) then
            exit;

        CSVBuffer.LoadDataFromStream(InStr, ',');

        GenJnlLine.Reset();
        GenJnlLine.SetRange("Journal Template Name", TemplateName);
        GenJnlLine.SetRange("Journal Batch Name", 'IMIS_PAY');
        if GenJnlLine.FindLast() then
            NextPayLineNo := GenJnlLine."Line No." + 10000
        else
            NextPayLineNo := 10000;

        GenJnlLine.Reset();
        GenJnlLine.SetRange("Journal Template Name", TemplateName);
        GenJnlLine.SetRange("Journal Batch Name", 'IMIS_REF');
        if GenJnlLine.FindLast() then
            NextRefundLineNo := GenJnlLine."Line No." + 10000
        else
            NextRefundLineNo := 10000;

        for LineNo := 2 to CSVBuffer.GetNumberOfLines() do begin
            ValText := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 3);

            if ValText <> '' then begin
                Clear(GenJnlLine);
                ValText := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 2);
                GenJournalDocType := PTEFieldImportValidations.ParseGenJournalDocType(LineNo, ValText);

                GenJnlLine.Init();
                GenJnlLine.Validate("Journal Template Name", TemplateName);
                if GenJournalDocType = GenJournalDocType::Payment then begin
                    GenJnlLine.Validate("Journal Batch Name", 'IMIS_PAY');
                    GenJnlLine.Validate("Line No.", NextPayLineNo);
                    NextPayLineNo += 10000;
                    PayEntryCount += 1;
                end else if GenJournalDocType = GenJournalDocType::Refund then begin
                    GenJnlLine.Validate("Journal Batch Name", 'IMIS_REF');
                    GenJnlLine.Validate("Line No.", NextRefundLineNo);
                    NextRefundLineNo += 10000;
                    RefundEntryCount += 1;
                end else
                    Error('Invalid Document Type in line %1. Expected Payment or Refund.', LineNo);

                PTEFieldImportValidations.EvaluateDate(ValDate, PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 1), LineNo);
                GenJnlLine.Validate("Posting Date", ValDate);
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
                CustLedgerEntry.SetRange(Open, true);
                if CustLedgerEntry.FindFirst() then begin
                    GenJnlLine.Validate("Applies-to Doc. Type", CustLedgerEntry."Document Type");
                    GenJnlLine.Validate("Applies-to Doc. No.", CustLedgerEntry."Document No.");
                    GenJnlLine.Validate("Dimension Set ID", CustLedgerEntry."Dimension Set ID");
                end;


                ValText := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 11);
                if ValText <> '' then
                    GenJnlLine."Payment Method Code" := ValText;

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
            end;
        end;

        Message('Import Complete.\Created %1 payment lines in batch %2.\Created %3 refund lines in batch %4.', PayEntryCount, 'IMIS_PAY', RefundEntryCount, 'IMIS_REF');
    end;
}