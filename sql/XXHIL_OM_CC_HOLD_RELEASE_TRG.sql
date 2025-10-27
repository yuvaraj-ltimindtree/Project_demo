CREATE OR REPLACE TRIGGER APPS.XXHIL_OM_CC_HOLD_RELEASE_TRG
   Before Update Of RELEASED_FLAG
   On "ONT"."OE_ORDER_HOLDS_ALL#"
   For Each Row
WHEN (
New.RELEASED_FLAG IN ('Y')  --AND NVL(OLD.ATTRIBUTE4,'X') <>'Y'
      )
DECLARE
PRAGMA AUTONOMOUS_TRANSACTION;

LV_HOLD_ID  OE_HOLD_SOURCES_ALL.HOLD_ID%TYPE;
LV_NAME OE_HOLD_DEFINITIONS.NAME%TYPE;
LV_TYPE_CODE OE_HOLD_DEFINITIONS.TYPE_CODE%TYPE;
LV_DESCRIPTION OE_HOLD_DEFINITIONS.DESCRIPTION%TYPE;
V_COUNT NUMBER;
LV_CUSTOMER OE_ORDER_HEADERS_ALL.SOLD_TO_ORG_ID%TYPE;
LV_AGEN_CD XXHIL_OM_CUSTOMER_GRP_V.AGEN_CD%TYPE;
LV_NET_CR_BAL XXHIL_AR_DR_LC_BALANCE_V.AR_UTILIZED_AMT%TYPE;
LV_NET_ORD_ITM_AMT XXHIL_AR_DR_LC_BALANCE_V.AR_UTILIZED_AMT%TYPE;
LV_SBU VARCHAR2(1);
LV_PRODUCT OE_ORDER_LINES_ALl.ORDERED_ITEM%TYPE;
LV_USER_NAME XXHIL_OM_CEDIT_CHK_RELEASE.USER_NAME%TYPE;
LV_USER_ID XXHIL_OM_CEDIT_CHK_RELEASE.USER_ID%TYPE;
LV_USER_NAME_U  FND_USER.USER_NAME%TYPE;
LV_OP_UNIT HR_OPERATING_UNITS.NAME%TYPE;
LV_CC_HOLD_CHECK NUMBER;
LV_CC_CHK       NUMBER;
LV_PAY_TRM    Varchar2(100);
LV_LC_CHECK  Number;
lv_payment_types     Varchar2(100);
lv_lc_exp_date             Date;
lv_line_cancel_flag     Varchar2(32);
LV_CC_HOLD_CNT NUMBER :=0;
lv_QUALIFIER  Varchar2(32);
lv_item_id NUMBER :=0;
LV_ALOC_AMT  NUMBER;
LV_CUR_ALOC_AMT  NUMBER;
l_sanction_term_amount NUMBER;
 l_sbu oe_transaction_types_all.attribute1%type;
 l_sale_category oe_transaction_types_all.attribute2%type;
LV_CUR_book_AMT NUMBER;
LV_allredy_book_AMT number;

BEGIN


BEGIN
select count(*)
into LV_CC_HOLD_CHECK
from XXHIL_OM_TMS_LOOKUP_MASTER where
lookup_code = 'XXHILCCHOLDRELEASE' and NVL(ACTIVE_IND,'N') ='Y' and
lookup_type ='XXHIL_OM_REPRICE_CHECK';

EXCEPTION WHEN OTHERS THEN
LV_CC_HOLD_CHECK := null;

END;




BEGIN
select count(*)
into LV_CC_HOLD_CNT
from XXHIL_OM_TMS_LOOKUP_MASTER where
lookup_code = 'XXHILCCHOLDRELEASE' and NVL(ACTIVE_IND,'N') ='Y' and
lookup_type ='XXHIL_OM_REPRICE_CHECK';

EXCEPTION WHEN OTHERS THEN
LV_CC_HOLD_CNT := 0;

END;


IF NVL(LV_CC_HOLD_CNT,0) = 0 THEN
   RETURN;
END IF;


Begin
    Select inventory_item_id
    Into   lv_item_id
    From   oe_order_lines_all
    Where line_id = :new.line_id;
Exception When Others Then
   lv_item_id :=Null;
End;

Begin
select QUALIFIER
into   lv_QUALIFIER
from   apps.xxhil_om_item_attributes_v
where inventory_item_id = lv_item_id
;
Exception when others then lv_QUALIFIER := Null;
End;


if nvl(lv_QUALIFIER,'X') in ( 'COPR','PMRG','BYPR','DAP') then
   return;
end if;



  BEGIN
            SELECT b.attribute1, b.attribute2
              INTO l_sbu, l_sale_category
              FROM oe_order_headers_all a, oe_transaction_types_all b
             WHERE     a.header_id = :new.header_id
                   AND a.order_type_id = b.transaction_type_id
                   AND UPPER (b.context) = 'ORDER';
        EXCEPTION
            WHEN OTHERS
            THEN
                l_sbu := NULL;
                l_sale_category:=NULL;
        END;

if  UPPER (l_sale_category)  IN ('EXPORT' , 'INTERNAL') THEN
    return;
end if;


Begin
    Select   rt.name
    Into         lv_payment_types
    From      oe_order_lines_all oola, ra_terms rt
    Where   oola.payment_term_id = rt.term_id
    And        oola.line_id = :new.line_id
    And        oola.header_id = :new.header_id;
EXCEPTION WHEN OTHERS THEN
   lv_payment_types :=Null;
End;

If (nvl(lv_payment_types,'########') Like '%LC%'  Or nvl(lv_payment_types,'########') Like '%L/C%' Or
 nvl(lv_payment_types,'########') Like '%L\C%')Then
Begin
  Select  Count(*)
  Into        LV_LC_CHECK
  From XXHIL_OM_TMS_LOOKUP_MASTER
  Where lookup_code in (Select user_name from fnd_user where user_id = fnd_global.user_id)
  And      description = 'XXHIL_LC_RELEASE'
  And      NVL(ACTIVE_IND,'N') ='Y'
  And     lookup_type ='XXHIL_OM_REPRICE_CHECK';
EXCEPTION WHEN OTHERS THEN
  LV_LC_CHECK := 0;
End;

    begin
             select distinct hold_id
             into lv_hold_id
             from oe_hold_sources_all
             where hold_entity_id = :new.header_id
             and   hold_source_id =  :new.hold_source_id;
             --AND   HOLD_RELEASE_ID IS NULL;
        exception when others then
            lv_hold_id := null;
        end;

    begin
         select name,type_code,description
         into lv_name,lv_type_code,lv_description
         from oe_hold_definitions
         where hold_id = lv_hold_id;
    exception
        when others then
        lv_name               := null;
        lv_type_code           := null;
        lv_description       := null;
    end;

If lv_name = 'HIL_LC_CHECK_HOLD' Then
Begin
    Select attribute4
    Into      lv_line_cancel_flag
    From   oe_order_lines_all
    Where line_id = :new.line_id;
Exception When Others Then
   lv_line_cancel_flag :=Null;
End;
If nvl(lv_line_cancel_flag,'N') ='N' Then
If Nvl(LV_LC_CHECK,0) <=0 Then
    raise_application_error(-20101, 'ERROR: You Are not authorised to LC Release !');
    Return;
    --ROLLBACK;
End If;
End If;
End If;

   Begin
      Select  trunc(nvl(last_date_of_shipment,expiry_date))
      Into       lv_lc_exp_date
      From    xxhil_om_lc_header
      Where lc_number in (Select lc_number From xxhil_om_ivlexp_lceitm
                                                    Where so_header_id = :new.header_id);
   Exception When Others Then
        lv_lc_exp_date :=Null;
   End;

  If lv_name = 'HIL_LC_CHECK_HOLD' Then
  Begin
    Select attribute4
    Into      lv_line_cancel_flag
    From   oe_order_lines_all
    Where line_id = :new.line_id;
Exception When Others Then
   lv_line_cancel_flag :=Null;
End;
If nvl(lv_line_cancel_flag,'N') ='N' Then
  If nvl(lv_lc_exp_date,'01-Jan-1900') < trunc(sysdate) Then
     raise_application_error(-20101, 'ERROR: You Are not authorised to LC Release !Due to LC already Expired.');
    Return;
  End If;
  End if;
End If;

End If;

/* Credit Check Release    */


Begin
    Select attribute4
    Into      lv_line_cancel_flag
    From   oe_order_lines_all
    Where line_id = :new.line_id;
Exception When Others Then
   lv_line_cancel_flag :=Null;
End;


IF  NVL(lv_line_cancel_flag,'X') <> 'Y' THEN

    If nvl(LV_CC_HOLD_CHECK,0) > 0  then
        IF :NEW.RELEASED_FLAG = 'Y' THEN

            Begin
                    Select  rt.name
                    Into lv_pay_trm
                    From    oe_order_headers_all ooha, oe_order_lines_all oola, ra_terms rt
                    Where ooha.header_id = oola.header_id
                    And      ooha.payment_term_id = rt.term_id
                    And     ooha.header_id =  :NEW.HEADER_ID
                    And     oola.line_id = :NEW.LINE_ID ;
                    --   And     (rt.name like '%LC%' Or rt.name like '%L/C%' Or rt.name like '%L\C%')
                    --  And      oola.flow_status_code = 'AWAITING_SHIPPING'
                    --And      oola.shipment_number = 1
                    --And    ooha.ORDER_NUMBER=2205050105306);
          Exception When No_Data_Found Then
                    lv_pay_trm := null;
          When Others Then
                    lv_pay_trm := null;
          End;
        If (lv_pay_trm not like '%LC%' Or lv_pay_trm not like '%L/C%' Or lv_pay_trm not   like '%L\C%') Then

                Begin
                     Select Distinct hold_id
                     Into lv_hold_id
                     From oe_hold_sources_all
                     Where hold_entity_id = to_char(:new.header_id)
                     And       hold_source_id =  :new.hold_source_id;
                     --And       hold_release_id Is null;
                Exception When Others Then
                    lv_hold_id := NULL;
                End;

                Begin
                     Select name,type_code,description
                     Into lv_name,lv_type_code,lv_description
                     From oe_hold_definitions
                     Where hold_id = lv_hold_id;
                Exception When Others Then
                    lv_name                   := null;
                    lv_type_code         := null;
                    lv_description       := null;
                End;

                If (lv_name = 'HIL Line CC Hold'  Or lv_name = 'HIL Overdue CC Hold'  or lv_name = 'HIL Stop Supply Enforcement CC Hold' ) Then
                      Begin
                           Select  substr(name,1,instr(name, '_', 1)-1)
                           Into lv_op_unit
                           From hr_operating_units
                           Where organization_id= :old.org_id;
                      Exception When No_Data_Found Then
                            lv_op_unit :=null;
                      When Others Then
                           lv_op_unit := null;
                      End;

                      Begin
                           Select substr(ordered_item,1,1)
                           Into lv_product
                           From  oe_order_lines_all
                           Where org_id= :new.org_id
                           And header_id =  :new.header_id
                           And line_id = :new.line_id ;
                      Exception When No_Data_Found Then
                            lv_product := null;
                      When Others Then
                            lv_product := null;
                      End;

                      If lv_product Is Not Null Then
                            Begin
                                 Select user_name
                                  Into lv_user_name_u
                                  From fnd_user
                                  Where user_id = :new.last_updated_by ;
                            Exception When No_Data_Found  Then
                                   lv_user_name_u :=null;
                            End;

                            Begin
                                 Select Distinct b.user_name ,b.user_id
                                 Into lv_user_name ,lv_user_id
                                 From xxhil_om_cedit_chk_release_hdr a,
                                             xxhil_om_cedit_chk_release b
                                 Where a.level_release = b.level_release
                                 And       b.user_id  = :new.last_updated_by
                                 And       b.product  = lv_product
                                 And       trunc(sysdate) between trunc(b.start_date)   and nvl(trunc(b.end_date),trunc(sysdate));
                                 --And zone = lv_op_unit
                                 --And  b.organization_id  = :old.org_id;
                            Exception When No_Data_Found Then
                                 lv_user_name := null;
                                 lv_user_id :=  null;
                            When Others Then
                                 lv_user_name := null;
                                 lv_user_id :=  null;
                            End;

                            If nvl(lv_user_name,'#########') = '#########' Then
                               raise_application_error(-20101, 'ERROR: You are not Authorise to Release Credit Check Hold, Kindly coordinate with Mr Baban Ingawale.!!!');
                               Rollback;
                             --  NULL;
                              -- lv_user_id:=1;
                            End If;

                            -- A.LEVEL_RELEASE ,B.DESCRIPTION,B.ZONE_ID,B.ZONE,  --B.PRODUCT,B.CEDIT_LIMIT_PER,B.CEDIT_LIMIT_AMOUNT,
                            --B.WAREHOUSE,B.OPERATING_UNIT,B.ORGANIZATION_ID,B.START_DATE,B.END_DATE
                      End If;

                      If lv_user_id Is Not Null Then
                            Begin
                                 Select  sold_to_org_id
                                 Into lv_customer
                                 From oe_order_headers_all
                                 Where  org_id  = :old.org_id
                                  And  header_id = :old.header_id;
                           Exception When No_Data_Found Then
                                  lv_customer :=Null;
                           End;

                           Begin
                                 Select Distinct agen_cd
                                 Into lv_agen_cd
                                 From xxhil_om_customer_grp_v
                                 Where agen_account_id = lv_customer;
                           Exception When No_Data_Found Then
                                 lv_agen_cd :=Null;
                           End;





                           Begin
                                Select substr(ltrim(rtrim(ordered_item)),1,1)
                                --,
                                              --nvl(round(ordered_quantity*unit_selling_price,2),0)
                                             -- + nvl((Select sum (unround_tax_amt_trx_curr)
                                                         --   From jai_tax_lines_v
                                                           -- Where     trx_id = :old.header_id
                                                            -- And entity_code like 'OE_ORDER_HEADERS'
                                                            -- And trx_line_id =:old.line_id),0)
                                Into lv_sbu --, lv_net_ord_itm_amt
                                From  oe_order_lines_all
                                Where org_id= :old.org_id
                                 And header_id =  :old.header_id
                                 And line_id = :old.line_id ;
                           Exception When No_Data_Found Then
                             lv_sbu                                   :=Null;
                            -- lv_net_ord_itm_amt     :=Null;
                           End;


                         lv_sbu:= nvl(lv_QUALIFIER,'X') ;

                                l_sanction_term_amount :=
                                                                                    XXHIL_OM_LIB_PKG.GET_EFF_CONTRACT_TERMS (
                                                                                        P_TERM_TYPE    => '67',     --DAP DISTRIBUTION MARGIN DISCOUNT
                                                                                        P_GROUP_CD     =>
                                                                                         xxhil_om_customer_group_fn (lv_agen_cd,
                                                                                                                        TRUNC (SYSDATE)),
                                                                                        p_agen_cd      => lv_agen_cd,
                                                                                        p_billto_id    => NULL,
                                                                                        P_ITEM_ID      => NULL,
                                                                                        P_INTGRD       => NULL,
                                                                                        P_CITY         => NULL,
                                                                                        P_STATE        => NULL,
                                                                                        P_SALE_CATEG   => NULL,
                                                                                        P_EXEC_LOCN    => NULL,
                                                                                        P_FR_DT        => TRUNC (SYSDATE),
                                                                                        P_ORG_ID       => NULL,
                                                                                        P_SBU          => lv_sbu);


                                IF l_sanction_term_amount = 0 THEN

                                 raise_application_error(-20101, 'ERROR: You are not Authorise to Release HIL Stop Supply Enhancement Hold Kindly coordinate with Mr Baban Ingawale.!!!');

                                 Rollback;
                               End If;

                            --- Calculate Already Allocated Amount--
                                              /*   BEGIN
                                                    select round(sum(amount+tax_amount),2)
                                                           INTO LV_ALOC_AMT
                                                                         from
                                                                        (
                                                                          select header_id , line_id , amount
                                                                        , sum(jai.TAX_RATE_PERCENTAGE) tax_rate
                                                                                 , ((amount*sum(jai.TAX_RATE_PERCENTAGE) /100)) tax_amount
                                                                                  from
                                                                                 (
                                                                                     select ooha.header_id,oola.line_id,oola.ORDER_QUANTITY_UOM,
                                                                                           decode(oola.ORDER_QUANTITY_UOM,'MT',
                                                                                           sum(wdd.picked_quantity/1000 * oola.unit_selling_price) ,sum(wdd.picked_quantity * oola.unit_selling_price))amount
                                                                                     from oe_order_headers_all ooha
                                                                                           , oe_order_lines_all oola
                                                                                           , wsh_delivery_details wdd
                                                                                            ,ra_terms_vl ftv
                                                                         where ooha.header_id = oola.header_id
                                                                                           and ooha.sold_to_org_id  = lv_customer --l_cust_acc_id
                                                                                           --and (ooha.INVOICE_TO_ORG_ID = :NBT_BLOCKINVOICE_TO OR :NBT_BLOCKINVOICE_TO IS NULL)
                                                                                           AND (oola.INVENTORY_ITEM_ID,oola.ship_from_org_id) IN (SELECT INVENTORY_ITEM_ID,ORGANIZATION_ID FROM MTL_SYSTEM_ITEMS_B WHERE SUBSTR(SEGMENT1,1,1)= lv_sbu )
                                                                                           and wdd.source_header_id = ooha.header_id
                                                                                            and wdd.source_line_id = oola.line_id
                                                                                           and wdd.released_status = 'Y'
                                                                                           and  ooha.payment_term_id = ftv.term_id
                                                                                           and NVL(ftv.attribute1,'XX') <>'LC'
                                                                                           and  ooha.header_id <>  :old.header_id --945952 --p_order_header_id
                                                                                           and  oola.line_id <> :old.line_id --2081020
                                                                                           GROUP BY ooha.header_id,oola.line_id,oola.ORDER_QUANTITY_UOM
                                                                           ) x
                                                                           , jai_tax_lines_v jai
                                                                           where
                                                                            jai.trx_id  = x.header_id
                                                                           and  jai.trx_line_id = x.line_id
                                                                           and jai.entity_code LIKE 'OE_ORDER_HEADERS'
                                                                            GROUP BY header_id,line_id,amount
                                                                 )    ;
                                                      EXCEPTION WHEN NO_DATA_FOUND THEN
                                                           LV_ALOC_AMT := 0;
                                                       WHEN OTHERS THEN
                                                           LV_ALOC_AMT := 0;
                                                       END;


                                                    BEGIN
                                                     Select NVL(round(SUM(NVL(amount,0)+NVL(tax_amount,0)),2),0)
                                                            INTO   LV_ALOC_AMT
                                                     from
                                                     (
                                                     select   ORG_ID,header_id,line_id,ORDER_QUANTITY_UOM,amount,tax_rate, ((amount*tax_rate) /100) tax_amount
                                                     from
                                                     (
                                                     select  ooha.ORG_ID,ooha.header_id,oola.line_id,oola.ORDER_QUANTITY_UOM,
                                                                                                               decode(oola.ORDER_QUANTITY_UOM,'MT',
                                                                                                               sum(wdd.picked_quantity/1000 * oola.unit_selling_price) ,sum(wdd.picked_quantity * oola.unit_selling_price))amount,
                                                                                                               (select  sum(jai.TAX_RATE_PERCENTAGE)  from  jai_tax_lines_v jai where
                                                                                                                          JAI.ORG_ID=ooha.ORG_ID
                                                                                                                         and jai.trx_id  = ooha.header_id
                                                                                                                         and jai.trx_line_id = oola.line_id
                                                                                                                         and jai.entity_code LIKE 'OE_ORDER_HEADERS')tax_rate
                                                                                                         from oe_order_headers_all ooha
                                                                                                               , oe_order_lines_all oola
                                                                                                               , wsh_delivery_details wdd
                                                                                                                ,ra_terms_vl ftv
                                                                                             where ooha.header_id = oola.header_id
                                                                                                               and ooha.sold_to_org_id  = lv_customer
                                                                                                               --and (ooha.INVOICE_TO_ORG_ID = :NBT_BLOCKINVOICE_TO OR :NBT_BLOCKINVOICE_TO IS NULL)
                                                                                                               AND (oola.INVENTORY_ITEM_ID,oola.ship_from_org_id) IN (SELECT INVENTORY_ITEM_ID,ORGANIZATION_ID FROM MTL_SYSTEM_ITEMS_B WHERE SUBSTR(SEGMENT1,1,1)= lv_sbu)
                                                                                                               and wdd.source_header_id = ooha.header_id
                                                                                                                and wdd.source_line_id = oola.line_id
                                                                                                               and wdd.released_status = 'Y'
                                                                                                               and  ooha.payment_term_id = ftv.term_id
                                                                                                               and NVL(ftv.attribute1,'XX') <>'LC'
                                                                                                              -- and  ooha.header_id <>   :old.header_id --945952 --p_order_header_id
                                                                                                               and  oola.line_id <> :old.line_id  --2081020
                                                                                                               GROUP BY ooha.header_id,oola.line_id,oola.ORDER_QUANTITY_UOM,ooha.ORG_ID
                                                       )
                                                       );
                                                                          EXCEPTION WHEN NO_DATA_FOUND THEN
                                                                               LV_ALOC_AMT := 0;
                                                                           WHEN OTHERS THEN
                                                                               LV_ALOC_AMT := 0;
                                                                           END;



                                                    */

                                -- Current Line Allocation Amount--

                              IF lv_sbu NOT IN ('C','K') THEN


                                BEGIN
                                 Select NVL(round(SUM(NVL(amount,0)+NVL(tax_amount,0)),2),0)
                                        INTO   LV_CUR_ALOC_AMT
                                 from
                                 (
                                 select   ORG_ID,header_id,line_id,ORDER_QUANTITY_UOM,amount,tax_rate, ((amount*tax_rate) /100) tax_amount
                                 from
                                 (
                                 select  ooha.ORG_ID,ooha.header_id,oola.line_id,oola.ORDER_QUANTITY_UOM,
                                                                                           decode(oola.ORDER_QUANTITY_UOM,'MT',
                                                                                           sum(wdd.picked_quantity/1000 * oola.unit_selling_price) ,sum(wdd.picked_quantity * oola.unit_selling_price))amount,
                                                                                           (select  sum(jai.TAX_RATE_PERCENTAGE)  from  jai_tax_lines_v jai where
                                                                                                      JAI.ORG_ID=ooha.ORG_ID
                                                                                                     and jai.trx_id  = ooha.header_id
                                                                                                     and jai.trx_line_id = oola.line_id
                                                                                                     and jai.entity_code LIKE 'OE_ORDER_HEADERS')tax_rate
                                                                                     from oe_order_headers_all ooha
                                                                                           , oe_order_lines_all oola
                                                                                           , wsh_delivery_details wdd
                                                                                            ,ra_terms_vl ftv
                                                                         where ooha.header_id = oola.header_id
                                                                                           and ooha.sold_to_org_id  = lv_customer
                                                                                           --and (ooha.INVOICE_TO_ORG_ID = :NBT_BLOCKINVOICE_TO OR :NBT_BLOCKINVOICE_TO IS NULL)
                                                                                           AND (oola.INVENTORY_ITEM_ID,oola.ship_from_org_id) IN (SELECT INVENTORY_ITEM_ID,ORGANIZATION_ID FROM MTL_SYSTEM_ITEMS_B WHERE SUBSTR(SEGMENT1,1,1)= lv_sbu)
                                                                                           and wdd.source_header_id = ooha.header_id
                                                                                            and wdd.source_line_id = oola.line_id
                                                                                           and wdd.released_status = 'Y'
                                                                                           and  ooha.payment_term_id = ftv.term_id
                                                                                           and NVL(ftv.attribute1,'XX') <>'LC'
                                                                                          and  ooha.header_id =   :old.header_id
                                                                                          and  oola.line_id = :old.line_id
                                                                                           GROUP BY ooha.header_id,oola.line_id,oola.ORDER_QUANTITY_UOM,ooha.ORG_ID
                                   )
                                   );
                                                      EXCEPTION WHEN NO_DATA_FOUND THEN
                                                           LV_CUR_ALOC_AMT := 0;
                                                       WHEN OTHERS THEN
                                                           LV_CUR_ALOC_AMT := 0;
                                                       END;


                                     /*
                                             BEGIN
                                                    select round(sum(amount+tax_amount),2)
                                                           INTO LV_CUR_ALOC_AMT
                                                                         from
                                                                        (
                                                                          select header_id , line_id , amount
                                                                        , sum(jai.TAX_RATE_PERCENTAGE) tax_rate
                                                                                 , ((amount*sum(jai.TAX_RATE_PERCENTAGE) /100)) tax_amount
                                                                                  from
                                                                                 (
                                                                                     select ooha.header_id,oola.line_id,oola.ORDER_QUANTITY_UOM,
                                                                                           decode(oola.ORDER_QUANTITY_UOM,'MT',
                                                                                           sum(wdd.picked_quantity/1000 * oola.unit_selling_price) ,sum(wdd.picked_quantity * oola.unit_selling_price))amount
                                                                                     from oe_order_headers_all ooha
                                                                                           , oe_order_lines_all oola
                                                                                           , wsh_delivery_details wdd
                                                                                            ,ra_terms_vl ftv
                                                                         where ooha.header_id = oola.header_id
                                                                                           and ooha.sold_to_org_id  = lv_customer --l_cust_acc_id
                                                                                           --and (ooha.INVOICE_TO_ORG_ID = :NBT_BLOCKINVOICE_TO OR :NBT_BLOCKINVOICE_TO IS NULL)
                                                                                           AND (oola.INVENTORY_ITEM_ID,oola.ship_from_org_id) IN (SELECT INVENTORY_ITEM_ID,ORGANIZATION_ID FROM MTL_SYSTEM_ITEMS_B WHERE SUBSTR(SEGMENT1,1,1)= lv_sbu )
                                                                                           and wdd.source_header_id = ooha.header_id
                                                                                            and wdd.source_line_id = oola.line_id
                                                                                           and wdd.released_status = 'Y'
                                                                                           and  ooha.payment_term_id = ftv.term_id
                                                                                           and NVL(ftv.attribute1,'XX') <>'LC'
                                                                                           and  ooha.header_id = :old.header_id -- p_order_header_id
                                                                                           and  oola.line_id = :old.line_id-- p_order_line_id
                                                                                           GROUP BY ooha.header_id,oola.line_id,oola.ORDER_QUANTITY_UOM
                                                                           ) x
                                                                           , jai_tax_lines_v jai
                                                                           where
                                                                            jai.trx_id  = x.header_id
                                                                           and  jai.trx_line_id = x.line_id
                                                                           and jai.entity_code LIKE 'OE_ORDER_HEADERS'
                                                                            GROUP BY header_id,line_id,amount
                                                                 )    ;
                                                      EXCEPTION WHEN NO_DATA_FOUND THEN
                                                           LV_CUR_ALOC_AMT := 0;
                                                       when OTHERS THEN
                                                           LV_CUR_ALOC_AMT := 0;
                                                       END;
                                                       */


                                -- End Current Line Allocation Amount--


                       --    lv_net_ord_itm_amt :=  NVL(LV_ALOC_AMT,0)+NVL(LV_CUR_ALOC_AMT,0); --10/01/2024  comment not to consider alredy hold amount
                             lv_net_ord_itm_amt := NVL(LV_CUR_ALOC_AMT,0);


                          --SELECT GET_CREDIT_LIMIT (LV_AGEN_CD,LV_SBU) INTO  LV_NET_CR_BAL FROM DUAL  ;
                          /*   Dated : 22-Dec-2023 */
                          Begin
                              Select xxhil_get_cr_limit_pkg_al.xxhil_get_cr_limit(lv_agen_cd,lv_sbu,null)
                              Into  lv_net_cr_bal From dual ;
                          Exception When No_Data_Found Then
                              lv_net_cr_bal :=Null;
                              when others then
                               lv_net_cr_bal :=Null;
                          End;

                           /*   Dated : 22-Dec-2023 */
                            If nvl(lv_net_ord_itm_amt,0)  >  nvl(lv_net_cr_bal,0)  and  lv_name = 'HIL Line CC Hold'  Then   --LV_NET_ORD_ITM_AMT  PENDING HOW TO CALCULATE
                                --raise_application_error(-20101, 'ERROR: Customer Credit Balance is less than Item Value!'   );
                                   RAISE_APPLICATION_ERROR(-20001, ' ERROR: Customer Credit Balance is less than Item Value! '|| ' Net Gap is :'|| nvl(lv_net_cr_bal,0)|| ' and  Order Line amt is  : '||nvl(lv_net_ord_itm_amt,0));
                                Rollback;
                            End If;


                  ELSE



                        Begin
                              Select xxhil_get_cr_limit_pkg_al.xxhil_get_cr_limit(lv_agen_cd,lv_sbu,null)
                              Into  lv_net_cr_bal From dual ;
                          Exception When No_Data_Found Then
                              lv_net_cr_bal :=0;
                              when others then
                               lv_net_cr_bal :=0;
                          End;

                               /* comment dt 070323  As per Babban call 
                                        BEGIN
                                            SELECT SUM(open_order_value_with_tax)
                                            INTO LV_allredy_book_AMT
                                                FROM
                                              (
                                              select open_order_value_with_tax
                                                from
                                                (
                                              Select ooha.order_number,
                                              sum(decode(ORDER_QUANTITY_UOM,'MT',ORDERED_QUANTITY*1000,ORDERED_QUANTITY))  open_order_quantity,
                                                sum(decode(ORDER_QUANTITY_UOM,'MT',(ORDERED_QUANTITY*1000)*(unit_selling_price/1000),ORDERED_QUANTITY*unit_selling_price))  open_order_value
                                                ,sum(decode(ORDER_QUANTITY_UOM,'MT',(ORDERED_QUANTITY*1000)*(unit_selling_price/1000),ORDERED_QUANTITY*unit_selling_price))
                                             +
                                                (sum(decode(ORDER_QUANTITY_UOM,'MT',(ORDERED_QUANTITY*1000)*(unit_selling_price/1000),ORDERED_QUANTITY*unit_selling_price))
                                                *
                                               (select sum(jai.TAX_RATE_PERCENTAGE)
                                                               from  jai_tax_lines_v jai where oola.header_id =   jai.trx_id and oola.line_id =  jai.trx_line_id  and jai.entity_code LIKE 'OE_ORDER_HEADERS' )/100)open_order_value_with_tax
                                               From oe_order_headers_all ooha, oe_order_lines_all oola,mtl_system_items_b msi, mtl_item_categories mic, mtl_categories mc
                                              Where ooha.header_id = oola.header_id
                                               And      oola.inventory_item_id = msi.inventory_item_id
                                                And      oola.ship_from_org_id = msi.organization_id
                                                And      msi.inventory_item_id = mic.inventory_item_id
                                                And      msi.organization_id = mic.organization_id
                                               And      mic.category_id = mc.category_id
                                               And      mic.category_set_id = 1100000041
                                                And      ooha.sold_to_org_id = lv_customer --25757
                                                And      mc.segment1=  l_sbu --'P'
                                               And      oola.flow_status_code  IN   ( 'AWAITING_SHIPPING','BOOKED')
                                                And      oola.header_id  <>   :old.header_id
                                                and      oola.line_id  <>  :old.line_id
                                                AND      NOT     EXISTS (
                                                                        select header_id , line_id from oe_order_holds_all   A , OE_HOLD_SOURCES_ALL B
                                                                               WHERE A.HOLD_SOURCE_ID  = B.HOLD_SOURCE_ID
                                                                               AND A.header_id = oola.header_id  and A.line_id =oola.line_iD
                                                                               AND HOLD_ID= 1001 AND A.RELEASED_FLAG = 'N'
                                                                               AND HOLD_COMMENT = 'HIL Line CC Hold'
                                                                         )
                                                group by ooha.order_number,oola.header_id ,oola.line_id)
                                             );
                                             EXCEPTION WHEN NO_DATA_FOUND THEN
                                                                               LV_allredy_book_AMT  := 0;
                                                                   WHEN OTHERS THEN
                                                                   -- RAISE_APPLICATION_ERROR(-20001, SQLERRM);

                                                                                LV_allredy_book_AMT  :=0;
                                                END;


                                    */


                                             BEGIN
                                             SELECT SUM(open_order_value_with_tax)
                                                INTO LV_CUR_book_AMT
                                                FROM
                                                (
                                                select open_order_value_with_tax
                                                from
                                                (
                                                Select ooha.order_number,
                                                sum(decode(ORDER_QUANTITY_UOM,'MT',ORDERED_QUANTITY*1000,ORDERED_QUANTITY))  open_order_quantity,
                                                sum(decode(ORDER_QUANTITY_UOM,'MT',(ORDERED_QUANTITY*1000)*(unit_selling_price/1000),ORDERED_QUANTITY*unit_selling_price))  open_order_value
                                                ,sum(decode(ORDER_QUANTITY_UOM,'MT',(ORDERED_QUANTITY*1000)*(unit_selling_price/1000),ORDERED_QUANTITY*unit_selling_price))
                                                +
                                                (sum(decode(ORDER_QUANTITY_UOM,'MT',(ORDERED_QUANTITY*1000)*(unit_selling_price/1000),ORDERED_QUANTITY*unit_selling_price))
                                                *
                                                (select sum(jai.TAX_RATE_PERCENTAGE)
                                                                from  jai_tax_lines_v jai where oola.header_id =   jai.trx_id and oola.line_id =  jai.trx_line_id  and jai.entity_code LIKE 'OE_ORDER_HEADERS' )/100)open_order_value_with_tax
                                                From oe_order_headers_all ooha, oe_order_lines_all oola,mtl_system_items_b msi, mtl_item_categories mic, mtl_categories mc
                                                Where ooha.header_id = oola.header_id
                                                And      oola.inventory_item_id = msi.inventory_item_id
                                                And      oola.ship_from_org_id = msi.organization_id
                                                And      msi.inventory_item_id = mic.inventory_item_id
                                                And      msi.organization_id = mic.organization_id
                                                And      mic.category_id = mc.category_id
                                                And      mic.category_set_id = 1100000041
                                                And      ooha.sold_to_org_id = lv_customer --25757
                                                And      mc.segment1=  l_sbu --'P'
                                                And      oola.flow_status_code  IN ( 'AWAITING_SHIPPING','BOOKED')
                                                And      oola.header_id  =   :old.header_id
                                                and      oola.line_id  =  :old.line_id
                                                group by ooha.order_number,oola.header_id ,oola.line_id)
                                               );
                                                EXCEPTION WHEN NO_DATA_FOUND THEN
                                                                                 LV_CUR_book_AMT  := 0;
                                                                   WHEN OTHERS THEN
                                                                                LV_CUR_book_AMT  := 0;
                                                END;


                                         -- lv_net_ord_itm_amt :=  NVL(LV_CUR_book_AMT,0) +  NVL(LV_allredy_book_AMT,0);
                                          lv_net_ord_itm_amt :=  NVL(LV_CUR_book_AMT,0) ;

                              If nvl(lv_net_ord_itm_amt,0)  >  nvl(lv_net_cr_bal,0)  and  lv_name = 'HIL Line CC Hold'  Then   --LV_NET_ORD_ITM_AMT  PENDING HOW TO CALCULATE
                                --raise_application_error(-20101, 'ERROR: Customer Credit Balance is less than Item Value!'   );
                                   RAISE_APPLICATION_ERROR(-20001, ' ERROR: Customer Credit Balance is less than Item Value! '|| ' Net Gap is :  '|| nvl(lv_net_cr_bal,0)|| '  and   Open  Order Line amt is  : '||nvl(lv_net_ord_itm_amt,0));
                                Rollback;
                            End If;

                      End If;



                 End If;
     End If;
   End If;
 End If;
End If;
End If;
End;
/
show errors;
exit;