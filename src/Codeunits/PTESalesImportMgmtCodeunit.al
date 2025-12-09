/// <summary>
/// Codeunit PTESalesImportMgmt (ID 50148).
/// </summary>
codeunit 50148 PTESalesImportMgmt
{
    procedure ImportSalesOrdersFromCSV()
    var
        CSVBuffer: Record "CSV Buffer" temporary;
        PTEFieldImportValidations: Codeunit PTEFieldImportValidations;
        FileName: Text;
        InStr: InStream;
        LineNo: Integer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocType: Enum "Sales Document Type";
        DocNo: Code[20];
        CustomerNo: Code[20];
        PrevCustomerNo: Code[20];
        ValDecimal: Decimal;
        LineNoInt: Integer;
        DocCount: Integer;
        DocTypeText: Text;
        ValText: Text;
        ValDate: Date;
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
                PTEFieldImportValidations.EvaluateDate(ValDate, PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 3), LineNo);
                SalesHeader.Validate("Document Date", ValDate);
                SalesHeader.Validate("Shipment Date", ValDate);
                PTEFieldImportValidations.EvaluateDate(ValDate, PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 4), LineNo);
                SalesHeader.Validate("Posting Date", ValDate);
                SalesHeader.Validate("Due Date", ValDate);
                SalesHeader.Validate("Your Reference", PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 5));
                SalesHeader.Modify(true);
                DocCount += 1;
            end;

            Clear(SalesLine);
            SalesLine.Init();
            SalesLine.Validate("Document Type", DocType);
            SalesLine.Validate("Document No.", DocNo);

            Evaluate(LineNoInt, PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 9));
            SalesLine."Line No." := LineNoInt * 10000;

            SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
            PTEFieldImportValidations.ParseAndSetDimensions(SalesLine, CSVBuffer, PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 11), lineNo);

            PTEFieldImportValidations.EvaluateDecimal(ValDecimal, PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 7));
            SalesLine.Validate(Quantity, ValDecimal);
            PTEFieldImportValidations.EvaluateDecimal(ValDecimal, PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 8));
            SalesLine.Validate("Unit Price", ValDecimal);

            // TODO: Getting an error because of this line on SalesLine.Insert trigger (code is not accessible to check the reason)
            //SalesLine.Validate("Deferral Code", PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 18));

            // Mapping for following fields has not been mentioned in the spec, so commenting out for now
            // SalesLine."Item No." := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 6);
            // SalesLine."Country Code" := GetCellValue(CSVBuffer, LineNo, 12);
            // EvaluateBoolean(SalesLine."Cp Individual", GetCellValue(CSVBuffer, LineNo, 14));
            // EvaluateBoolean(SalesLine."Cp Pays", GetCellValue(CSVBuffer, LineNo, 15));
            // EvaluateDate(SalesLine."Period Start", GetCellValue(CSVBuffer, LineNo, 16));
            // EvaluateDate(SalesLine."Period End", GetCellValue(CSVBuffer, LineNo, 17));
            // SalesLine."Member Type" := CopyStr(GetCellValue(CSVBuffer, LineNo, 13), 1, 20);

            if SalesLine.Insert(true) then;
        end;

        Message('Import Complete. Processed %1 orders.', DocCount);
    end;
}