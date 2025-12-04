/// <summary>
/// Pageextension PTECustomerListExt (ID 50149) extends Page Customer List.
/// </summary>
pageextension 50149 PTECustomerListExt extends "Customer List"
{
    actions
    {
        addlast(processing)
        {
            action(ImportCustomers)
            {
                Caption = 'Import IMIS Customers';
                ToolTip = 'Import IMIS customer data from a CSV file. Updates existing customers or creates new ones.';
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = ImportExcel;

                trigger OnAction()
                var
                    CustImportMgmt: Codeunit PTECustomerImportMgt;
                begin
                    CustImportMgmt.ImportCustomersFromCSV();
                end;
            }
        }
    }
}