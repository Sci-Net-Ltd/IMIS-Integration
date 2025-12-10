/// <summary>
/// Codeunit PTECustomerImportMgt (ID 50149).
/// </summary>
codeunit 50149 PTECustomerImportMgt
{
    /// <summary>
    /// ImportCustomersFromCSV.
    /// </summary>
    procedure ImportCustomersFromCSV()
    var
        CSVBuffer: Record "CSV Buffer" temporary;
        Customer: Record Customer;
        ShiptoAddress: Record "Ship-to Address";
        PTEFieldImportValidations: Codeunit PTEFieldImportValidations;
        InStr: InStream;
        CustomerId: Code[20];
        LineNo: Integer;
        UpdatedCount: Integer;
        InsertedCount: Integer;
        ValDate: Date;
        FileName: Text;
        ValText: Text;
        IncorrectDocType: Label 'Please fill Customer ID on line %1.';
    begin
        if not UploadIntoStream('Select CSV File', '', 'CSV Files (*.csv)|*.csv', FileName, InStr) then
            exit;

        CSVBuffer.LoadDataFromStream(InStr, ',');

        for LineNo := 2 to CSVBuffer.GetNumberOfLines() do begin
            CustomerId := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 1);

            if CustomerId = '' then
                Error(IncorrectDocType, LineNo);

            if Customer.Get(CustomerId) then begin
                UpdatedCount += 1;
            end else begin
                Customer.Init();
                Customer.Validate("No.", CustomerId);
                Customer.Insert(true);
                InsertedCount += 1;
            end;

            ValText := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 2);
            if ValText <> '' then
                Customer.Validate("Customer Posting Group", ValText);

            PTEFieldImportValidations.EvaluateBoolean(Customer."CP Individual MOD02", PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 3), LineNo);
            PTEFieldImportValidations.EvaluateBoolean(Customer."CP Payes MOD02", PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 4), LineNo);
            ValText := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 5);
            if ValText <> '' then begin
                if not ShiptoAddress.Get(CustomerId, ValText) then begin
                    ShiptoAddress.Init();
                    ShiptoAddress.Validate("Customer No.", CustomerId);
                    ShiptoAddress.Validate(Code, ValText);
                    ShiptoAddress.Insert(true);
                end;

                Customer.Validate("Ship-to Code", ShiptoAddress.Code);
            end;

            ValText := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 6);
            if ValText <> '' then begin
                Customer.Validate("VAT Bus. Posting Group", ValText);
                Customer.Validate("Gen. Bus. Posting Group", ValText);
            end;

            ValText := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 7);
            if ValText <> '' then
                Customer.Validate("Country/Region Code", ValText);

            Customer.Validate("Prices Including VAT", true);
            PTEFieldImportValidations.EvaluateDate(ValDate, PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 8), LineNo);
            Customer.Validate("CQI Mem Start MOD02", ValDate);
            PTEFieldImportValidations.EvaluateDate(ValDate, PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 11), LineNo);
            Customer.Validate("IRCA Start Date MOD02", ValDate);

            // During development, it was unclear where to map CSV cells in the Business Central.
            // Customer.Validate("Cqi Mem Grade", CopyStr(GetCellValue(CSVBuffer, LineNo, 9), 1, 50));
            // Customer.Validate("Cqi Home Branch", CopyStr(GetCellValue(CSVBuffer, LineNo, 10), 1, 50));
            // Customer.Validate("Irca Aerospace Grade", CopyStr(GetCellValue(CSVBuffer, LineNo, 12), 1, 50));
            // Customer.Validate("Irca Bcms Grade", CopyStr(GetCellValue(CSVBuffer, LineNo, 13), 1, 50));
            // Customer.Validate("Irca Eicc Grade", CopyStr(GetCellValue(CSVBuffer, LineNo, 14), 1, 50));
            // Customer.Validate("Irca Ems Grade", CopyStr(GetCellValue(CSVBuffer, LineNo, 15), 1, 50));
            // Customer.Validate("Irca Fsms Grade", CopyStr(GetCellValue(CSVBuffer, LineNo, 16), 1, 50));
            // Customer.Validate("Irca Isms Grade", CopyStr(GetCellValue(CSVBuffer, LineNo, 17), 1, 50));
            // Customer.Validate("Irca Itsms Grade", CopyStr(GetCellValue(CSVBuffer, LineNo, 18), 1, 50));
            // Customer.Validate("Irca Maritime Grade", CopyStr(GetCellValue(CSVBuffer, LineNo, 19), 1, 50));
            // Customer.Validate("Irca Ohs Grade", CopyStr(GetCellValue(CSVBuffer, LineNo, 20), 1, 50));
            // Customer.Validate("Irca Pqms Grade", CopyStr(GetCellValue(CSVBuffer, LineNo, 21), 1, 50));
            // Customer.Validate("Irca Qms Grade", CopyStr(GetCellValue(CSVBuffer, LineNo, 22), 1, 50));
            // Customer.Validate("Irca Ss Grade", CopyStr(GetCellValue(CSVBuffer, LineNo, 23), 1, 50));
            Customer.Modify(true);
            Commit();
        end;

        Message('Import Complete.\ Records Created: %1\ Records Updated: %2', InsertedCount, UpdatedCount);
    end;
}