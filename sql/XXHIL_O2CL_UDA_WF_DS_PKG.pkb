CREATE OR REPLACE PACKAGE BODY APPS.xxhil_o2cl_uda_wf_ds_pkg
AS
/**********************************************************************************

  * FILE NAME: XXHIL_O2CL_UDA_WF_PKG.pkb
  *
  *
  * OBJECT NAME: (WFL-PL2P-5243)- O2CL UDA Workflow
  *
  *
  * DESCRIPTION:  This Package will be used for O2CL UDA Workflow.
  *
  * HISTORY
  * =======
  *
  * VERSION DATE        AUTHOR          DESCRIPTION
  * ------- ----------- --------------- ------------------------------------------- *
  * 1.0     25-AUG-2021 Ninad Pimpale    XXHIL_O2CL_UDA_WF_DS_PKG (FRICEW: WFL-PL2P-5243)
  ***********************************************************************************/
   PROCEDURE start_workflow (p_so_number    NUMBER,
                             p_so_line      NUMBER,
                             p_csr_no       VARCHAR2)
   AS
      lc_itemtype       VARCHAR2 (10);
      lc_itemkey        VARCHAR2 (60);
      lc_process_name   VARCHAR2 (60);
      lc_item_owner     VARCHAR2 (240);
      ln_debug_info     NUMBER;
      v_history_id      NUMBER;
   BEGIN
      --    begin
      --
      --    select   xxhi_o2cl_wf_seq.nextval into v_history_id from dual;
      --
      --    end;

      lc_itemtype := 'XUDA_DS';
      lc_itemkey :=
         'HILUDA_DS_' || p_so_number || '|' || p_so_line || '|' || p_csr_no;
      --(p_wf_req_id);  --have to change parameter
      lc_process_name := 'HIL_UDA_PROCESS';
      lc_item_owner := 'SYSADMIN';
      wf_engine.createprocess (lc_itemtype, lc_itemkey, lc_process_name);
      wf_engine.setitemowner (lc_itemtype, lc_itemkey, lc_item_owner);
       wf_engine.setitemattrtext (lc_itemtype, lc_itemkey, 'I_KEY', lc_itemkey);
      --  wf_engine.setitemattrtext(p_itemtype,p_itemkey,'history_id',v_history_id);
      wf_engine.startprocess (lc_itemtype, lc_itemkey);

      insert into xxhil.xxhil_o2cl_uda_log_t_ds values(XXHIL.XXHIL_O2CL_UDA_LOG_S_ds.nextval,'1',lc_itemtype);

       insert into xxhil.xxhil_o2cl_uda_log_t_ds values(XXHIL.XXHIL_O2CL_UDA_LOG_S_ds.nextval,'2',lc_itemkey);



      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         wf_core.context ('XXHIL_O2CL_UDA_WF_DS_PKG',
                          'start_workflow',
                          lc_itemtype,
                          lc_itemkey,
                          ln_debug_info);
         RAISE;
   END start_workflow;

   PROCEDURE set_item_attributes (p_itemtype    IN     VARCHAR2,
                                  p_itemkey     IN     VARCHAR2,
                                  p_actid       IN     NUMBER,
                                  p_funcmode    IN     VARCHAR2,
                                  x_resultout      OUT VARCHAR2)
   AS
      ln_debug_info      NUMBER;
      lc_request_no      VARCHAR2 (240);
      lc_subject         VARCHAR2 (4000);
      lc_message         VARCHAR2 (4000);
      lc_requester       VARCHAR2 (240);
      lc_performer       VARCHAR2 (240);
      lc_url             VARCHAR2 (4000);
      lc_csr_number      VARCHAR2 (30);
      lc_fg_item         VARCHAR2 (100);
      lc_org             VARCHAR2 (25);
      lc_customer_name   VARCHAR2 (100);
      lc_uda_status      VARCHAR2 (10);
      ln_version         NUMBER;
      lc_csr_ver_no      VARCHAR2 (50);
      lc_to_recipients   VARCHAR2 (50);
      lc_cc_recipients   VARCHAR2 (240);
      v_csr_num          VARCHAR2 (200);
      lc_p1              VARCHAR2 (200);
      lc_uda_ref_no      VARCHAR2 (200);
      lc_url_parameter   VARCHAR2 (200);
   --cursor c
   --is
   --select  csr_number,
   --        fg_item,
   --        org,
   --        customer_name,
   --        csr_status,
   --        version
   --from    xxhil.xxhil_o2c_csr_master
   --where   'hilcsr_'||csr_number||'|'||version=p_itemkey;--'1012' 1012|1  -- have to pass parameter
   --and rownum = 1;  --have to delete rownum
   BEGIN
      BEGIN                                               -- get_history_id --
         --v_history_id := wf_engine.getitemattrtext(p_itemtype,p_itemkey,'history_id');

         SELECT   SUBSTR (p_itemkey, INSTR (p_itemkey,
                                            '|',
                                            2,
                                            2)
                                     + 1)
                     "CSR_NUMBER"
           INTO   v_csr_num
           FROM   DUAL;

           SELECT   MAX (version),
                    csr_number,
                    fg_item,
                    org,
                    customer_name,
                    csr_status
             INTO   ln_version,
                    lc_csr_number,
                    lc_fg_item,
                    lc_org,
                    lc_customer_name,
                    lc_uda_status
             FROM   xxhil.xxhil_o2c_csr_master
            WHERE   csr_number = v_csr_num
         GROUP BY   csr_number,
                    fg_item,
                    org,
                    customer_name,
                    csr_status;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.log,'Error In Getting CSR details' || SQLERRM);
      END;


      --        open c;
      --        fetch c into lc_csr_number  ,   lc_fg_item , lc_org, lc_customer_name , lc_csr_status,ln_version;
      --        close c;
      lc_csr_ver_no := lc_csr_number || '|' || ln_version;

      insert into xxhil.xxhil_o2cl_uda_log_t_ds values(XXHIL.XXHIL_O2CL_UDA_LOG_S_ds.nextval,'3',lc_csr_ver_no);

      lc_p1 := SUBSTR (p_itemkey, INSTR (p_itemkey, '_', 1) + 1);
      lc_uda_ref_no := SUBSTR (lc_p1, 1, INSTR (lc_p1, '|', 1) + 1);
      lc_url_parameter := SUBSTR (lc_p1, 1, INSTR (lc_p1, '|', 1) - 1);

      lc_url := get_url ('XXHILOMLINKAGE_DS_F','Hindalco PL2P Custom',lc_url_parameter); -- 'XX Custom Responsibility'
      lc_url := SUBSTR (lc_url, 1, INSTR (lc_url, 'oas') - 1);
      fnd_file.put_line (fnd_file.log,lc_url);
                             insert into xxhil.xxhil_o2cl_uda_log_t_ds values(XXHIL.XXHIL_O2CL_UDA_LOG_S_DS.nextval,'4',lc_url);
                           --  commit;
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 'URL',
                                 lc_url);
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 'UDA_REF_NO',
                                 lc_uda_ref_no);
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 'CSR_UDA_REF_NO',
                                 lc_csr_ver_no);
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 'UDASTATUS',
                                 lc_uda_status);
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 'CUSTOMERNAME',
                                 lc_customer_name);
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 'ORG',
                                 lc_org);
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 'FGITEM',
                                 lc_fg_item);

      BEGIN
         fnd_message.set_name ('XXHIL', 'XXHIL_UDA_QT_REVIEW');
         fnd_message.set_token ('UDA_REF_NO', lc_uda_ref_no);
         fnd_message.set_token ('CSR_UDA_REF_NO', lc_csr_number);
         lc_subject := fnd_message.get;
      END;

      BEGIN
         fnd_message.set_name ('XXHIL', 'XXHIL_UDA_QT_MESSAGE');
         -- pending with quality team message after csr details entered in master table by marketing team
         fnd_message.set_token ('UDA_REF_NO', lc_uda_ref_no);
         fnd_message.set_token ('CSR_UDA_REF_NO', lc_csr_ver_no);
         fnd_message.set_token ('UDASTATUS', lc_uda_status);
         fnd_message.set_token ('CUSTOMERNAME', lc_customer_name);
         fnd_message.set_token ('ORG', lc_org);
         fnd_message.set_token ('FGITEM', lc_fg_item);
         lc_message := fnd_message.get;
      END;

      BEGIN
         SELECT   to_recipients, cc_recipients
           INTO   lc_to_recipients, lc_cc_recipients
           FROM   alr_distribution_lists
          WHERE   1=1 --name = 'RKT-INIT-UDA#QTY';
            AND   name = lc_org||'-INIT-UDA#QTY';
      END;

      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 '#FROM_ROLE',
                                 'SYSADMIN');
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 'SUBJECT',
                                 lc_subject);
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 'MESSAGE',
                                 lc_message);
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 'PERFORMER',
                                 lc_to_recipients);
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 '#WFM_CC',
                                 lc_cc_recipients);

      insert_history (NULL,
                      'New',
                      NULL,
                      lc_uda_ref_no,
                      'PWQT',
                      p_itemkey,
                      lc_org||'-INIT-UDA#QTY');
   -- request no not generated at this stage
   EXCEPTION
      WHEN OTHERS
      THEN
         wf_core.context ('XXHIL_O2CL_UDA_WF_DS_PKG',
                          'set_item_attributes',
                          p_itemtype,
                          p_itemkey,
                          ln_debug_info);
         RAISE;
   END set_item_attributes;

   PROCEDURE get_next_approver (p_itemtype    IN     VARCHAR2,
                                p_itemkey     IN     VARCHAR2,
                                p_actid       IN     NUMBER,
                                p_funcmode    IN     VARCHAR2,
                                x_resultout      OUT VARCHAR2)
   AS
      CURSOR c
      IS
         SELECT   a.request_number,
                  b.organization_name,
                  a.org_code,
                  a.csr_ref_no_ver_no,
                  a.uda_ref_no,
                  a.customer_name,
                  a.customer_ship,
                  a.fg_item_name,
                  a.status,
                  a.wf_approval_status,
                  a.global_decision,
                  a.wf_comments,
                  a.INSTRUCTIONS2,
                  a.REASON,
                  a.LINKAGE_HEADER_ID
           FROM   xxhil.xxhil_om_linkage_header_ds a,
                  org_organization_definitions b
          WHERE   a.org_id = b.organization_id
                  AND 'HILUDA_DS_' || uda_ref_no =
                        SUBSTR (p_itemkey, 1, INSTR (p_itemkey,
                                                     '|',
                                                     -1,
                                                     2)
                                              + 1);               --p_itemkey;

      --a.linkage_header_id = 1000088;  --have to update  (csr_ref_no_ver_no = parameter)

      lc_flow_status_code    VARCHAR2 (25);
      lc_request_no          VARCHAR2 (30);
      lc_performer           VARCHAR2 (20);
      lc_complete_code       VARCHAR2 (20);
      lc_subject             VARCHAR2 (4000);
      lc_message             VARCHAR2 (4000);
      lc_url                 VARCHAR2 (4000);
      lc_subject_code        VARCHAR2 (240);
      lc_message_code        VARCHAR2 (240);
      lc_uda_number          VARCHAR2 (200);
      lc_csr_number          VARCHAR2 (200);
      lc_fg_item             VARCHAR2 (150);
      lc_org                 VARCHAR2 (25);
      lc_customer_name       VARCHAR2 (150);
      lc_uda_status          VARCHAR2 (100);
      ln_debug_info          NUMBER;
      lc_resultout           VARCHAR2 (30);
      lc_global_decision     VARCHAR2 (240);
      lv_wf_note             VARCHAR2 (4000) := NULL;
      lc_to_recipients       VARCHAR2 (50);
      lc_cc_recipients       VARCHAR2 (240);
      lc_distribution_code   VARCHAR2 (50);
      lc_reason               varchar2(4000);
      lc_instructions         varchar2(4000);
      lc_LINKAGE_HEADER_ID   NUMBER;
      lc_itemkey                VARCHAR2(100) := p_itemkey;
      lc_document_id          CLOB;
      lc_wf_comments          VARCHAR2(2000);


   BEGIN
      FOR i IN c
      LOOP
         lc_flow_status_code := i.wf_approval_status;
         lc_request_no := i.request_number;
         lc_csr_number := i.csr_ref_no_ver_no;
         lc_uda_number := i.uda_ref_no;
         lc_uda_status := i.status;
         lc_customer_name := i.customer_name;
         lc_org := i.org_code; -- organization_name
         lc_fg_item := i.fg_item_name;
         lc_global_decision := i.global_decision;
         lv_wf_note := i.wf_comments;
         lc_reason           :=  i.reason;
         lc_instructions     :=  i.INSTRUCTIONS2;
         lc_LINKAGE_HEADER_ID := i.LINKAGE_HEADER_ID;
         lc_wf_comments := i.WF_COMMENTS;
      END LOOP;

      lc_url := get_url ('XXHILOMLINKAGE_DS_F', 'Hindalco PL2P Custom',lc_uda_number);
      lc_url := SUBSTR (lc_url, 1, INSTR (lc_url, 'oas') - 1);

      lc_resultout :=
         wf_engine.getitemattrtext (p_itemtype, p_itemkey, 'RESULTOUT');
      -- to find out wheather planning/ marketing team approves or rejects from notification
      fnd_file.put_line (fnd_file.log,'lc_flow_status_code' || lc_flow_status_code);
      fnd_file.put_line (fnd_file.log,'lc_resultout' || lc_resultout);
      fnd_file.put_line (fnd_file.log,'lc_global_decision' || lc_global_decision);



              insert into xxhil.xxhil_o2cl_uda_log_t_ds values(xxhil.xxhil_o2cl_uda_log_s_ds.nextval,lc_flow_status_code,'Before If Result_out:'||lc_resultout||'__'||'Uda Status:'||lc_uda_status);
      IF (lc_flow_status_code != 'APPROVED'
          AND lc_flow_status_code != 'REJECTED')
      THEN
                     insert into xxhil.xxhil_o2cl_uda_log_t_ds values(xxhil.xxhil_o2cl_uda_log_s_ds.nextval,lc_flow_status_code,'Inside If Result_out:'||lc_resultout||'__'||'Uda Status:'||lc_uda_status);

         IF lc_flow_status_code = 'PWMT'
            AND lc_uda_status = 'Sent for alternate proposal approval'
         THEN                                   -- pending with marketing team
            fnd_file.put_line (fnd_file.log,'Inside');
            --            lc_performer        :=  'sysadmin';     --have to update
            lc_complete_code := 'PWMT';
            lc_subject_code := 'XXHIL_UDA_MATEAM_SUBJECT';
            --pending with marketing team message after quality team updates alternate proposal
            lc_message_code := 'XXHIL_UDA_MATEAM_MESSAGE';
            lc_distribution_code := lc_org||'-ALPS-UDA#MKT';
         ELSIF lc_flow_status_code = 'PWPT' AND lc_uda_status = 'Sent for formula change approval'
         THEN                                    -- pending with planning team
            --            lc_performer        :=  'sysadmin';   --have to update
            lc_complete_code := 'PWPT';
            lc_subject_code := 'XXHIL_UDA_POTEAM_SUBJECT';
            -- pending with planning team after quality team updates global decision
            lc_message_code := 'XXHIL_UDA_POTEAM_MESSAGE';
            lc_distribution_code := lc_org||'-GCF-UDA#PLN';
         ELSIF lc_flow_status_code = 'PWPT' AND lc_uda_status = 'Sent for resource change approval'
         THEN                                    -- pending with planning team
            --            lc_performer        :=  'sysadmin';   --have to update
            lc_complete_code := 'PWPT';
            lc_subject_code := 'XXHIL_UDA_POTEAM_SUBJECT';
            -- pending with planning team after quality team updates global decision
            lc_message_code := 'XXHIL_UDA_POTEAM_MESSAGE';
            lc_distribution_code := lc_org||'-GCR-UDA#PLN';
         ELSIF lc_flow_status_code = 'PWPT' AND lc_uda_status = 'Sent for formula and resource change approval'
         THEN                                    -- pending with planning team
            --            lc_performer        :=  'sysadmin';   --have to update
            lc_complete_code := 'PWPT';
            lc_subject_code := 'XXHIL_UDA_POTEAM_SUBJECT';
            -- pending with planning team after quality team updates global decision
            lc_message_code := 'XXHIL_UDA_POTEAM_MESSAGE';
            lc_distribution_code := lc_org||'-GCFR-UDA#PLN';
         /*elsif lc_flow_status_code = 'rejected'
         then
            -- rejected from quality team final stage

            lc_performer := 'sysadmin';                       --have to update
            lc_complete_code := 'rejected';
            lc_subject_code := 'xxhil_csr_uda_rej_subject';
            -- rejected message to marketing team from quality team
            lc_message_code := 'xxhil_uda_rej_message';*/
         ELSIF lc_flow_status_code = 'PWQTA'
         THEN
            -- pending with quality team approval from planning/marketing team approves or reject from notification
            -- insert into xxhil.xxhil_o2cl_uda_log_t_ds values(xxhil.xxhil_o2cl_uda_log_s.nextval,lc_flow_status_code,'in PWQTA lc_resultout:'||lc_resultout||'__'||'lc_uda_status : '||lc_uda_status);



           IF (lc_resultout = 'Approve'-- to check if variable issue
                AND lc_uda_status = 'Alternate Proposal Approved')
            THEN
               --                    lc_performer        :=  'sysadmin';   --have to update
               lc_complete_code := 'PWQTA';
               lc_subject_code := 'XXHIL_UDA_PWQTA_SUBJECT';
               -- pending with quality team approval from marketing team after approves the request
               lc_message_code := 'XXHIL_UDA_PWQTA_MESSAGE';
               lc_distribution_code := lc_org||'-ALPA-UDA#QTY';
            ELSIF (lc_resultout = 'Approve' AND lc_uda_status = 'Formula change approved')
            THEN
               -- pending with quality team approval from planning team after approves the request
               --                    lc_performer        :=  'sysadmin';   --have to update
               lc_complete_code := 'PWQTA';
               lc_subject_code := 'XXHIL_UDA_PWQTA_SUBJECT';
               lc_message_code := 'XXHIL_UDA_PWQTPA_MESSAGE';
               -- pending with quality team approval from planning team after approves the request
               lc_distribution_code := lc_org||'-GCFA-UDA#QTY';
            ELSIF (lc_resultout = 'Approve' AND lc_uda_status = 'Resource change approved')
            THEN
               -- pending with quality team approval from planning team after approves the request
               --                    lc_performer        :=  'sysadmin';   --have to update
               lc_complete_code := 'PWQTA';
               lc_subject_code := 'XXHIL_UDA_PWQTPA_SUBJECT';
               lc_message_code := 'XXHIL_UDA_PWQTPA_MESSAGE';
               -- pending with quality team approval from planning team after approves the request
               lc_distribution_code := lc_org||'-GCRA-UDA#QTY';
            ELSIF (lc_resultout = 'Approve' AND lc_uda_status = 'Formula and resource change approved')
            THEN
               -- pending with quality team approval from planning team after approves the request
               --                    lc_performer        :=  'sysadmin';   --have to update
               lc_complete_code := 'PWQTA';
               lc_subject_code := 'XXHIL_UDA_PWQTPA_SUBJECT';
               lc_message_code := 'XXHIL_UDA_PWQTPA_MESSAGE';
               -- pending with quality team approval from planning team after approves the request
               lc_distribution_code := lc_org||'-GCFRA-UDA#QTY';
            ELSIF (lc_resultout = 'Reject' AND lc_uda_status = 'Alternate Proposal Rejected')
            THEN
               -- pending with quality team approval from marketing team after reject the request
               --                    lc_performer        :=  'sysadmin';   --have to update
               lc_complete_code := 'PWQTA';
               lc_subject_code := 'XXHIL_UDA_PWQTMR_SUBJECT';
               lc_message_code := 'XXHIL_UDA_PWQTMR_MESSAGE';
               -- pending with quality team approval from marketing team after reject the request
               lc_distribution_code := lc_org||'-ALPR-UDA#QTY';
            ELSIF (lc_resultout = 'Reject' AND lc_uda_status = 'Formula change rejected')
            THEN
               --                    lc_performer        :=  'sysadmin';   --have to update
               lc_complete_code := 'PWQTA';
               lc_subject_code := 'XXHIL_UDA_PWQTPR_SUBJECT';
               lc_message_code := 'XXHIL_UDA_PWQTPR_MESSAGE';
               -- pending with quality team approval from planning team after reject the request
               lc_distribution_code := lc_org||'-GCFR-UDA#QTY';
            ELSIF (lc_resultout = 'Reject' AND lc_uda_status = 'Resource change rejected')
            THEN
               --                    lc_performer        :=  'sysadmin';   --have to update
               lc_complete_code := 'PWQTA';
               lc_subject_code := 'XXHIL_UDA_PWQTPR_SUBJECT';
               lc_message_code := 'XXHIL_UDA_PWQTPR_MESSAGE';
               -- pending with quality team approval from planning team after reject the request
               lc_distribution_code := lc_org||'-GCRR-UDA#QTY';
            ELSIF (lc_resultout = 'Reject' AND lc_uda_status = 'Formula and resource change rejected')
            THEN
               --                    lc_performer        :=  'sysadmin';   --have to update
               lc_complete_code := 'PWQTA';
               lc_subject_code := 'XXHIL_UDA_PWQTPR_SUBJECT';
               lc_message_code := 'XXHIL_UDA_PWQTPR_MESSAGE';
               -- pending with quality team approval from planning team after reject the request
               lc_distribution_code := lc_org||'-GCFRR-UDA#QTY';
            END IF;
         ELSIF lc_flow_status_code = 'CWFG'
         THEN
            lc_performer := 'SYSADMIN';                       --have to update
            lc_complete_code := 'CWFG';
            lc_subject_code := 'XXHIL_UDA_FG_MT_SUBJECT';
            lc_message_code := 'XXHIL_UDA_FG_MT_MESSAGE';
            lc_distribution_code := lc_org||'-GCFG-CSR#MKT';
         -- have to discuss about approve/ reject message from planning / marketing team to quality team
         /*elsif lc_flow_status_code = 'approved'
         then
            lc_performer := 'sysadmin';                       --have to update
            lc_complete_code := 'approved';
            lc_subject_code := 'xxhil_csr_uda_approved_subject';
            lc_message_code := 'xxhil_uda_approved_message';*/
         END IF;

         BEGIN
            fnd_message.set_name ('XXHIL', lc_subject_code);
            fnd_message.set_token ('UDA_REF_NO', lc_uda_number);
            fnd_message.set_token ('CSR_UDA_REF_NO', lc_csr_number);
            lc_subject := fnd_message.get;
         END;

         BEGIN
            fnd_message.set_name ('XXHIL', lc_message_code);
            fnd_message.set_token ('PERFORMER', lc_performer);
            fnd_message.set_token ('REQUESTNO', lc_request_no);
            fnd_message.set_token ('UDA_REF_NO', lc_uda_number);
            fnd_message.set_token ('CSR_UDA_REF_NO', lc_csr_number);
            fnd_message.set_token ('UDASTATUS', lc_uda_status);
            fnd_message.set_token ('CUSTOMERNAME', lc_customer_name);
            fnd_message.set_token ('ORG', lc_org);
            fnd_message.set_token ('FGITEM', lc_fg_item);
            fnd_message.set_token('INSTRUCTIONS'  , lc_instructions);
            fnd_message.set_token('REASON'        , lc_reason);
            fnd_message.set_token('WF_COMMENTS',lc_wf_comments);
            lc_message := fnd_message.get;
         END;

         BEGIN
            SELECT   to_recipients, cc_recipients
              INTO   lc_to_recipients, lc_cc_recipients
              FROM   alr_distribution_lists
             WHERE   name = lc_distribution_code;
         END;

          --insert into xxhil.xxhil_o2cl_uda_log_t_ds values(xxhil.xxhil_o2cl_uda_log_s.nextval,lc_flow_status_code,'Subject:'||lc_subject||'__'||'To :'||lc_to_recipients||'__'||'CC :'||lc_cc_recipients);

--         lc_document_id := 'PLSQL:XXHIL_O2CL_UDA_WF_PKG.get_document_details/' || lc_itemkey;

--          insert into xxhil.xxhil_o2cl_uda_log_t_ds values(xxhil.xxhil_o2cl_uda_log_s.nextval,'Docment ID','lc_document_id:'||lc_document_id);

       wf_engine.setitemattrtext (p_itemtype,
                                    p_itemkey,
                                    '#FROM_ROLE',
                                    'SYSADMIN');
         wf_engine.setitemattrtext (p_itemtype,
                                    p_itemkey,
                                    'SUBJECT',
                                    lc_subject);
         wf_engine.setitemattrtext (p_itemtype,
                                    p_itemkey,
                                    'MESSAGE',
                                    lc_message);
         wf_engine.setitemattrtext (p_itemtype,
                                    p_itemkey,
                                    'PERFORMER',
                                    lc_to_recipients);
         wf_engine.setitemattrtext (p_itemtype,
                                    p_itemkey,
                                    '#WFM_CC',
                                    lc_cc_recipients);
         wf_engine.setitemattrtext (p_itemtype,
                                    p_itemkey,
                                    'LINKAGE_HEADER_ID',
                                    lc_LINKAGE_HEADER_ID);
        /* wf_engine.setitemattrtext (p_itemtype,
                                    p_itemkey,
                                    'ALT_PROP_LINE_BODY',
                                    lc_document_id);*/


      ELSE

       --insert into xxhil.xxhil_o2cl_uda_log_t_ds values(xxhil.xxhil_o2cl_uda_log_s.nextval,lc_flow_status_code,'Main Else Part Result_out:'||lc_resultout||'__'||'Uda Status:'||lc_uda_status);

         lc_complete_code := lc_flow_status_code;

      END IF;




      IF lc_flow_status_code = 'PWQTA'
      THEN
         insert_history (lc_request_no,
                         lc_uda_status,
                         lv_wf_note,
                         lc_uda_number,
                         lc_flow_status_code,
                         p_itemkey,
                         lc_distribution_code);
      END IF;

     -- insert into xxhil.xxhil_o2cl_uda_log_t_ds values(xxhil.xxhil_o2cl_uda_log_s.nextval,'GET_APP_FINAL','Get App Final Result_out:'||lc_complete_code);

      x_resultout := 'COMPLETE:' || lc_complete_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         wf_core.context ('XXHIL_O2CL_UDA_WF_DS_PKG',
                          'get_next_approver',
                          p_itemtype,
                          p_itemkey,
                          ln_debug_info);
         fnd_file.put_line (fnd_file.log,'lc_flow_status_code' || SQLERRM);
         RAISE;
   END get_next_approver;

   PROCEDURE release_workflow (p_uda_ref_no IN VARCHAR2)
   IS
      lc_item_key          VARCHAR2 (240);
      lc_item_type         VARCHAR2 (8);
      lc_block_type        VARCHAR2 (20);
      lc_flow_status       VARCHAR2 (30);
      ln_debug_no          NUMBER;
      lc_response          VARCHAR2 (30);
      ln_hist_id           NUMBER;
      lc_pending_with      VARCHAR2 (60);
      lc_request_num       VARCHAR2 (50);
      lc_approval_status   VARCHAR2 (15);
      lc_uda_status        VARCHAR2 (75);
      lc_csr_ref_no        VARCHAR2 (200);
      lc_err_msg           VARCHAR2 (4000);

      CURSOR c1
      IS
         SELECT   request_number,
                  wf_approval_status,
                  status,
                  csr_ref_no_ver_no
           FROM   xxhil.xxhil_om_linkage_header_ds
          WHERE   uda_ref_no = p_uda_ref_no;
   --'1012|1' --have to update parameter
   --    and rownum = 1;  --have to remove

   BEGIN
      OPEN c1;

      FETCH c1
         INTO
                   lc_request_num, lc_approval_status, lc_uda_status, lc_csr_ref_no;

      CLOSE c1;


      lc_item_key :=
            'HILUDA_DS_'
         || p_uda_ref_no
         || '|'
         || SUBSTR (lc_csr_ref_no, 1, INSTR (lc_csr_ref_no, '|', 1) - 1);
      --'hilcsr_'||to_char(p_ref_no);
      lc_item_type := 'XXHUDA_DS';
      lc_flow_status := lc_approval_status;
      -- have to discuss about status from trigger

      ln_debug_no := 1;
      --    update  xxhil.xxhil_om_linkage_header
      --    set     wf_item_type        =   lc_item_type,
      --            wf_item_key         =   lc_item_key,
      --            wf_approval_status  =   lc_flow_status
      --    where   csr_ref_no_ver_no   =   '1012|1'
      --    and linkage_header_id = 1000088;--have to update parameter

      insert_history (lc_request_num,
                      lc_uda_status,
                      NULL,
                      p_uda_ref_no,
                      lc_flow_status,
                      lc_item_key,
                      NULL);

      BEGIN
         wf_engine.completeactivity (lc_item_type,
                                     lc_item_key,
                                     'BLOCK',
                                     'Approve');
         wf_engine.background (lc_item_type);
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         wf_core.context ('XXHIL_O2CL_UDA_WF_DS_PKG',
                          'release_workflow',
                          lc_item_type,
                          lc_item_key,
                          ln_debug_no);

         INSERT INTO xxhil.xxhil_o2cl_uda_release_trg_t
           VALUES   (lc_item_type,
                     NULL,
                     lc_approval_status,
                     SYSDATE,
                     'Inside Release Exception :' || lc_err_msg);

         RAISE;
   END release_workflow;

   PROCEDURE insert_history (p_request_no      IN VARCHAR2,
                             p_action          IN VARCHAR2,
                             p_appr_comments   IN VARCHAR2,
                             p_ref_no          IN VARCHAR2,
                             p_status          IN VARCHAR2,
                             p_item_key        IN VARCHAR2,
                             p_dist_list       IN VARCHAR2)
   IS
      ln_hist_id       NUMBER;
      ln_approver_id   NUMBER;
      ln_request_id    NUMBER;
      ln_iteration     NUMBER;
      ln_person_id     NUMBER;
      lc_response      VARCHAR2 (100);
      lc_item_key      VARCHAR2 (200);
      v_history_id     NUMBER;
      lc_csr_ref_no    VARCHAR2 (200);
   --  cursor hist_cur
   --  is
   --   select request_id,wf_item_key,wf_item_type,iteration
   --   from xxolm_lms_requests_t where request_id=p_request_id;
   BEGIN
      /*select   substr (csr_ref_no_ver_no,
                       1,
                       instr (csr_ref_no_ver_no, '|', 1) - 1)
        into   lc_csr_ref_no
        from   xxhil.xxhil_om_linkage_header
       where   uda_ref_no = p_ref_no;*/
      --and request_number = p_request_no;

      SELECT   xxhi_o2cl_wf_seq.NEXTVAL INTO v_history_id FROM DUAL;

      --      ln_hist_id       := xxolm_wf_approver_hist_s.nextval;
      --      for hist_rec in hist_cur
      --      loop
      --      ln_request_id    := hist_rec.request_id;
      --      ln_iteration     := hist_rec.iteration;
      --      ln_approver_id   := p_person_id;
      --      end loop;
      --      ln_approver_id   := p_person_id;
      --      lc_response      := p_action;

      -- inserting the values into action history table

      INSERT   ALL
        INTO   xxhil_o2cl_action_hist_t_ds (history_id,
                                         request_no,
                                         TYPE,
                                         reference_no,
                                         o2cl_status,
                                         changes_type,
                                         wf_item_type,
                                         wf_item_key,
                                         creation_date,
                                         created_by,
                                         approver_comments,
                                         action_date,
                                         wf_status,
                                         distribution_list)
      VALUES   (history_id,
                request_no,
                TYPE,
                reference_no,
                o2cl_status,
                changes_type,
                wf_item_type,
                wf_item_key,
                creation_date,
                created_by,
                approver_comments,
                action_date,
                wf_status,
                distribution_list)
         WITH SOURCE_DATA AS (SELECT   v_history_id history_id,
                                       p_request_no request_no,
                                       'UDA' TYPE,
                                       p_ref_no reference_no,
                                       p_action o2cl_status,
                                       NULL changes_type,
                                       'XXHUDA_DS' wf_item_type,
                                       p_item_key wf_item_key,
                                       SYSDATE creation_date,
                                       fnd_global.user_id created_by,
                                       p_appr_comments approver_comments,
                                       SYSDATE action_date,
                                       p_status wf_status,
                                       p_dist_list distribution_list
                                FROM   DUAL)
         SELECT   history_id,
                  request_no,
                  TYPE,
                  reference_no,
                  o2cl_status,
                  changes_type,
                  wf_item_type,
                  wf_item_key,
                  creation_date,
                  created_by,
                  approver_comments,
                  action_date,
                  wf_status,
                  distribution_list
           FROM   SOURCE_DATA src
          WHERE   1 = 1
                  AND NOT EXISTS
                        (SELECT   1
                           FROM   xxhil_o2cl_action_hist_t_ds X3
                          WHERE       1 = 1
                                  AND x3.reference_no = src.reference_no
                                  AND x3.wf_item_key = src.wf_item_key
                                  AND x3.wf_status = src.wf_status);


      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         wf_core.context ('XXHIL_O2CL_UDA_WF_PKG', 'insert_history');
         RAISE;
   END insert_history;

   FUNCTION get_url (p_func_name    IN VARCHAR2,
                     p_resp_name    IN VARCHAR2,
                     p_parameters   IN VARCHAR2)
      RETURN VARCHAR2
   AS
      lc_item_key      VARCHAR2 (240);
      lc_item_type     VARCHAR2 (8);
      lc_block_type    VARCHAR2 (20);
      lc_flow_status   VARCHAR2 (30);
      ln_debug_no      NUMBER;
      l_resp_appl_id   NUMBER;
      l_resp_id        NUMBER;
      l_function_id    NUMBER;
      lc_url           VARCHAR (400);
   BEGIN
      l_function_id :=
         fnd_function.get_function_id (p_function_name => p_func_name /* function name */
                                                                     );

      SELECT   responsibility_id, application_id
        INTO   l_resp_id, l_resp_appl_id
        FROM   fnd_responsibility_tl
       WHERE   responsibility_name = p_resp_name;

      --responsibility name to which we attach the function


      lc_url :=
         fnd_run_function.get_run_function_url (
            p_function_id         => l_function_id,
            p_resp_appl_id        => l_resp_appl_id,
            p_resp_id             => l_resp_id,
            p_security_group_id   => 0,
            p_parameters          => 'P_UDA_REF_NO=' || p_parameters,
            -- have to discuss about parameter
            p_override_agent      => NULL,
            p_org_id              => NULL,
            p_lang_code           => NULL,
            p_encryptparameters   => TRUE
         );

      fnd_file.put_line (fnd_file.log,'URL --> ' || lc_url);

      RETURN lc_url;         -- || '/="_blank"exit="-noframemerging"';
   EXCEPTION
      WHEN OTHERS
      THEN
         wf_core.context ('XXHIL_O2CL_UDA_WF_DS_PKG',
                          'get_url',
                          lc_item_type,
                          lc_item_key,
                          ln_debug_no);
         RAISE;
   END get_url;

   PROCEDURE validate_response (p_itemtype    IN            VARCHAR2,
                                p_itemkey     IN            VARCHAR2,
                                p_actid       IN            NUMBER,
                                p_funcmode    IN            VARCHAR2,
                                x_resultout      OUT NOCOPY VARCHAR2)
   IS
      lv_wf_note       VARCHAR2 (4000);
      lv_response      VARCHAR2 (100);
      lc_err_msg       VARCHAR2 (240);
      lc_o2cl_status   VARCHAR2 (70);
   BEGIN
      IF (p_funcmode = 'RESPOND')
      THEN
         lv_response :=
            wf_notification.getattrtext (wf_engine.context_nid, 'RESULT');
         lv_wf_note :=
            wf_notification.getattrtext (wf_engine.context_nid, 'NOTE');

         BEGIN
            SELECT   status
              INTO   lc_o2cl_status
              FROM   xxhil.xxhil_om_linkage_header_ds
             WHERE   'HILUDA_DS_' || uda_ref_no || '|'
                     || SUBSTR (csr_ref_no_ver_no,
                                1,
                                INSTR (csr_ref_no_ver_no, '|', 1) - 1) =
                        p_itemkey;
         END;

       --  insert into xxhil.xxhil_o2cl_uda_log_t_ds values(xxhil.xxhil_o2cl_uda_log_s.nextval,'VAL_RES','Validate Response, respone:'||lv_response||'__'||'Form Status'||lc_o2cl_status);



         IF (lv_response = 'APPROVED')
         THEN
            IF (lc_o2cl_status = 'Sent for alternate proposal approval')
            THEN
               BEGIN
                  UPDATE   xxhil.xxhil_om_linkage_header_ds
                     SET   wf_item_type = p_itemtype,
                           wf_item_key = p_itemkey,
                           wf_approval_status = 'PWQTA',
                           wf_comments = lv_wf_note,
                           status = 'Alternate Proposal Approved'
                   WHERE   'HILUDA_DS_' || uda_ref_no || '|'
                           || SUBSTR (csr_ref_no_ver_no,
                                      1,
                                      INSTR (csr_ref_no_ver_no, '|', 1) - 1) =
                              p_itemkey;

                  wf_engine.setitemattrtext (p_itemtype,
                                             p_itemkey,
                                             'RESULTOUT',
                                             'Approve');
               END;
            ELSIF (lc_o2cl_status = 'Sent for formula change approval')
            THEN
               BEGIN
                  UPDATE   xxhil.xxhil_om_linkage_header_ds
                     SET   wf_item_type = p_itemtype,
                           wf_item_key = p_itemkey,
                           wf_approval_status = 'PWQTA',
                           wf_comments = lv_wf_note,
                           status = 'Formula change approved'
                   WHERE   'HILUDA_DS_' || uda_ref_no || '|'
                           || SUBSTR (csr_ref_no_ver_no,
                                      1,
                                      INSTR (csr_ref_no_ver_no, '|', 1) - 1) =
                              p_itemkey;

                  wf_engine.setitemattrtext (p_itemtype,
                                             p_itemkey,
                                             'RESULTOUT',
                                             'Approve');
               END;
            ELSIF (lc_o2cl_status = 'Sent for resource change approval')
            THEN
               BEGIN
                  UPDATE   xxhil.xxhil_om_linkage_header_ds
                     SET   wf_item_type = p_itemtype,
                           wf_item_key = p_itemkey,
                           wf_approval_status = 'PWQTA',
                           wf_comments = lv_wf_note,
                           status = 'Resource change approved'
                   WHERE   'HILUDA_DS_' || uda_ref_no || '|'
                           || SUBSTR (csr_ref_no_ver_no,
                                      1,
                                      INSTR (csr_ref_no_ver_no, '|', 1) - 1) =
                              p_itemkey;

                  wf_engine.setitemattrtext (p_itemtype,
                                             p_itemkey,
                                             'RESULTOUT',
                                             'Approve');
               END;
            ELSIF (lc_o2cl_status = 'Sent for formula and resource change approval')
            THEN
               BEGIN
                  UPDATE   xxhil.xxhil_om_linkage_header_ds
                     SET   wf_item_type = p_itemtype,
                           wf_item_key = p_itemkey,
                           wf_approval_status = 'PWQTA',
                           wf_comments = lv_wf_note,
                           status = 'Formula and resource change approved'
                   WHERE   'HILUDA_DS_' || uda_ref_no || '|'
                           || SUBSTR (csr_ref_no_ver_no,
                                      1,
                                      INSTR (csr_ref_no_ver_no, '|', 1) - 1) =
                              p_itemkey;

                  wf_engine.setitemattrtext (p_itemtype,
                                             p_itemkey,
                                             'RESULTOUT',
                                             'Approve');
               END;
            END IF;
         ELSE
            IF (lc_o2cl_status = 'Sent for alternate proposal approval')
            THEN
               BEGIN
                  UPDATE   xxhil.xxhil_om_linkage_header_ds
                     SET   wf_item_type = p_itemtype,
                           wf_item_key = p_itemkey,
                           wf_approval_status = 'PWQTA',
                           wf_comments = lv_wf_note,
                           status = 'Alternate Proposal Rejected'
                   WHERE   'HILUDA_DS_' || uda_ref_no || '|'
                           || SUBSTR (csr_ref_no_ver_no,
                                      1,
                                      INSTR (csr_ref_no_ver_no, '|', 1) - 1) =
                              p_itemkey;

                  wf_engine.setitemattrtext (p_itemtype,
                                             p_itemkey,
                                             'RESULTOUT',
                                             'Reject');
               END;
            ELSIF (lc_o2cl_status = 'Sent for formula change approval')
            THEN
               BEGIN
                  UPDATE   xxhil.xxhil_om_linkage_header_ds
                     SET   wf_item_type = p_itemtype,
                           wf_item_key = p_itemkey,
                           wf_approval_status = 'PWQTA',
                           wf_comments = lv_wf_note,
                           status = 'Formula change rejected'
                   WHERE   'HILUDA_DS_' || uda_ref_no || '|'
                           || SUBSTR (csr_ref_no_ver_no,
                                      1,
                                      INSTR (csr_ref_no_ver_no, '|', 1) - 1) =
                              p_itemkey;

                  wf_engine.setitemattrtext (p_itemtype,
                                             p_itemkey,
                                             'RESULTOUT',
                                             'Reject');
               END;
            ELSIF (lc_o2cl_status = 'Sent for resource change approval')
            THEN
               BEGIN
                  UPDATE   xxhil.xxhil_om_linkage_header_ds
                     SET   wf_item_type = p_itemtype,
                           wf_item_key = p_itemkey,
                           wf_approval_status = 'PWQTA',
                           wf_comments = lv_wf_note,
                           status = 'Resource change rejected'
                   WHERE   'HILUDA_DS_' || uda_ref_no || '|'
                           || SUBSTR (csr_ref_no_ver_no,
                                      1,
                                      INSTR (csr_ref_no_ver_no, '|', 1) - 1) =
                              p_itemkey;

                  wf_engine.setitemattrtext (p_itemtype,
                                             p_itemkey,
                                             'RESULTOUT',
                                             'Reject');
               END;
            ELSIF (lc_o2cl_status = 'Sent for formula and resource change approval')
            THEN
               BEGIN
                  UPDATE   xxhil.xxhil_om_linkage_header_ds
                     SET   wf_item_type = p_itemtype,
                           wf_item_key = p_itemkey,
                           wf_approval_status = 'PWQTA',
                           wf_comments = lv_wf_note,
                           status = 'Formula and resource change rejected'
                   WHERE   'HILUDA_DS_' || uda_ref_no || '|'
                           || SUBSTR (csr_ref_no_ver_no,
                                      1,
                                      INSTR (csr_ref_no_ver_no, '|', 1) - 1) =
                              p_itemkey;

                  wf_engine.setitemattrtext (p_itemtype,
                                             p_itemkey,
                                             'RESULTOUT',
                                             'Reject');
               END;
            END IF;
         END IF;

         COMMIT;
      END IF;
   END validate_response;

   PROCEDURE update_approved_workfllow (p_itemtype    IN     VARCHAR2,
                                        p_itemkey     IN     VARCHAR2,
                                        p_actid       IN     NUMBER,
                                        p_funcmode    IN     VARCHAR2,
                                        x_resultout      OUT VARCHAR2)
   AS
      CURSOR c1
      IS
         SELECT   a.request_number,
                  b.organization_name,
                  a.org_code,
                  a.csr_ref_no_ver_no,
                  a.uda_ref_no,
                  a.customer_name,
                  a.customer_ship,
                  a.fg_item_name,
                  a.status,
                  a.wf_approval_status,
                  a.global_decision,
                  a.wf_comments,
                  a.INSTRUCTIONS2,
                  a.REASON
           FROM   xxhil.xxhil_om_linkage_header_ds a,
                  org_organization_definitions b
          WHERE   a.org_id = b.organization_id
                  AND 'HILUDA_DS_' || uda_ref_no =
                        SUBSTR (p_itemkey, 1, INSTR (p_itemkey,
                                                     '|',
                                                     -1,
                                                     2)
                                              + 1);

      lc_flow_status_code    VARCHAR2 (25);
      lc_request_no          VARCHAR2 (30);
      lc_performer           VARCHAR2 (20);
      lc_complete_code       VARCHAR2 (20);
      lc_subject             VARCHAR2 (4000);
      lc_message             VARCHAR2 (4000);
      lc_subject_code        VARCHAR2 (240);
      lc_message_code        VARCHAR2 (240);
      lc_csr_number          VARCHAR2 (50);
      lc_uda_number          VARCHAR2 (200);
      lc_fg_item             VARCHAR2 (150);
      lc_org                 VARCHAR2 (25);
      lc_customer_name       VARCHAR2 (150);
      lc_uda_status          VARCHAR2 (100);
      ln_debug_info          NUMBER;
      lc_global_decision     VARCHAR2 (240);
      lv_wf_note             VARCHAR2 (4000) := NULL;
      lc_to_recipients       VARCHAR2 (50);
      lc_cc_recipients       VARCHAR2 (240);
      lc_distribution_code   VARCHAR2 (50);
      lc_reason               varchar2(4000);
      lc_instructions         varchar2(4000);
   BEGIN
      FOR i IN c1
      LOOP
         lc_flow_status_code := i.wf_approval_status;
         lc_request_no := i.request_number;
         lc_csr_number := i.csr_ref_no_ver_no;
         lc_uda_number := i.uda_ref_no;
         lc_uda_status := i.status;
         lc_customer_name := i.customer_name;
         lc_org := i.org_code;--organization_name;
         lc_fg_item := i.fg_item_name;
         lc_global_decision := i.global_decision;
         lv_wf_note := i.wf_comments;
         lc_reason           :=  i.reason;
         lc_instructions     :=  i.INSTRUCTIONS2;
      END LOOP;

      IF (lc_flow_status_code = 'APPROVED')
      THEN
         lc_complete_code := 'APPROVED';
         lc_subject_code := 'XXHIL_UDA_APPROVED_SUBJECT';
         lc_message_code := 'XXHIL_UDA_APPROVED_MESSAGE';
         lc_distribution_code := lc_org||'-APP-UDA#MKT';
      ELSE
         lc_complete_code := 'REJECTED';
         lc_subject_code := 'XXHIL_UDA_REJ_SUBJECT';
         -- rejected message to marketing team from quality team
         lc_message_code := 'XXHIL_UDA_REJ_MESSAGE';
         lc_distribution_code := lc_org||'-REJ-UDA#MKT';
      END IF;

      BEGIN
         fnd_message.set_name ('XXHIL', lc_subject_code);
         fnd_message.set_token ('UDA_REF_NO', lc_uda_number);
         fnd_message.set_token ('CSR_UDA_REF_NO', lc_csr_number);
         lc_subject := fnd_message.get;
      END;

      BEGIN
         fnd_message.set_name ('XXHIL', lc_message_code);
         fnd_message.set_token ('PERFORMER', lc_performer);
         fnd_message.set_token ('REQUESTNO', lc_request_no);
         fnd_message.set_token ('UDA_REF_NO', lc_uda_number);
         fnd_message.set_token ('CSR_UDA_REF_NO', lc_csr_number);
         fnd_message.set_token ('UDASTATUS', lc_uda_status);
         fnd_message.set_token ('CUSTOMERNAME', lc_customer_name);
         fnd_message.set_token ('ORG', lc_org);
         fnd_message.set_token ('FGITEM', lc_fg_item);
         fnd_message.set_token('INSTRUCTIONS'  , lc_instructions);
          fnd_message.set_token('REASON'        , lc_reason);
         lc_message := fnd_message.get;
      END;

      BEGIN
         SELECT   to_recipients, cc_recipients
           INTO   lc_to_recipients, lc_cc_recipients
           FROM   alr_distribution_lists
          WHERE   name = lc_distribution_code;
      END;

      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 '#FROM_ROLE',
                                 'SYSADMIN');
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 'SUBJECT',
                                 lc_subject);
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 'MESSAGE',
                                 lc_message);
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 'PERFORMER',
                                 lc_to_recipients);
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 '#WFM_CC',
                                 lc_cc_recipients);
   EXCEPTION
      WHEN OTHERS
      THEN
         wf_core.context ('XXHIL_O2CL_UDA_WF_DS_PKG',
                          'update_approved_workfllow',
                          p_itemtype,
                          p_itemkey,
                          ln_debug_info);
         RAISE;
   END update_approved_workfllow;

   PROCEDURE send_plannedteam_ntf (p_itemtype    IN     VARCHAR2,
                                   p_itemkey     IN     VARCHAR2,
                                   p_actid       IN     NUMBER,
                                   p_funcmode    IN     VARCHAR2,
                                   x_resultout      OUT VARCHAR2)
   AS
      CURSOR c1
      IS
         SELECT   a.request_number,
                  b.organization_name,
                  a.csr_ref_no_ver_no,
                  a.uda_ref_no,
                  a.customer_name,
                  a.customer_ship,
                  a.fg_item_name,
                  a.status,
                  a.wf_approval_status,
                  a.global_decision,
                  a.wf_comments,
                  a.INSTRUCTIONS2,
                  a.REASON
           FROM   xxhil.xxhil_om_linkage_header a,
                  org_organization_definitions b
          WHERE   a.org_id = b.organization_id
                  AND 'HILUDA_DS_' || uda_ref_no =
                        SUBSTR (p_itemkey, 1, INSTR (p_itemkey,
                                                     '|',
                                                     -1,
                                                     2)
                                              + 1);

      lc_flow_status_code    VARCHAR2 (25);
      lc_request_no          VARCHAR2 (30);
      lc_performer           VARCHAR2 (20);
      lc_complete_code       VARCHAR2 (20);
      lc_subject             VARCHAR2 (4000);
      lc_message             VARCHAR2 (4000);
      lc_subject_code        VARCHAR2 (240);
      lc_message_code        VARCHAR2 (240);
      lc_csr_number          VARCHAR2 (50);
      lc_uda_number          VARCHAR2 (50);
      lc_fg_item             VARCHAR2 (150);
      lc_org                 VARCHAR2 (25);
      lc_customer_name       VARCHAR2 (150);
      lc_uda_status          VARCHAR2 (100);
      ln_debug_info          NUMBER;
      lc_global_decision     VARCHAR2 (240);
      lv_wf_note             VARCHAR2 (4000) := NULL;
      lc_to_recipients       VARCHAR2 (50);
      lc_cc_recipients       VARCHAR2 (240);
      lc_distribution_code   VARCHAR2 (50);
      lc_reason               varchar2(4000);
      lc_instructions         varchar2(4000);
   BEGIN
      FOR i IN c1
      LOOP
         lc_flow_status_code := i.wf_approval_status;
         lc_request_no := i.request_number;
         lc_csr_number := i.csr_ref_no_ver_no;
         lc_uda_number := i.uda_ref_no;
         lc_uda_status := i.status;
         lc_customer_name := i.customer_name;
         lc_org := i.organization_name;
         lc_fg_item := i.fg_item_name;
         lc_global_decision := i.global_decision;
         lv_wf_note := i.wf_comments;
         lc_reason           :=  i.reason;
         lc_instructions     :=  i.INSTRUCTIONS2;

      END LOOP;


      IF (lc_flow_status_code = 'APPROVED')
      THEN
         lc_complete_code := 'APPROVED';
         lc_subject_code := 'XXHIL_UDA_APPROVED_PT_SUBJECT';
         --'xxhil_csr_approved_pt_subject';
         lc_message_code := 'XXHIL_UDA_APPROVED_PT_MESSAGE';
         --'xxhil_csr_approved_pt_message';
         lc_distribution_code := lc_org||'-APP-UDA#PLN';
      ELSE
         lc_complete_code := 'REJECTED';
         lc_subject_code := 'XXHIL_UDA_REJ_PT_SUBJECT';
         --'xxhil_csr_rej_pt_subject';  -- rejected message to marketing team from quality team
         lc_message_code := 'XXHIL_UDA_REJ_PT_MESSAGE';
         --'xxhil_csr_rej_pt_message';
         lc_distribution_code := lc_org||'-REJ-UDA#PLN';
      END IF;

      BEGIN
         fnd_message.set_name ('XXHIL', lc_subject_code);
         fnd_message.set_token ('UDA_REF_NO', lc_uda_number);
         lc_subject := fnd_message.get;
      END;

      BEGIN
         fnd_message.set_name ('XXHIL', lc_message_code);
         fnd_message.set_token ('PERFORMER', lc_performer);
         fnd_message.set_token ('REQUESTNO', lc_request_no);
         fnd_message.set_token ('UDA_REF_NO', lc_uda_number);
         fnd_message.set_token ('CSR_UDA_REF_NO', lc_csr_number);
         fnd_message.set_token ('UDASTATUS', lc_uda_status);
         fnd_message.set_token ('CUSTOMERNAME', lc_customer_name);
         fnd_message.set_token ('ORG', lc_org);
         fnd_message.set_token ('FGITEM', lc_fg_item);
         fnd_message.set_token('INSTRUCTIONS'  , lc_instructions);
         fnd_message.set_token('REASON'        , lc_reason);
         lc_message := fnd_message.get;
      END;

      BEGIN
         SELECT   to_recipients, cc_recipients
           INTO   lc_to_recipients, lc_cc_recipients
           FROM   alr_distribution_lists
          WHERE   name = lc_distribution_code;
      END;

      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 '#FROM_ROLE',
                                 'SYSADMIN');
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 'SUBJECT',
                                 lc_subject);
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 'MESSAGE',
                                 lc_message);
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 'PERFORMER',
                                 lc_to_recipients);
      wf_engine.setitemattrtext (p_itemtype,
                                 p_itemkey,
                                 '#WFM_CC',
                                 lc_cc_recipients);
   EXCEPTION
      WHEN OTHERS
      THEN
         wf_core.context ('XXHIL_O2CL_UDA_WF_DS_PKG',
                          'send_plannedTeam_ntf',
                          p_itemtype,
                          p_itemkey,
                          ln_debug_info);
         RAISE;
   END send_plannedteam_ntf;

   PROCEDURE get_document_details (
      document_id     IN              VARCHAR2,
      display_type    IN              VARCHAR2,
      document        IN OUT NOCOPY   CLOB,
      document_type   IN OUT NOCOPY   VARCHAR2
   ) IS

   CURSOR REC IS
                 select TEST,
                        CSR_UDA_MIN,
                        CSR_UDA_MAX,
                        CSR_UDA_TARGET,
                        ACHIVABLE,
                        ALTER_PROPOSAL_MIN,
                        ALTER_PROPOSAL_MAX,
                        ALTER_PROPOSAL_TARGET,
                        INSTRUCTIONS1
                   from xxhil.XXHIL_OM_LINKAGE_LINES_DS
                   where 1=1
                     AND ACHIVABLE = 'YES WITH CONDITIONS'
                     AND LINKAGE_HEADER_ID = (SELECT LINKAGE_HEADER_ID
                                                FROM xxhil.xxhil_om_linkage_header_DS
                                               WHERE 1=1
                                                 AND 'HILUDA_DS_' || uda_ref_no = SUBSTR (document_id, 1, INSTR (document_id,
                                                                                                             '|',
                                                                                                             -1,
                                                                                                             2)
                                                                                                           + 1)); --V_LINKAGE_HEADER_ID--'1000643';

   l_document_type    VARCHAR2 (25);
   l_document         VARCHAR2 (32000)           := '';
   l_CSR_UDA_MIN        VARCHAR2(500);
   l_CSR_UDA_MAX        VARCHAR2(500);
   l_CSR_UDA_TARGET     VARCHAR2(500);
   l_ACHIVABLE          VARCHAR2(200);
   l_ALTER_PROPOSAL_MIN VARCHAR2(500);
   l_ALTER_PROPOSAL_MAX VARCHAR2(500);
   l_ALTER_PROPOSAL_TARGET VARCHAR2(500);
   l_INSTRUCTIONS1 VARCHAR2(500);
   l_uda_test       VARCHAR2(100);

   l_linkage_header_id number;
   l_item_key VARCHAR2(200);
   l_item_type varchar2(200) := 'XXHUDA_DS';
   l_max_lines_disp   NUMBER                     := 60;


  BEGIN

    --    document_type := 'text/html';

      --  l_linkage_header_id := wf_engine.getitemattrtext (itemtype      => l_item_type,
                                                      --    itemkey       => document_id,
                                                       --   aname         => 'LINKAGE_HEADER_ID'
                                                        -- );
      --  insert into xxhil.xxhil_o2cl_uda_log_t_ds values(xxhil.xxhil_o2cl_uda_log_s.nextval,'LINK ID','l_linkage_header_id :'||l_linkage_header_id);

      IF document IS NULL
      THEN
         document := ' ';
      END IF;



    --  insert into xxhil.xxhil_o2cl_uda_log_t_ds values(xxhil.xxhil_o2cl_uda_log_s.nextval,'DOC ID','Document ID :'||document_id);


   BEGIN

            l_document :=
                           '<BR>'
                        || '<table border="1">'
                        || '<tr>'
                        || '<td><b>Test</b></td>'
                        || '<td><b>CSR UDA MIN</b></td>'
                        || '<td><b>CSR UDA MAX</b></td>'
                        || '<td><b>CSR UDA TARGET</b></td>'
                        || '<td><b>ACHIVABLE</b></td>'
                        || '<td><b>ALTER PROPOSAL MIN</b></td>'
                        || '<td><b>ALTER PROPOSAL MAX</b></td>'
                        || '<td><b>ALTER PROPOSAL TARGET</b></td>'
                        || '<td><b>ALTERNATE PROPOSAL INSTRUCTIONS</b></td>'
                        || '</tr>';
                        wf_notification.writetoclob (document, l_document);
                        l_document := NULL;


            FOR GET_REC IN REC LOOP

            l_UDA_TEST := GET_REC.TEST;
            l_CSR_UDA_MIN := GET_REC.CSR_UDA_MIN;
            l_CSR_UDA_MAX := GET_REC.CSR_UDA_MAX;
            l_CSR_UDA_TARGET := GET_REC.CSR_UDA_TARGET;
            l_ACHIVABLE := GET_REC.ACHIVABLE;
            l_ALTER_PROPOSAL_MIN := GET_REC.ALTER_PROPOSAL_MIN;
            l_ALTER_PROPOSAL_MAX := GET_REC.ALTER_PROPOSAL_MAX;
            l_ALTER_PROPOSAL_TARGET := GET_REC.ALTER_PROPOSAL_TARGET;
            l_INSTRUCTIONS1 := GET_REC.INSTRUCTIONS1;



                BEGIN
                       l_document :=
                         '<tr>'
                        || '<td>'||l_UDA_TEST||'</td>'
                        || '<td>'||l_CSR_UDA_MIN||'</td>'
                        || '<td>'||l_CSR_UDA_MAX||'</td>'
                        || '<td>'||l_CSR_UDA_TARGET||'</td>'
                        || '<td>'||l_ACHIVABLE||'</td>'
                        || '<td>'||l_ALTER_PROPOSAL_MIN||'</td>'
                        || '<td>'||l_ALTER_PROPOSAL_MAX||'</td>'
                        || '<td>'||l_ALTER_PROPOSAL_TARGET||'</td>'
                        || '<td>'||l_INSTRUCTIONS1||'</td>'
                        || '</tr>';
                         wf_notification.writetoclob (document, l_document);
                         l_document := NULL;

                END;

            END LOOP;

            l_document := '</table>' || '<BR>' || '<BR>';
                 wf_notification.writetoclob (document, l_document);
                 l_document := NULL;


           -- document := l_document;

         --   document_type := 'text/html';

    --         insert into xxhil.xxhil_o2cl_uda_log_t_ds values(xxhil.xxhil_o2cl_uda_log_s.nextval,'IDENDLOOP','document:'||document);


    EXCEPTION
    WHEN OTHERS THEN
    document := '<H4>Error: '|| sqlerrm || '</H4>';

    raise_application_error (-20001, ' error ' || SQLERRM);
    END;



  END get_document_details;
END xxhil_o2cl_uda_wf_ds_pkg;
/

SHOW ERROR;
EXIT;