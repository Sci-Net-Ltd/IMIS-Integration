/// <summary>
/// Codeunit PTESalesImportMgmt (ID 50148).
/// </summary>
codeunit 50148 PTESalesImportMgmt
{
    procedure ImportSalesOrdersFromCSV()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CSVBuffer: Record "CSV Buffer" temporary;
        PTEFieldImportValidations: Codeunit PTEFieldImportValidations;
        DocNo: Code[20];
        CustomerNo: Code[20];
        PrevCustomerNo: Code[20];
        DeferralCode: Code[10];
        DocType: Enum "Sales Document Type";
        ValDecimal: Decimal;
        LineNo: Integer;
        LineNoInt: Integer;
        DocCount: Integer;
        FileName: Text;
        DocTypeText: Text;
        ValText: Text;
        ValDate: Date;
        InStr: InStream;
    begin
        if not UploadIntoStream('Select Sales Order CSV', '', 'CSV Files (*.csv)|*.csv', FileName, InStr) then
            exit;

        CSVBuffer.LoadDataFromStream(InStr, ',');

        for LineNo := 2 to CSVBuffer.GetNumberOfLines() do begin
            DocTypeText := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 21);
            DocType := PTEFieldImportValidations.ParseDocumentType(LineNo, DocTypeText);
            CustomerNo := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 2);

            if CustomerNo <> PrevCustomerNo then begin
                PrevCustomerNo := CustomerNo;
                Clear(SalesHeader);
                SalesHeader.Init();
                SalesHeader.Validate("Document Type", DocType);
                SalesHeader.Validate("External Document No.", PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 1));
                SalesHeader.Insert(true);
                DocNo := SalesHeader."No.";
                SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
                PTEFieldImportValidations.EvaluateDate(ValDate, PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 4), LineNo);
                SalesHeader.Validate("Posting Date", ValDate);
                PTEFieldImportValidations.EvaluateDate(ValDate, PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 3), LineNo);
                SalesHeader.Validate("Document Date", ValDate);
                SalesHeader.Validate("Shipment Date", ValDate);
                SalesHeader.Validate("Due Date", ValDate);
                SalesHeader.Validate("Your Reference", PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 5));
                SalesHeader.Modify(true);
                DocCount += 1;
                LineNoInt := 0;
            end;

            Clear(SalesLine);
            SalesLine.Init();
            SalesLine.Validate("Document Type", DocType);
            SalesLine.Validate("Document No.", DocNo);

            LineNoInt += 10000;
            SalesLine."Line No." := LineNoInt;

            SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
            PTEFieldImportValidations.ParseAndSetDimensions(SalesLine, CSVBuffer, PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 11), lineNo);

            PTEFieldImportValidations.EvaluateDecimal(ValDecimal, PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 7));
            SalesLine.Validate(Quantity, ValDecimal);
            PTEFieldImportValidations.EvaluateDecimal(ValDecimal, PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 8));
            SalesLine.Validate("Unit Price", ValDecimal);
            DeferralCode := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 18);
            SalesLine.Validate("Deferral Code", DeferralCode);

            // Mapping for following fields has not been mentioned in the spec, so commenting out for now
            // SalesLine."Item No." := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 6);
            // SalesLine."Country Code" := GetCellValue(CSVBuffer, LineNo, 12);
            // EvaluateBoolean(SalesLine."Cp Individual", GetCellValue(CSVBuffer, LineNo, 14));
            // EvaluateBoolean(SalesLine."Cp Pays", GetCellValue(CSVBuffer, LineNo, 15));
            // EvaluateDate(SalesLine."Period Start", GetCellValue(CSVBuffer, LineNo, 16));
            // EvaluateDate(SalesLine."Period End", GetCellValue(CSVBuffer, LineNo, 17));
            // SalesLine."Member Type" := CopyStr(GetCellValue(CSVBuffer, LineNo, 13), 1, 20);
            SalesLine.Insert(true);
        end;

        Message('Import Complete. Processed %1 orders.', DocCount);
    end;
}