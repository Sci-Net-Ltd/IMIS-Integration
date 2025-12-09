/// <summary>
/// Pageextension PTECashReceiptJournalExt (ID 50147) extends Page Sales Invoice List.
/// </summary>
pageextension 50147 PTECashReceiptJournalExt extends "Cash Receipt Journal"
{
    actions
    {
        addlast(processing)
        {
            action(ImportPayments)
            {
                Caption = 'Import IMIS Payments';
                ToolTip = 'Import IMIS payments data from a CSV file.';
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = ImportExcel;

                trigger OnAction()
                var
                    PaymentImportMgmt: Codeunit PTEPaymentImportMgmt;
                begin
                    PaymentImportMgmt.ImportPayments(Rec."Journal Template Name", Rec."Journal Batch Name");
                end;
            }
        }
    }
}