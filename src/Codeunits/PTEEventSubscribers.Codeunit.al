/// <summary>
/// Codeunit PTEEventSubscribers (ID 50145).
/// </summary>
codeunit 50145 PTEEventSubscribers
{
    /// <summary>
    /// OnBeforeCheckShipmentDateBeforeWorkDate.
    /// </summary>
    /// <param name="IsHandled">VAR Boolean.</param>
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeCheckShipmentDateBeforeWorkDate', '', false, false)]
    local procedure OnBeforeCheckShipmentDateBeforeWorkDate(var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;
}