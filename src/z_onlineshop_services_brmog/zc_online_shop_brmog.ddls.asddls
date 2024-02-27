@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection view for online shop'
@Metadata.allowExtensions: true
@ObjectModel: { 
    representativeKey: 'OrderUuid',
    semanticKey: [ 'OrderUuid' ],
    usageType: {
        serviceQuality: #X,
        sizeCategory: #S,
        dataClass: #TRANSACTIONAL 
    }
}
define root view entity ZC_ONLINE_SHOP_BRMOG
provider contract transactional_query 
as projection on  ZI_ONLINE_SHOP_MOG
{
    key OrderUuid,
    OrderId,
    OrderedItem,
    DeliveryDate,
    CreationDate,
    PackageId,
    CostCenter,
    _Shop.PurchaseRequisitionNumber,
    
    /* Associations */
    _PrePackageItems, 
    _Shop
    
}
