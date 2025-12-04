/// <summary>
/// Pageextension PTESalesInvoiceListExt (ID 50148) extends Page Sales Invoice List.
/// </summary>
pageextension 50148 PTESalesInvoiceListExt extends "Sales Invoice List"
{
    actions
    {
        addlast(processing)
        {
            action(ImportSalesOrders)
            {
                Caption = 'Import IMIS Sales Invoices';
                ToolTip = 'Import IMIS Sales Invoices and Lines from a CSV file.';
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = ImportExcel;

                trigger OnAction()
                var
                    SalesImportMgmt: Codeunit PTESalesImportMgmt;
                begin
                    SalesImportMgmt.ImportSalesOrdersFromCSV();
                end;
            }
        }
    }
}