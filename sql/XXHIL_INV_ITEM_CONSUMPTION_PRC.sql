SET DEFINE OFF;
--
-- XXHIL_INV_ITEM_CONSUMPTION_PRC  (Procedure) 
--
/***********************************************************************************

    Procedure to get RM items consumption for Dashbaord
   
    
*/
--
CREATE OR REPLACE PROCEDURE APPS.XXHIL_INV_ITEM_CONSUMPTION_PRC
                        ( errbuf out varchar2,
                          retcode out number,
                          P_delete_flag varchar2,
                          P_incremental_flag    varchar2)
is


 cursor c2 (p_item_code varchar2, in_org_id number)is
 select INVENTORY_ITEM_ID,
    item_code ,
    TRANSACTION_DATE Consumption_date,
    TRANSACTION_UOM,
    OPERATING_UNIT,
     sum(open_qty) open_qty ,
    sum(issue_QUANTITY) issue_QUANTITY,
    sum(RECEIPT_QTY )RECEIPT_QTY
    from (
SELECT msi.INVENTORY_ITEM_ID,
       msi.segment1 item_code ,
--       DESCRIPTION,
       trunc(TRANSACTION_DATE) TRANSACTION_DATE,
       decode(TO_CHAR(trunc(TRANSACTION_DATE),'DD-MON-RRRR'), '01-DEC-2022', 500,0) open_qty,
       (sum(TRANSACTION_QUANTITY))*-1 issue_QUANTITY,
       0 RECEIPT_QTY,
       TRANSACTION_UOM,
         ood.OPERATING_UNIT
--      , t.*
  FROM mtl_material_transactions t,
  MTL_system_items msi,
  org_organization_definitions ood
 WHERE     1 = 1
       AND msi.INVENTORY_ITEM_ID = t.INVENTORY_ITEM_ID
       AND t.ORGANIZATION_ID = msi.ORGANIZATION_ID
       and TRANSACTION_TYPE_ID in (35  --WIP Issue
                                  , 43 -- WIP Return
                                  ,32 --Miscellaneous issue
                                  )
        and t.ORGANIZATION_ID = ood.ORGANIZATION_ID
       and OPERATING_UNIT =  in_org_id
--       and t.ORGANIZATION_ID=inv_ORG_ID
        and msi.segment1 =p_item_code
          AND TRANSACTION_DATE >=    '01-nov-2022'
           AND trunc(TRANSACTION_DATE)<trunc(sysdate)
group by msi.INVENTORY_ITEM_ID,
       msi.segment1,
        trunc(TRANSACTION_DATE),--to_char(TRANSACTION_DATE),
         TRANSACTION_UOM,
          ood.OPERATING_UNIT
--order by 3
union all
SELECT msi.INVENTORY_ITEM_ID,
       msi.segment1,
--       DESCRIPTION,
       trunc(TRANSACTION_DATE) TRANSACTION_DATE,
       0,
       0 TRANSACTION_QUANTITY,
       (sum(TRANSACTION_QUANTITY)) RECEIPT_QTY  ,
       TRANSACTION_UOM,
    OPERATING_UNIT
  FROM mtl_material_transactions t,
   MTL_system_items msi,
   org_organization_definitions ood
 WHERE     1 = 1
       AND msi.INVENTORY_ITEM_ID = t.INVENTORY_ITEM_ID
       AND t.ORGANIZATION_ID = msi.ORGANIZATION_ID
       and TRANSACTION_TYPE_ID in (18  --PO receipt
                                   ,36  --Return to Vendor
                                   ,42  --Miscellaneous receipt
                                    )
       and t.ORGANIZATION_ID = ood.ORGANIZATION_ID
       and ood.ORGANIZATION_CODE like 'A%' ---(RM org code for receipt )
        and OPERATING_UNIT =  in_org_id
        and msi.segment1 =p_item_code
--       and msi.segment1 IN ('503042000006'   , '123523160005'      )
          AND TRANSACTION_DATE >=    '01-nov-2022'
           AND trunc(TRANSACTION_DATE)<trunc(sysdate)
group by msi.INVENTORY_ITEM_ID,
       msi.segment1,
        trunc(TRANSACTION_DATE),
         TRANSACTION_UOM,
--         SUBINVENTORY_CODE,
--         t.ORGANIZATION_ID,
         OPERATING_UNIT
         ) a
--         where a.TRANSACTION_DATE='31-dec-2022'
--       where item_code='503042000006'
 group by INVENTORY_ITEM_ID,
    item_code ,
    TRANSACTION_DATE ,
    TRANSACTION_UOM,
    OPERATING_UNIT
            order by 3, 2;

cursor blend_c2 (p_item_code varchar2, in_org_id number)is
 select INVENTORY_ITEM_ID,
    item_code ,
    TRANSACTION_DATE Consumption_date,
    TRANSACTION_UOM,
    OPERATING_UNIT,
     sum(open_qty) open_qty ,
    sum(issue_QUANTITY) issue_QUANTITY,
    sum(RECEIPT_QTY )RECEIPT_QTY
    from (
SELECT msi.INVENTORY_ITEM_ID,
       msi.segment1 item_code ,
--       DESCRIPTION,
       trunc(TRANSACTION_DATE) TRANSACTION_DATE,
       decode(TO_CHAR(trunc(TRANSACTION_DATE),'DD-MON-RRRR'), '01-DEC-2022', 500,0) open_qty,
       (sum(TRANSACTION_QUANTITY))*-1 issue_QUANTITY,
       0 RECEIPT_QTY,
       TRANSACTION_UOM,
         ood.OPERATING_UNIT
--      , t.*
  FROM mtl_material_transactions t,
  MTL_system_items msi,
  org_organization_definitions ood
 WHERE     1 = 1
       AND msi.INVENTORY_ITEM_ID = t.INVENTORY_ITEM_ID
       AND t.ORGANIZATION_ID = msi.ORGANIZATION_ID
       and TRANSACTION_TYPE_ID in (35, 43)
        and t.ORGANIZATION_ID = ood.ORGANIZATION_ID
--        and t.ORGANIZATION_ID=inv_ORG_ID
       and OPERATING_UNIT =  in_org_id
        and msi.segment1 ='CAUSTIC'
          AND TRANSACTION_DATE >=    '01-nov-2022'
           AND trunc(TRANSACTION_DATE)<trunc(sysdate)
group by msi.INVENTORY_ITEM_ID,
       msi.segment1,
        trunc(TRANSACTION_DATE),--to_char(TRANSACTION_DATE),
         TRANSACTION_UOM,
          ood.OPERATING_UNIT
--order by 3
union all
SELECT  670587 INVENTORY_ITEM_ID,
      'CAUSTIC',
--       DESCRIPTION,
       trunc(TRANSACTION_DATE) TRANSACTION_DATE,
       0,
       0 TRANSACTION_QUANTITY,
       (sum(TRANSACTION_QUANTITY)) RECEIPT_QTY  ,
       'DMT' TRANSACTION_UOM,
    OPERATING_UNIT
  FROM mtl_material_transactions t,
   MTL_system_items msi,
   org_organization_definitions ood
 WHERE     1 = 1
       AND msi.INVENTORY_ITEM_ID = t.INVENTORY_ITEM_ID
       AND t.ORGANIZATION_ID = msi.ORGANIZATION_ID
       and TRANSACTION_TYPE_ID in (18  --PO receipt
                                   ,36  --Return to Vendor
                                   ,42  --Miscellaneous receipt
                                    )
       and t.ORGANIZATION_ID = ood.ORGANIZATION_ID
        and OPERATING_UNIT =  in_org_id
         and ood.ORGANIZATION_CODE like 'A%' ---(RM org code for receipt )
        and msi.segment1 in('123523160005' , '123523160002' )
          AND TRANSACTION_DATE >=    '01-nov-2022'
           AND trunc(TRANSACTION_DATE)<trunc(sysdate)
group by msi.INVENTORY_ITEM_ID,
       msi.segment1,
        trunc(TRANSACTION_DATE),
         TRANSACTION_UOM,
--         SUBINVENTORY_CODE,
--         t.ORGANIZATION_ID,
         OPERATING_UNIT
         ) a
--         where a.TRANSACTION_DATE='31-dec-2022'
--       where item_code='503042000006'
 group by INVENTORY_ITEM_ID,
    item_code ,
    TRANSACTION_DATE ,
    TRANSACTION_UOM,
    OPERATING_UNIT
            order by 3, 2;

    cursor item_cur is
    SELECT DESCRIPTION item_code, TAG, ORGANIZATION_ID org_id,
    attribute1 open_qty,
    attribute2 safety_stock,
    attribute3  AVG_CONSUMPTION_QTY
 FROM  FND_LOOKUP_VALUES_VL V ,
 HR_OPERATING_UNITS ou
WHERE LOOKUP_TYPE ='XXHIL_INV_CONSUMPTION_LK'
and   ATTRIBUTE_CATEGORY='XXHIL_INV_CONSUMPTION'
and ou.name =tag
AND ENABLED_FLAG='Y'
and TRUNC (SYSDATE) BETWEEN START_DATE_ACTIVE AND NVL(END_DATE_ACTIVE, TRUNC( SYSDATE))
order by tag, DESCRIPTION,to_number(attribute4)  ;
   Cursor project_PO_qnt (p_item_code varchar2, in_org_id number )is
    SELECT poh.ORG_ID,
       poh.PO_HEADER_ID,
       pol.PO_LINE_ID,
       pll.LINE_LOCATION_ID,
       POH.TYPE_LOOKUP_CODE PO_TYPE,
          poh.SEGMENT1
       || (SELECT DECODE (poh.TYPE_LOOKUP_CODE,
                          'BLANKET', '-' || por.release_num,
                          NULL)
             FROM po_releases por
            WHERE     por.po_header_id = poh.po_header_id
                  AND por.PO_RELEASE_ID = pll.PO_RELEASE_ID)
          PO_NUMBER,
       (SELECT vendor_name
          FROM ap_suppliers aps
         WHERE aps.vendor_id = poh.vendor_id)
          supplier_name,
       pol.item_id INVENTORY_ITEM_ID,
       MSI.segment1  ITEM_code,
       pol.line_num,
       pol.UNIT_MEAS_LOOKUP_CODE UNIT_MEAS_LOOKUP_CODE,
       NVL (pll.QUANTITY, 0) PROMISE_QTY,
       (  NVL (pll.QUANTITY, 0)
        - (NVL (QUANTITY_RECEIVED, 0) - NVL (QUANTITY_CANCELLED, 0)))
          quantity_due,
       pll.PROMISED_DATE PROMISED_DATE,
       --       nvl(pll.QUANTITY_REJECTED,0) REJECTED_QTY,
       pll.QUANTITY_RECEIVED,
       --       pll.LINE_LOCATION_ID,
       pll.SHIP_TO_ORGANIZATION_ID
  FROM po_headers_all poh,
        po_lines_all pol,
         po_line_locations_all pll,
         mtl_system_items msi
 WHERE     1 = 1
       AND (   (NVL (pll.INSPECTION_REQUIRED_FLAG, 'N') = 'Y')
            OR (NVL (pll.INSPECTION_REQUIRED_FLAG, 'N') <> 'Y'))
       AND (PLL.PROMISED_DATE) BETWEEN trunc(SYSDATE ) AND trunc(SYSDATE )+30
       AND NVL (pll.quantity_cancelled, 0) = 0
       AND pll.PO_HEADER_ID = pol.PO_HEADER_ID
       AND pol.PO_LINE_ID = pll.po_line_id
       AND NVL (pol.CANCEL_FLAG, 'N') = 'N'
       AND pol.PO_HEADER_ID = poh.PO_HEADER_ID
       AND NVL (poh.CANCEL_FLAG, 'N') = 'N'
       AND (   poh.AUTHORIZATION_STATUS = 'APPROVED' --'APPROVED'--'INCOMPLETE'
            OR (    poh.AUTHORIZATION_STATUS <> 'APPROVED'
                AND pll.QUANTITY_RECEIVED > 0))
        and msi.inventory_item_id=  pol.item_id
        AND msi.ORGANIZATION_ID = pll.SHIP_TO_ORGANIZATION_ID
        and msi.segment1=  p_item_code
       AND poh.org_id = in_org_id
       AND poh.TYPE_LOOKUP_CODE IN ('BLANKET', 'CONTRACT', 'STANDARD');

Cursor project_PO_BLEND (p_item_code varchar2, in_org_id number )is
    SELECT poh.ORG_ID,
       poh.PO_HEADER_ID,
       pol.PO_LINE_ID,
       pll.LINE_LOCATION_ID,
       POH.TYPE_LOOKUP_CODE PO_TYPE,
          poh.SEGMENT1
       || (SELECT DECODE (poh.TYPE_LOOKUP_CODE,
                          'BLANKET', '-' || por.release_num,
                          NULL)
             FROM po_releases por
            WHERE     por.po_header_id = poh.po_header_id
                  AND por.PO_RELEASE_ID = pll.PO_RELEASE_ID)
          PO_NUMBER,
       (SELECT vendor_name
          FROM ap_suppliers aps
         WHERE aps.vendor_id = poh.vendor_id)
          supplier_name,
       670587 INVENTORY_ITEM_ID,
       MSI.segment1  ITEM_code,
       pol.line_num,
       pol.UNIT_MEAS_LOOKUP_CODE UNIT_MEAS_LOOKUP_CODE,
       NVL (pll.QUANTITY, 0) PROMISE_QTY,
       (  NVL (pll.QUANTITY, 0)
        - (NVL (QUANTITY_RECEIVED, 0) - NVL (QUANTITY_CANCELLED, 0)))
          quantity_due,
       pll.PROMISED_DATE PROMISED_DATE,
       --       nvl(pll.QUANTITY_REJECTED,0) REJECTED_QTY,
       pll.QUANTITY_RECEIVED,
       --       pll.LINE_LOCATION_ID,
       pll.SHIP_TO_ORGANIZATION_ID
  FROM po_headers_all poh,
        po_lines_all pol,
         po_line_locations_all pll,
         mtl_system_items msi
 WHERE     1 = 1
       AND (   (NVL (pll.INSPECTION_REQUIRED_FLAG, 'N') = 'Y')
            OR (NVL (pll.INSPECTION_REQUIRED_FLAG, 'N') <> 'Y'))
       AND (PLL.PROMISED_DATE) BETWEEN trunc(SYSDATE ) AND trunc(SYSDATE )+30
       AND NVL (pll.quantity_cancelled, 0) = 0
       AND pll.PO_HEADER_ID = pol.PO_HEADER_ID
       AND pol.PO_LINE_ID = pll.po_line_id
       AND NVL (pol.CANCEL_FLAG, 'N') = 'N'
       AND pol.PO_HEADER_ID = poh.PO_HEADER_ID
       AND NVL (poh.CANCEL_FLAG, 'N') = 'N'
       AND (   poh.AUTHORIZATION_STATUS = 'APPROVED')
        and msi.inventory_item_id=  pol.item_id
        AND msi.ORGANIZATION_ID = pll.SHIP_TO_ORGANIZATION_ID
        and msi.segment1  IN ('123523160005' , '123523160002'  )
--       AND pol.item_id IN (100706, 28777)
       AND poh.org_id = in_org_id
       AND poh.TYPE_LOOKUP_CODE IN ('BLANKET', 'CONTRACT', 'STANDARD');

   l_OPEN_INV_QTY number:=0;
   l_item_code xxhil_inv_item_consumption.item_code%type;
   l_CLOSING_INV_QTY number:=0;
   l_consumption_date  date;
--   l_closing_inv_qty number ;
   l_avg_consumption_qty  number;
   l_quantity_due number;
    l_safety_qty number;
    l_primary_uom    VARCHAR2(20);
   l_user_id         NUMBER := NVL (fnd_global.user_id, 4554);
   l_resp_id         NUMBER := NVL (fnd_profile.VALUE ('RESP_ID'), 20707);
   l_resp_appl_id    NUMBER := NVL (fnd_profile.VALUE ('RESP_APPL_ID'), 201);
   l_login_id        NUMBER := fnd_profile.VALUE ('login_id');
   l_request_id      NUMBER := fnd_global.conc_request_id;
   l_org_id          NUMBER := NVL (fnd_profile.VALUE ('ORG_ID'), 104);
begin
    if P_delete_flag='Y' THEN
        DELETE xxhil_inv_item_consumption;
        DELETE XXHIL_INV_ITEM_PROJECT_PO;
        COMMIT;

    END IF ;
    for r_item in item_cur loop
        l_OPEN_INV_QTY:=r_item.open_qty;
        IF r_item.item_code='CAUSTIC' THEN
            for r1  in blend_c2 (r_item.item_code, r_item.org_id)loop
                l_closing_inv_qty:=l_OPEN_INV_QTY +r1.RECEIPT_QTY-r1.issue_QUANTITY;
            insert into  xxhil_inv_item_consumption
                 (ORG_ID, ITEM_CODE, PRIMARY_UOM, T_DATE, OPEN_INV_QTY,
                    CONSUMPTION_DATE, CONSUMPTION_QTY, AVG_CONSUMPTION_QTY, RECEIPT_QTY, SAFETY_QTY,
                PLANNED_RECEIPTS, CLOSING_INV_QTY, SUBINVENTORY_CODE, ORGANIZATION_CODE, OU_NAME,
                CREATED_BY, CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN,
                REQUEST_ID)
             Values
               (r1.OPERATING_UNIT, r1.ITEM_CODE, r1.TRANSACTION_UOM, r1.CONSUMPTION_DATE, l_OPEN_INV_QTY,
                r1.CONSUMPTION_DATE, r1.ISSUE_QUANTITY, r_item.AVG_CONSUMPTION_QTY, r1.RECEIPT_QTY, r_item.safety_stock,
                NULL, l_CLOSING_INV_QTY, null, null, NULL,
                l_user_id, sysdate, l_user_id, SYSDATE, l_login_id,
                NULL);
                 l_OPEN_INV_QTY:=l_CLOSING_INV_QTY;
            end loop;
          ELSE
            for r1  in c2 (r_item.item_code, r_item.org_id)loop
                l_closing_inv_qty:=l_OPEN_INV_QTY +r1.RECEIPT_QTY-r1.issue_QUANTITY;
            insert into  xxhil_inv_item_consumption
                 (ORG_ID, ITEM_CODE, PRIMARY_UOM, T_DATE, OPEN_INV_QTY,
                    CONSUMPTION_DATE, CONSUMPTION_QTY, AVG_CONSUMPTION_QTY, RECEIPT_QTY, SAFETY_QTY,
                PLANNED_RECEIPTS, CLOSING_INV_QTY, SUBINVENTORY_CODE, ORGANIZATION_CODE, OU_NAME,
                CREATED_BY, CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN,
                REQUEST_ID)
             Values
               (r1.OPERATING_UNIT, r1.ITEM_CODE, r1.TRANSACTION_UOM, r1.CONSUMPTION_DATE, l_OPEN_INV_QTY,
                r1.CONSUMPTION_DATE, r1.ISSUE_QUANTITY, r_item.AVG_CONSUMPTION_QTY, r1.RECEIPT_QTY, r_item.safety_stock,
                NULL, l_CLOSING_INV_QTY, null, null, NULL,
                l_user_id, sysdate, l_user_id, SYSDATE, l_login_id,
                NULL);
                 l_OPEN_INV_QTY:=l_CLOSING_INV_QTY;
            end loop;
          END IF;
    end loop;
    begin
        for r_item in item_cur loop
            IF r_item.item_code='CAUSTIC' THEN
                for r1 in project_PO_BLEND (r_item.item_code, r_item.org_id) loop
                    Insert into APPS.XXHIL_INV_ITEM_PROJECT_PO
                       (ORG_ID, PO_HEADER_ID, PO_LINE_ID, LINE_LOCATION_ID, PO_TYPE,
                        PO_NUMBER, SUPPLIER_NAME, INVENTORY_ITEM_ID, ITEM_CODE, LINE_NUM,
                        UNIT_MEAS_LOOKUP_CODE, PROMISE_QTY, QUANTITY_DUE, PROMISED_DATE,
                        SHIP_TO_ORGANIZATION_ID,
                        CREATED_BY, CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN)
                     Values
                       ( r1.ORG_ID, r1.PO_HEADER_ID, r1.PO_LINE_ID, r1.LINE_LOCATION_ID, r1.PO_TYPE,
                        r1.PO_NUMBER, r1.SUPPLIER_NAME, r1.INVENTORY_ITEM_ID, 'CAUSTIC' , r1.LINE_NUM,
                        r1.UNIT_MEAS_LOOKUP_CODE, r1.PROMISE_QTY, r1.QUANTITY_DUE, r1.PROMISED_DATE,
                        r1.SHIP_TO_ORGANIZATION_ID,
                         l_user_id, sysdate, l_user_id, SYSDATE, l_login_id);
                     END LOOP;
                ELSE
                    for r1 in project_PO_qnt (r_item.item_code, r_item.org_id) loop
                        Insert into APPS.XXHIL_INV_ITEM_PROJECT_PO
                           (ORG_ID, PO_HEADER_ID, PO_LINE_ID, LINE_LOCATION_ID, PO_TYPE,
                            PO_NUMBER, SUPPLIER_NAME, INVENTORY_ITEM_ID, ITEM_CODE, LINE_NUM,
                            UNIT_MEAS_LOOKUP_CODE, PROMISE_QTY, QUANTITY_DUE, PROMISED_DATE,
                            SHIP_TO_ORGANIZATION_ID,
                            CREATED_BY, CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN)
                         Values
                           ( r1.ORG_ID, r1.PO_HEADER_ID, r1.PO_LINE_ID, r1.LINE_LOCATION_ID, r1.PO_TYPE,
                            r1.PO_NUMBER, r1.SUPPLIER_NAME, r1.INVENTORY_ITEM_ID, r1.ITEM_CODE, r1.LINE_NUM,
                            r1.UNIT_MEAS_LOOKUP_CODE, r1.PROMISE_QTY, r1.QUANTITY_DUE, r1.PROMISED_DATE,
                            r1.SHIP_TO_ORGANIZATION_ID,
                             l_user_id, sysdate, l_user_id, SYSDATE, l_login_id);
                    end loop;
               END IF;
         end loop;
    end;
    for r_item in item_cur loop
        begin
            select (CONSUMPTION_DATE),CLOSING_INV_QTY, AVG_CONSUMPTION_QTY,SAFETY_QTY,PRIMARY_UOM
                into l_consumption_date , l_closing_inv_qty, l_avg_consumption_qty, l_safety_qty,l_primary_uom
            from xxhil_inv_item_consumption t
            where  CONSUMPTION_DATE= (select  max(CONSUMPTION_DATE)
                                                            from  xxhil_inv_item_consumption t1
                                                            where  t1.item_code= r_item.item_code
                                                            and   t1.org_id= r_item.org_id)
             and t.item_code= r_item.item_code
            and  t.org_id= r_item.org_id;
            exception
                when others then
                 l_consumption_date:=null;
          end ;
           dbms_output.put_line( 'l_consumption_date '||l_consumption_date);
          if l_consumption_date is not null then
               FOR i IN 1 .. 30
               LOOP
                    l_OPEN_INV_QTY:=l_closing_inv_qty;
                    dbms_output.put_line( 'l_OPEN_INV_QTY '||l_OPEN_INV_QTY);
                    dbms_output.put_line( 'l_closing_inv_qty '||l_closing_inv_qty);
                    begin
                        select sum(QUANTITY_DUE )into l_quantity_due
                          from XXHIL_INV_ITEM_PROJECT_PO
                          where item_code= r_item.item_code
                          and org_id= r_item.org_id
                          and trunc(PROMISED_DATE)=l_consumption_date+i;
                    exception
                        when others then
                           l_quantity_due:=0;
                    end ;
                      l_closing_inv_qty:=l_OPEN_INV_QTY-l_avg_consumption_qty+nvl(l_quantity_due,0);
                   insert into  xxhil_inv_item_consumption
                    (ORG_ID, ITEM_CODE ,  T_DATE, OPEN_INV_QTY,
                    CONSUMPTION_DATE, CONSUMPTION_QTY, AVG_CONSUMPTION_QTY,  SAFETY_QTY,
                     PLANNED_RECEIPTS, CLOSING_INV_QTY,primary_uom,
                     CREATED_BY, CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN)
                    values (r_item.ORG_ID, r_item.ITEM_CODE, l_consumption_date+i, l_OPEN_INV_QTY,
                            null, null, l_avg_consumption_qty, l_safety_qty,
                            l_quantity_due,l_closing_inv_qty,l_primary_uom,
                            l_user_id, sysdate, l_user_id, SYSDATE, l_login_id  );
               END LOOP;
            end if;
    end loop;
--    CONSUMPTION_DATE
end;
/
SHOW ERRORS;
exit;
