@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Data Model to Online Shop'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel: { 
    representativeKey: 'OrderUuid',
    semanticKey: [ 'OrderUuid' ],
    usageType: {
        serviceQuality: #X,
        sizeCategory: #S,
        dataClass: #TRANSACTIONAL 
    }
}
define view entity ZI_SHOP_AS_BRMOG as select from zshop_as_brmog

    association [1] to ZI_ONLINE_SHOP_MOG            as _OnlineShop
        on  $projection.OrderUuid                       = _OnlineShop.OrderUuid

{
    key order_uuid  as OrderUuid,
    purchasereqn    as PurchaseRequisitionNumber,
    purinforecord   as PurchaseInfoRecord,
    purorder        as PuchaseOrder,
    costcenter      as CostCenter, 
    
    _OnlineShop
}
