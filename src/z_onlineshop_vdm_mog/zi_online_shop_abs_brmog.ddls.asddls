@EndUserText.label: 'Abstract entity for action'
define abstract entity ZI_ONLINE_SHOP_ABS_BRMOG 
{
    OrderUuid       : sysuuid_x16;          
    OrderId         : abap.char(10);  
    OrderedItem     : abap.char(10);  
    DeliveryDate    : abap.dats;               
    CreationDate    : abap.dats;               
    PackageId       : abap.int1;               
    CostCenter: abap.char(10);
}
