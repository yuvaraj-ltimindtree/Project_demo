CREATE OR REPLACE PROCEDURE apps.XXHIL_PL2P_L3_AUTO_DL_PATCH1
                                    (
                                     P_RETCODE               OUT NUMBER,
                                     P_ERRBUFF               OUT VARCHAR2,
                                     P_ORGANIZATION_ID       IN  NUMBER,
                                     P_BATCH_NO              IN  VARCHAR2,
                                     P_FROM_DATE             IN DATE,
                                     P_TO_DATE               IN DATE
                                     )
is

   l_organization_id     NUMBER;
   l_organization_code   VARCHAR2 (12);
   l_batch_no            VARCHAR2 (32);
   l_lot_ticket_id       NUMBER;
   l_lot_ticket_number   VARCHAR2 (32);
   l_subinventory        VARCHAR2 (32);
   l_ip_lot_lot          VARCHAR2 (32);
   l_lot_no              VARCHAR2 (32);
   l_coil_weight         NUMBER;
   l_ip_coil_weight      NUMBER;
   l_prev_lt_tkt_no      VARCHAR2 (50):= NULL;
   l_prev_batch_no       VARCHAR2 (50):= NULL;
   l_batch_id            NUMBER       := 0;
   l_prev_item_no        varchar2(32);
   l_prev_inv_item_id    NUMBER       := 0;
   l_prev_lot_number     VARCHAR2 (50):= NULL;
   l_actual_wt           NUMBER       := 0;
   l_cnt                 NUMBER;

   l_min_batch_no        VARCHAR2(32);
   
   l_hm_op_qty           NUMBER;
   
   l_lot_number          VARCHAR2(60);
               
   l_primary_lot_qty     NUMBER;
               
   l_sub_inv             VARCHAR2(60);
   
   l_batch_prim_actual_rsrc_qty     number;

   l_batch_sec_actual_rsrc_qty      number;
   l_batch_sec_actual_rsrc_qty_tot  number;
   l_batch_sec_actual_rsrc_qty_cnt  number;
   
   l_batch_prod_qty                 number;
   

 Cursor c_soak_cur is
  select c.batch_no, a.*   
    from XXHIL_PL2P_HKF_SOAK_OUTPUT a,
         gme_batch_header c
   where 1 = 1 
    and not exists (
                     select 1
                       from xxhil_pl2p_l2_auto_feedback b
                      where a.oracle_batch_id = b.batch_id
                       and trunc(b.creation_date) between P_FROM_DATE and P_TO_DATE
                       and resources like  'HFW-SP%'
                    ) 
    and trunc(a.process_date) between P_FROM_DATE and P_TO_DATE
    and a.oracle_batch_id = c.batch_id
    and c.batch_no = decode (P_BATCH_NO, 'ALL',c.batch_no,P_BATCH_NO) 
    and c.organization_id = p_organization_id
    and c.batch_status not in (-1);
    
        
 CURSOR lcur_batch_no_details(p_lot_ticket_number in varchar2)
   IS
      SELECT   xplsm.lot_ticket_number,
               xplsm.batch_number,
               ood.organization_code,
               ood.organization_id
        FROM   xxhil.xxhil_pl2p_ltckt_so_mapping xplsm,
               apps.org_organization_definitions ood
       WHERE   xplsm.LOT_TICKET_NUMBER =p_lot_ticket_number
               AND xplsm.wip_warehouse = ood.organization_code
               --AND ood.organization_id = :p_organization_id
               AND EXISTS
                     (SELECT   1
                        FROM   apps.gme_batch_header gbh,
                               apps.gme_batch_steps gbs,
                               apps.gme_batch_step_activities gbsa,
                               apps.gme_batch_step_resources gbsr,
                               apps.cr_rsrc_mst crm,
                               apps.cr_rsrc_dtl crd
                       WHERE       gbh.batch_no = xplsm.batch_number
                               AND gbh.batch_id = gbs.batch_id
                               AND gbs.batch_id = gbsa.batch_id
                               AND gbs.batchstep_id = gbsa.batchstep_id
                               AND gbsa.activity = 'RUNTIME'
                               AND gbsa.batchstep_activity_id = gbsr.batchstep_activity_id
                               AND gbsa.batch_id = gbsr.batch_id
                               AND gbsr.prim_rsrc_ind = 1
                               AND gbsr.resources = crm.resources
                               AND crm.resources = crd.resources
                               AND crm.resource_class = 'PH'
                               AND crd.organization_id = ood.organization_id
                               --AND  ood.organization_id = :p_organization_id
                               --AND xxhil_pl2p_batch_ready_for_L2 (ood.organization_id,xplsm.lot_ticket_number, xplsm.batch_number) = 'Y'
                               --AND gbh.batch_status  IN (1,2)
                               );

   CURSOR c1 (
      p_batch_number                 VARCHAR2
   )
   IS
      SELECT   DISTINCT crm.resources
        --INTO l_furnace_rsrc
        FROM   apps.gme_batch_header gbh,
               apps.gme_batch_steps gbs,
               apps.gme_batch_step_activities gbsa,
               apps.gme_batch_step_resources gbsr,
               apps.cr_rsrc_mst crm,
               apps.cr_rsrc_dtl crd
       WHERE       gbh.batch_no = p_batch_number
               AND gbh.batch_id = gbs.batch_id
               AND gbs.batch_id = gbsa.batch_id
               AND gbs.batchstep_id = gbsa.batchstep_id
               AND gbsa.activity = 'RUNTIME'
               AND gbsa.batchstep_activity_id = gbsr.batchstep_activity_id
               AND gbsa.batch_id = gbsr.batch_id
               AND gbsr.prim_rsrc_ind = 1
               AND gbsr.resources = crm.resources
               AND crm.resources = crd.resources
               AND crm.resource_class = 'PH'
               --AND crd.organization_id = p_organization_id
               --AND gbh.batch_status IN (1,2)
               ;


   CURSOR c2 (
      p_batch_number                 VARCHAR2
   )
   IS
      SELECT   gmd.line_type,
               msib.segment1,
               msib.inventory_item_id,
               msib.PRIMARY_UOM_CODE,
               msib.SECONDARY_UOM_CODE,
               DECODE (gmd.line_type,
                       -1, 'WIP Issue',
                       1, 'WIP Completion',
                       gmd.line_type)
                  transaction_type
        FROM   gme_material_details gmd,
               gme_batch_header gbh,
               mtl_system_items_b msib
       WHERE       gmd.inventory_item_id = msib.inventory_item_id
               AND gmd.organization_id = msib.organization_id
               AND gbh.batch_id = gmd.batch_id
               AND gbh.batch_no = p_batch_number
               and gmd.line_type in (-1,1);
               
               
    
   Cursor C3 is
     SELECT DISTINCT 
            gbh.batch_no, 
            gbh.batch_id,
            gbs.batchstep_no, 
            gbsr.resources,
            gbsr.ACTUAL_RSRC_Usage,
            gbsr.BATCHSTEP_RESOURCE_ID
       FROM apps.gme_batch_header gbh,
            apps.gme_batch_steps gbs,
            apps.gme_batch_step_activities gbsa,
            apps.gme_batch_step_resources gbsr
      WHERE gbs.batch_id = gbh.batch_id
        AND gbs.batch_id = gbsa.batch_id
        AND gbs.batch_id = gbsr.batch_id
        AND gbsa.batch_id = gbsr.batch_id
        AND gbs.batchstep_id = gbsr.batchstep_id
        AND gbs.batchstep_id = gbsa.batchstep_id
        AND gbsa.batchstep_id = gbsr.batchstep_id
        AND gbsa.batchstep_activity_id = gbsr.batchstep_activity_id
        AND gbsa.activity = 'RUNTIME'
        --AND gbs.batchstep_no =p_batchstep_no
        AND gbsr.organization_id = P_ORGANIZATION_ID
        AND gbsr.prim_rsrc_ind = 1
        --and (gbsr.ACTUAL_RSRC_Usage is not null OR nvl(gbsr.ACTUAL_RSRC_Usage,0) <> 0)
        and gbsr.ACTUAL_RSRC_QTY  = 10000
        and trunc(gbsr.ACTUAL_CMPLT_DATE) between P_FROM_DATE and P_TO_DATE
        and gbsr.resources like 'HFW-SP%'
        and gbh.batch_no = decode (P_BATCH_NO, 'ALL',gbh.batch_no,P_BATCH_NO) 
        and gbh.batch_status not in (-1)
        ;
   
   cursor c4 (p_batch_no in varchar2 ) is
     select * 
       from apps.xxhil_pl2p_l2_auto_feedback
      where batch_no  = p_batch_no
        and organization_id = p_organization_id;
        
  cursor c5 is
    select gbh.batch_no,
           gbh.batch_id,
           gbh.organization_id,
           gbs.BATCHSTEP_NO,
           gbs.BATCHSTEP_ID
      from apps.gme_batch_header gbh,
           apps.gme_batch_steps gbs
     where gbh.organization_id = P_ORGANIZATION_ID
       and gbh.batch_status = 3
       and gbh.batch_no = decode (P_BATCH_NO, 'ALL',gbh.batch_no,P_BATCH_NO) 
       and trunc(gbh.ACTUAL_CMPLT_DATE) between P_FROM_DATE and P_TO_DATE
       and gbh.batch_id = gbs.batch_id
       and gbs.step_status = 3
       order by 1;
   
   
BEGIN

  
 For c_soak_rec in c_soak_cur
 Loop
 
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Within Cursor c_soak_rec for Batch '||c_soak_rec.batch_no);

   FOR lrec_batch_no_details IN lcur_batch_no_details(c_soak_rec.LOTTKTCODE)
   LOOP
   
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Within Cursor lrec_batch_no_details for Lot Ticket '||c_soak_rec.LOTTKTCODE);


      BEGIN
         SELECT   gbh.batch_no,gbh.batch_ID ,ood.organization_id, ood.organization_code
           INTO   l_batch_no,l_batch_id, l_organization_id, l_organization_code
           FROM   gme_batch_header gbh, org_organization_definitions ood
          WHERE   gbh.batch_id = c_soak_rec.ORACLE_BATCH_ID --lrec_batch_no_details.batch_number  -- Changes done by Souvik on 08.10.2021
            AND   gbh.organization_id = ood.organization_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_batch_no := NULL;
            l_batch_id := NULL;
            l_organization_id   := NULL;
            l_organization_code := NULL;
      END;



      BEGIN

      SELECT DISTINCT xplsm.lot_ticket_number, xplsm.batch_number
         INTO l_prev_lt_tkt_no, l_prev_batch_no
         FROM xxhil.xxhil_pl2p_ltckt_so_mapping xplsm,
              apps.org_organization_definitions ood
        WHERE xplsm.LOT_TICKET_NUMBER = decode (lrec_batch_no_details.lot_ticket_number,'ALL',xplsm.LOT_TICKET_NUMBER,lrec_batch_no_details.lot_ticket_number)
          AND xplsm.wip_warehouse = ood.organization_code
          --AND ood.organization_id = p_organization_id
          AND xplsm.batch_number < lrec_batch_no_details.BATCH_NUMBER
          AND EXISTS (
                    SELECT 1
                      FROM apps.gme_batch_header gbh,
                           apps.gme_batch_steps gbs,
                           apps.gme_batch_step_activities gbsa,
                           apps.gme_batch_step_resources gbsr,
                           apps.cr_rsrc_mst crm,
                           apps.cr_rsrc_dtl crd
                     WHERE gbh.batch_no = xplsm.batch_number
                       AND gbh.batch_id = gbs.batch_id
                       AND gbs.batch_id = gbsa.batch_id
                       AND gbs.batchstep_id = gbsa.batchstep_id
                       AND gbsa.activity = 'RUNTIME'
                       AND gbsa.batchstep_activity_id = gbsr.batchstep_activity_id
                       AND gbsa.batch_id = gbsr.batch_id
                       AND gbsr.prim_rsrc_ind = 1
                       AND gbsr.resources = crm.resources
                       AND crm.resources = crd.resources
                       AND crm.resource_class = 'SCLP'
                       AND crd.organization_id = ood.organization_id
                      -- AND  ood.organization_id = p_organization_id
                       );

      EXCEPTION

         WHEN OTHERS THEN
            l_prev_lt_tkt_no  := NULL;
            l_prev_batch_no   := NULL;
      END;


      If l_prev_batch_no is null then

          begin

            select min(batch_number)
              into l_min_batch_no
              from xxhil_pl2p_ltckt_so_mapping
             where lot_ticket_number = c_soak_rec.LOTTKTCODE;

          exception

            when others then

                  l_min_batch_no := null;

          end;


          If l_min_batch_no = lrec_batch_no_details.BATCH_NUMBER then

               begin

                 select PRODUCT,
                        LOT_NUMBER,
                        LOT_QUANTITY
                   into l_prev_item_no,
                        l_prev_lot_number,
                        l_actual_wt
                   from xxhil_pl2p_ltckt_so_mapping
                  where lot_ticket_number = c_soak_rec.LOTTKTCODE
                    and BATCH_NUMBER is null;


               exception

                 when others then

                        l_prev_item_no    := null;
                        l_prev_lot_number := null;
                        l_actual_wt       := null;

               end;

               If l_prev_item_no is not null then

                     begin

                       select distinct inventory_item_id
                         into l_prev_inv_item_id
                         from mtl_system_items_b
                        where segment1 = l_prev_lot_number;

                     exception

                       when others then

                          l_prev_inv_item_id := null;

                     end;

               End If;


          End If;

      Else

             BEGIN

              SELECT  DISTINCT mmt.inventory_item_id
                     ,mtln.lot_number
                     ,gmd.actual_qty
                INTO  l_prev_inv_item_id
                     ,l_prev_lot_number
                     ,l_actual_wt
                FROM  gme_batch_header gbh
                     ,gme_material_details gmd
                     ,mtl_material_transactions mmt
                     ,mtl_transaction_lot_numbers mtln
                     ,mtl_onhand_quantities moq
               WHERE  3=3
                 AND  gbh.batch_id = gmd.batch_id
                 AND  mmt.transaction_source_id = gbh.batch_id
                 AND  mmt.transaction_id = mtln.transaction_id
                 AND  mmt.organization_id = mtln.organization_id
                 AND  mmt.inventory_item_id = gmd.inventory_item_id
                 AND  mmt.organization_id  = gbh.organization_id
                 AND  moq.inventory_item_id = gmd.inventory_item_id
                 AND  moq.organization_id  = gbh.organization_id
                 AND  moq.lot_number = mtln.lot_number
                 AND  gmd.line_type = 1
                 --AND  mmt.organization_id = :p_organization_id
                 AND  gbh.batch_no = l_prev_batch_no;

             EXCEPTION
                 WHEN OTHERS THEN
                 l_prev_lot_number := NULL;

             END;


      End If;

      BEGIN
         SELECT   xxhil_pl2p_batch_grp_chk_func (l_organization_id,
                                                 l_batch_no)
           INTO   l_lot_ticket_number
           FROM   dual;
      EXCEPTION
         WHEN OTHERS THEN
            l_lot_ticket_number := NULL;
      END;

--      INSERT INTO xxhil_debug_tab
--        VALUES   ('HM Trigger', '#2');

      BEGIN
         SELECT   group_id
           INTO   l_lot_ticket_id
           FROM   gme_batch_groups_b
          WHERE   group_name      = l_lot_ticket_number
            AND   organization_id = l_organization_id;
      EXCEPTION
         WHEN OTHERS THEN
            l_lot_ticket_id := NULL;
      END;




        BEGIN

            select SECONDARY_INVENTORY_NAME
              into l_subinventory
              from MTL_SECONDARY_INVENTORIES msi,
                   MTL_MATERIAL_STATUSES_TL mmst
             where organization_id = l_organization_id
               and msi.status_id = mmst.status_id
               and mmst.STATUS_CODE = 'WIP';

        EXCEPTION

           When Others then
                  l_subinventory := null;

        END;

      BEGIN
         SELECT   lotnumber, totalchargeweight
           INTO   l_ip_lot_lot, l_ip_coil_weight
           FROM   xxhil.xxhil_pl2p_hkf_soak_output
          WHERE   lotnumber = c_soak_rec.lotnumber
            AND   ROWNUM = 1;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_ip_lot_lot := NULL;
            l_ip_coil_weight := NULL;
      END;



      FOR c1_rec IN c1 (lrec_batch_no_details.batch_number)
      LOOP
      
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Within Cursor C1 for batch '||lrec_batch_no_details.batch_number);
          


         FOR c2_rec IN c2 (lrec_batch_no_details.batch_number)
         LOOP
         
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Within Cursor C2 for batch '||lrec_batch_no_details.batch_number);
           

            IF c2_rec.line_type = -1
            THEN
               l_lot_no := l_prev_lot_number;
               l_coil_weight := l_actual_wt;
            ELSIF c2_rec.line_type = 1
            THEN
               l_lot_no := l_prev_lot_number;
               l_coil_weight := c_soak_rec.totalchargeweight;
            END IF;

--            INSERT INTO xxhil_debug_tab
--              VALUES   ('HM Trigger', 'Before insert.');

           SELECT COUNT (1)
           INTO l_cnt
           FROM xxhil.XXHIL_PL2P_L2_AUTO_FEEDBACK
          WHERE batch_id =l_batch_id
           and ITEM_NO= c2_rec.segment1
           and LOT_NUMBER=l_lot_no
            AND RESOURCES=c1_rec.RESOURCES
           AND  TRANSACTION_TYPE= c2_rec.transaction_type
           and LINE_TYPE=c2_rec.line_type;

         if l_cnt=0 then

            INSERT INTO XXHIL.XXHIL_PL2P_L2_AUTO_FEEDBACK (
                                                               UNIQUE_ID,
                                                               RESOURCES,
                                                               ORGANIZATION_ID,
                                                               ORGANIZATION_CODE,
                                                               BATCH_ID,
                                                               BATCH_NO,
                                                               LOT_TICKET_ID,
                                                               LOT_TICKET_NUMBER,
                                                               LINE_TYPE,
                                                               START_DATE,
                                                               END_DATE,
                                                               ITEM_NO,
                                                               ITEM_ID,
                                                               LOT_NUMBER,
                                                               PRIMARY_LOT_QTY,
                                                               SECONDARY_LOT_QTY,
                                                               SUBINVENTORY,
                                                               TRANSACTION_TYPE,
                                                               PRIMARY_UOM,
                                                               SECONDARY_UOM,
                                                               TRANSACTION_DATE,
                                                               LOCATOR_ID,
                                                               STATUS,
                                                               MESSAGE_TEXT,
                                                               LAST_UPDATE_DATE,
                                                               LAST_UPDATED_BY,
                                                               CREATION_DATE,
                                                               CREATED_BY,
                                                               LAST_UPDATE_LOGIN
                       )
              VALUES   (xxhil.xxhil_pl2p_l2_auto_fedback_seq.NEXTVAL,
                        c1_rec.RESOURCES,
                        l_organization_id,
                        l_organization_code,
                        l_batch_id,
                        l_batch_no,
                        l_lot_ticket_id,
                        l_lot_ticket_number,
                        c2_rec.line_type,
                        c_soak_rec.HEATSTARTTIME,
                        c_soak_rec.HEATOVERTIME,
                        c2_rec.segment1,
                        c2_rec.inventory_item_id,
                        l_lot_no,
                        l_coil_weight,
                        NULL,
                        l_subinventory,
                        c2_rec.transaction_type,
                        c2_rec.primary_uom_code,
                        c2_rec.secondary_uom_code,
                        SYSDATE,
                        NULL,
                        null,
                        NULL,
                        SYSDATE,
                        fnd_global.user_id,
                        SYSDATE,
                        fnd_global.user_id,
                        NULL);
                        
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Data suceessfully Inserted in L2 Feedback for Batch '||l_batch_no||' Having Trans_type' ||c2_rec.transaction_type);

             commit;  
         
           END IF;
         END LOOP;
      END LOOP;
   END LOOP;
   
    For c4_rec in c4(c_soak_rec.batch_no)
    Loop
    
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Within Cursor C4 for Batch '||c4_rec.batch_no);
       
       l_lot_number := null;
               
       l_primary_lot_qty := null;
               
       l_sub_inv := null;
    
        Begin
          select LOT_NUMBER,PRIMARY_LOT_QTY, SUBINVENTORY
            into l_lot_number, l_primary_lot_qty, l_sub_inv
            from xxhil_pl2p_l2_auto_feedback
           where batch_no = c4_rec.batch_no
             and organization_id = p_organization_id
             and resources = 'HFW-HM1'
             and line_type = -1;
             
        Exception
          when others then
          
               l_lot_number := null;
               
               l_primary_lot_qty := null;
               
               l_sub_inv := null;
               
        End;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'l_lot_number '||l_lot_number||' l_primary_lot_qty '||l_primary_lot_qty||' l_sub_inv '||l_sub_inv);
               
        If (c4_rec.resources like 'HFW-SP%' and l_lot_number is not null and l_primary_lot_qty is not null and l_sub_inv is not null) then
        
           update xxhil_pl2p_l2_auto_feedback
              set lot_number = l_lot_number,
                  primary_lot_qty = l_primary_lot_qty,
                  subinventory = l_sub_inv
            where batch_no = c4_rec.batch_no
              and organization_id = p_organization_id;
              
             FND_FILE.PUT_LINE(FND_FILE.LOG,'SP update done for batch '||c4_rec.batch_no);
              
         Elsif c4_rec.resources = 'HFW-HM1' and c4_rec.line_type = 1 then
           
             update xxhil_pl2p_l2_auto_feedback
                set status = 'DS'
              where batch_no = c4_rec.batch_no
                and organization_id = p_organization_id
                and resources = 'HFW-HM1'
                and line_type = 1;
                
               FND_FILE.PUT_LINE(FND_FILE.LOG,'HM update done for batch '||c4_rec.batch_no);
                
        End If;
        
        commit;
    End Loop;
    
 End Loop;
 

 
 For c3_rec in c3
 Loop
  
   l_hm_op_qty := null;
   
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Within Cursor C3 for Batch '||c3_rec.batch_no);
 
    Begin
    
         select PRIMARY_LOT_QTY
          into  l_hm_op_qty
          from xxhil_pl2p_l2_auto_feedback 
         where batch_no = c3_rec.batch_no
           and RESOURCES = 'HFW-HM1' 
           and organization_id = p_organization_id
           and line_type = 1;
    
    Exception
    
      when others then
          
          l_hm_op_qty := null;
    
    
    End;
    
    
    If nvl(l_hm_op_qty,0) <> 0 then
    
       update apps.gme_batch_step_resources gbsr
          set gbsr.ACTUAL_RSRC_QTY = l_hm_op_qty
        where batch_id = c3_rec.batch_id
          and resources = c3_rec.resources
          and BATCHSTEP_RESOURCE_ID = c3_rec.BATCHSTEP_RESOURCE_ID;
          
          FND_FILE.PUT_LINE(FND_FILE.LOG,'For Batch '||c3_rec.batch_no||' Soaking ACTUAL_RSRC_QTY updated as per HM Output qty '||l_hm_op_qty);
          
    End If;
    
    commit;


 End Loop;
  
  
 For c5_rec in c5
 Loop
 
    l_batch_prim_actual_rsrc_qty     := null;
           
    l_batch_sec_actual_rsrc_qty      := null;
    l_batch_sec_actual_rsrc_qty_tot  := null;
    l_batch_sec_actual_rsrc_qty_cnt  := null;
    
    l_batch_prod_qty                 := null;
    
    
     Begin
           
        select  sum(gbsr.ACTUAL_RSRC_QTY)
          into  l_batch_prim_actual_rsrc_qty
          from  apps.gme_batch_steps             gbs,
                apps.gme_batch_step_activities   gbsa,
                apps.gme_batch_step_resources    gbsr
          WHERE 1 = 1
            and gbs.batch_id = c5_rec.batch_id
            AND gbs.batch_id = gbsa.batch_id
            AND gbs.batchstep_id = gbsa.batchstep_id
            AND gbsa.activity = 'RUNTIME'
            AND gbsa.batchstep_activity_id = gbsr.batchstep_activity_id
            AND gbsa.batch_id = gbsr.batch_id
            AND gbsr.prim_rsrc_ind = 1
            AND gbsr.organization_id = c5_rec.organization_id
            and gbs.BATCHSTEP_NO = c5_rec.BATCHSTEP_NO
                    ;
     Exception
           
              When Others then
                
                l_batch_prim_actual_rsrc_qty := null;
                
     End;
     
     Begin
                select  sum(gbsr.ACTUAL_RSRC_QTY), 
                        count(1), 
                        sum(gbsr.ACTUAL_RSRC_QTY) / count(1)
                  into  l_batch_sec_actual_rsrc_qty_tot, 
                        l_batch_sec_actual_rsrc_qty_cnt, 
                        l_batch_sec_actual_rsrc_qty
                  from  apps.gme_batch_steps             gbs,
                        apps.gme_batch_step_activities   gbsa,
                        apps.gme_batch_step_resources    gbsr
                  WHERE 1 = 1
                    and gbs.batch_id = c5_rec.batch_id
                    AND gbs.batch_id = gbsa.batch_id
                    AND gbs.batchstep_id = gbsa.batchstep_id
                    AND gbsa.activity = 'RUNTIME'
                    AND gbsa.batchstep_activity_id = gbsr.batchstep_activity_id
                    AND gbsa.batch_id = gbsr.batch_id
                    AND gbsr.prim_rsrc_ind = 0
                    AND gbsr.organization_id = p_organization_id
                    and gbsr.resources not like '%AF%POWER%'
                    and gbs.BATCHSTEP_NO = c5_rec.BATCHSTEP_NO
                    and gbsr.ACTUAL_RSRC_USAGE <> 0;
                         
     Exception
           
              When Others then
                
                     l_batch_sec_actual_rsrc_qty_tot  := null;
                     l_batch_sec_actual_rsrc_qty_cnt  := null;
                     l_batch_sec_actual_rsrc_qty      := null;
                     
                     
                     
     End;
     
     If round(nvl(l_batch_prim_actual_rsrc_qty,0),5) <> round(nvl(l_batch_sec_actual_rsrc_qty,0),5) then
     
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Within IF of Cursor C5 for batch '||c5_rec.batch_no);
     
          Begin
           
            select sum(ACTUAL_QTY) 
              into l_batch_prod_qty
              from gme_material_details 
             where batch_id = c5_rec.batch_id
               and line_type = 1;
               
          Exception
          
            When Others then
            
                   l_batch_prod_qty := null;
                   
          End;
           
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Batch Prod Qty '||l_batch_prod_qty);
           
         update apps.gme_batch_step_resources
            set actual_rsrc_qty = l_batch_prod_qty
          where 1 = 1 --batchstep_id = c5_rec.batchstep_id
            and batch_id = c5_rec.batch_id;
            
         commit;
     
     
     End If;
     
 End loop;

END;
/
SHOW ERROR;
EXIT; 