create or replace PACKAGE BODY      XXHIL_INV_ITEM_MIN_MAX_PKG
 /********************************************************************** *
        *
        * FILE NAME:XXHIL_INV_ITEM_MIN_MAX_PKG.pkb
        * 
        *
        * HISTORY
        * =======
        *
        * VERSION DATE        AUTHOR          DESCRIPTION
        * ------- ----------- --------------- ---------------------------------
        * 1.1   21-MAR-2024  SAGAR SONULE     Pakage is already developed added union in 'ins_active_min_max_item' procedure for SR93407

        **********************************************************************/

as   procedure ins_active_min_max_item(
                                      in_org_id             in number
                                      ,in_organization_id    in  number  default     null
                                      ,in_trans_date        in    date default     null
                                     )
as
  cursor item_min_max_cur is
    SELECT INVENTORY_ITEM_ID,
       ORGANIZATION_ID,
       SEGMENT1,
       DESCRIPTION,
       PRIMARY_UNIT_OF_MEASURE,
       LIST_PRICE_PER_UNIT,
       MIN_MINMAX_QUANTITY,
       MAX_MINMAX_QUANTITY,
       (  NVL (PREPROCESSING_LEAD_TIME, 0)
        + NVL (FULL_LEAD_TIME, 0)
        + NVL (POSTPROCESSING_LEAD_TIME, 0)
        + NVL (FIXED_LEAD_TIME, 0)
        + NVL (VARIABLE_LEAD_TIME, 0))
          lead_time,
       msi.INVENTORY_ITEM_STATUS_CODE
  FROM mtl_system_items msi
 WHERE     --INVENTORY_ITEM_STATUS_CODE = 'Active'
       --AND 
       INVENTORY_PLANNING_CODE = 2
       /*AND NVL (MIN_MINMAX_QUANTITY, 0) > 0
       AND NVL (MAX_MINMAX_QUANTITY, 0) > 0
       AND (  NVL (PREPROCESSING_LEAD_TIME, 0)
            + NVL (FULL_LEAD_TIME, 0)
            + NVL (POSTPROCESSING_LEAD_TIME, 0)
            + NVL (FIXED_LEAD_TIME, 0)
            + NVL (VARIABLE_LEAD_TIME, 0)) > 0*/
            and ORGANIZATION_ID in(select ORGANIZATION_ID
                        from org_organization_definitions OOD where  OPERATING_UNIT=in_org_id
                         and ORGANIZATION_ID = nvl( in_organization_id,ORGANIZATION_ID ))

               union --added new union for  ITEM_TYPE in('UDI','PR ITEM(UDI)','ROL')  SR93407 21032024
              SELECT INVENTORY_ITEM_ID,
       ORGANIZATION_ID,
       SEGMENT1,
       DESCRIPTION,
       PRIMARY_UNIT_OF_MEASURE,
       LIST_PRICE_PER_UNIT,
       MIN_MINMAX_QUANTITY,
       MAX_MINMAX_QUANTITY,
       (  NVL (PREPROCESSING_LEAD_TIME, 0)
        + NVL (FULL_LEAD_TIME, 0)
        + NVL (POSTPROCESSING_LEAD_TIME, 0)
        + NVL (FIXED_LEAD_TIME, 0)
        + NVL (VARIABLE_LEAD_TIME, 0))
          lead_time,
       msi.INVENTORY_ITEM_STATUS_CODE
  FROM mtl_system_items msi
 WHERE     --INVENTORY_ITEM_STATUS_CODE = 'Active'
           --and
           ITEM_TYPE in('UDI','PR ITEM(UDI)','ROL') 
            and ORGANIZATION_ID in(select ORGANIZATION_ID
                        from org_organization_definitions OOD where  OPERATING_UNIT=in_org_id
                         and ORGANIZATION_ID = nvl( in_organization_id,ORGANIZATION_ID ))
             AND INVENTORY_PLANNING_CODE <> 2          
                         ;

     TYPE fetch_array IS TABLE OF item_min_max_cur%ROWTYPE;
        s_array fetch_array;
        l_date_frm      DATE;
        l_date_to       DATE;
   begin
        delete  XXHIL_PO_MTL_SYSTEM_ITEMS_GTT;
        delete XXHIL_INV_CONSUMP_DATA_GTT;
        commit;
        OPEN item_min_max_cur;
          LOOP
            FETCH item_min_max_cur BULK COLLECT INTO s_array LIMIT 1000;

            FORALL i IN 1..s_array.COUNT
            INSERT INTO XXHIL_PO_MTL_SYSTEM_ITEMS_GTT VALUES s_array(i);

            EXIT WHEN item_min_max_cur%NOTFOUND;
          END LOOP;
        CLOSE item_min_max_cur;
      dbms_output.put_line( ' Active min max item inserted  ');
      COMMIT;

--      l_date_frm     :=trunc(in_trans_date,'MON');
--      l_date_to      := in_trans_date ;
--      XXHIL_INV_ITEM_MIN_MAX_PKG.INS_ITEM_CONSUMP ( IN_ORG_ID, IN_ORGANIZATION_ID, l_date_frm,l_date_to);
--        dbms_output.put_line('sr :'||1 ||' Consumption Processed for fRM DATE    '||l_date_frm|| 'TO DATE '||l_date_to);
--      for i in 1..11 loop
--        l_date_frm    :=TRUNC(add_months(IN_TRANS_DATE,-i),'MON');
--        l_date_to     := LAST_day(l_date_frm);
----        dbms_output.put_line('sr :'||i ||' v_date '||l_date);
--        XXHIL_INV_ITEM_MIN_MAX_PKG.INS_ITEM_CONSUMP ( IN_ORG_ID, IN_ORGANIZATION_ID, l_date_frm,l_date_to );
--        dbms_output.put_line('sr :'||i ||' Consumption Processed fRM DATE    '||l_date_frm|| 'TO DATE '||l_date_to);
--
--       end loop;
--      COMMIT;
   end  ins_active_min_max_item;
   procedure ins_item_consump(
                                      in_org_id             in number
                                      ,in_organization_id    in  number  default     null
                                      ,in_trans_date_frm     in    date   default     null
                                      ,in_trans_date_to     in    date   default     null
                                     )
   as
    cursor consump_cur is
     /* commneted by sudheer 29/01/20 to remove 11i dependecny
     SELECT /*+ no_expand  parallel (mmt,default) parallel (gcc,default)  */
             /*  to_char(MMT.TRANSACTION_DATE,'DD-MON-RRRR')TRANSACTION_DATE,
               ood.OPERATING_UNIT,
               MMT.ORGANIZATION_ID,
               MMT.INVENTORY_ITEM_ID,
               SUM (MMT.PRIMARY_QUANTITY) TRANSACTION_QUANTITY,
               SUM (MTA.BASE_TRANSACTION_VALUE) val
          FROM MTL_TXN_REQUEST_HEADERS MTRH,
               MTL_TXN_REQUEST_LINES MTRL,
               MTL_TRANSACTION_ACCOUNTS MTA,
               MTL_MATERIAL_TRANSACTIONS MMT,
               CST_ACTIVITIES CA,
               MTL_SYSTEM_ITEMS MSI,
               BOM_DEPARTMENTS BD,
               BOM_RESOURCES BR,
               MTL_TRANSACTION_REASONS MTR,
               MTL_TXN_SOURCE_TYPES MTST,
               MTL_TRANSACTION_TYPES MTT,
               MFG_LOOKUPS LU1,
               MFG_LOOKUPS LU2,
               GL_CODE_COMBINATIONS GCC,
               ORG_ORGANIZATION_DEFINITIONS OOD,
               MTL_ITEM_CATEGORIES_V MIC,
               MTL_CATEGORY_SETS MCS,
               MTL_CATEGORIES MCAT,
               MTL_TRANSACTION_LOT_VAL_V lot
         WHERE     mtrh.header_id(+) = mtrl.header_id
               AND mtrl.LINE_ID(+) = MMT.MOVE_ORDER_LINE_ID
               AND lot.transaction_id(+) = mmt.transaction_id
               AND mcat.CATEGORY_ID = mic.CATEGORY_ID
               AND mcs.CATEGORY_SET_ID = 1
               AND mcs.CATEGORY_SET_ID = mic.CATEGORY_SET_ID
               AND msi.ORGANIZATION_ID = mic.ORGANIZATION_ID
               AND mic.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
               AND BD.DEPARTMENT_ID(+) = MMT.DEPARTMENT_ID
               AND MTR.REASON_ID(+) = MMT.REASON_ID
               AND BR.RESOURCE_ID(+) = MTA.RESOURCE_ID
               AND LU1.LOOKUP_TYPE = 'CST_ACCOUNTING_LINE_TYPE'
               AND LU1.LOOKUP_CODE = MTA.ACCOUNTING_LINE_TYPE
               AND LU2.LOOKUP_CODE(+) = MTA.BASIS_TYPE
               AND LU2.LOOKUP_TYPE(+) = 'CST_BASIS_SHORT'
               AND CA.ACTIVITY_ID(+) = MTA.ACTIVITY_ID
--               AND GCC.SEGMENT4 NOT IN ('4103201',
--                                        '4103202',
--                                        '4103203',
--                                        '4103204',
--                                        '4103205',
--                                        '4301101',
--                                        '4301102',
--                                        '4301105',
--                                        '4301201',
--                                        '4301202',
--                                        '4301203',
--                                        '4303001',
--                                        '4303002',
--                                        '4607701',
--                                        '4607702',
--                                        '4301014')
               AND GCC.CODE_COMBINATION_ID = MTA.REFERENCE_ACCOUNT
               AND MTT.TRANSACTION_TYPE_ID = MMT.TRANSACTION_TYPE_ID
               AND MTST.TRANSACTION_SOURCE_TYPE_ID =
                      MMT.TRANSACTION_SOURCE_TYPE_ID
               AND MTA.transaction_id = MMT.transaction_id
               AND MTA.inventory_item_id = MMT.inventory_item_id
               AND MSI.INVENTORY_ITEM_ID = MMT.INVENTORY_ITEM_ID
               AND MSI.ORGANIZATION_ID = MMT.ORGANIZATION_ID
               --AND TRUNC(MMT.TRANSACTION_DATE) BETWEEN v_fr_mth and  v_to_mth
               AND  MMT.TRANSACTION_DATE >= to_date(in_trans_date_frm||' 00:00:01','dd/MM/RRRR hh24:MI:SS') and MMT.TRANSACTION_DATE <=to_date(in_trans_date_to||' 23:59:59','dd/MM/RRRR hh24:MI:SS')
               AND MMT.ORGANIZATION_ID = ood.ORGANIZATION_ID
               AND MMT.ORGANIZATION_ID = nvl(in_organization_id,mmt.ORGANIZATION_ID )
               AND ood.OPERATING_UNIT = in_org_id
      GROUP BY  to_char(MMT.TRANSACTION_DATE,'DD-MON-RRRR'),
               ood.OPERATING_UNIT,
               MMT.ORGANIZATION_ID,
               MMT.INVENTORY_ITEM_ID ;
--      ORDER BY TRUNC (MMT.TRANSACTION_DATE),
--               MMT.ORGANIZATION_ID
*/
    select  TO_CHAR (MMT.TRANSACTION_DATE, 'DD-MON-RRRR') TRANSACTION_DATE,
        ood.OPERATING_UNIT,
       MMT.ORGANIZATION_ID,
       MMT.INVENTORY_ITEM_ID,
       sum(TRANSACTION_QUANTITY), --SUM (MMT.PRIMARY_QUANTITY) TRANSACTION_QUANTITY ,
       sum(0) val
     from mtl_material_transactions mmt, org_organization_definitions ood
     where     mmt.organization_id = ood.organization_id
       AND  MMT.TRANSACTION_DATE >= to_date(in_trans_date_frm||' 00:00:00','dd/MM/RRRR hh24:MI:SS') and MMT.TRANSACTION_DATE <=to_date(in_trans_date_to||' 23:59:59','dd/MM/RRRR hh24:MI:SS')
--                AND (TRANSACTION_TYPE_ID = 32) --Missc Issue
                AND (TRANSACTION_TYPE_ID in(63,32,64,35))       
                --Move Order Issue  TRANSACTION_TYPE_ID=63           already present Move Order Issue 63 
                --Miscellaneous issue   TRANSACTION_TYPE_ID= 32      added Miscellaneous issue 32 for SR93407 02042024
                --Move Order Transfer  TRANSACTION_TYPE_ID=64        added Move Order Transfer 64 for SR93407 02042024
                --WIP Issue  TRANSACTION_TYPE_ID=35                  added WIP Issue 35 for SR93407 02042024              

               AND MMT.ORGANIZATION_ID = nvl(in_organization_id,mmt.ORGANIZATION_ID )
               AND ood.OPERATING_UNIT = in_org_id
               AND mmt.SUBINVENTORY_CODE in('PR_Item','ROL/MinMax') 
      GROUP BY TO_CHAR (MMT.TRANSACTION_DATE, 'DD-MON-RRRR'),
         ood.OPERATING_UNIT,
         MMT.ORGANIZATION_ID,
         MMT.INVENTORY_ITEM_ID         ;
     TYPE fetch_array IS TABLE OF consump_cur%ROWTYPE;
        s_array fetch_array;
   begin
        begin mo_global.set_policy_context('S',in_org_id); end;
        OPEN consump_cur;
      LOOP
        FETCH consump_cur BULK COLLECT INTO s_array LIMIT 1000;

        FORALL i IN 1..s_array.COUNT
        INSERT INTO XXHIL_INV_CONSUMP_DATA_GTT VALUES s_array(i);

        EXIT WHEN consump_cur%NOTFOUND;
      END LOOP;
      CLOSE consump_cur;
      COMMIT;

   end ins_item_consump;
   FUNCTION HIL_ATTACH_ITEM ( pkval         VARCHAR2,
                           P_ORG_ID     NUMBER,
                           p_ORGANIZATION_CODE VARCHAR2
                        )
   RETURN VARCHAR2
    IS
   text1                 BLOB;
   textNum               INTEGER := 1;
   myfile                UTL_FILE.file_type;
   filename              VARCHAR2 (50);

   sql_str               VARCHAR2 (30000);
   l_delim               VARCHAR2 (1) := ',';
   v_process_date        DATE;

   emesg                 VARCHAR2 (250);
   V_UPLOAD_ID           NUMBER;
   retcode               NUMBER;
   UPLOAD_VALIDATION_ERROR EXCEPTION;



   PROCEDURE print_blob
   IS
      offset   NUMBER;
      len      NUMBER;
      o_buf    VARCHAR2 (10000);
      amount   NUMBER;                                                     --}
      f_amt    NUMBER := 0;                      --}To hold the amount of data
      f_amt2   NUMBER;                          --}to be read or that has been
      amt2     NUMBER := -1;                                           --}read
      TYPE var_array IS TABLE OF VARCHAR2 (300)
         INDEX BY VARCHAR2 (300);
      v_var1   var_array;
      v_Organzation_Code          VARCHAR2(100) ;
    v_Item_Code                 VARCHAR2(100) ;
    V_PLANING_METHOD            VARCHAR2(100) ;
    V_MIN_MINMAX_QUANTITY       VARCHAR2(100) ;
    V_MAX_MINMAX_QUANTITY       VARCHAR2(100) ;
     l_ch_line             VARCHAR2 (30000);
     cnt                   NUMBER := 0;
    v_Item_NAME                 VARCHAR2(500) ;
    v_Item_UOM                  VARCHAR2(500) ;
      l_month1               VARCHAR2(500);
  l_month2              VARCHAR2(500);
  l_month3                VARCHAR2(500);
  l_month4                VARCHAR2(500);
  l_month5                VARCHAR2(500);
  l_month6                VARCHAR2(500);
  l_month7                VARCHAR2(500);
  l_month8                VARCHAR2(500);
  l_month9                VARCHAR2(500);
  l_month10               VARCHAR2(500);
  l_month11               VARCHAR2(500);
  l_month12              VARCHAR2(500);
  l_monthly_average       VARCHAR2(500);
  Tot_months             VARCHAR2(500);
  l_counts_consump_mth    VARCHAR2(500);
  l_lead_time            VARCHAR2(500);
  l_min_qty_current       VARCHAR2(500);
  l_max_qty_current      VARCHAR2(500);
  l_min_qty_proposed      VARCHAR2(500);
  l_max_qty_proposed      VARCHAR2(500);
   BEGIN
      emesg:='1';
      len := DBMS_LOB.GETLENGTH (text1);
      offset := 1;
      WHILE len > 0
      LOOP
        cnt:=cnt+1;
         amount :=
            DBMS_LOB.INSTR (text1,
                            UTL_RAW.cast_to_raw (CHR (13)),
                            offset,
                            1);

         --Amount returned is the count from the start of the file,
         --not from the offset.
         IF amount = 0
         THEN
            --No more linefeeds so need to read remaining data.
            amount := len;
            amt2 := amount;
         ELSE
            f_amt2 := amount;                      --Store position of next LF
            amount := amount - f_amt;             --Calc position from last LF
            f_amt := f_amt2;                    --Store position for next time
            amt2 := amount - 1;                    --Read up to but not the LF
         END IF;

         IF amt2 != 0
         THEN     --If there is a linefeed as the first character then ignore.
            -- DBMS_LOB.READ(utl_raw.cast_to_varchar2(text1),amt2,offset,o_buf);
            DBMS_LOB.READ (text1,
                           amt2,
                           offset,
                           o_buf);

            l_ch_line := UTL_RAW.cast_to_varchar2 (o_buf);

            sql_str := '1';

--               Organization_code
                v_Organzation_Code :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, ',') - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, ',') + 1,
                          LENGTH (l_ch_line));
--                v_Organzation_Code:=translate(v_Organzation_Code,chr(10)||chr(11)||chr(13), '');
                v_Organzation_Code:=trim(translate((translate(v_Organzation_Code, chr(13), chr(32))),chr(10), chr(32))) ;
--              UOM
--                v_Item_UOM :=
--                  TRIM (
--                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (9)) - 1));
--               l_ch_line :=
--                  SUBSTR (l_ch_line,
--                          INSTR (l_ch_line, CHR (9)) + 1,
--                          LENGTH (l_ch_line));

                V_PLANING_METHOD:=2;


--               Item_code
               v_Item_Code :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, ',') - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, ',') + 1,
                          LENGTH (l_ch_line));

--               Item_NAME
               v_Item_NAME :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, ',') - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, ',') + 1,
                          LENGTH (l_ch_line));

--               Item_UOM
               v_Item_UOM :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, ',') - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, ',') + 1,
                          LENGTH (l_ch_line));



--               MAX_QUANTITY
--               V_MAX_MINMAX_QUANTITY :=
--                  TRIM (
--                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line,CHR (44)) - 1));
--               l_ch_line :=
--                  SUBSTR (l_ch_line,
--                          INSTR (l_ch_line, CHR (44)) + 1,
--                          LENGTH (l_ch_line));

                --Month 1
                l_month1  :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));

               --Month 2
                l_month2  :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));

               --Month 1
                l_month3   :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));

               --Month 4
                l_month4  :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));

               --Month 5
                l_month5  :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));

               --Month 6
                l_month6  :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));

               --Month 7
                l_month7   :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));

               --Month 8
                l_month8  :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));

               --Month 9
                l_month9  :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));

               --Month10
                l_month10  :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));

               --Month 11
                l_month11   :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));

               --Month 12
                l_month12  :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));


--              Total for (Considered months)
              Tot_months :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));

               --l_monthly_average
                l_monthly_average   :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));

               --l_counts_consump_mth
                l_counts_consump_mth  :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));

               --l_lead_time
                l_lead_time  :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));
                 l_lead_time:=REGEXP_REPLACE(l_lead_time, '[^0-9]', '');

                --trim(translate((translate(l_lead_time, chr(13), chr(32))),chr(10), chr(32))) ;
               --l_min_qty_current
                l_min_qty_current  :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));

               --l_max_qty_current
                l_max_qty_current   :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));

               --l_min_qty_proposed
                l_min_qty_proposed  :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));

               --l_max_qty_proposed
                l_max_qty_proposed  :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));
                l_max_qty_proposed:=REGEXP_REPLACE(l_max_qty_proposed, '[^0-9]', '');
--               MIN_QUANTITY FINAL
                V_MIN_MINMAX_QUANTITY :=
                  TRIM (
                     SUBSTR (l_ch_line, 1, INSTR (l_ch_line, CHR (44)) - 1));
               l_ch_line :=
                  SUBSTR (l_ch_line,
                          INSTR (l_ch_line, CHR (44)) + 1,
                          LENGTH (l_ch_line));
                 v_min_minmax_quantity:=REGEXP_REPLACE(v_min_minmax_quantity, '[^0-9]', '');
               --               MAX_QUANTITY FINAL
               V_MAX_MINMAX_QUANTITY  := TRIM (SUBSTR (l_ch_line, 1));
--               V_MAX_MINMAX_QUANTITY:=
--                       TRIM (SUBSTR (l_ch_line, 1, INSTR (l_ch_line, ',') - 1));
--               V_MAX_MINMAX_QUANTITY := REPLACE(V_MAX_MINMAX_QUANTITY,CHR(13),NULL);

                v_Organzation_Code := REPLACE(v_Organzation_Code,CHR(13),NULL);
--


              if cnt<>1 and v_Item_Code is not null then
                 begin
                 IF v_Organzation_Code <> p_ORGANIZATION_CODE THEN

                    RAISE_APPLICATION_ERROR('-20001','Organization Not Matched ..Item :'|| v_Item_Code )  ;
                 END IF;

                      INSERT INTO  XXHIL_INV_ITEM_UPDATE_STG
                         (
                         ORGANIZATION_CODE     ,
                         SET_PROCESS_ID         ,
                         TRANSACTION_TYPE       ,
                         ITEM_CODE              ,
                         UOM         ,
                         MIN_MINMAX_QUANTITY    ,
                         MAX_MINMAX_QUANTITY    ,
--                         MINIMUM_ORDER_QUANTITY ,
--                         MAXIMUM_ORDER_QUANTITY ,
                         SOURCE_TYPE_CODE       ,
--                         BUYER_ID               ,
                         CREATED_BY             ,
                         CREATION_DATE          ,
                         REMARK                 ,
                         ERROR_FLAG             ,
                         MONTH1              ,
                          MONTH2              ,
                          MONTH3              ,
                          MONTH4              ,
                          MONTH5              ,
                          MONTH6              ,
                          MONTH7              ,
                          MONTH8              ,
                          MONTH9              ,
                          MONTH10             ,
                          MONTH11             ,
                          MONTH12             ,
                          MONTHLY_AVERAGE     ,
                          COUNTS_CONSUMP_MTH  ,
                          LEAD_TIME           ,
                          MIN_QTY_CURRENT     ,
                          MAX_QTY_CURRENT     ,
                          MIN_QTY_PROPOSED    ,
                          MAX_QTY_PROPOSED
                         )
                        VALUES (v_Organzation_Code ,
                                PKVAL,
                                'UPDATE',
                                v_Item_Code ,
                                v_Item_UOM,
                                V_MIN_MINMAX_QUANTITY,
                                V_MAX_MINMAX_QUANTITY ,
--                                V_MINIMUM_ORDER_QUANTITY,
--                                V_MAXIMUM_ORDER_QUANTITY ,
                                '2',
--                                NULL,
                                FND_GLOBAL.USER_ID,
                                SYSDATE,
                                NULL,
                                NULL    ,
                                  l_month1               ,
                                  l_month2               ,
                                  l_month3               ,
                                  l_month4               ,
                                  l_month5               ,
                                  l_month6               ,
                                  l_month7               ,
                                  l_month8               ,
                                  l_month9               ,
                                  l_month10              ,
                                  l_month11              ,
                                  l_month12              ,
                                  l_monthly_average      ,
                                  l_counts_consump_mth   ,
                                  l_lead_time            ,
                                  l_min_qty_current      ,
                                  l_max_qty_current      ,
                                  l_min_qty_proposed     ,
                                  l_max_qty_proposed
                                );
                EXCEPTION
                   when INVALID_NUMBER then
                            emesg :='Error-> Number format in row number :'||cnt||' ' || SQLERRM;
                            rollback;
                            return ;
                   when DUP_VAL_ON_INDEX then
                            emesg :='Error-> Duplicate Data exists in row number :'||cnt||' ' || SQLERRM;
                            rollback;
                            return ;
                   WHEN VALUE_ERROR     THEN
                      emesg := 'Error-> Value Error in row num :'||cnt||' ' || SQLERRM;
                      rollback;
                      return ;
                   when OTHERS then
                        IF SQLCODE LIKE '%2290%' THEN
                              rollback;
                               emesg :='error value should be greater than 0 or equal in row number : '||cnt||' ' || SQLERRM;
                              RETURN  ;
                        else
                           emesg :='error others in row number :'||cnt||' ' || SQLERRM;
                            rollback;
                            return ;
                      end if;
                END;

             end if;
         END IF;

         len := len - amount;
         offset := offset + amount;

            v_Organzation_Code 		:=null;
            v_Item_Code 			:=null;
            V_MIN_MINMAX_QUANTITY		:=null;
            V_MAX_MINMAX_QUANTITY 		:=null;
              l_month1               :=null;
              l_month2               :=null;
              l_month3               :=null;
              l_month4               :=null;
              l_month5               :=null;
              l_month6               :=null;
              l_month7               :=null;
              l_month8               :=null;
              l_month9               :=null;
              l_month10              :=null;
              l_month11              :=null;
              l_month12              :=null;
              l_monthly_average      :=null;
              l_counts_consump_mth   :=null;
              l_lead_time            :=null;
              l_min_qty_current      :=null;
              l_max_qty_current      :=null;
              l_min_qty_proposed     :=null;
              l_max_qty_proposed 	:=null;
      END LOOP;

      UTL_FILE.fclose (myfile);
   END;
BEGIN
   SELECT file_data,
          SUBSTR (file_name,
                    INSTR (file_name,
                           '/',
                           1,
                           1)
                  + 1)
     INTO text1, filename
     FROM fnd_lobs
    WHERE file_id =
             (SELECT file_id
                FROM fnd_lobs
               WHERE file_id IN (SELECT media_id
                                   FROM fnd_documents
                                  WHERE document_id IN (SELECT document_id
                                                          FROM FND_ATTACHED_DOCUMENTS
                                                         WHERE     entity_name LIKE
                                                                      'XXHIL_INV_ITEM_ATTACH'
                                                               AND PK1_VALUE =
                                                                      pkval)));

   -- DBMS_OUTPUT.PUT_LINE('Size of the text is: ' ||
   -- DBMS_LOB.GETLENGTH(text1));

   print_blob;

   COMMIT;
   RETURN emesg;
EXCEPTION
WHEN OTHERS
   THEN
     emesg := SQLERRM;
   IF SQLCODE LIKE '%20001%' THEN
      rollback;
      RETURN   emesg|| 'Please correct and reload.';
   ELSE
      rollback;
      RETURN   emesg|| 'File Not Loaded Properly';
   END IF;
END HIL_ATTACH_ITEM;

    PROCEDURE xxhil_itemstg_inferface_prg (
        errbuf              OUT NOCOPY VARCHAR2,
        retcode             OUT NOCOPY VARCHAR2,
        p_set_id            NUMBER,
        p_organization_id   NUMBER
    ) IS

        CURSOR citstg IS SELECT
                            *
                        FROM
                            xxhil_inv_item_update_stg itm
                        WHERE
                            set_process_id = p_set_id
                            AND error_flag IS NULL
        FOR UPDATE;

        vitmstg               citstg%rowtype;
        v_organization_id     NUMBER;
        vitem_id              NUMBER;
        verror_flag           VARCHAR2(5) := 'S';
        verror_msg            VARCHAR2(500);
        v_plannign_method     VARCHAR2(50);
        nn_intupload          NUMBER := 0;
        nn_interror           NUMBER := 0;
        nn_totalrce           NUMBER := 0;
        v_imp_request         NUMBER := 0;
        lc_phase              VARCHAR2(50);
        lc_status             VARCHAR2(50);
        lc_dev_phase          VARCHAR2(50);
        lc_dev_status         VARCHAR2(50);
        lc_message            VARCHAR2(50);
        l_req_return_status   BOOLEAN;
        v_buyer_id            NUMBER;
        v_org_id              NUMBER := fnd_profile.value('ORG_ID');
        vintsucess_record     NUMBER;
        vinterror_record      NUMBER;
    BEGIN
        OPEN citstg;
        LOOP
            FETCH citstg INTO vitmstg;
            IF citstg%found THEN
                verror_flag := 'S';
                verror_msg := '';
                nn_totalrce := nvl(nn_totalrce,0) + 1;

     /* Check vaied Organization*/
                BEGIN
                    SELECT
                        organization_id
                    INTO v_organization_id
                    FROM
                        org_organization_definitions od
                    WHERE
                        od.organization_code = vitmstg.organization_code;

                EXCEPTION
                    WHEN OTHERS THEN
                        v_organization_id := '-1';
                        verror_flag := 'E';
                        verror_msg := 'Invalid Organization ';
                END;

      /* Check item Validation*/

                IF v_organization_id <>-1 THEN
                    BEGIN
                        SELECT
                            inventory_item_id
                        INTO vitem_id
                        FROM
                            mtl_system_items_b mtl
                        WHERE
                            mtl.organization_id = v_organization_id
                            AND segment1 = rtrim(ltrim(vitmstg.item_code) );

                    EXCEPTION
                        WHEN OTHERS THEN
                            vitem_id := '';
               vERROR_FLAG :='E';
               vERROR_MSG  := vERROR_MSG||' '|| 'Item Code Note found for in Organization ';
      -- fnd_file.PUT_LINE (fnd_file.LOG, vitmstg.item_code || '  '||'Item Not assign to Organization');
                    END;
                END IF;
                v_buyer_id := xxhil_inv_item_min_max_pkg.get_valid_buyer_id(vitem_id,v_organization_id,v_org_id);
                IF v_buyer_id = 0 THEN
                    v_buyer_id := NULL;
                END IF;
                v_plannign_method := '2';
                IF verror_flag = 'S' THEN
                    INSERT INTO inv.mtl_system_items_interface (
                        process_flag,
                        set_process_id,
                        transaction_type,
                        segment1,
                        organization_id,
                        inventory_planning_code,
                        min_minmax_quantity,
                        max_minmax_quantity,
                        last_update_date,
                        last_updated_by,
                        buyer_id,
                        source_type
                    ) VALUES (
                        '1',
                        p_set_id,
                        'UPDATE',
                        rtrim(ltrim(vitmstg.item_code) ),
                        v_organization_id,
                        2,
                        vitmstg.min_minmax_quantity,
                        vitmstg.max_minmax_quantity,
                        SYSDATE,
                        fnd_global.user_id,
                        v_buyer_id,
                        vitmstg.source_type_code
                    );

                    UPDATE xxhil_inv_item_update_stg x
                    SET
                        error_flag = verror_flag,
                        x.remark = substr(verror_msg,1,500)
                    WHERE
                        CURRENT OF citstg;

                    nn_intupload := nvl(nn_intupload + 1,0);
                ELSE
                    UPDATE xxhil_inv_item_update_stg x
                    SET
                        error_flag = verror_flag,
                        x.remark = substr(verror_msg,1,500)
                    WHERE
                        CURRENT OF citstg;

                    nn_interror := nvl(nn_interror + 1,0);
                END IF;

            ELSE
                EXIT;
            END IF;

        END LOOP;

        CLOSE citstg;
        IF nn_totalrce = 0 THEN
--Raise_Application_Error('-20001','Error No data found for Proceess');
            fnd_file.put_line(fnd_file.log,'No Data found for upload');
        END IF;

        fnd_file.put_line(fnd_file.log,'P_SET_ID : ' || p_set_id);
        fnd_file.new_line(fnd_file.log);
        fnd_file.put_line(fnd_file.log,'Total Record found to update :  ' || nn_totalrce);
        fnd_file.new_line(fnd_file.log);
        fnd_file.put_line(fnd_file.log,'No of Record Uploaded into IntreFace Table  ' || nn_intupload);
        fnd_file.new_line(fnd_file.log);
        fnd_file.put_line(fnd_file.log,'Error  Uploaded into IntreFace Table invalid data  ' || nn_interror);
        fnd_file.new_line(fnd_file.log);
        IF nn_totalrce > 0 THEN
            v_imp_request := xxhil_call_itm_incoin(p_set_id,p_organization_id);
            fnd_file.put_line(fnd_file.log,'Item Import Called  Request ID :' || v_imp_request);
        END IF;

        IF v_imp_request > 0 THEN
            l_req_return_status := fnd_concurrent.wait_for_request(request_id => v_imp_request,INTERVAL => 20,   /*  default value - sleep time in secs, PUT THE VALUE BASED ON YOUR REQUEST COMPLETION TIME*/max_wait => 0,    /* default value - max wait in secs,0 means indefinite time */phase => lc_phase,status => lc_status,dev_phase => lc_dev_phase,dev_status => lc_dev_status,message => lc_message);

            COMMIT;
        END IF;

        fnd_file.put_line(fnd_file.log,'Item UPDATE Completed');
        fnd_file.new_line(fnd_file.log);
        fnd_file.new_line(fnd_file.log);
        BEGIN
            BEGIN
                SELECT
                    COUNT(*)
                INTO vintsucess_record
                FROM
                    mtl_system_items_interface a
                WHERE
                    a.set_process_id = p_set_id
                    AND a.process_flag = 7;

            EXCEPTION
                WHEN OTHERS THEN
                    vintsucess_record := 0;
            END;

            BEGIN
                SELECT
                    COUNT(*)
                INTO vinterror_record
                FROM
                    mtl_system_items_interface a
                WHERE
                    a.set_process_id = p_set_id
                    AND a.process_flag != 7;

            EXCEPTION
                WHEN OTHERS THEN
                    vinterror_record := 0;
            END;

            fnd_file.put_line(fnd_file.log,'Successfully Updated : ' || vintsucess_record);
            fnd_file.put_line(fnd_file.log,'Error In Interface   : ' || vinterror_record);
        END;

        IF nvl(vinterror_record,0) > 0 THEN
            DECLARE
                CURSOR cerror IS SELECT DISTINCT
                                     replace(rpad(a.segment1,30)
                                               || b.error_message,CHR(10),'') error_desc
                                 FROM
                                     mtl_system_items_interface a,
                                     mtl_interface_errors b
                                 WHERE
                                     a.transaction_id = b.transaction_id
                                     AND a.set_process_id = p_set_id
                                     AND a.process_flag <> 7;

            BEGIN
                fnd_file.put_line(fnd_file.log,'============================================================================================================'
                );
                fnd_file.put_line(fnd_file.log,rpad('Item ',30)
                                                 || 'Error Detail');

                fnd_file.put_line(fnd_file.log,'============================================================================================================='

                );
                FOR i IN cerror LOOP
                    fnd_file.put_line(fnd_file.log,i.error_desc);
                    fnd_file.new_line(fnd_file.log);
                END LOOP;

            END;
        END IF;

    END;
function XXHIL_CALL_ITM_INCOIN(P_SET_ID number,P_ORGANIZATION_ID number)
RETURN NUMBER IS
    v_request_id NUMBER;
    err_msg      VARCHAR2(100);
  BEGIN
    v_request_id := fnd_request.submit_request('INV',
                                               'INCOIN',
                                                NULL,
                                                SYSDATE,
                                                FALSE,
                                                P_ORGANIZATION_ID,
                                               '2',
                                               '1',
                                               '1',
                                               '2',
                                               P_SET_ID,
                                               '2',
                                               CHR(0),
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '',
                                               '');

    if v_request_id != 0 then
      COMMIT;
      return v_request_id;
    else
      err_msg := 'Request Not Created for the Programm HILRTGSANXAAL';
      return 0;
      --raise submit_failed;
    end if;

  END XXHIL_CALL_ITM_INCOIN;

    FUNCTION get_valid_buyer_id (
        p_item_id           NUMBER,
        p_organization_id   NUMBER,
        p_org_id            NUMBER
    ) RETURN NUMBER IS
        v_default_buyer   NUMBER := 0;
    BEGIN
        BEGIN
            SELECT
                buyer_id
            INTO v_default_buyer
            FROM
                mtl_system_items_b a,
                po_buyers_val_v b
            WHERE
                a.inventory_item_id = p_item_id
                AND a.organization_id = p_organization_id
                AND a.buyer_id = b.employee_id
                AND ROWNUM = 1;

        EXCEPTION
            WHEN OTHERS THEN
                v_default_buyer := 0;
        END;

        IF v_default_buyer = 0 THEN
            SELECT
                employee_id
            INTO v_default_buyer
            FROM
                fnd_lookup_values a,
                fnd_user fu
            WHERE
                a.lookup_type = 'BPS_DEFAULT_BUYER'
                AND a.meaning = fu.user_name
                AND lookup_code = p_org_id
                AND nvl(a.enabled_flag,'N') = 'Y';

        END IF;

        RETURN v_default_buyer;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN v_default_buyer;
    END get_valid_buyer_id;
end  xxhil_inv_item_min_max_pkg;
/
SHOW ERROR;
EXIT;