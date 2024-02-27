CLASS lhc_Online_Shop DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Online_Shop RESULT result.

    METHODS create_pr FOR MODIFY
      IMPORTING keys FOR ACTION Online_Shop~create_pr.

*    METHODS set_inforecord FOR MODIFY
*      IMPORTING keys FOR ACTION Online_Shop~set_inforecord.

    METHODS update_inforecord FOR MODIFY
      IMPORTING keys FOR ACTION Online_Shop~update_inforecord.

    METHODS calculate_order_id FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Online_Shop~calculate_order_id.

ENDCLASS.

CLASS lhc_Online_Shop IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create_pr.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
*  if a new package is ordered, trigger a new purchase requisition

      SELECT SINGLE * FROM ZI_PrePackagedItems_MOG WHERE PackageId = @<key>-%param-PackageId INTO @DATA(ls_prepitem).

      MODIFY ENTITIES OF i_purchaserequisitiontp
      ENTITY purchaserequisition
      CREATE FIELDS ( purchaserequisitiontype )
      WITH VALUE #(  ( %cid                    = 'My%CID_1'
                       purchaserequisitiontype = 'NB' ) )
      CREATE BY \_purchaserequisitionitem
      FIELDS ( plant
               purchaserequisitionitemtext
               accountassignmentcategory
               requestedquantity
               baseunit
               purchaserequisitionprice
               purreqnitemcurrency
               materialgroup
               purchasinggroup
               purchasingorganization )
      WITH VALUE #( ( %cid_ref = 'My%CID_1'
                      %target  = VALUE #( ( %cid                            = 'My%ItemCID_1'
                                           plant                           = ls_prepitem-Plant
                                           purchaserequisitionitemtext     = ls_prepitem-PurchaseRequisitionItemText
                                           accountassignmentcategory       = ls_prepitem-AccountAssignmentCategory
                                           requestedquantity               = ls_prepitem-RequestedQuantity
                                           baseunit                        = ls_prepitem-BaseUnit
                                           purchaserequisitionprice        = ls_prepitem-PurchaseRequisitionPrice
                                           purreqnitemcurrency             = ls_prepitem-PurReqnItemCurrency
                                           materialgroup                   = ls_prepitem-MaterialGroup
                                           purchasinggroup                 = ls_prepitem-PurchasingGroup
                                           purchasingorganization          = ls_prepitem-PurchasingOrganization ) ) ) )
      ENTITY purchaserequisitionitem
      CREATE BY \_purchasereqnacctassgmt
      FIELDS ( CostCenter
               GLAccount
               Quantity
               BaseUnit )
      WITH VALUE #( ( %cid_ref = 'My%ItemCID_1'
                      %target  = VALUE #( ( %cid = 'My%CC_1'
                                            CostCenter   = <key>-%param-CostCenter " e.g. 'JMW-COST'
                                            GLAccount    = '0051600000' ) ) ) )
      CREATE BY \_purchasereqnitemtext
      FIELDS ( plainlongtext )
      WITH VALUE #( ( %cid_ref = 'My%ItemCID_1'
                      %target  = VALUE #( (
                                          %cid = 'My%CCT_1'
                                          textobjecttype = 'B01'
                                          language       = 'E'
                                          plainlongtext  = 'item text created from PAAS API XXX'
                                        ) (
                                          %cid = 'My%CCT_2'
                                          textobjecttype = 'B02'
                                          language       = 'E'
                                          plainlongtext  = 'item2 text created from PAAS API XXX'
                                        ) )
              )   )
      REPORTED DATA(ls_pr_reported)
      MAPPED DATA(ls_pr_mapped)
      FAILED DATA(ls_pr_failed).

      zbp_i_online_shop_mog=>cv_pr_mapped = ls_pr_mapped.
    ENDLOOP.

  ENDMETHOD.

*  METHOD set_inforecord.
*  ENDMETHOD.

  METHOD update_inforecord.
    SELECT SINGLE * FROM i_purchasinginforecordtp  WHERE PurchasingInfoRecord = '5300000220' INTO @DATA(ls_data).

* Update an existing info record
    MODIFY ENTITIES OF i_purchasinginforecordtp
           ENTITY purchasinginforecord
           UPDATE SET FIELDS WITH
           VALUE #( ( %key-PurchasingInfoRecord = '5300000220'
                       Supplier                 = ls_data-supplier
                       MaterialGroup            = ls_data-MaterialGroup
                       SupplierMaterialGroup    = ls_data-SupplierMaterialGroup
                       NoDaysReminder1          = '12'
                       PurchasingInfoRecordDesc = 'noDays remainder updated'
                  ) )
             FAILED   DATA(ls_failed_update)
             REPORTED DATA(ls_reported_update)
             MAPPED   DATA(ls_mapped_update).

  ENDMETHOD.

  METHOD calculate_order_id.
    DATA:
      online_shops TYPE TABLE FOR UPDATE zi_online_shop_mog,
      online_shop  TYPE STRUCTURE FOR UPDATE zi_online_shop_mog.

    "Possible to use interval number range

    SELECT MAX( orderId ) FROM zi_online_shop_mog INTO @DATA(max_order_id).

    READ ENTITIES OF zi_online_shop_mog IN LOCAL MODE
       ENTITY Online_Shop
        ALL FIELDS
          WITH CORRESPONDING #( keys )
          RESULT DATA(lt_online_shop_result)
      FAILED    DATA(lt_failed)
      REPORTED  DATA(lt_reported).

    DATA(today) = cl_abap_context_info=>get_system_date( ).

    LOOP AT lt_online_shop_result INTO DATA(online_shop_read).
      max_order_id += 1.

      online_shop               = CORRESPONDING #( online_shop_read ).
      online_shop-orderId      = max_order_id.
      online_shop-CreationDate  = today.
      online_shop-DeliveryDate  = today + 10.
      APPEND online_shop TO online_shops.
    ENDLOOP.

    MODIFY ENTITIES OF zi_online_shop_mog IN LOCAL MODE
    ENTITY Online_Shop UPDATE SET FIELDS WITH online_shops "UPDATE FROM
    MAPPED   DATA(ls_mapped_modify)
    FAILED   DATA(lt_failed_modify)
    REPORTED DATA(lt_reported_modify).

    DATA: lt_create_pr_imp TYPE TABLE FOR ACTION IMPORT  zi_online_shop_mog~create_pr,
          ls_create_pr_imp LIKE LINE OF lt_create_pr_imp.

    LOOP AT lt_online_shop_result INTO DATA(ls_online_shop_result).
      ls_create_pr_imp-OrderUuid = ls_online_shop_result-OrderUuid.
      ls_create_pr_imp-%param = CORRESPONDING #( ls_online_shop_result ).
      APPEND ls_create_pr_imp TO lt_create_pr_imp.
    ENDLOOP.

* if a new package is ordered, trigger a new purchase requisition
    IF lt_failed_modify IS INITIAL.
      MODIFY ENTITIES OF zi_online_shop_mog IN LOCAL MODE
      ENTITY Online_Shop EXECUTE create_pr FROM CORRESPONDING #( lt_create_pr_imp ) "CORRESPONDING #( keys )
      FAILED DATA(lt_pr_failed)
      REPORTED DATA(lt_pr_reported).
    ENDIF.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_ONLINE_SHOP_MOG DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_ONLINE_SHOP_MOG IMPLEMENTATION.

  METHOD save_modified.
    DATA : lt_online_shop_as TYPE STANDARD TABLE OF zshop_as_brmog,
           ls_online_shop_as TYPE                   zshop_as_brmog.
    IF zbp_i_online_shop_mog=>cv_pr_mapped-purchaserequisition IS NOT INITIAL.
      LOOP AT zbp_i_online_shop_mog=>cv_pr_mapped-purchaserequisition ASSIGNING FIELD-SYMBOL(<fs_pr_mapped>).
        CONVERT KEY OF i_purchaserequisitiontp FROM <fs_pr_mapped>-%pid TO DATA(ls_pr_key).
        <fs_pr_mapped>-purchaserequisition = ls_pr_key-purchaserequisition.
      ENDLOOP.
    ENDIF.

    IF create-online_shop IS NOT INITIAL.
      " Creates internal table with instance data
      lt_online_shop_as = CORRESPONDING #( create-online_shop ).
      lt_online_shop_as[ 1 ]-order_uuid     = create-online_shop[ 1 ]-OrderUuid.
      lt_online_shop_as[ 1 ]-purchasereqn   = ls_pr_key-purchaserequisition .

      INSERT zshop_as_brmog FROM TABLE @lt_online_shop_as.
    ENDIF.

  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
