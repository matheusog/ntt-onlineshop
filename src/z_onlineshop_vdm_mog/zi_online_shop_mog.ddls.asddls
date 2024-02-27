@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Data model for online shop'
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


/*+[hideWarning] { "IDS" : [ "CARDINALITY_CHECK" ]  } */
define root view entity ZI_ONLINE_SHOP_MOG 
as select from zonlineshop_mog

//composition [1] of ZI_SHOP_AS_BRMOG             as _Shop 
    
association [1..1] to ZI_SHOP_AS_BRMOG          as _Shop 
    on  $projection.OrderUuid                   = _Shop.OrderUuid
  
association [0..1] to ZI_PrePackagedItems_MOG   as _PrePackageItems
    on  $projection.PackageId                   = _PrePackageItems.PackageId
{

  key order_uuid   as OrderUuid             ,
      order_id     as OrderId               ,
      ordereditem  as OrderedItem           ,
      deliverydate as DeliveryDate          ,
      creationdate as CreationDate          ,
      @ObjectModel.foreignKey.association: '_PrePackageItems'
      pkgid        as PackageId             , 
      _Shop.CostCenter                      ,

      /*Associations*/
      _PrePackageItems                      , 
      _Shop
}
