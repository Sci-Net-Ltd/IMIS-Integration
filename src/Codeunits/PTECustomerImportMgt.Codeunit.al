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
        PTEFieldImportValidations: Codeunit PTEFieldImportValidations;
        FileName: Text;
        InStr: InStream;
        LineNo: Integer;
        Customer: Record Customer;
        CustomerId: Code[20];
        ValText: Text;
        IncorrectDocType: Label 'Please fill Customer ID on line %1.';
        UpdatedCount: Integer;
        InsertedCount: Integer;
    begin
        // TODO: Below commented lines are for future use.
        // During development, it was unclear where to map CSV cells in the Business Central.

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
            // ValText := GetCellValue(CSVBuffer, LineNo, 5);
            // if ValText <> '' then
            //     Customer.Validate("Geography Revenue", CopyStr(ValText, 1, 20));
            ValText := PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 6);
            if ValText <> '' then begin
                Customer.Validate("VAT Bus. Posting Group", ValText);
                Customer.Validate("Gen. Bus. Posting Group", ValText);
            end;
            // ValText := GetCellValue(CSVBuffer, LineNo, 7);
            // if ValText <> '' then
            //     Customer.Validate("Geography Membership", CopyStr(ValText, 1, 20));
            PTEFieldImportValidations.EvaluateDate(Customer."CQI Mem Start MOD02", PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 8), LineNo);
            // Customer.Validate("Cqi Mem Grade", CopyStr(GetCellValue(CSVBuffer, LineNo, 9), 1, 50));
            // Customer.Validate("Cqi Home Branch", CopyStr(GetCellValue(CSVBuffer, LineNo, 10), 1, 50));
            PTEFieldImportValidations.EvaluateDate(Customer."IRCA Start Date MOD02", PTEFieldImportValidations.GetCellValue(CSVBuffer, LineNo, 11), LineNo);
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
        end;

        Message('Import Complete.\ Records Created: %1\ Records Updated: %2', InsertedCount, UpdatedCount);
    end;
}