create or replace PACKAGE BODY      XXHIL_OM_MAIL_ALERTS_PKG
AS
    --------------------------------------------------------------------------------------
    --File Name: ? ? ? ? ? ? ? ?XXHIL_OM_MAIL_ALERTS_PKG.pkb
    --Object Name: ? ? ? ? ? ? ?XXHIL_OM_MAIL_ALERTS_PKG
    --Old Object Name: ? ? ? ? ?XXBC_OM_MAIL_ALERTS
    --RICEW Object id: ? ? ? ? ?FRM-02C-59
    --Description: ? ? ? ? ? ? ?Custom Package Body.
    --Maintenance History
    -- ? ?Date ? ? ? ? ? ? ? ?Author Name ? ? ? ? ? ? ? ? ? ? ? Version ? ? ? ? ? ? Description
    -- ? ?------- ? ? ? ? ? ? ----------- ? ? ? ? ? ? ? ? ? ? ? -------- ? ? ? ? ? ?-----------
    -- ? 21-06-2019 ? ? ? ?   Darshan Shah ? ? ? ? ? ? ? ? ? ? ? ? 1.0 ? ? ? ? ? ? ? ?Created ?
    /*  14-FEB-2024   Incident ID - 262776 Dhanashree H. minor fixes for performance issues  */
    -------------------------------------------------------------------------------------
    PROCEDURE PENDING_SANCTION_STATUS
    AS
        l_from_email      VARCHAR2 (1000) := NULL;
        l_to_email        VARCHAR2 (2000) := NULL;
        l_cc_email        VARCHAR2 (2000) := NULL;
        l_bcc_email       VARCHAR2 (2000) := NULL;
        l_subject         VARCHAR2 (1000) := NULL;
        l_message         VARCHAR2 (32000) := NULL;

        l_attachment1     VARCHAR2 (1000) := NULL;
        l_attachment2     VARCHAR2 (1000) := NULL;
        l_attachment3     VARCHAR2 (1000) := NULL;
        l_attachment4     VARCHAR2 (1000) := NULL;
        v_error           VARCHAR2 (1000) := NULL;
        text              VARCHAR2 (32000);
        vpresent_status   VARCHAR2 (250) := 'XX';
        p_date            DATE := SYSDATE - 1;

        /*CURSOR c1_comm IS
            SELECT DISTINCT b.attribute4     comm
              FROM xxbc_om_sanction a, fnd_lookup_values_vl b
             WHERE     TO_CHAR (a.sanction_next_level) = b.meaning
                   AND a.sanction_status = 'ENTERED'
                   AND INSTR (b.attribute1, 'COMMENT') != 0;*/

        CURSOR c1 (p_comm VARCHAR2)
        IS
              SELECT ou_id                                   ou,
                     xxhil_om_lib_pkg.get_ou_name (ou_id)    ou_name,
                     to_role_code                            stage,
                     COUNT (*)                               nos,
                     /*COUNT (b.lookup_code) OVER (PARTITION BY b.lookup_code)
                         row_cnt,
                     */
                     NVL ((SELECT TRUNC (MAX (d.action_date))
                             FROM xxhil_om_sanct_wf_apprv_hist d
                            WHERE d.sanction_header_id = a.sanction_header_id),
                          TRUNC (b.creation_date))           pending_since,
                     RTRIM (
                         XMLAGG (XMLELEMENT (e, a.sanction_header_id || ', ')).EXTRACT (
                             '//text()'),
                         ', ')                               sanction_nos
                FROM xxhil_om_sanction a, XXHIL_OM_SANCT_WF_APPRV_HIST b
               WHERE     a.sanction_header_id = b.sanction_header_Id
                     AND a.sanction_status = 'INPROCESS'
                     AND a.sbu = 'COPR'
                     AND NOT EXISTS
                             (SELECT 'x'
                                FROM XXHIL_OM_SANCT_WF_APPRV_HIST c
                               WHERE     c.notification_id = b.notification_id
                                     AND c.status = 'ANSWER')
                     --and notification_id <> 0
                     AND b.status IN ('SUBMIT', 'QUESTION')
            GROUP BY ou_id,
                     xxhil_om_lib_pkg.get_ou_name (ou_id),
                     to_role_code,
                     a.sanction_header_id,
                     TRUNC (b.creation_date)
            ORDER BY 3, xxhil_om_lib_pkg.get_ou_name (ou_id) DESC;
    BEGIN
        l_from_email := XXHIL_OM_MAIL_ALERTS_PKG.G_EMAIL_FROM;

        /*FOR x IN c1_comm
        LOOP
          */
        --l_bcc_email := 'jayant.khandelwal@adityabirla.com';
        l_message := NULL;
        text := NULL;
        l_subject :=
            'Pending Sanctions List for ' || 'COPR' || ' as on ' || p_date;

        l_message :=
               l_message
            || '<font face = "Calibri"><b>Dear All,</b><BR>Please find herewith list of sanctions which are pending at your respective role: ';

        text :=
               text
            || '<STYLE> table,th,td {border:1px solid Black; font-family:calibri;}</STYLE>';


        text := text || '<TABLE width="870">';

        text := text || '<TR>';

        text :=
               text
            || '<Td width=100 align="Center" bgcolor="#C0C0C0" >Role</Td>';
        text :=
            text || '<Td width=100 align="Center" bgcolor="#C0C0C0" >OU</Td>';
        text :=
            text || '<Td width=30 align="Center" bgcolor="#C0C0C0" >Nos</Td>';
        text :=
               text
            || '<Td width=120 align="Center" bgcolor="#C0C0C0" >Pending Since</Td>';
        text :=
               text
            || '<Td width=520 align="Center" bgcolor="#C0C0C0" >Sanction IDs</Td>';

        text := text || '</TR>';

        l_to_email := NULL;
        l_cc_email := NULL;
        l_bcc_email := NULL;

        /*IF x.comm = 'COPR'
        THEN*/
        /*xxbc_om_mail_alerts.add_profile_email (
           'XXBC_OM_DOM_CU_MKTG_ROLE',
           'MKTG-RM',
           l_to_email,
           NULL);
        xxbc_om_mail_alerts.add_profile_email (
           'XXBC_OM_DOM_CU_MKTG_ROLE',
           'MKTG-MHO',
           l_cc_email,
           NULL);

        xxbc_om_mail_alerts.add_profile_email (
           'XXBC_OM_DOM_CU_MKTG_ROLE',
           'DOM-HEAD',
           l_cc_email,
           NULL);

        xxbc_om_mail_alerts.add_profile_email (
           'XXBC_OM_DOM_CU_MKTG_ROLE',
           'CMO',
           l_cc_email,
           NULL);

        xxbc_om_mail_alerts.add_profile_email (
           'XXBC_OM_DOM_CU_MKTG_ROLE',
           'FIN-MHO',
           l_cc_email,
           NULL);


        xxbc_om_mail_alerts.add_profile_email (
           'XXBC_OM_DOM_CU_MKTG_ROLE',
           'ADMIN',
           l_bcc_email,
           NULL);*/

        l_to_email :=
            xxhil_om_mail_alerts_pkg.get_role_mail ('PEND_SANC_COPR',
                                                    NULL,
                                                    'TO');
        l_cc_email :=
            xxhil_om_mail_alerts_pkg.get_role_mail ('PEND_SANC_COPR',
                                                    NULL,
                                                    'CC');

        IF l_cc_email IS NOT NULL
        THEN
            l_cc_email :=
                   l_cc_email
                || ','
                || xxhil_om_mail_alerts_pkg.mail_list (NULL,
                                                       NULL,
                                                       'PEND_SANC_COPR',
                                                       NULL,
                                                       'Cc');
        END IF;

        l_bcc_email :=
            xxhil_om_mail_alerts_pkg.get_role_mail ('PEND_SANC_COPR',
                                                    NULL,
                                                    'BCC');

        FOR i IN c1 ('COPR')
        LOOP
            /*IF i.present_status <> vpresent_status
            THEN
                vpresent_status := i.present_status;
                text := text || '<TR>';
                text :=
                       text
                    || '<TD Rowspan = '
                    || i.row_cnt
                    || ' align = "Left"BgColor = "#FFFF99"><I>'
                    || vpresent_status
                    || '</I></TD>';
            END IF;*/

            Text := Text || '<TD align="Left">' || i.stage || '</TD>';
            text :=
                text || '<TD>' || i.ou_name || ' [' || i.ou || ']' || '</TD>';
            text := text || '<TD align="Center">' || i.nos || '</TD>';
            text :=
                text || '<TD align="Center">' || i.pending_since || '</TD>';
            text :=
                   text
                || '<TD align="Left">'
                || LTRIM (RTRIM (i.sanction_nos))
                || '</TD>';


            text := text || '</TR>';
        END LOOP;

        text := text || '</TABLE><BR>';

        l_message :=
               l_message
            || text
            || '<BR>Thank You,</font><BR><BR> NOTE: This is a System Generated Mail, Please do not reply.<BR><BR>';


        /*xxsendmail ('XX_SCH_DIR',
                    l_from_email,
                    l_to_email,
                    l_cc_email,
                    l_bcc_email,
                    l_subject,
                    l_message,
                    l_attachment1);*/

        XXHIL_OM_MAIL_ALERTS_PKG.PUSH_MAIL (
            P_REQUEST_ID    => NULL,
            P_MSG_FROM      => l_from_email,
            P_MSG_TO        => l_to_email,
            P_MSG_CC        => l_cc_email,
            P_MSG_BCC       => l_bcc_email,
            P_MSG_SUBJECT   => l_subject,
            P_MSG_TEXT      => l_message,
            P_FROM_FILE     => NULL,
            P_TO_FILE       => NULL,
            P_TO_EXTN       => NULL,
            P_WAIT_FLG      => NULL,
            P_CALLED_FROM   => 'XXHIL_OM_MAIL_ALERTS_PKG.PENDING_SANCTION');
    -- END LOOP;
    END PENDING_SANCTION_STATUS;

    PROCEDURE GET_COPPER_MKTG_STATUS_EMAIL (p_TEXT IN VARCHAR2)
    IS
        l_from_email    VARCHAR2 (1000) := NULL;
        l_to_email      VARCHAR2 (2000) := NULL;
        l_cc_email      VARCHAR2 (2000) := NULL;
        l_bcc_email     VARCHAR2 (2000) := NULL;
        l_subject       VARCHAR2 (1000) := NULL;
        l_message       VARCHAR2 (32000) := NULL;

        l_attachment1   VARCHAR2 (1000) := NULL;
        l_attachment2   VARCHAR2 (1000) := NULL;
        l_attachment3   VARCHAR2 (1000) := NULL;
        l_attachment4   VARCHAR2 (1000) := NULL;
        v_error         VARCHAR2 (1000) := NULL;
        text            VARCHAR2 (32000);
        LvMessage       VARCHAR2 (32767);
    BEGIN
        LvMessage := p_TEXT;
        l_from_email := XXHIL_OM_MAIL_ALERTS_PKG.G_EMAIL_FROM;

        FOR x IN 1 .. 1
        LOOP
            l_message := NULL;
            text := NULL;

            SELECT SUBSTR (LvMessage, 1, 40) INTO l_subject FROM DUAL;

            l_message :=
                l_message || '<font face = "Calibri"><b>Dear All,</b><BR>';

            text :=
                   text
                || '<STYLE> table,th,td {border:1px solid Black; font-family:calibri;}</STYLE>';

            SELECT SUBSTR (LvMessage, 40) INTO LvMessage FROM DUAL;


            text := text || LvMessage;

            l_to_email := NULL;
            l_cc_email := NULL;
            l_bcc_email := NULL;

            l_to_email :=
                xxhil_om_mail_alerts_pkg.mail_list (NULL,
                                                    NULL,
                                                    'COPR_MKTG_STATUS',
                                                    NULL,
                                                    'TO');


            FOR i IN (SELECT name
                        FROM hr_operating_units
                       WHERE name LIKE '%CU_OU')
            LOOP
                l_to_email :=
                       l_to_email
                    || ','
                    || xxhil_om_mail_alerts_pkg.GET_SBU_ROLE_MAIL (
                           p_mdlid       => 'COPR_MKTG_STATUS',
                           p_ou          => i.name,
                           p_mail_type   => 'TO',
                           P_SBU         => NULL);
            END LOOP;

            l_cc_email :=
                xxhil_om_mail_alerts_pkg.mail_list (NULL,
                                                    NULL,
                                                    'COPR_MKTG_STATUS',
                                                    NULL,
                                                    'CC');

            FOR i IN (SELECT name
                        FROM hr_operating_units
                       WHERE name LIKE '%CU_OU')
            LOOP
                l_cc_email :=
                       l_cc_email
                    || ','
                    || xxhil_om_mail_alerts_pkg.GET_SBU_ROLE_MAIL (
                           p_mdlid       => 'COPR_MKTG_STATUS',
                           p_ou          => i.name,
                           p_mail_type   => 'CC',
                           P_SBU         => NULL);
            END LOOP;



            l_bcc_email :=
                xxhil_om_mail_alerts_pkg.mail_list (NULL,
                                                    NULL,
                                                    'COPR_MKTG_STATUS',
                                                    NULL,
                                                    'BCC');


            FOR i IN (SELECT name
                        FROM hr_operating_units
                       WHERE name LIKE '%CU_OU')
            LOOP
                l_bcc_email :=
                       l_bcc_email
                    || ','
                    || xxhil_om_mail_alerts_pkg.GET_SBU_ROLE_MAIL (
                           p_mdlid       => 'COPR_MKTG_STATUS',
                           p_ou          => i.name,
                           p_mail_type   => 'BCC',
                           P_SBU         => NULL);
            END LOOP;

            l_message :=
                   l_message
                || text
                || '<BR><B>Thank You,</font><BR><BR> NOTE: This is a System Generated Mail, Please do not reply.<BR><BR></B>';

            DBMS_OUTPUT.PUT_LINE ('l_to_email = ' || l_to_email);
            DBMS_OUTPUT.PUT_LINE ('l_cc_email = ' || l_cc_email);
            DBMS_OUTPUT.PUT_LINE ('l_bcc_email = ' || l_bcc_email);

            --  l_to_email := 'jayant.khandelwal@adityabirla.com';
            --- l_cc_email := 'darshankumar.s@adityabirla.com';
            --  l_bcc_email := 'gaurav.bansal@adityabirla.com';


            DBMS_OUTPUT.PUT_LINE ('l_subject = ' || l_subject);
            DBMS_OUTPUT.PUT_LINE ('l_message = ' || l_message);

            /*XXSENDMAIL ('XX_SCH_DIR',
                        l_from_email,
                        l_to_email,
                        l_cc_email,
                        l_bcc_email,
                        l_subject,
                        l_message,
                        l_attachment1);*/
            XXHIL_OM_MAIL_ALERTS_PKG.PUSH_MAIL (
                P_REQUEST_ID    => NULL,
                P_MSG_FROM      => l_from_email,
                P_MSG_TO        => l_to_email,
                P_MSG_CC        => l_cc_email,
                P_MSG_BCC       => l_bcc_email,
                P_MSG_SUBJECT   => l_subject,
                P_MSG_TEXT      => l_message,
                P_FROM_FILE     => NULL,
                P_TO_FILE       => NULL,
                P_TO_EXTN       => NULL,
                P_WAIT_FLG      => NULL,
                P_CALLED_FROM   =>
                    'XXHIL_OM_SMS_PKG.GET_COPPER_MKTG_STATUS_EMAIL');
        END LOOP;
    END;

    FUNCTION G_EMAIL_FROM
        RETURN VARCHAR2
    IS
        LV_FROM_EMAIL   XXHIL_ALL_MAIL_CREDENTIALS.SMTP_USER%TYPE;
    BEGIN
        SELECT SMTP_USER
          INTO LV_FROM_EMAIL
          FROM XXHIL_ALL_MAIL_CREDENTIALS
         WHERE ACTIVE_FLAG = 'Y' AND ROWNUM = 1;

        RETURN LV_FROM_EMAIL;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END G_EMAIL_FROM;

    PROCEDURE MSG (P_MSG VARCHAR2)
    IS
    BEGIN
        DBMS_OUTPUT.put_line (
            TO_CHAR (SYSDATE, 'DDMON HH24:MI:SS') || '> ' || p_msg);

        fnd_file.put_line (
            fnd_file.LOG,
            TO_CHAR (SYSDATE, 'DDMON HH24:MI:SS') || '> ' || p_msg);
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END msg;

    PROCEDURE PUSH_MAIL (p_request_id    NUMBER,
                         p_msg_from      VARCHAR2,
                         p_msg_to        VARCHAR2,
                         p_msg_cc        VARCHAR2,
                         p_msg_bcc       VARCHAR2,
                         p_msg_subject   VARCHAR2,
                         p_msg_text      VARCHAR2,
                         p_from_file     VARCHAR2,
                         p_to_file       VARCHAR2,
                         p_to_extn       VARCHAR2,
                         p_wait_flg      VARCHAR2,
                         p_called_from   VARCHAR2)
    AS
    BEGIN
        msg ('PUSH_MAIL START***');
        msg ('Parameters');
        msg ('p_request_id:' || p_request_id);
        msg ('p_msg_from:' || p_msg_from);
        msg ('p_msg_to:' || p_msg_to);
        msg ('p_msg_cc:' || p_msg_cc);
        msg ('p_msg_bcc:' || p_msg_bcc);
        msg ('p_msg_subject:' || p_msg_subject);
        msg ('p_msg_text:' || p_msg_text);
        msg ('p_from_file:' || p_from_file);
        msg ('p_to_file:' || p_to_file);
        msg ('p_to_extn:' || p_to_extn);
        msg ('p_wait_flg:' || p_wait_flg);
        msg ('p_called_from:' || p_called_from);

        IF    p_msg_to IS NOT NULL
           OR p_msg_cc IS NOT NULL
           OR p_msg_bcc IS NOT NULL
        THEN
            INSERT INTO xxhil_om_req_attch_mail (called_from,
                                                 created_by,
                                                 creation_date,
                                                 from_file,
                                                 last_updated_by,
                                                 last_update_date,
                                                 mail_sent_flg,
                                                 msg_bcc,
                                                 msg_cc,
                                                 msg_from,
                                                 msg_subject,
                                                 msg_text,
                                                 msg_to,
                                                 request_id,
                                                 status_code,
                                                 to_extn,
                                                 to_file,
                                                 wait_flg)
                 VALUES (p_called_from,                         --called_from,
                         fnd_global.user_id,                     --created_by,
                         SYSDATE,                             --creation_date,
                         p_from_file,                             --from_file,
                         NULL,                              --last_updated_by,
                         NULL,                             --last_update_date,
                         'N',                                 --mail_sent_flg,
                         p_msg_bcc,                                 --msg_bcc,
                         p_msg_cc,                                   --msg_cc,
                         p_msg_from,                               --msg_from,
                         p_msg_subject,                         --msg_subject,
                         SUBSTR (p_msg_text, 0, 4000),             --msg_text,
                         p_msg_to,                                   --msg_to,
                         p_request_id,                           --request_id,
                         NULL,                                  --status_code,
                         p_to_extn,                                 --to_extn,
                         p_to_file,                                 --to_file,
                         p_wait_flg                                 --wait_flg
                                   );
        --COMMIT;
        END IF;

        xxhil_om_lib_pkg.msg ('PUSH_MAIL END***');
    END PUSH_MAIL;

    PROCEDURE POP_MAIL (errbuf OUT VARCHAR2, retcode OUT VARCHAR2)
    IS
        lv_success    BOOLEAN := TRUE;
        lv_TERMINAL   VARCHAR2 (100);
    BEGIN
        msg ('POP_MAIL START');

        --Update concurrent request status

        UPDATE xxhil_om_req_attch_mail a
           SET MSG_BCC = LTRIM (msg_bcc, ',')
         WHERE     1 = 1
               AND SUBSTR (MSG_BCC, 1, 1) = (',')
               --AND NVL (a.status_code, 'X') <> 'C'
               --AND a.request_id IS NOT NULL
               AND NVL (mail_sent_flg, 'X') <> 'Y';

        UPDATE xxhil_om_req_attch_mail a
           SET MSG_CC = LTRIM (msg_cc, ',')
         WHERE     1 = 1
               AND SUBSTR (MSG_CC, 1, 1) = (',')
               --AND NVL (a.status_code, 'X') <> 'C'
               --AND a.request_id IS NOT NULL
               AND NVL (mail_sent_flg, 'X') <> 'Y';

        UPDATE xxhil_om_req_attch_mail a
           SET MSG_TO = LTRIM (msg_to, ',')
         WHERE     1 = 1
               AND SUBSTR (MSG_to, 1, 1) = (',')
               --AND NVL (a.status_code, 'X') <> 'C'
               --AND a.request_id IS NOT NULL
               AND NVL (mail_sent_flg, 'X') <> 'Y';

        UPDATE xxhil_om_req_attch_mail a
           SET a.status_code =
                   (SELECT b.status_code
                      FROM fnd_concurrent_requests b
                     WHERE a.request_id = b.request_id),
               last_updated_by = fnd_global.user_id,
               last_update_date = SYSDATE
         WHERE     1 = 1
               AND NVL (a.status_code, 'X') <> 'C'
               AND a.request_id IS NOT NULL
               AND NVL (mail_sent_flg, 'X') <> 'Y';

        msg (
               SQL%ROWCOUNT
            || 'row(s) UPDATE xxhil_om_req_attch_mail with status_code');
        COMMIT;

        FOR email
            IN (  SELECT *
                    FROM xxhil_om_req_attch_mail
                   WHERE     1 = 1
                         --and alert_id = 33265
                         AND mail_sent_flg = 'N'
                         -- AND scheduled_date <= SYSDATE
                         AND (   NVL (status_code, 'X') = 'C'
                              OR request_id IS NULL)
                         AND (   msg_to IS NOT NULL
                              OR msg_cc IS NOT NULL
                              OR msg_bcc IS NOT NULL)
                         AND NVL (attempt, 0) < 3
                         AND TRUNC (scheduled_date) BETWEEN TRUNC (SYSDATE) - 3
                                                        AND TRUNC (SYSDATE)
                ORDER BY scheduled_date, request_id)
        LOOP
            DECLARE
                LV_USER_FILE_NAME   fnd_concurrent_requests.outfile_name%TYPE;
                LV_DIRECTORY_NAME   DBA_DIRECTORIES.DIRECTORY_NAME%TYPE
                                        := 'XX_MAIL_ATTACHMENT'; --'LOBMANIP';
            BEGIN
                MSG ('');
                MSG ('*****NEW ALERT ID:' || EMAIL.ALERT_ID);

                DECLARE
                    LV_SQL_STMT           VARCHAR2 (32767);
                    LV_CONC_FILE_NAME     fnd_concurrent_requests.outfile_name%TYPE;
                    LV_DIRECTORY_PATH     DBA_DIRECTORIES.DIRECTORY_PATH%TYPE;
                    LV_OUTPUT_FILE_TYPE   FND_CONCURRENT_REQUESTS.OUTPUT_FILE_TYPE%TYPE;
                BEGIN
                    IF email.REQUEST_ID IS NOT NULL
                    THEN
                        BEGIN
                            SELECT SUBSTR (
                                       rq.outfile_name,
                                       INSTR (rq.outfile_name, '/', -1) + 1),
                                   SUBSTR (
                                       rq.outfile_name,
                                       1,
                                       INSTR (rq.outfile_name, '/', -1) - 1),
                                   OUTPUT_FILE_TYPE
                              INTO LV_CONC_FILE_NAME,
                                   LV_DIRECTORY_PATH,
                                   LV_OUTPUT_FILE_TYPE
                              FROM fnd_concurrent_requests rq
                             WHERE rq.request_id = email.REQUEST_ID;

                            --/ebsdevlog/oracle/EBSDEV/conc/out/XXHIL_OM_TAXINVMETDOM_4198626_1.PDF

                            IF LV_OUTPUT_FILE_TYPE = 'XML'
                            THEN
                                SELECT SUBSTR (
                                           rq.FILE_NAME,
                                           INSTR (rq.FILE_NAME, '/', -1) + 1),
                                       SUBSTR (
                                           rq.FILE_NAME,
                                           1,
                                           INSTR (rq.FILE_NAME, '/', -1) - 1)
                                  INTO LV_CONC_FILE_NAME, LV_DIRECTORY_PATH
                                  FROM FND_CONC_REQ_OUTPUTS rq
                                 WHERE rq.CONCURRENT_REQUEST_ID =
                                       email.REQUEST_ID;
                            END IF;

                            MSG (
                                   'LV_OUTPUT_FILE_TYPE = '
                                || LV_OUTPUT_FILE_TYPE);
                            MSG ('LV_DIRECTORY_NAME = ' || LV_DIRECTORY_NAME);
                            MSG ('LV_DIRECTORY_PATH = ' || LV_DIRECTORY_PATH);
                            MSG ('LV_CONC_FILE_NAME = ' || LV_CONC_FILE_NAME);

                            DECLARE
                                LV_DIRECTORIES_COUNT   NUMBER;
                            BEGIN
                                SELECT COUNT (1)
                                  INTO LV_DIRECTORIES_COUNT
                                  FROM DBA_DIRECTORIES
                                 WHERE DIRECTORY_PATH = LV_DIRECTORY_PATH;

                                IF LV_DIRECTORIES_COUNT = 0
                                THEN
                                    LV_SQL_STMT :=
                                           'CREATE OR REPLACE DIRECTORY "'
                                        || LV_DIRECTORY_NAME
                                        || '" AS '''
                                        || LV_DIRECTORY_PATH
                                        || '''';

                                    EXECUTE IMMEDIATE LV_SQL_STMT;
                                END IF;
                            END;

                            --UTL_FILE.FRENAME('LOBMANIP', lv_filenm, 'LOBMANIP', 'TEST.PDF', TRUE);
                            LV_USER_FILE_NAME :=
                                   NVL (email.to_file, email.REQUEST_ID)
                                || '.'
                                || NVL (email.to_extn, LV_OUTPUT_FILE_TYPE);

                            MSG ('LV_USER_FILE_NAME = ' || LV_USER_FILE_NAME);

                            msg (
                                   'COPY "'
                                || LV_CONC_FILE_NAME
                                || '" TO '
                                || LV_USER_FILE_NAME
                                || ' ON PATH = '
                                || LV_DIRECTORY_PATH);

                            UTL_FILE.FCOPY (LV_DIRECTORY_NAME,   --'LOBMANIP',
                                            LV_CONC_FILE_NAME,
                                            LV_DIRECTORY_NAME,   --'LOBMANIP',
                                            LV_USER_FILE_NAME);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                LV_DIRECTORY_NAME := NULL;
                                LV_USER_FILE_NAME := NULL;
                        END;
                    END IF;
                END;

                xxhil_om_mail_alerts_pkg.sendmail (
                    p_directory     => LV_DIRECTORY_NAME,        --'LOBMANIP',
                    p_sender        => email.msg_from,
                    p_recipient     => email.msg_to,
                    p_cc            => email.msg_cc,
                    p_bcc           => email.msg_bcc,
                    p_subject       => email.msg_subject,
                    p_body          => email.msg_text,
                    p_attachment1   => LV_USER_FILE_NAME,
                    p_attachment2   => NULL,
                    p_attachment3   => NULL,
                    p_attachment4   => NULL);

                UPDATE xxhil_om_req_attch_mail a
                   SET mail_sent_flg = 'Y',
                       last_updated_by = fnd_global.user_id,
                       last_update_date = SYSDATE,
                       attempt = NVL (attempt, 0) + 1
                 WHERE a.alert_id = email.alert_id;

                MSG (
                       SQL%ROWCOUNT
                    || 'rows updated on xxhil_om_req_attch_mail with mail_sent_flg=Y where ALERT_ID='
                    || email.alert_id);

                COMMIT;
            EXCEPTION
                WHEN OTHERS
                THEN
                    msg ('Error while send mail');
                    msg ('Alert ID:' || email.alert_id);
                    msg ('Error:' || SQLERRM);
                    lv_success := FALSE;
            END;
        END LOOP;

        IF lv_success = FALSE
        THEN
            app_exception.raise_exception;
        END IF;

        xxhil_om_lib_pkg.msg ('POP_MAIL END');
    EXCEPTION
        WHEN OTHERS
        THEN
            xxhil_om_lib_pkg.msg ('SQLERRM' || SQLERRM);
    END POP_MAIL;

    PROCEDURE SENDMAIL (p_directory     IN VARCHAR2,
                        p_sender        IN VARCHAR2,
                        p_recipient     IN VARCHAR2,
                        p_cc            IN VARCHAR2,
                        p_bcc           IN VARCHAR2,
                        p_subject       IN VARCHAR2,
                        p_body          IN VARCHAR2,
                        p_attachment1   IN VARCHAR2 DEFAULT NULL,
                        p_attachment2   IN VARCHAR2 DEFAULT NULL,
                        p_attachment3   IN VARCHAR2 DEFAULT NULL,
                        p_attachment4   IN VARCHAR2 DEFAULT NULL)
    IS
        lv_err_msg          VARCHAR2 (1000);
        lv_db_name          VARCHAR2 (1000);
        lv_prifix_subject   VARCHAR2 (1000);
        lv_prifix_body      VARCHAR2 (1000);
    BEGIN
        msg ('SENDMAIL START');
        msg ('p_directory = ' || p_directory);
        msg ('p_sender = ' || p_sender);
        msg ('p_recipient = ' || p_recipient);
        msg ('p_cc = ' || p_cc);
        msg ('p_bcc = ' || p_bcc);
        msg ('p_subject = ' || p_subject);
        msg ('p_body = ' || p_body);
        msg ('p_attachment1 = ' || p_attachment1);
        msg ('p_attachment2 = ' || p_attachment2);
        msg ('p_attachment3 = ' || p_attachment3);
        msg ('p_attachment4 = ' || p_attachment4);

        --SELECT name INTO lv_db_name FROM v$database;
        SELECT NAME INTO lv_db_name FROM v$pdbs;

        MSG ('lv_db_name = ' || lv_db_name);

        IF lv_db_name NOT IN ('EBSPROD', 'EBSPRD')
        THEN
            lv_prifix_subject := '[' || lv_db_name || ' TESTING] ';
            lv_prifix_body :=
                   '<b>'
                || '<font color=red>'
                || 'NOTE: Mail Containing Data are from '
                || lv_db_name
                || ' Database and used for testing purpose only.'
                || '</font>'
                || '</b></br></br>';
        END IF;


        xxhil_smtp_pkg.send_email (
            p_directory     => p_directory,
            p_sender        => p_sender,
            p_recipient     => REPLACE (p_recipient, ',,', ','),
            p_cc            => REPLACE (p_cc, ',,', ','),
            p_bcc           => REPLACE (p_bcc, ',,', ','),
            p_subject       => lv_prifix_subject || p_subject,
            p_body          => lv_prifix_body || p_body,
            --p_attachment1   => REPLACE (x_attachment1, ' ', '_'),
            --p_attachment2   => REPLACE (x_attachment2, ' ', '_'), --replace with your attachment filename or null
            --p_attachment3   => REPLACE (x_attachment3, ' ', '_'), --replace with your attachment filename or null
            --p_attachment4   => REPLACE (x_attachment4, ' ', '_'), --replace with your attachment filename or null.
            p_attachment1   => p_attachment1,
            p_attachment2   => p_attachment2, --replace with your attachment filename or null
            p_attachment3   => p_attachment3, --replace with your attachment filename or null
            p_attachment4   => p_attachment4, --replace with your attachment filename or null.
            p_error         => lv_err_msg);

        xxhil_om_lib_pkg.msg ('THIS IS THE ERROR: ' || lv_err_msg);
    END SENDMAIL;


    PROCEDURE ADD_PROFILE_EMAIL (p_option_name   IN     VARCHAR2,
                                 p_role          IN     VARCHAR2,
                                 p_email_id      IN OUT NOCOPY VARCHAR2, --nocopy added for Incident ID - 262776
                                 p_ou            IN     VARCHAR2)
    AS
    BEGIN
        MSG ('INSIDE ADD_PROFILE_EMAIL');

        MSG ('p_option_name:' || p_option_name);
        MSG ('p_role:' || p_role);
        MSG ('p_email_id:' || p_email_id);
        MSG ('p_ou:' || p_ou);

        FOR i
            IN (  SELECT DISTINCT
                         NVL (fua.email_address, PAPF.email_address)    email_address
                    FROM apps.fnd_profile_option_values po,
                         apps.fnd_user                 fua,
                         apps.fnd_profile_options_vl   pov,
                         (SELECT person_id, email_address
                            FROM APPS.PER_ALL_PEOPLE_F
                           WHERE TRUNC (SYSDATE) BETWEEN EFFECTIVE_START_DATE
                                                     AND EFFECTIVE_END_DATE)
                         PAPF
                   WHERE     1 = 1
                         AND po.profile_option_id = pov.profile_option_id
                         AND po.level_value = fua.user_id
                         AND fua.EMPLOYEE_ID = PAPF.PERSON_ID(+)
                         AND NVL (fua.end_date, TRUNC (SYSDATE)) >=
                             TRUNC (SYSDATE)
                         AND NVL (fua.email_address, PAPF.email_address)
                                 IS NOT NULL
                         AND po.profile_option_value = p_role      --'MKTG-RM'
                         AND pov.profile_option_name = p_option_name
                         AND (   p_ou IS NULL
                              OR EXISTS
                                     (SELECT 1
                                        FROM apps.fnd_profile_options_vl   a,
                                             apps.fnd_profile_option_values b,
                                             --apps.fnd_responsibility_vl    c,
                                             FND_RESPONSIBILITY            c,
                                             apps.per_security_profiles_v  d,
                                             apps.per_security_organizations_v
                                             c1,
                                             apps.hr_operating_units       d1,
                                             apps.fnd_user_resp_groups_direct
                                             furg,
                                             apps.fnd_user                 fu
                                       WHERE     1 = 1
                                             AND furg.user_id = fu.user_id
                                             AND furg.responsibility_id =
                                                 c.responsibility_id
                                             AND a.user_profile_option_name LIKE
                                                     'MO%Security%'
                                             AND TRUNC (SYSDATE) BETWEEN furg.start_date
                                                                     AND NVL (
                                                                             furg.end_date,
                                                                               SYSDATE
                                                                             + 1)
                                             --AND c.start_date <= SYSDATE
                                             --AND (c.end_date > SYSDATE OR c.end_date is null)
                                             --and c.end_date is null
                                             AND a.profile_option_id =
                                                 b.profile_option_id
                                             --AND TO_NUMBER (b.level_value) = c.responsibility_id
                                             AND b.level_value =
                                                 TO_CHAR (c.responsibility_id)
                                             AND d.security_profile_id =
                                                 b.profile_option_value
                                             AND c1.security_profile_id =
                                                 d.security_profile_id
                                             AND c1.organization_id =
                                                 d1.organization_id
                                             AND fu.user_id = fua.user_id
                                             AND d1.NAME = p_ou))
                --REMOVED IN EKAAYAN--AND (   EXISTS
                --REMOVED IN EKAAYAN--           (SELECT 'x'
                --REMOVED IN EKAAYAN--              FROM xx_bc_usr_access x
                --REMOVED IN EKAAYAN--             WHERE     xxom.get_ou_name (x.org_id) = p_ou
                --REMOVED IN EKAAYAN--                   AND x.user_id = b.user_id)
                --REMOVED IN EKAAYAN--     OR p_ou IS NULL)
                ORDER BY 1)
        LOOP
            IF p_email_id IS NULL
            THEN
                p_email_id := i.email_address;
            ELSE
                p_email_id := p_email_id || ', ' || i.email_address;
            END IF;
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END ADD_PROFILE_EMAIL;

    PROCEDURE ADD_SBU_PROFILE_EMAIL (P_OPTION_NAME   IN     VARCHAR2,
                                     P_ROLE          IN     VARCHAR2,
                                     P_EMAIL_ID      IN OUT NOCOPY VARCHAR2, --added nocopy for Incident ID - 262776
                                     P_OU            IN     VARCHAR2,
                                     P_SBU           IN     VARCHAR2)
    AS
    BEGIN
        MSG ('INSIDE ADD_SBU_PROFILE_EMAIL');

        MSG ('P_OPTION_NAME:' || P_OPTION_NAME);
        MSG ('P_ROLE:' || P_ROLE);
        MSG ('P_EMAIL_ID:' || P_EMAIL_ID);
        MSG ('P_OU:' || P_OU);
        MSG ('P_SBU:' || P_SBU);

        FOR i
            IN (  SELECT DISTINCT
                         NVL (fua.email_address, PAPF.email_address)    email_address
                    FROM APPS.FND_PROFILE_OPTION_VALUES PO,
                         APPS.FND_USER                 FUA,
                         APPS.FND_PROFILE_OPTIONS_VL   POV,
                         (SELECT person_id, email_address
                            FROM APPS.PER_ALL_PEOPLE_F
                           WHERE TRUNC (SYSDATE) BETWEEN EFFECTIVE_START_DATE
                                                     AND EFFECTIVE_END_DATE)
                         PAPF
                   WHERE     1 = 1
                         AND PO.PROFILE_OPTION_ID = POV.PROFILE_OPTION_ID
                         AND PO.LEVEL_VALUE = FUA.USER_ID
                         AND FUA.EMPLOYEE_ID = PAPF.PERSON_ID(+)
                         AND NVL (FUA.END_DATE, TRUNC (SYSDATE)) >=
                             TRUNC (SYSDATE)
                         AND NVL (FUA.EMAIL_ADDRESS, PAPF.EMAIL_ADDRESS)
                                 IS NOT NULL
                         AND PO.PROFILE_OPTION_VALUE = P_ROLE      --'MKTG-RM'
                         AND POV.PROFILE_OPTION_NAME = P_OPTION_NAME
                         AND (   P_SBU IS NULL
                              OR EXISTS
                                     ((SELECT 1
                                         FROM XXHIL_OM_USER_LINKAGE HDR
                                        WHERE     1 = 1
                                              AND HDR.PROFILE = 'HIL OTC Roles'
                                              AND HDR.APPLICATION_NAME =
                                                  'Order Capture'
                                              AND HDR.ROLE = P_ROLE
                                              AND HDR.SBU = P_SBU)))
                         AND (   p_ou IS NULL
                              OR EXISTS
                                     (SELECT 1
                                        FROM apps.fnd_profile_options_vl   a,
                                             apps.fnd_profile_option_values b,
                                             --apps.fnd_responsibility_vl    c,
                                             FND_RESPONSIBILITY            c,
                                             apps.per_security_profiles_v  d,
                                             apps.per_security_organizations_v
                                             c1,
                                             apps.hr_operating_units       d1,
                                             apps.fnd_user_resp_groups_direct
                                             furg,
                                             apps.fnd_user                 fu
                                       WHERE     1 = 1
                                             AND furg.user_id = fu.user_id
                                             AND furg.responsibility_id =
                                                 c.responsibility_id
                                             AND a.user_profile_option_name LIKE
                                                     'MO%Security%'
                                             AND a.profile_option_id =
                                                 b.profile_option_id
                                             AND TRUNC (SYSDATE) BETWEEN furg.start_date
                                                                     AND NVL (
                                                                             furg.end_date,
                                                                               SYSDATE
                                                                             + 1)
                                             --AND c.start_date <= SYSDATE
                                             --AND NVL (c.end_date, SYSDATE + 1) > SYSDATE
                                             --AND (c.end_date > SYSDATE OR c.end_date is null)
                                             --and c.end_date is null
                                             --AND TO_NUMBER (b.level_value) = c.responsibility_id
                                             AND b.level_value =
                                                 TO_CHAR (c.responsibility_id)
                                             AND d.security_profile_id =
                                                 b.profile_option_value
                                             AND c1.security_profile_id =
                                                 d.security_profile_id
                                             AND c1.organization_id =
                                                 d1.organization_id
                                             AND fu.user_id = fua.user_id
                                             AND d1.NAME = p_ou))
                --REMOVED IN EKAAYAN--AND (   EXISTS
                --REMOVED IN EKAAYAN--           (SELECT 'x'
                --REMOVED IN EKAAYAN--              FROM xx_bc_usr_access x
                --REMOVED IN EKAAYAN--             WHERE     xxom.get_ou_name (x.org_id) = p_ou
                --REMOVED IN EKAAYAN--                   AND x.user_id = b.user_id)
                --REMOVED IN EKAAYAN--     OR p_ou IS NULL)
                ORDER BY 1)
        LOOP
            IF P_EMAIL_ID IS NULL
            THEN
                P_EMAIL_ID := I.EMAIL_ADDRESS;
            ELSE
                P_EMAIL_ID := P_EMAIL_ID || ', ' || I.EMAIL_ADDRESS;
            END IF;
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END ADD_SBU_PROFILE_EMAIL;


    FUNCTION GET_ROLE_MAIL (p_mdlid       VARCHAR2,
                            p_ou          VARCHAR2,
                            p_mail_type   VARCHAR2)
        RETURN VARCHAR2
    IS
        lv_mail   VARCHAR2 (4000);
    BEGIN
        FOR I
            IN (SELECT PROFILE, USRROLE
                  FROM XXHIL_USERMAIL
                 WHERE     UPPER (MDLID) = UPPER (P_MDLID)
                       AND UPPER (EMAILTYPE) = UPPER (P_MAIL_TYPE)
                       AND STATUS = 'ACTIVE'
                       AND START_DATE <= TRUNC (SYSDATE)
                       AND NVL (END_DATE, TRUNC (SYSDATE)) >= TRUNC (SYSDATE))
        LOOP
            XXHIL_OM_MAIL_ALERTS_PKG.ADD_PROFILE_EMAIL (
                P_OPTION_NAME   => I.PROFILE,
                P_ROLE          => I.USRROLE,
                P_EMAIL_ID      => LV_MAIL,
                P_OU            => P_OU);
        END LOOP;

        RETURN lv_mail;
    END GET_ROLE_MAIL;

    FUNCTION GET_SBU_ROLE_MAIL (P_MDLID       VARCHAR2,
                                P_OU          VARCHAR2,
                                P_MAIL_TYPE   VARCHAR2,
                                P_SBU         VARCHAR2)
        RETURN VARCHAR2
    IS
        LV_MAIL   VARCHAR2 (4000);
    BEGIN
        FOR I
            IN (SELECT PROFILE, USRROLE
                  FROM XXHIL_USERMAIL
                 WHERE     1 = 1
                       AND UPPER (MDLID) = UPPER (P_MDLID)
                       AND UPPER (EMAILTYPE) = UPPER (P_MAIL_TYPE)
                       AND DECODE (SBU, NULL, P_SBU || 'X', SBU) =
                           DECODE (SBU, NULL, P_SBU || 'X', NVL (P_SBU, SBU))
                       AND STATUS = 'ACTIVE'
                       AND START_DATE <= TRUNC (SYSDATE)
                       AND NVL (END_DATE, TRUNC (SYSDATE)) >= TRUNC (SYSDATE))
        LOOP
            XXHIL_OM_MAIL_ALERTS_PKG.ADD_SBU_PROFILE_EMAIL (
                P_OPTION_NAME   => I.PROFILE,
                P_ROLE          => I.USRROLE,
                P_EMAIL_ID      => LV_MAIL,
                P_OU            => P_OU,
                P_SBU           => P_SBU);
        END LOOP;

        RETURN LV_MAIL;
    END GET_SBU_ROLE_MAIL;

    PROCEDURE PRCREQ_MAIL (
        ERRBUF         OUT VARCHAR2,
        RETCODE        OUT VARCHAR2,
        P_REQUEST_ID       XXHIL_OM_PRCREQ.REQUEST_ID%TYPE,
        P_FX_ID            XXHIL_OM_FXREQ.FX_ID%TYPE)
    IS
        LV_MSG_SUBJECT   XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
        LV_MSG_TEXT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
        LV_MSG_FROM      XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE;
        LV_MSG_TO        XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
        LV_MSG_CC        XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
        LV_MSG_BCC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
        LV_MAILABLE      BOOLEAN := FALSE;
        LV_SBU           XXHIL_OM_PRCREQ.SBU%TYPE;
        LV_OU            XXHIL_OM_PRCREQ.OU_NAME%TYPE;
    BEGIN
        lv_msg_text :=
               '<!DOCTYPE html>'
            || '<html>'
            || '<head>'
            || '<style type=text/css>table{border-collapse:collapse;} th{background-color:#cfe0f1;text-indent:1;border: 1px solid black;vertical-align:top;} td{background-color:#f2f2f5;border:1px solid black;vertical-align:top;}</style>'
            || '</head>'
            || '<body>';

        FOR QP IN (SELECT *
                     FROM XXHIL_OM_PRCREQ
                    WHERE REQUEST_ID = P_REQUEST_ID AND STATUS = 'FINAL')
        LOOP
            LV_MAILABLE := TRUE;

            LV_SBU := QP.SBU;
            LV_OU := QP.OU_NAME;

            DECLARE
                LV_PARTY_NAME            XXHIL_OM_CUSTOMER_V.AGEN_NAME%TYPE;
                LV_CATEG_DESC            XXHIL_OM_HEDGING_CATEGORY_V.CATEG_DESC%TYPE;
                LV_QP_USER_NAME          FND_USER.USER_NAME%TYPE;
                LV_QP_USER_DESCRIPTION   FND_USER.DESCRIPTION%TYPE;
                LV_FX_USER_NAME          FND_USER.USER_NAME%TYPE;
                LV_FX_USER_DESCRIPTION   FND_USER.DESCRIPTION%TYPE;
                LV_SBU_DESC              XXHIL_OM_SBU_V.SBU_DESC%TYPE;
            BEGIN
                SELECT DISTINCT AGEN_NAME
                  INTO LV_PARTY_NAME
                  FROM XXHIL_OM_CUSTOMER_V
                 WHERE AGEN_CD = QP.PARTY_ID;

                lv_msg_subject :=
                       'PRICING REQUEST ('
                    || qp.request_id
                    || ') '
                    || qp.commodity
                    || ' | '
                    || lv_party_name;

                lv_msg_text := lv_msg_text || '<table>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                       lv_msg_text
                    || '<th colspan=2 style="background-color:#b4c3e0">Pricing Request</th>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>Request ID</th>';
                lv_msg_text :=
                    lv_msg_text || '<td>' || qp.request_id || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>Request Date</th>';
                lv_msg_text :=
                       lv_msg_text
                    || '<td>'
                    || TO_CHAR (qp.request_date, 'DD-MON-RRRR')
                    || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                SELECT SBU_DESC
                  INTO LV_SBU_DESC
                  FROM XXHIL_OM_SBU_V
                 WHERE SBU_CD = QP.SBU;

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text := lv_msg_text || '<th align=right>SBU</th>';
                lv_msg_text :=
                       lv_msg_text
                    || '<td>'
                    || qp.sbu
                    || '('
                    || lv_sbu_desc
                    || ')'
                    || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>Commodity</th>';
                lv_msg_text :=
                    lv_msg_text || '<td>' || qp.commodity || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text := lv_msg_text || '<th align=right>Party</th>';
                lv_msg_text :=
                       lv_msg_text
                    || '<td>'
                    || qp.party_id
                    || '-'
                    || lv_party_name
                    || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>QP Basis / Type</th>';
                lv_msg_text :=
                       lv_msg_text
                    || '<td>'
                    || qp.qp_basis
                    || ' / '
                    || qp.qp_type
                    || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                SELECT CATEG_DESC
                  INTO LV_CATEG_DESC
                  FROM XXHIL_OM_HEDGING_CATEGORY_V
                 WHERE CATEG_CD = QP.SALE_TYPE;

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>Sale Type</th>';
                lv_msg_text :=
                       lv_msg_text
                    || '<td>'
                    || qp.sale_type
                    || '('
                    || lv_categ_desc
                    || ')'
                    || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>Avg Period</th>';
                lv_msg_text :=
                       lv_msg_text
                    || '<td>'
                    || 'From: '
                    || TO_CHAR (qp.qp_period_from, 'DD-MON-RRRR')
                    || ' To: '
                    || TO_CHAR (qp.qp_period_to, 'DD-MON-RRRR')
                    || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>Deal Period</th>';
                lv_msg_text :=
                       lv_msg_text
                    || '<td>'
                    || 'From: '
                    || TO_CHAR (qp.deal_period_from, 'DD-MON-RRRR')
                    || ' To: '
                    || TO_CHAR (qp.deal_period_from, 'DD-MON-RRRR')
                    || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>Informed Qty</th>';
                lv_msg_text :=
                    lv_msg_text || '<td>' || qp.informed_qty || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text := lv_msg_text || '<th align=right>Price</th>';
                lv_msg_text :=
                    lv_msg_text || '<td>' || NVL (qp.qp_price, '') || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text := lv_msg_text || '<th align=right>Status</th>';
                lv_msg_text := lv_msg_text || '<td>' || qp.status || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';


                lv_msg_text := lv_msg_text || '</table>';
                lv_msg_text := lv_msg_text || '<br>';

                DECLARE
                    lv_fxreq_cnt   NUMBER := 0;
                BEGIN
                    FOR fx IN (SELECT *
                                 FROM xxhil_om_fxreq
                                WHERE request_id = p_request_id)
                    LOOP
                        lv_fxreq_cnt := lv_fxreq_cnt + 1;

                        IF lv_fxreq_cnt = 1
                        THEN
                            lv_msg_text := lv_msg_text || '<table>';
                            lv_msg_text := lv_msg_text || '<tr>';
                            lv_msg_text :=
                                   lv_msg_text
                                || '<th colspan=11 style="background-color:#c3cad9">Forex Request</th>';
                            lv_msg_text := lv_msg_text || '</tr>';
                            lv_msg_text := lv_msg_text || '<tr>';
                            lv_msg_text := lv_msg_text || '<th>Forex ID</th>';
                            lv_msg_text := lv_msg_text || '<th>Basis</th>';
                            lv_msg_text :=
                                lv_msg_text || '<th>Basis From</th>';
                            lv_msg_text := lv_msg_text || '<th>Basis To</th>';
                            lv_msg_text :=
                                lv_msg_text || '<th>Currency Base</th>';
                            lv_msg_text :=
                                lv_msg_text || '<th>Currency Conv.</th>';
                            lv_msg_text := lv_msg_text || '<th>Rate</th>';
                            lv_msg_text :=
                                lv_msg_text || '<th>Other Chg</th>';
                            lv_msg_text := lv_msg_text || '<th>Qty</th>';
                            lv_msg_text := lv_msg_text || '<th>Value</th>';
                            lv_msg_text := lv_msg_text || '<th>Status</th>';
                            lv_msg_text := lv_msg_text || '</tr>';
                        END IF;

                        lv_msg_text := lv_msg_text || '<tr>';
                        lv_msg_text :=
                            lv_msg_text || '<td>' || fx.fx_id || '</th>';
                        lv_msg_text :=
                            lv_msg_text || '<td>' || fx.fx_basis || '</th>';
                        lv_msg_text :=
                               lv_msg_text
                            || '<td>'
                            || TO_CHAR (fx.fx_basis_from, 'DD-MON-RRRR')
                            || '</th>';
                        lv_msg_text :=
                               lv_msg_text
                            || '<td>'
                            || TO_CHAR (fx.fx_basis_to, 'DD-MON-RRRR')
                            || '</th>';
                        lv_msg_text :=
                               lv_msg_text
                            || '<td>'
                            || fx.fx_base_curr
                            || '</th>';
                        lv_msg_text :=
                               lv_msg_text
                            || '<td>'
                            || fx.fx_conv_curr
                            || '</th>';
                        lv_msg_text :=
                            lv_msg_text || '<td>' || fx.fx_rate || '</th>';
                        lv_msg_text :=
                            lv_msg_text || '<td>' || fx.fx_oth_chg || '</th>';
                        lv_msg_text :=
                            lv_msg_text || '<td>' || fx.fx_qty || '</th>';
                        lv_msg_text :=
                            lv_msg_text || '<td>' || fx.fx_value || '</th>';
                        lv_msg_text :=
                            lv_msg_text || '<td>' || fx.fx_status || '</th>';
                        lv_msg_text := lv_msg_text || '</tr>';

                        SELECT user_name, description
                          INTO lv_fx_user_name, lv_fx_user_description
                          FROM fnd_user
                         WHERE user_id = fx.created_by;
                    END LOOP;

                    IF lv_fxreq_cnt <> 0
                    THEN
                        lv_msg_text := lv_msg_text || '</table>';
                        lv_msg_text := lv_msg_text || '<br>';
                    END IF;
                END;

                SELECT USER_NAME, DESCRIPTION
                  INTO LV_QP_USER_NAME, LV_QP_USER_DESCRIPTION
                  FROM FND_USER
                 WHERE USER_ID = QP.CREATED_BY;

                lv_msg_text := lv_msg_text || '<table>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>Request Created By</th>';
                lv_msg_text :=
                       lv_msg_text
                    || '<td>'
                    || lv_qp_user_name
                    || '('
                    || lv_qp_user_description
                    || ')'
                    || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                       lv_msg_text
                    || '<th align=right>Request Creation Date</th>';
                lv_msg_text :=
                       lv_msg_text
                    || '<td>'
                    || TO_CHAR (qp.creation_date, 'DD-MON-RRRR HH24:MI:SS')
                    || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '</table>';

                lv_msg_text := lv_msg_text || '</body>';
                lv_msg_text := lv_msg_text || '</html>';
            END;
        END LOOP;

        IF lv_mailable = TRUE
        THEN
            --LV_MSG_TO :=
            --    XXHIL_OM_MAIL_ALERTS_PKG.GET_ROLE_MAIL (
            --        P_MDLID       => 'XXHIL_OM_PRCREQ',
            --        P_OU          => NULL,
            --        P_MAIL_TYPE   => 'TO');

            LV_MSG_TO :=
                XXHIL_OM_MAIL_ALERTS_PKG.GET_SBU_ROLE_MAIL (
                    P_MDLID       => 'XXHIL_OM_PRCREQ',
                    P_OU          => LV_OU,
                    P_MAIL_TYPE   => 'TO',
                    P_SBU         => LV_SBU);

            --LV_MSG_CC :=
            --    XXHIL_OM_MAIL_ALERTS_PKG.GET_ROLE_MAIL (
            --        P_MDLID       => 'XXHIL_OM_PRCREQ',
            --        P_OU          => NULL,
            --        P_MAIL_TYPE   => 'CC');

            LV_MSG_CC :=
                XXHIL_OM_MAIL_ALERTS_PKG.GET_SBU_ROLE_MAIL (
                    P_MDLID       => 'XXHIL_OM_PRCREQ',
                    P_OU          => LV_OU,
                    P_MAIL_TYPE   => 'CC',
                    P_SBU         => LV_SBU);
            --LV_MSG_BCC :=
            --    XXHIL_OM_MAIL_ALERTS_PKG.GET_ROLE_MAIL (
            --        P_MDLID       => 'XXHIL_OM_PRCREQ',
            --        P_OU          => NULL,
            --        P_MAIL_TYPE   => 'BCC');

            LV_MSG_BCC :=
                XXHIL_OM_MAIL_ALERTS_PKG.GET_SBU_ROLE_MAIL (
                    P_MDLID       => 'XXHIL_OM_PRCREQ',
                    P_OU          => LV_OU,
                    P_MAIL_TYPE   => 'BCC',
                    P_SBU         => LV_SBU);

            -- lv_msg_to := 'darshankumar.s@adityabirla.com';
            --   lv_msg_to := 'prince.upadhyay@adityabirla.com';

            --SELECT DBMS_RANDOM.string ('X', 7) || '@adityabirla.com'     str
            --  INTO lv_msg_from
            --  FROM DUAL;


            XXHIL_OM_MAIL_ALERTS_PKG.PUSH_MAIL (
                P_REQUEST_ID    => NULL,
                P_MSG_FROM      => G_EMAIL_FROM,
                P_MSG_TO        => LV_MSG_TO,
                P_MSG_CC        => LV_MSG_CC,
                P_MSG_BCC       => LV_MSG_BCC,
                P_MSG_SUBJECT   => LV_MSG_SUBJECT,
                P_MSG_TEXT      => LV_MSG_TEXT,
                P_FROM_FILE     => NULL,
                P_TO_FILE       => NULL,
                P_TO_EXTN       => NULL,
                P_WAIT_FLG      => NULL,
                P_CALLED_FROM   => 'XXHIL_OM_PRCREQ');
        END IF;
    END PRCREQ_MAIL;

    PROCEDURE DEAL_MAIL (
        ERRBUF                 OUT VARCHAR2,
        RETCODE                OUT VARCHAR2,
        P_DEAL_ID                  XXHIL_OM_DEAL_HDR.DEAL_ID%TYPE,
        P_REQUEST_ID               XXHIL_OM_PRCREQ.REQUEST_ID%TYPE,
        P_DEAL_DATE                XXHIL_OM_DEAL_HDR.DEAL_DATE%TYPE,
        P_DEAL_CREATION_DATE       XXHIL_OM_DEAL_HDR.CREATION_DATE%TYPE,
        P_CREATED_BY               XXHIL_OM_DEAL_HDR.CREATED_BY%TYPE,
        P_DELD_DEAL_QTY            XXHIL_OM_DEAL_DTL.DELD_DEAL_QTY%TYPE,
        P_DEAL_DESC                XXHIL_OM_DEAL_HDR.DEAL_DESC%TYPE,
        P_CATEGORY                 XXHIL_OM_DEAL_HDR.CATEGORY%TYPE,
        P_DEAL_RATE                XXHIL_OM_DEAL_HDR.DEAL_RATE%TYPE)
    IS
    BEGIN
        --
        -- DEAL CONFIRMARION MAIL
        --
        FOR QP IN (SELECT REQUEST_ID               DELD_REQ_ID,
                          P_CREATED_BY             CREATED_BY,
                          P_DEAL_ID                DEAL_ID,
                          P_DEAL_DATE              DEAL_DATE,
                          QP.COMMODITY,
                          P_DEAL_RATE              DEAL_RATE,
                          QP.QP_BASIS,
                          QP.QP_TYPE,
                          QP.QP_PERIOD_FROM,
                          QP.QP_PERIOD_TO,
                          P_CATEGORY               CATEGORY,
                          P_DEAL_DESC              DEAL_DESC,
                          P_DELD_DEAL_QTY          DELD_DEAL_QTY,
                          P_DEAL_CREATION_DATE     CREATION_DATE,
                          QP.party_id,
                          qp.INVOICE_TO_ORG_ID,
                          QP.SBU,
                          QP.OU_NAME,
                          QP.REQUEST_ID
                     FROM XXHIL_OM_PRCREQ QP /*,
                        XXHIL_OM_DEAL_DTL  DD,
                        XXHIL_OM_DEAL_HDR  DH*/
                    WHERE 1 = 1 AND REQUEST_ID = P_REQUEST_ID /*AND (   DELD_REQ_ID = P_REQUEST_ID
                                                                   OR P_REQUEST_ID IS NULL)
                                                              AND DELD_ID = DEAL_ID
                                                              AND DELD_REQ_ID = REQUEST_ID*/
                                                             )
        LOOP
            MSG ('REQUEST_ID:' || QP.REQUEST_ID);

            DECLARE
                LV_USER_NAME       FND_USER.USER_NAME%TYPE;
                LV_MSG_SUBJECT     XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
                LV_MSG_TEXT        XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
                LV_MSG_FROM        XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE;
                LV_MSG_TO          XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
                LV_MSG_CUST_TO     XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
                LV_MSG_CC          XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
                LV_MSG_BCC         XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
                LV_SBU_DESC        XXHIL_OM_SBU_V.SBU_DESC%TYPE;
                LV_CUSTOMER_NAME   XXHIL_OM_PRICING_REQUEST_V.PARTY_NAME%TYPE;
                LV_INFORMED_QTY    XXHIL_OM_PRICING_REQUEST_V.PR_QTY%TYPE;
            BEGIN
                SELECT USER_NAME, EMAIL_ADDRESS
                  INTO LV_USER_NAME, LV_MSG_FROM
                  FROM FND_USER
                 WHERE USER_ID = QP.CREATED_BY;

                lv_msg_subject :=
                    'Request no ' || QP.DELD_REQ_ID || ' deal confirmed ';

                lv_msg_text :=
                       '<!DOCTYPE html>'
                    || '<html>'
                    || '<head>'
                    || '<style type=text/css>table{border-collapse:collapse;} th{background-color:#cfe0f1;text-indent:1;border: 1px solid black;vertical-align:top;} td{background-color:#f2f2f5;border:1px solid black;vertical-align:top;}</style>'
                    || '</head>'
                    || '<body>';

                lv_msg_text := lv_msg_text || '<table>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                       lv_msg_text
                    || '<th colspan=2 style="background-color:#b4c3e0">DEAL CONFIRMATION</th>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>Request ID</th>';
                lv_msg_text :=
                    lv_msg_text || '<td>' || QP.DELD_REQ_ID || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text := lv_msg_text || '<th align=right>Deal ID</th>';
                lv_msg_text := lv_msg_text || '<td>' || QP.DEAL_ID || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>Deal Date</th>';
                lv_msg_text :=
                       lv_msg_text
                    || '<td>'
                    || TO_CHAR (QP.DEAL_DATE, 'DD-MON-RRRR')
                    || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';


                SELECT SBU_DESC
                  INTO LV_SBU_DESC
                  FROM XXHIL_OM_SBU_V
                 WHERE SBU_CD = QP.SBU;

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text := lv_msg_text || '<th align=right>SBU</th>';
                lv_msg_text :=
                       lv_msg_text
                    || '<td>'
                    || QP.SBU
                    || ' ('
                    || LV_SBU_DESC
                    || ')'
                    || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>Commodity</th>';
                lv_msg_text :=
                    lv_msg_text || '<td>' || QP.COMMODITY || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>Deal Rate</th>';
                lv_msg_text :=
                    lv_msg_text || '<td>' || QP.DEAL_RATE || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>QP Basis/Type</th>';
                lv_msg_text :=
                       lv_msg_text
                    || '<td>'
                    || QP.QP_BASIS
                    || '/'
                    || QP.QP_TYPE
                    || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>Avg Period</th>';
                lv_msg_text :=
                       lv_msg_text
                    || '<td>'
                    || 'From: '
                    || TO_CHAR (QP.QP_PERIOD_FROM, 'DD-MON-RRRR')
                    || ' '
                    || 'TO: '
                    || TO_CHAR (QP.QP_PERIOD_TO, 'DD-MON-RRRR')
                    || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>Sale Type</th>';
                lv_msg_text :=
                    lv_msg_text || '<td>' || QP.CATEGORY || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text := lv_msg_text || '<th align=right>Remarks</th>';
                lv_msg_text :=
                    lv_msg_text || '<td>' || QP.DEAL_DESC || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                SELECT DISTINCT PARTY_NAME, PR_QTY
                  INTO LV_CUSTOMER_NAME, LV_INFORMED_QTY
                  FROM XXHIL_OM_PRICING_REQUEST_V
                 WHERE REQUEST_ID = QP.REQUEST_ID;

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text := lv_msg_text || '<th align=right>Party</th>';
                lv_msg_text :=
                    lv_msg_text || '<td>' || LV_CUSTOMER_NAME || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text := lv_msg_text || '<th align=right>Inf Qty</th>';
                lv_msg_text :=
                    lv_msg_text || '<td>' || LV_INFORMED_QTY || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text := lv_msg_text || '<th align=right>Deal Qty</th>';
                lv_msg_text :=
                       lv_msg_text
                    || '<td>'
                    || ROUND (QP.DELD_DEAL_QTY, 5)
                    || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '</table>';

                lv_msg_text := lv_msg_text || '</BR>';

                lv_msg_text := lv_msg_text || '<table>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>Deal Done By</th>';
                lv_msg_text :=
                    lv_msg_text || '<td>' || LV_USER_NAME || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '<tr>';
                lv_msg_text :=
                    lv_msg_text || '<th align=right>Creation Date</th>';
                lv_msg_text :=
                       lv_msg_text
                    || '<td>'
                    || TO_CHAR (QP.CREATION_DATE, 'DD-MON-RRRR HH24:MI:SS')
                    || '</td>';
                lv_msg_text := lv_msg_text || '</tr>';

                lv_msg_text := lv_msg_text || '</table>';

                lv_msg_text := lv_msg_text || '</body>';
                lv_msg_text := lv_msg_text || '</html>';

                LV_MSG_TO :=
                    XXHIL_OM_MAIL_ALERTS_PKG.GET_SBU_ROLE_MAIL (
                        P_MDLID       => 'XXHIL_OM_DEAL',
                        P_OU          => QP.OU_NAME,
                        P_MAIL_TYPE   => 'TO',
                        P_SBU         => QP.SBU);

                MSG ('LV_MSG_TO:' || LV_MSG_TO);

                LV_MSG_CC :=
                    XXHIL_OM_MAIL_ALERTS_PKG.GET_SBU_ROLE_MAIL (
                        P_MDLID       => 'XXHIL_OM_DEAL',
                        P_OU          => QP.OU_NAME,
                        P_MAIL_TYPE   => 'CC',
                        P_SBU         => QP.SBU);

                MSG ('LV_MSG_CC:' || LV_MSG_CC);

                LV_MSG_BCC :=
                    XXHIL_OM_MAIL_ALERTS_PKG.GET_SBU_ROLE_MAIL (
                        P_MDLID       => 'XXHIL_OM_DEAL',
                        P_OU          => QP.OU_NAME,
                        P_MAIL_TYPE   => 'BCC',
                        P_SBU         => QP.SBU);

                MSG ('LV_MSG_BCC:' || LV_MSG_BCC);

                XXHIL_OM_MAIL_ALERTS_PKG.PUSH_MAIL (
                    P_REQUEST_ID    => NULL,
                    P_MSG_FROM      => XXHIL_OM_MAIL_ALERTS_PKG.G_EMAIL_FROM,
                    P_MSG_TO        => LV_MSG_TO,
                    P_MSG_CC        => LV_MSG_CC,
                    P_MSG_BCC       => LV_MSG_BCC,
                    P_MSG_SUBJECT   => LV_MSG_SUBJECT,
                    P_MSG_TEXT      => LV_MSG_TEXT,
                    P_FROM_FILE     => NULL,
                    P_TO_FILE       => NULL,
                    P_TO_EXTN       => NULL,
                    P_WAIT_FLG      => NULL,
                    P_CALLED_FROM   => 'XXHIL_OM_DEAL');

                --
                -- Customer Mail
                --

                FOR I
                    IN (SELECT DISTINCT
                               LOWER (CNSG_EMAIL_ID)     CNSG_EMAIL_ID
                          FROM XXHIL_OM_CONSIGNEE_CONTACT_V
                         WHERE     CNSG_EMAIL_ID IS NOT NULL
                               AND CNSG_EMAIL_ID LIKE '%@%'
                               AND CNSG_CD IN
                                       (SELECT CNSG_CD
                                          FROM XXHIL_OM_SITE_V C
                                         WHERE     1 = 1
                                               --AND C.CNSG_AGEN_CD = :XXHIL_OM_DEAL_DTL.NBT_PARTY_ID
                                               AND C.CNSG_AGEN_CD =
                                                   QP.party_id --:XXHIL_OM_DEAL_DTL.NBT_PARTY_ID
                                               AND CNSG_CD =
                                                   QP.INVOICE_TO_ORG_ID --:NBT_BILLTO
                                               AND cnsg_catg = 'COPR'
                                               AND C.CNSG_TYPE_OF_ADD =
                                                   'BILL_TO'
                                               AND C.CNSG_STATUS = 'A')
                        UNION ALL
                        SELECT DISTINCT
                               LOWER (AGEN_EMAIL_ID)     AGEN_EMAIL_ID
                          FROM XXHIL_OM_CUSTOMER_CONTACT_V
                         WHERE     AGEN_EMAIL_ID IS NOT NULL
                               AND AGEN_EMAIL_ID LIKE '%@%'
                               AND agen_cd IN
                                       (SELECT cnsg_agen_cd
                                          FROM xxhil_om_site_v
                                         WHERE     CNSG_CD =
                                                   QP.INVOICE_TO_ORG_ID --:NBT_BILLTO
                                               AND cnsg_catg = 'COPR')
                               AND AGEN_CD = QP.party_id --:XXHIL_OM_DEAL_DTL.NBT_PARTY_ID
                                                        )
                LOOP
                    IF LV_MSG_CUST_TO IS NULL
                    THEN
                        LV_MSG_CUST_TO := I.CNSG_EMAIL_ID;
                    ELSE
                        LV_MSG_CUST_TO :=
                            LV_MSG_CUST_TO || ',' || I.CNSG_EMAIL_ID;
                    END IF;
                END LOOP;

                MSG ('LV_MSG_CUST_TO:' || LV_MSG_CUST_TO);

                XXHIL_OM_MAIL_ALERTS_PKG.PUSH_MAIL (
                    P_REQUEST_ID    => NULL,
                    P_MSG_FROM      => XXHIL_OM_MAIL_ALERTS_PKG.G_EMAIL_FROM,
                    P_MSG_TO        => LV_MSG_CUST_TO,
                    P_MSG_CC        => NULL,
                    P_MSG_BCC       => NULL,
                    P_MSG_SUBJECT   => LV_MSG_SUBJECT,
                    P_MSG_TEXT      => LV_MSG_TEXT,
                    P_FROM_FILE     => NULL,
                    P_TO_FILE       => NULL,
                    P_TO_EXTN       => NULL,
                    P_WAIT_FLG      => NULL,
                    P_CALLED_FROM   => 'XXHIL_OM_DEAL');
            END;
        END LOOP;

        FOR AS30
            IN (SELECT AS30_IMPORTID, DEAL_ID
                  FROM XXHIL_OM_DEAL_HDR
                 WHERE DEAL_ID = P_DEAL_ID AND AS30_IMPORTID IS NOT NULL)
        LOOP
            DECLARE
                LV_MSG_SUBJECT   XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
                LV_MSG_TEXT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
                LV_MSG_FROM      XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE;
                LV_MSG_TO        XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
                LV_MSG_CC        XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
                LV_MSG_BCC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
            BEGIN
                IF AS30.AS30_IMPORTID IS NOT NULL
                THEN
                    LV_MSG_SUBJECT :=
                           'Updation of deal after Reval Import for Deal '
                        || as30.DEAL_ID;

                    SELECT REPLACE (CHG_COL, ';', CHR (13))
                      INTO LV_MSG_TEXT
                      FROM XXHIL_OM_DEAL_HDR_HIST_V
                     WHERE     1 = 1
                           AND DEAL_ID = as30.DEAL_ID
                           AND CHG_COL IS NOT NULL;

                    LV_MSG_TO :=
                        XXHIL_OM_MAIL_ALERTS_PKG.GET_SBU_ROLE_MAIL (
                            P_MDLID       => 'XXHIL_OM_DEAL_IMP',
                            P_OU          => NULL,
                            P_MAIL_TYPE   => 'TO',
                            P_SBU         => NULL);

                    LV_MSG_CC :=
                        XXHIL_OM_MAIL_ALERTS_PKG.GET_SBU_ROLE_MAIL (
                            P_MDLID       => 'XXHIL_OM_DEAL_IMP',
                            P_OU          => NULL,
                            P_MAIL_TYPE   => 'CC',
                            P_SBU         => NULL);

                    LV_MSG_BCC :=
                        XXHIL_OM_MAIL_ALERTS_PKG.GET_SBU_ROLE_MAIL (
                            P_MDLID       => 'XXHIL_OM_DEAL_IMP',
                            P_OU          => NULL,
                            P_MAIL_TYPE   => 'BCC',
                            P_SBU         => NULL);

                    IF LV_MSG_TEXT IS NOT NULL
                    THEN
                        BEGIN
                            XXHIL_OM_MAIL_ALERTS_PKG.PUSH_MAIL (
                                P_REQUEST_ID    => NULL,
                                P_MSG_FROM      =>
                                    XXHIL_OM_MAIL_ALERTS_PKG.G_EMAIL_FROM,
                                P_MSG_TO        => LV_MSG_TO,
                                P_MSG_CC        => LV_MSG_CC,
                                P_MSG_BCC       => LV_MSG_BCC,
                                P_MSG_SUBJECT   => LV_MSG_SUBJECT,
                                P_MSG_TEXT      => LV_MSG_TEXT,
                                P_FROM_FILE     => NULL,
                                P_TO_FILE       => NULL,
                                P_TO_EXTN       => NULL,
                                P_WAIT_FLG      => NULL,
                                P_CALLED_FROM   => 'XXHIL_OM_DEAL_IMP');
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                NULL;
                        END;
                    END IF;
                END IF;
            END;
        END LOOP;
    END DEAL_MAIL;

    PROCEDURE GL_DAILY_RATES_MAIL (
        errbuf              OUT VARCHAR2,
        retcode             OUT VARCHAR2,
        p_conversion_date       gl_daily_rates.conversion_date%TYPE,
        p_from_currency         gl_daily_rates.from_currency%TYPE,
        p_to_currency           gl_daily_rates.to_currency%TYPE,
        p_conversion_type       gl_daily_rates.conversion_type%TYPE)
    IS
        lv_msg_subject       xxhil_om_req_attch_mail.msg_subject%TYPE;
        lv_msg_text          xxhil_om_req_attch_mail.msg_text%TYPE;
        lv_msg_from          xxhil_om_req_attch_mail.msg_from%TYPE;
        lv_msg_to            xxhil_om_req_attch_mail.msg_to%TYPE;
        lv_msg_cc            xxhil_om_req_attch_mail.msg_cc%TYPE;
        lv_msg_bcc           xxhil_om_req_attch_mail.msg_bcc%TYPE;
        lv_mailable          BOOLEAN := FALSE;

        lv_conversion_type   gl_daily_conversion_types.user_conversion_type%TYPE;
    BEGIN
        SELECT user_conversion_type
          INTO lv_conversion_type
          FROM gl_daily_conversion_types
         WHERE conversion_type = p_conversion_type;

        IF lv_conversion_type IN ('RBI', 'TTS') AND p_from_currency = 'USD'
        THEN
            FOR rate
                IN (SELECT *
                      FROM gl_daily_rates
                     WHERE     conversion_type = p_conversion_type
                           AND from_currency = p_from_currency
                           AND to_currency = p_to_currency
                           AND conversion_date = p_conversion_date)
            LOOP
                lv_msg_text :=
                       '<!DOCTYPE html>'
                    || '<html>'
                    || '<head>'
                    || '<style type=text/css>table{border-collapse:collapse;} th{background-color:#cfe0f1;text-indent:1;border: 1px solid black;vertical-align:top;} td{background-color:#f2f2f5;border:1px solid black;vertical-align:top;}</style>'
                    || '</head>'
                    || '<body>';
            END LOOP;
        END IF;
    END GL_DAILY_RATES_MAIL;

    PROCEDURE INSERT_REQ_ATTCH_REC (request_id    NUMBER,
                                    msg_from      VARCHAR2,
                                    msg_to        VARCHAR2,
                                    msg_cc        VARCHAR2,
                                    msg_bcc       VARCHAR2,
                                    msg_subject   VARCHAR2,
                                    msg_text      VARCHAR2,
                                    from_file     VARCHAR2,
                                    to_file       VARCHAR2,
                                    to_extn       VARCHAR2,
                                    wait_flg      VARCHAR2,
                                    called_from   VARCHAR2)
    AS
    BEGIN
        IF msg_to IS NOT NULL OR msg_cc IS NOT NULL OR msg_bcc IS NOT NULL
        THEN
            INSERT INTO XXHIL_OM_REQ_ATTCH_MAIL (called_from,
                                                 created_by,
                                                 creation_date,
                                                 from_file,
                                                 last_updated_by,
                                                 last_update_date,
                                                 mail_sent_flg,
                                                 msg_bcc,
                                                 msg_cc,
                                                 msg_from,
                                                 msg_subject,
                                                 msg_text,
                                                 msg_to,
                                                 request_id,
                                                 status_code,
                                                 to_extn,
                                                 to_file,
                                                 wait_flg)
                 VALUES (called_from,
                         fnd_global.user_id,
                         SYSDATE,
                         from_file,
                         NULL,
                         NULL,
                         'N',
                         msg_bcc,
                         msg_cc,
                         msg_from,
                         msg_subject,
                         SUBSTR (msg_text, 0, 4000),
                         msg_to,
                         request_id,
                         NULL,
                         to_extn,
                         to_file,
                         wait_flg);

            COMMIT;
        END IF;
    END INSERT_REQ_ATTCH_REC;

    PROCEDURE MV_REFRESH (errbuf OUT VARCHAR2, retcode OUT VARCHAR2)
    AS
    BEGIN
        FOR i
            IN (SELECT    'BEGIN dbms_mview.refresh('''
                       || owner
                       || '.'
                       || mview_name
                       || ''',''?''); END; '    script
                  FROM user_mviews a
                 WHERE    mview_name LIKE 'XXHIL_OM%MV'
                       OR mview_name LIKE 'XXHIL_OTM%MV'
                       OR mview_name LIKE 'XXHIL_AR%MV')
        --SELECT    ' dbms_mview.refresh('''
        --       || owner
        --       || '.'
        --       || mview_name
        --       || ''',''?'') '    script
        --  FROM user_mviews a
        -- WHERE    mview_name LIKE 'XXHIL_OM%MV'
        --       OR mview_name LIKE 'XXHIL_OTM%MV')
        LOOP
            DECLARE
                lv_errbuf    VARCHAR2 (32767);
                lv_retcode   VARCHAR2 (32767);
            BEGIN
                xxhil_om_mail_alerts_pkg.alert (errbuf       => lv_errbuf,
                                                retcode      => lv_retcode,
                                                p_criteria   => i.script);
            END;
        END LOOP;
    END MV_REFRESH;

    PROCEDURE ALERT (ERRBUF       OUT VARCHAR2,
                     RETCODE      OUT VARCHAR2,
                     P_CRITERIA       VARCHAR2)
    IS
    BEGIN
        msg ('ALERT START*******');
        msg ('PARAMETER..');
        msg ('P_CRITERIA:' || P_CRITERIA);

        CASE UPPER (p_criteria)
            WHEN 'MTM'
            THEN
                xxhil_om_mail_alerts_pkg.mtm;
            WHEN 'ONE_PAGE_CCR'
            THEN
                xxhil_om_mail_alerts_pkg.one_page_ccr;
            WHEN 'ONE_PAGE_CATH'
            THEN
                xxhil_om_mail_alerts_pkg.one_page_cathode;
            WHEN 'ONE_PAGE_WIRE'
            THEN
                xxhil_om_mail_alerts_pkg.one_page_wire;
            WHEN 'ONE_PAGE_SCRAP'
            THEN
                xxhil_om_mail_alerts_pkg.one_page_scrap;
            WHEN 'ONE_PAGE_COBR'
            THEN
                xxhil_om_mail_alerts_pkg.one_page_cobr;
            WHEN 'ONE_PAGE_GOLD'
            THEN
                xxhil_om_mail_alerts_pkg.one_page_gold;
            WHEN 'ONE_PAGE_SLVR'
            THEN
                xxhil_om_mail_alerts_pkg.one_page_slvr;
            /* WHEN 'CCR_METALAC'
             THEN
                 XXHIL_OM_MAIL_ALERTS_PKG.CCR_METALAC;
             WHEN 'RBD_METALAC'
             THEN
                 XXHIL_OM_MAIL_ALERTS_PKG.RBD_METALAC;
             */
            WHEN 'DEPO_STOCK_STATUS'
            THEN
                XXHIL_OM_MAIL_ALERTS_PKG.DEPO_STOCK_STATUS;
            --WHEN 'CHARGE'
            --THEN
            --    xxbc_om_charge_entry;
            --WHEN 'TABLE_GROWTH'
            --THEN
            --    table_growth;
            --WHEN 'MD_CELL_DO'
            --THEN
            --    md_cell_reports (TRUNC (SYSDATE), 'DO');
            --WHEN 'DBA_ACTIVITY'
            --THEN
            --    dba_activity;
            --    --concurrent_queue;
            --    read_rw_access;
            --WHEN 'CRM_MV_INST'
            --THEN
            --    DECLARE
            --        v_errbuf    VARCHAR2 (10000);
            --        v_retcode   VARCHAR2 (10000);
            --    BEGIN
            --        xxbc_crm_request_run.refresh_table (v_errbuf,
            --                                            v_retcode,
            --                                            'INST');
            --    END;
            --WHEN 'CRM_MV_GPS'
            --THEN
            --    DECLARE
            --        v_errbuf    VARCHAR2 (32767);
            --        v_retcode   VARCHAR2 (32767);
            --    BEGIN
            --        xxbc_crm_request_run.refresh_table (v_errbuf,
            --                                            v_retcode,
            --                                            'GPS');
            --    END;
            --WHEN 'CRM_MV'
            --THEN
            --    -- End Date CRM User if it is end dated in ERP
            --    UPDATE xxhilcrm_users_all@rkt_crm_sams u
            --       SET end_date_active = TRUNC (SYSDATE),
            --           last_updated_by = -1,
            --           last_update_date = SYSDATE
            --     WHERE     end_date_active IS NULL
            --           AND user_class <> 'CUSTOMER'
            --           AND NVL (crm_business, '-') = 'COPPER'
            --           AND EXISTS
            --                   (SELECT 'x'
            --                      FROM fnd_user a, xxbc_crm_user b
            --                     WHERE     b.user_id = a.user_id
            --                           AND a.end_date IS NOT NULL
            --                           AND b.crm_login_id = u.user_id);
            --
            --    --Remove End Date CRM User if it is active in ERP
            --    UPDATE xxhilcrm_users_all@rkt_crm_sams xul
            --       SET end_date_active = NULL
            --     WHERE     crm_business = 'COPPER'
            --           AND user_class NOT IN ('CUSTOMER')
            --           AND end_date_active IS NOT NULL
            --           AND EXISTS
            --                   (SELECT 1
            --                      FROM xxbc_crm_user cu, fnd_user fu
            --                     WHERE     fu.user_id = cu.user_id
            --                           AND cu.crm_login_id = xul.user_id
            --                           AND cu.inactive_user_date IS NULL
            --                           AND fu.end_date IS NULL);
            --
            --    xxbc_crm_request_run.insert_grp_agen;
            --
            --    DECLARE
            --        v_errbuf    VARCHAR2 (10000);
            --        v_retcode   VARCHAR2 (10000);
            --    BEGIN
            --        xxbc_crm_request_run.refresh_table (v_errbuf,
            --                                            v_retcode,
            --                                            'ALL');
            --    END;
            --
            --
            --
            --    DECLARE
            --        v_errbuf    VARCHAR2 (10000);
            --        v_retcode   VARCHAR2 (10000);
            --    BEGIN
            --        bccrm_lib.mail_criteria@rkt_crm_sams (v_errbuf,
            --                                              v_retcode,
            --                                              'MVIEW_REFRESH',
            --                                              NULL);
            --    END;
            --
            --    iface_correction;
            --
            /*WHEN 'NET_REALIZATION'
            THEN
                xxbc_om_mail_alerts.premium_realization;
            WHEN 'DISPATCH_MAIL_ATTACH'
            THEN
                xxbc_om_mail_alerts.dispatch_mail_attachment ('SAP');
                */
            WHEN 'SAP'
            THEN
                xxhil_om_mail_alerts_pkg.dispatch_mail (p_criteria);
            WHEN 'PHG'
            THEN
                xxhil_om_mail_alerts_pkg.dispatch_mail (p_criteria);
            WHEN 'HFA'
            THEN
                xxhil_om_mail_alerts_pkg.dispatch_mail (p_criteria);
            WHEN 'ALF'
            THEN
                xxhil_om_mail_alerts_pkg.dispatch_mail (p_criteria);
            WHEN 'ALS'
            THEN
                xxhil_om_mail_alerts_pkg.dispatch_mail (p_criteria);
            --WHEN 'SALE_QTY'
            --THEN
            --    xxbc_om_mail_alerts.sale_qty;
            --WHEN 'OPEN_ORDER'
            --THEN
            --    xxbc_om_mail_alerts.open_orders;
            WHEN 'RECO'
            THEN
                XXHIL_OM_MAIL_ALERTS_PKG.RECO;
            /*WHEN 'INSTRUMENT'
            THEN
                xxbc_om_mail_alerts.pndg_inv_undr_cr;
                xxbc_om_mail_alerts.not_remitted_receipt;
                xxbc_om_mail_alerts.receipt_entry_delay;
                xxbc_om_mail_alerts.int_dr_notes_mail;
                xxbc_om_mail_alerts.pending_refund;
                request_id :=
                    fnd_request.submit_request (
                        'JA',
                        'JAINARST',
                        'India - ST forms Receipt processing',
                        '',
                        FALSE,
                        TO_CHAR (TRUNC (TRUNC (SYSDATE) - 15, 'mm'),
                                 'rrrr/mm/dd hh24:mi:ss'),
                        TO_CHAR (TRUNC (SYSDATE) - 7,
                                 'rrrr/mm/dd hh24:mi:ss'),
                        'Y',
                        NULL,
                        'C',
                        NULL,
                        NULL,
                        'N',
                        'N',
                        CHR (0));
                COMMIT;
                fnd_file.put_line (fnd_file.LOG,
                                   'Request Id : ' || request_id);
                fnd_file.put_line (
                    fnd_file.LOG,
                       'File name : '
                    || ''''
                    || 'o'
                    || request_id
                    || '.out'
                    || '''');
                p_status :=
                    fnd_concurrent.wait_for_request (request_id,
                                                     1,
                                                     0,
                                                     p_rphase,
                                                     p_rstatus,
                                                     p_dphase,
                                                     p_dstatus,
                                                     p_message);
                COMMIT;

                --
                -- Liability removal for the cases where there is no impact of CST
                --
                DELETE FROM
                    jai_cmn_st_form_dtls
                      WHERE     EXISTS
                                    (SELECT 'x'
                                       FROM xxar_sales
                                      WHERE     customer_trx_id = invoice_id
                                            AND cst = 0
                                            AND line_id =
                                                customer_trx_line_id)
                            AND NVL (matched_amount, 0) = 0;

                xxbc_om_mail_alerts.bg_register;
                --Supplementary Invoice Draft Mails
                request_id :=
                    fnd_request.submit_request (
                        'XXCU',
                        'XXBC_OM_SUPP_MAIL',
                        'Process > Supplementary Invoice Mail (Draft)',
                        '',
                        FALSE,
                        TO_CHAR (TRUNC (SYSDATE) - 1,
                                 'rrrr/mm/dd hh24:mi:ss'),
                        CHR (0));
                COMMIT;
                fnd_file.put_line (fnd_file.LOG,
                                   'Request Id : ' || request_id);
                --DBMS_OUTPUT.put_line ('Request Id : ' || request_id);
                fnd_file.put_line (
                    fnd_file.LOG,
                       'File name : '
                    || ''''
                    || 'o'
                    || request_id
                    || '.out'
                    || '''');
            --xxbc_om_mail_alerts.active_instrument;
            WHEN 'PROVISION'
            THEN
                -- Provision Updation Process

                IF TO_NUMBER (TO_CHAR (SYSDATE, 'DD')) BETWEEN 3 AND 29
                THEN
                    FOR i
                        IN (  SELECT organization_id,
                                     GROUP_ID,
                                     agen_cd,
                                     MIN (fdt)     fdt,
                                     MAX (tdt)     tdt
                                FROM (SELECT DISTINCT organization_id,
                                                      GROUP_ID,
                                                      agen_cd,
                                                      from_date     fdt,
                                                      TO_DATE       tdt
                                        FROM xxbc_ar_slab_disc_mst
                                       WHERE     (   TRUNC (SYSDATE) - 1 BETWEEN from_date
                                                                             AND TO_DATE
                                                  OR TRUNC (creation_date) BETWEEN   TRUNC (
                                                                                         SYSDATE)
                                                                                   - 3
                                                                               AND TRUNC (
                                                                                       SYSDATE))
                                             AND disc_code IN ('LTC', 'YLTC')
                                      UNION
                                      SELECT DISTINCT term_exec_locn,
                                                      term_group_id,
                                                      term_site_id,
                                                      term_fr_dt,
                                                      term_to_dt
                                        FROM xxbc_om_contract_terms
                                       WHERE     (   TRUNC (SYSDATE) - 1 BETWEEN term_fr_dt
                                                                             AND term_to_dt
                                                  OR TRUNC (creation_date) BETWEEN   TRUNC (
                                                                                         SYSDATE)
                                                                                   - 3
                                                                               AND TRUNC (
                                                                                       SYSDATE))
                                             AND term_type = 'P')
                            GROUP BY organization_id, GROUP_ID, agen_cd)
                    LOOP
                        request_id :=
                            fnd_request.submit_request (
                                'XXCU',
                                'XXBC_AR_UPDATE_PROVISION',
                                'Process > Update Terms',
                                '',
                                FALSE,
                                TO_CHAR (i.fdt, 'rrrr/mm/dd hh24:mi:ss'),
                                TO_CHAR (i.tdt, 'rrrr/mm/dd hh24:mi:ss'),
                                i.organization_id,
                                i.GROUP_ID,                           -- Group
                                i.agen_cd,                            -- Party
                                'P',                              -- Provision
                                NULL,
                                CHR (0));
                        COMMIT;
                        fnd_file.put_line (fnd_file.LOG,
                                           'Request Id : ' || request_id);
                        --DBMS_OUTPUT.put_line ('Request Id : ' || request_id);
                        fnd_file.put_line (
                            fnd_file.LOG,
                               'File name : '
                            || ''''
                            || 'o'
                            || request_id
                            || '.out'
                            || '''');

                        --waiting for the request to get completed...
                        p_status :=
                            fnd_concurrent.wait_for_request (request_id,
                                                             1,
                                                             0,
                                                             p_rphase,
                                                             p_rstatus,
                                                             p_dphase,
                                                             p_dstatus,
                                                             p_message);
                        COMMIT;
                    END LOOP;
                END IF;
            --waiting for the request to get completed...
            WHEN 'SETTLEMENT'
            THEN
                -- Final Rate Updation Process
                request_id :=
                    fnd_request.submit_request (
                        'XXCU',
                        'XXBC_OM_UPDATE_MIS',
                        'Process > Update MIS Table for Final Price Calculation',
                        '',
                        FALSE,
                        CHR (0));
                COMMIT;
                fnd_file.put_line (fnd_file.LOG,
                                   'Request Id : ' || request_id);
                --DBMS_OUTPUT.put_line ('Request Id : ' || request_id);
                fnd_file.put_line (
                    fnd_file.LOG,
                       'File name : '
                    || ''''
                    || 'o'
                    || request_id
                    || '.out'
                    || '''');
                --waiting for the request to get completed...
                p_status :=
                    fnd_concurrent.wait_for_request (request_id,
                                                     1,
                                                     0,
                                                     p_rphase,
                                                     p_rstatus,
                                                     p_dphase,
                                                     p_dstatus,
                                                     p_message);
                COMMIT;

                UPDATE xx_marketing_mis a
                   SET a.final_pricing_flag = 'N'
                 WHERE     a.final_pricing_flag = 'Y'
                       AND EXISTS
                               (SELECT 'x'
                                  FROM xx_marketing_mis b
                                 WHERE     a.shipment_id = b.shipment_id
                                       AND NVL (b.final_price, 0) = 0)
                       AND order_contract_type IN ('KQKP', 'KQUP', 'UQUP');

                UPDATE xx_marketing_mis a
                   SET a.final_pricing_flag = 'Y'
                 WHERE     a.final_pricing_flag = 'N'
                       AND NOT EXISTS
                               (SELECT 'x'
                                  FROM xx_marketing_mis b
                                 WHERE     a.shipment_id = b.shipment_id
                                       AND NVL (b.final_price, 0) = 0)
                       AND order_contract_type IN ('KQKP', 'KQUP', 'UQUP');

                xxbc_om_update_terms_stk;

                COMMIT;
                xxbc_om_mail_alerts.lme_ex_mismatch;
            WHEN 'PENDING_DELIVERY'
            THEN
                DECLARE
                    a   VARCHAR2 (10000);
                    b   VARCHAR2 (10000);
                BEGIN
                    FOR i
                        IN (  SELECT org_id, MAX (delivery_id) delivery_id
                                FROM xxbc_om_invoice_hdr
                               WHERE     delivery_id IS NOT NULL
                                     AND invh_no IS NULL
                                     AND excise_invoice_no IS NULL
                            GROUP BY org_id)
                    LOOP
                        xxbc_om_shipment.docs_print (a, b, i.delivery_id);
                        fnd_file.put_line (
                            fnd_file.LOG,
                               'Pending Delivery Set : '
                            || i.org_id
                            || '/'
                            || i.delivery_id
                            || ' '
                            || a
                            || '/'
                            || b);

                        FOR j
                            IN (SELECT delivery_id
                                  FROM xxbc_om_invoice_hdr
                                 WHERE     org_id = i.org_id
                                       AND delivery_id IS NOT NULL
                                       AND invh_no IS NULL
                                       AND excise_invoice_no IS NULL)
                        LOOP
                            xxbc_om_upd_inv_detail (j.delivery_id);
                        END LOOP;
                    END LOOP;
                END;
            */
            WHEN 'DPR'
            THEN
                xxhil_om_charge_entry_prc;

                --price_list_mail;
                --xml_layout :=
                --    fnd_request.add_layout ('XXCU', -- Application of Template
                --                            'XXBC_OM_ONHAND_STOCK_EXCEL', -- Name of Template
                --                            'en',
                --                            'US',
                --                            'EXCEL');
                ---- Export Summary (XLS)
                --request_id :=
                --    fnd_request.submit_request (
                --        'XXCU',
                --        'XXBC_OM_ONHAND_STOCK_EXCEL',
                --        'Register > Onhand Stock Report -XLS',
                --        '',
                --        FALSE,
                --        NULL,
                --        NULL,
                --        NULL,
                --        NULL,
                --        CHR (0));
                --COMMIT;

                xxhil_om_mail_alerts_pkg.one_page_ccr;
                MSG ('One Page CCR Completed.');
                xxhil_om_mail_alerts_pkg.one_page_cathode;
                MSG ('One Page Cathode Completed.');
                xxhil_om_mail_alerts_pkg.one_page_wire;
                MSG ('One Page Wire Completed.');
                xxhil_om_mail_alerts_pkg.one_page_scrap;
                MSG ('One Page Scrap Completed.');
                xxhil_om_mail_alerts_pkg.one_page_cobr;
                MSG ('One Page Copper Bar Completed');
                xxhil_om_mail_alerts_pkg.one_page_gold;
                MSG ('One Page Gold Completed');
                xxhil_om_mail_alerts_pkg.one_page_slvr;
                MSG ('One Page Silver Completed');
                --xxbc_om_mail_alerts.dup_prod_analysis;
                --xxbc_om_mail_alerts.ccr_metalac;
                --MSG('One Page CCR Metal Account Completed');
                --xxbc_om_mail_alerts.rbd_metalac;
                --MSG('One Page RBD Metal Account Completed.');
                xxhil_om_mail_alerts_pkg.depo_stock_status;
                MSG ('Depot Stock Status Completed.');

                DECLARE
                    a   VARCHAR2 (1000);
                    b   VARCHAR2 (1000);
                BEGIN
                    IF TO_CHAR (SYSDATE, 'DD') = '01'
                    THEN
                        xxhil_om_month_end_prc (a, b);
                    END IF;
                END;

                DECLARE
                    v_cnt       NUMBER;
                    p_status    BOOLEAN;
                    p_rphase    VARCHAR2 (80);
                    p_rstatus   VARCHAR2 (80);
                    p_dphase    VARCHAR2 (30);
                    p_dstatus   VARCHAR2 (30);
                    p_message   VARCHAR2 (240);
                BEGIN
                    v_cnt := 0;

                    FOR i
                        IN (SELECT request_id
                              FROM xxhil_om_req_attch_mail
                             WHERE     1 = 1
                                   AND wait_flg = 'SMS_DISPATCH'
                                   AND TRUNC (creation_date) =
                                       TRUNC (SYSDATE))
                    LOOP
                        p_status :=
                            fnd_concurrent.wait_for_request (i.request_id,
                                                             1,
                                                             0,
                                                             p_rphase,
                                                             p_rstatus,
                                                             p_dphase,
                                                             p_dstatus,
                                                             p_message);



                        IF     UPPER (p_rstatus) <> 'NORMAL'
                           AND UPPER (p_rphase) <> 'COMPLETED'
                        THEN
                            v_cnt := NVL (v_cnt, 0) + 1;
                        END IF;
                    END LOOP;

                    IF v_cnt = 0
                    THEN
                        xxhil_om_mail_alerts_pkg.stock_aging_detail;
                        MSG ('Stock Aging Detail Completed.');
                    --xxbc_om_mail_alerts.stock_aging_summary;
                    --MSG ('Stock Aging Summary Completed.');
                    END IF;
                END;

                DECLARE
                    v_errbuf    VARCHAR2 (32767);
                    v_retcode   VARCHAR2 (32767);
                BEGIN
                    XXHIL_OM_SMS_PKG.ALERT (v_errbuf, v_retcode, 'DISPATCH');
                END;
            --SAP Dispatch Figures -  Realization inserting to DPR
            --dprmis.main_mis_pkg.prc_insert_morning_data@legacy_read_bcdprod1.hil.com (
            --    16,
            --    TRUNC (SYSDATE) - 1,
            --    NULL,
            --    NULL,
            --    'Y',
            --    v_qty);

            --COMMIT;
            --MSG('SAP - 1 Insertion Completed.');
            --dprmis.main_mis_pkg.prc_insert_morning_data@legacy_read_bcdprod1.hil.com (
            --    17,
            --    TRUNC (SYSDATE) - 1,
            --    NULL,
            --    NULL,
            --    'Y',
            --    v_qty);
            --
            --COMMIT;
            --MSG('SAP - 3 Insertion Completed.');
            --dprmis.main_mis_pkg.prc_insert_morning_data@legacy_read_bcdprod1.hil.com (
            --    18,
            --    TRUNC (SYSDATE) - 1,
            --    NULL,
            --    NULL,
            --    'Y',
            --    v_qty);
            --
            --COMMIT;
            --MSG('SAP - Commercial Insertion Completed.');
            --
            --dprmis.main_mis_pkg.prc_insert_morning_data@legacy_read_bcdprod1.hil.com (
            --    10,
            --    TRUNC (SYSDATE) - 1,
            --    NULL,
            --    NULL,
            --    'Y',
            --    v_qty);
            --COMMIT;
            --MSG('ALF Insertion Completed.');
            --
            ---- PMR GOLD / Silver Dispatch Figures inserting to DPR
            --
            --dprmis.main_mis_pkg.prc_insert_morning_data@legacy_read_bcdprod1.hil.com (
            --    11,
            --    TRUNC (SYSDATE) - 1,
            --    NULL,
            --    NULL,
            --    'Y',
            --    v_qty);

            --MSG('PMR Insertion Completed.');
            --
            --dprmis.main_mis_pkg.set_closing_data@legacy_read_bcdprod1.hil.com (
            --    11,
            --    TRUNC (SYSDATE) - 1);
            --
            --fnd_file.put_line (fnd_file.LOG,
            --                   'PMR Setting Closing Completed.');
            --
            ---- Stock Item Insertion

            --COMMIT;

            --FOR i
            --    IN (SELECT DISTINCT b.mis_print_dept_cd, c.mt_pdate
            --          FROM legacy_read.main_mis@legacy_read_bcdprod1.hil.com
            --               a,
            --               legacy_read.main_mis_dtl@legacy_read_bcdprod1.hil.com
            --               b,
            --               legacy_read.mt_mis_daily_entry@legacy_read_bcdprod1.hil.com
            --               c
            --         WHERE     a.mis_report_id = b.mis_report_id
            --               AND a.mis_status = 'O'
            --               AND NVL (a.insert_auto_flg, 'N') = 'Y'
            --               AND c.mt_report_id = a.mis_report_id
            --               AND c.mt_dept_cd = b.mis_print_dept_cd
            --               AND c.mt_pdate = TRUNC (SYSDATE - 1))
            --LOOP
            --    dprmis.main_mis_pkg.mail_list_html@legacy_read_bcdprod1.hil.com (
            --        'M',
            --        i.mis_print_dept_cd,
            --        i.mt_pdate,
            --        -9);
            --END LOOP;

            WHEN 'MORNING'
            THEN
                -- Close the User Mail Notifications
                UPDATE xxhil_usermail a
                   SET a.end_date =
                           (SELECT b.end_date
                              FROM fnd_user b
                             WHERE b.user_id = a.user_id),
                       status = 'INACTIVE',
                       last_update_date = SYSDATE,
                       last_updated_by = -1
                 WHERE     a.end_date IS NULL
                       AND a.user_id IS NOT NULL
                       AND EXISTS
                               (SELECT 'x'
                                  FROM fnd_user c
                                 WHERE     c.user_id = a.user_id
                                       AND c.end_date IS NOT NULL);

                --
                --UPDATE xxbc_usrmail a
                --   SET a.end_date =
                --           (SELECT b.end_date
                --              FROM fnd_user b
                --             WHERE b.user_id = a.user_id),
                --       status = 'INACTIVE',
                --       last_update_date = SYSDATE,
                --       last_updated_by = -1
                -- WHERE     a.end_date IS NULL
                --       AND EXISTS
                --               (SELECT 'x'
                --                  FROM fnd_user c
                --                 WHERE     c.user_id = a.user_id
                --                       AND c.end_date IS NOT NULL
                --                       AND NOT EXISTS
                --                               (SELECT 'x'
                --                                  FROM xx_vw_gm_nemp d
                --                                 WHERE     UPPER (
                --                                               d.temh_mail) =
                --                                           UPPER (
                --                                               c.email_address)
                --                                       AND NVL (
                --                                               d.temh_resign_dt,
                --                                               TRUNC (
                --                                                   SYSDATE)) >=
                --                                           TRUNC (SYSDATE)));
                --
                --UPDATE xxbc_usrmail a
                --   SET a.end_date = TRUNC (SYSDATE) - 1,
                --       status = 'INACTIVE',
                --       last_update_date = SYSDATE,
                --       last_updated_by = -1
                -- WHERE     a.end_date IS NULL
                --       AND EXISTS
                --               (SELECT 'x'
                --                  FROM xx_vw_emp
                --                 WHERE UPPER (emph_email) = UPPER (emailid))
                --       AND NOT EXISTS
                --               (SELECT 'x'
                --                  FROM xx_vw_emp
                --                 WHERE     UPPER (emph_email) =
                --                           UPPER (emailid)
                --                       AND NVL (emph_system_block_dt,
                --                                TRUNC (SYSDATE)) >=
                --                           TRUNC (SYSDATE))
                --       AND NOT EXISTS
                --               (SELECT 'x'
                --                  FROM xx_vw_gm_nemp
                --                 WHERE     UPPER (temh_mail) =
                --                           UPPER (emailid)
                --                       AND NVL (temh_resign_dt,
                --                                TRUNC (SYSDATE)) >=
                --                           TRUNC (SYSDATE));
                --
                --
                --UPDATE xxbc_usrmail a
                --   SET a.end_date = TRUNC (SYSDATE) - 1,
                --       status = 'INACTIVE',
                --       last_update_date = SYSDATE,
                --       last_updated_by = -1
                -- WHERE     a.end_date IS NULL
                --       AND EXISTS
                --               (SELECT 'x'
                --                  FROM xx_vw_gm_nemp
                --                 WHERE UPPER (temh_mail) = UPPER (emailid))
                --       AND NOT EXISTS
                --               (SELECT 'x'
                --                  FROM xx_vw_gm_nemp
                --                 WHERE     UPPER (temh_mail) =
                --                           UPPER (emailid)
                --                       AND NVL (temh_resign_dt,
                --                                TRUNC (SYSDATE)) >=
                --                           TRUNC (SYSDATE))
                --       AND NOT EXISTS
                --               (SELECT 'x'
                --                  FROM xx_vw_emp
                --                 WHERE     UPPER (emph_email) =
                --                           UPPER (emailid)
                --                       AND NVL (emph_system_block_dt,
                --                                TRUNC (SYSDATE)) >=
                --                           TRUNC (SYSDATE));
                --
                --xxbc_om_mail_alerts.dispatch_mail_attachment ('SAP');

                --IF     TO_CHAR (SYSDATE, 'DD') = '07'
                --   AND TO_CHAR (SYSDATE, 'MM') IN ('01',
                --                                   '04',
                --                                   '07',
                --                                   '10')
                --THEN
                --    xxbc_om_mail_alerts.ledger (
                --        NULL,
                --        NULL,
                --        'DAP',
                --        ADD_MONTHS (TRUNC (SYSDATE, 'mm'), -3),
                --        TRUNC (SYSDATE, 'mm') - 1);
                --END IF;

                XXHIL_OM_MAIL_ALERTS_PKG.nonc_realization;
                --xxbc_om_mail_alerts.gate_in_byp;
                --xxbc_om_mail_alerts.act_advl;
                --
                xxhil_om_mail_alerts_pkg.pending_sanction_status;
                xxhil_om_mail_alerts_pkg.expiry_sanction_status;
                xxhil_om_mail_alerts_pkg.mtm;
                --
                --xxbc_om_mail_alerts.pend_supp_print;
                --
                --FOR i
                --    IN (SELECT DISTINCT org_id, batch_source_name
                --          FROM ra_interface_lines_all
                --         WHERE batch_source_name IN
                --                   ('Interest Reversal',
                --                    'Encashment Discount',
                --                    'Encashment Reversal',
                --                    'Interest Debit Note - Manual'))
                --LOOP
                --    -- Auto Invoice Master Program
                --    SELECT batch_source_id
                --      INTO v_batch_source_id
                --      FROM ra_batch_sources_all
                --     WHERE name = i.batch_source_name AND org_id = i.org_id;
                --
                --    request_id :=
                --        fnd_request.submit_request (
                --            'XXCU',
                --            'XXBC_AR_IMPORT_DN_CN',
                --            'Process > Import DN / CN along with Taxes',
                --            '',
                --            FALSE,
                --            i.org_id,
                --            --v_batch_source_id,
                --            i.batch_source_name,
                --            NULL,
                --            CHR (0));
                --    COMMIT;
                --    --waiting for the request to get completed...
                --    p_status :=
                --        fnd_concurrent.wait_for_request (request_id,
                --                                         1,
                --                                         0,
                --                                         p_rphase,
                --                                         p_rstatus,
                --                                         p_dphase,
                --                                         p_dstatus,
                --                                         p_message);
                --    COMMIT;
                --    fnd_file.put_line (fnd_file.output,
                --                       'Request Id : ' || request_id);
                --END LOOP;



                -- D3 Transfer Eentry
                --request_id :=
                --    fnd_request.submit_request (
                --        'XXCU',
                --        'XXBC_OM_D3_TRANSFER',
                --        'Process > D3 Stock transfer to CCR',
                --        '',
                --        FALSE,
                --        NULL,
                --        CHR (0));
                --COMMIT;
                --fnd_file.put_line (fnd_file.LOG,
                --                   'Request Id : ' || request_id);
                --DBMS_OUTPUT.put_line ('Request Id : ' || request_id);
                --fnd_file.put_line (
                --    fnd_file.LOG,
                --       'File name : '
                --    || ''''
                --    || 'o'
                --    || request_id
                --    || '.out'
                --    || '''');
                XXHIL_OM_MAIL_ALERTS_PKG.DELETE_UNDERLOAD;

                --XXHIL_OM_MAIL_ALERTS_PKG.LME_EX_REGISTER;
                --Interest Dr Notes to Customers

                --xxbc_om_mail_alerts.sale_qty;
                --xxbc_om_mail_alerts.premium_realization;

                -- Missing 402 Numbers
                --INSERT INTO xxbc_om_missing_f402 (f402_no,
                --                                  status,
                --                                  creation_date,
                --                                  sr)
                --      SELECT f402_no,
                --             'O',
                --             TRUNC (SYSDATE),
                --             MAX (ls_no)
                --        FROM xxbc_om_invoice_hdr a
                --       WHERE     a.f402_no IS NOT NULL
                --             AND a.invh_status = 'C'
                --             AND a.rr_lr_dt >= (SELECT MAX (start_date)
                --                                  FROM xxbc_om_doc_serial
                --                                 WHERE doc_type = 'F402')
                --             AND NOT EXISTS
                --                     (SELECT 'x'
                --                        FROM xxbc_om_invoice_hdr b
                --                       WHERE     b.f402_no = a.f402_no
                --                             AND b.invh_status <> 'C')
                --             AND NOT EXISTS
                --                     (SELECT 'x'
                --                        FROM xxbc_om_missing_f402 miss
                --                       WHERE miss.f402_no = a.f402_no)
                --    GROUP BY f402_no, TRUNC (SYSDATE);
                --
                --xxbc_om_cancel_road_permit;
                --xxbc_om_mail_alerts.open_orders;

                --xxbc_om_mail_alerts.order_beyond_credit_limit;
                --xxbc_om_mail_alerts.despatch_beyond_time_line;

                --xxbc_om_mail_alerts.pending_receiving;

                --xxhil_om_mail_alerts_pkg.sales_agreement_expiry;

                --xxbc_om_mail_alerts.gps_trip_data;

                --DECLARE
                --    v_errbuf    VARCHAR2 (10000);
                --    v_retcode   VARCHAR2 (10000);
                --BEGIN
                --    bccrm_complaint.mail@rkt_crm_sams (v_errbuf,
                --                                       v_retcode,
                --                                       NULL,
                --                                       NULL,
                --                                       'PENDING_COMPLAINT',
                --                                       'COPR');
                --
                --    fnd_file.put_line (
                --        fnd_file.LOG,
                --        'Pending Complaint COPR : ' || v_errbuf);
                --
                --    bccrm_complaint.mail@rkt_crm_sams (v_errbuf,
                --                                       v_retcode,
                --                                       NULL,
                --                                       NULL,
                --                                       'PENDING_COMPLAINT',
                --                                       'DAP');
                --
                --    fnd_file.put_line (
                --        fnd_file.LOG,
                --        'Pending Complaint DAP : ' || v_errbuf);
                --
                --    bccrm_complaint.mail@rkt_crm_sams (v_errbuf,
                --                                       v_retcode,
                --                                       NULL,
                --                                       NULL,
                --                                       'PENDING_COMPLAINT',
                --                                       'NONC');
                --
                --    fnd_file.put_line (
                --        fnd_file.LOG,
                --        'Pending Complaint NONC : ' || v_errbuf);
                --END;

                --DECLARE
                --    v_errbuf    VARCHAR2 (10000);
                --    v_retcode   VARCHAR2 (10000);
                --BEGIN
                --    bccrm_complaint.complaint_removal@rkt_crm_sams (
                --        v_errbuf,
                --        v_retcode);
                --    fnd_file.put_line (fnd_file.LOG,
                --                       'Cancellation : ' || v_errbuf);
                --END;

                --IF TO_NUMBER (TO_CHAR (SYSDATE, 'DD')) = 5
                --THEN
                --    DECLARE
                --        v_errbuf    VARCHAR2 (10000);
                --        v_retcode   VARCHAR2 (10000);
                --    BEGIN
                --        bccrm_lib.mail_criteria@rkt_crm_sams (
                --            v_errbuf,
                --            v_retcode,
                --            'CRM_LOGIN_ALERT',
                --            NULL);
                --    END;
                --END IF;

                --xxhil_om_mail_alerts_pkg.open_exchange_rate;
                xxhil_om_mail_alerts_pkg.open_exchange_rate ('COPR');
                xxhil_om_mail_alerts_pkg.open_exchange_rate ('GOLD');
                xxhil_om_mail_alerts_pkg.open_exchange_rate ('SLVR');
            --WHEN 'UGHAI'
            --THEN
            --    xxbc_om_mail_alerts.ughai;
            WHEN 'MV_REFRESH'
            THEN
                msg ('MV_REFRESH START');

                DECLARE
                    lv_errbuf    VARCHAR2 (32767);
                    lv_retcode   VARCHAR2 (32767);
                BEGIN
                    mv_refresh (errbuf => lv_errbuf, retcode => lv_retcode);
                    msg ('lv_errbuf:' || lv_errbuf);
                    msg ('lv_retcode:' || lv_retcode);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        msg ('exception in mv_refresh');
                        msg ('sqlerrm:' || SQLERRM);
                END;

                msg ('mv_refresh end');
            ELSE
                msg ('else part start');

                DECLARE
                    lv_script   VARCHAR2 (32767);
                BEGIN
                    msg ('EXECUTE IMMEDIATE (''' || p_criteria || '''');

                    EXECUTE IMMEDIATE (p_criteria);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        msg ('exception in else part');
                        msg ('sqlerrm:' || SQLERRM);
                END;

                msg ('else part end');
        END CASE;
    END ALERT;

    PROCEDURE INVOICE (P_DELIVERY_ID   NUMBER,
                       P_TREN_ID       NUMBER,
                       P_IS_VEH_OUT    VARCHAR2 DEFAULT 'N')
    IS
        FUNCTION GET_DRIVER_MOBILE (P_TREN_ID NUMBER, P_ORG_CD VARCHAR2)
            RETURN VARCHAR2
        IS
            PRAGMA AUTONOMOUS_TRANSACTION;
            LV_DRIVER_MOBILE   XXHIL_WEIGHBRIDGE_DETAILS.DRIVER_MOBILE%TYPE;
        BEGIN
            BEGIN
                SELECT DRIVER_MOBILE
                  INTO LV_DRIVER_MOBILE
                  FROM XXHIL_WEIGHBRIDGE_DETAILS
                 WHERE TREN_ID = P_TREN_ID AND SOURCE_LOCATION = P_ORG_CD;
            EXCEPTION
                WHEN OTHERS
                THEN
                    LV_DRIVER_MOBILE := NULL;
            END;

            RETURN LV_DRIVER_MOBILE;
        END;
    BEGIN
        msg ('INVOICE START*****');

        msg ('PARAMETERS');
        msg ('P_DELIVERY_ID = ' || P_DELIVERY_ID);
        msg ('P_TREN_ID = ' || P_TREN_ID);

        FOR dl
            IN ( /*SELECT DISTINCT
                        WND.DELIVERY_ID
                            DELIVERY_ID,
                        NVL (JTF.ACKNOWLEDGEMENT_NUMBER, JTL.TAX_INVOICE_NUM)
                            INVOICE_NUM,
                        TRUNC (
                            NVL (JTL.TAX_INVOICE_DATE,
                                 JTF.ACKNOWLEDGEMENT_DATE))
                            INVOICE_DATE,
                        OOT.ATTRIBUTE2
                            SALE_CATEGORY,
                        JTL.ITEM_ID
                            ITEM_ID,
                        JTL.ORG_ID
                            OU_ID,
                        JTL.ORGANIZATION_ID
                            IO_ID,
                        DOCUMENT_TYPE,
                        jtl.PARTY_NUMBER,
                        ooh.order_source_id,
                        xx.stk_trans_locn
                   FROM WSH_NEW_DELIVERIES         WND,
                        JAI_TAX_DET_FCT_LINES_V    JTF,
                        JAI_TAX_LINES_V            JTL,
                        OE_TRANSACTION_TYPES_ALL   OOT,
                        OE_ORDER_HEADERS_ALL       OOH,
                        XXHIL_WEIGHBRIDGE_DETAILS  XWD,
                        xxhil_om_invoice_hdr       xx
                  WHERE     1 = 1
                        AND JTF.TRX_ID = JTL.TRX_ID
                        AND JTF.TRX_LINE_ID = JTL.TRX_LINE_ID
                        AND JTF.ENTITY_CODE = 'SALES_ORDER_ISSUE'
                        AND JTF.EVENT_CLASS_CODE = 'SALES_ORDER_ISSUE'
                        AND JTF.TRX_ID = WND.DELIVERY_ID
                        AND xx.delivery_id = wnd.delivery_id
                        AND OOT.TRANSACTION_TYPE_ID = OOH.ORDER_TYPE_ID
                        AND OOH.HEADER_ID = WND.SOURCE_HEADER_ID
                        AND TO_CHAR (XWD.TREN_ID) = WND.ATTRIBUTE2
                        AND (   XWD.OUTER_GATE_OUT_TIMESTAMP IS NOT NULL
                             OR P_IS_VEH_OUT = 'Y')
                        AND (   (    XWD.TREN_ID = TO_CHAR (P_TREN_ID)
                                 AND P_TREN_ID IS NOT NULL)
                             OR (    xx.DELIVERY_ID = P_DELIVERY_ID
                                 AND P_DELIVERY_ID IS NOT NULL))*/
                SELECT DISTINCT WND.DELIVERY_ID         DELIVERY_ID,
                                XX.INVH_NO              INVOICE_NUM,
                                XX.INVH_DT              INVOICE_DATE,
                                OOT.ATTRIBUTE2          SALE_CATEGORY,
                                XX.ITEM_ID              ITEM_ID,
                                XX.ORG_ID               IO_ID,
                                XX.ORG_CD               ORG_CD,
                                XX.OU_ID                OU_ID,
                                CUST_CD                 PARTY_NUMBER,
                                OOH.ORDER_SOURCE_ID     ORDER_SOURCE_ID,
                                XX.STK_TRANS_LOCN       STK_TRANS_LOCN,
                                XX.TREN_ID              TREN_ID,
                                OOH.ORDER_NUMBER        ORDER_NUMBER,
                                OTT.NAME                ORDER_TYPE,
                                OOH.CUST_PO_NUMBER      CUST_PO_NUMBER,
                                XX.AGEN_CD              AGEN_CD,
                                XX.CONS_CD              CONS_CD,
                                WND.ATTRIBUTE1          TRANSPORTER_NAME,
                                WND.ATTRIBUTE3          VEH_NO,
                                WND.ATTRIBUTE4          LR_NO,
                                WND.ATTRIBUTE5          LR_DT,
                                XX.TRANS_CD             TRANS_CD,
                                XX.INV_QTY,
                                XX.INVH_DEST
                  FROM WSH_NEW_DELIVERIES        WND,
                       OE_TRANSACTION_TYPES_ALL  OOT,
                       OE_ORDER_HEADERS_ALL      OOH,
                       OE_TRANSACTION_TYPES_TL   OTT,
                       --XXHIL_WEIGHBRIDGE_DETAILS  XWD,
                       XXHIL_OM_INVOICE_HDR      XX
                 WHERE     1 = 1
                       AND XX.DELIVERY_ID = WND.DELIVERY_ID
                       AND OOT.TRANSACTION_TYPE_ID = OOH.ORDER_TYPE_ID
                       AND OTT.TRANSACTION_TYPE_ID = OOH.ORDER_TYPE_ID
                       AND OOH.HEADER_ID = WND.SOURCE_HEADER_ID
                       AND NOT EXISTS
                               (SELECT 1
                                  FROM OE_ORDER_HEADERS_ALL  OH,
                                       OE_ORDER_LINES_ALL    OL
                                 WHERE     OH.HEADER_ID = OL.HEADER_ID
                                       AND OL.CONTEXT = 'HIL Return'
                                       AND OL.REFERENCE_LINE_ID =
                                           SOURCE_LINE_ID
                                       AND OH.CONTEXT = 'Return'
                                       AND OL.FLOW_STATUS_CODE NOT IN
                                               ('ENTERED',
                                                'AWAITING_RETURN',
                                                'CANCELLED')
                                       AND OH.ATTRIBUTE1 = 'Internal')
                       AND NOT EXISTS
                               (SELECT 'x'
                                  FROM XXHIL_AR_INVOICE_CANCELLATION
                                 WHERE     PROCESS_FLAG <> 'E'
                                       AND RETURN_TO IN
                                               ('WITHIN PLANT', 'ACCIDENT')
                                       AND SHIPMENT_NUMBER =
                                           TO_CHAR (WND.DELIVERY_ID))
                       AND TO_CHAR (XX.TREN_ID) = WND.ATTRIBUTE2
                       /*AND (   XWD.OUTER_GATE_OUT_TIMESTAMP IS NOT NULL
                            OR P_IS_VEH_OUT = 'Y')
                       */
                       AND (   (    XX.TREN_ID = TO_CHAR (P_TREN_ID)
                                AND P_TREN_ID IS NOT NULL)
                            OR (    XX.DELIVERY_ID = P_DELIVERY_ID
                                AND P_DELIVERY_ID IS NOT NULL)))
        LOOP
            MSG ('NEW CASE*****');
            MSG ('DELIVERY_ID = ' || DL.DELIVERY_ID);
            msg ('INVOICE_NUM = ' || DL.INVOICE_NUM);
            msg ('INVOICE_DATE = ' || DL.INVOICE_DATE);
            msg ('ITEM_ID = ' || DL.ITEM_ID);
            msg ('OU_ID = ' || DL.OU_ID);
            msg ('IO_ID = ' || DL.IO_ID);
            msg ('ORG_CODE = ' || DL.org_cd);
            msg ('TREN_ID = ' || DL.TREN_ID);
            msg ('SALE_CATEGORY = ' || DL.SALE_CATEGORY);

            DECLARE
                LV_REQUEST_ID       XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
                LV_DB_NAME          VARCHAR2 (100);
                LV_MSG_FROM         XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                        := G_EMAIL_FROM (); --:= 'hilerp.alert@adityabirla.com';
                LV_MSG_TO           XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
                LV_MSG_CC           XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
                LV_MSG_BCC          XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
                LV_SUBJECT          XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
                LV_MSG_TEXT         XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
                LV_FROM_FILE        XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
                LV_TO_FILE          XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
                LV_XML_LAYOUT       BOOLEAN;
                LV_PROD_GROUP       XXHIL_OM_PROD_V.PROD_GRP%TYPE;
                LV_PROD_SUB_GROUP   XXHIL_OM_PROD_V.PROD_SUB_GRP%TYPE;
                EX_EXPORT_CASE      EXCEPTION;
                EX_GOLD_SLVR_CASE   EXCEPTION;
                LV_USER_ID          FND_USER.USER_ID%TYPE;
                LV_RESP_ID          FND_RESPONSIBILITY_TL.RESPONSIBILITY_ID%TYPE;
                LV_RESP_APPL_ID     FND_RESPONSIBILITY_TL.APPLICATION_ID%TYPE;
                LV_DRIVER_MOBILE    XXHIL_WEIGHBRIDGE_DETAILS.DRIVER_MOBILE%TYPE;
                LV_SHIP_TO_NAME     XXHIL_OM_SITE_V.CNSG_NAME%TYPE;
                LV_BILL_TO_NAME     XXHIL_OM_SITE_V.CNSG_NAME%TYPE;
                LV_CARRIER_NAME     XXHIL_OM_TRANS_V.CARRIER_NAME%TYPE;
            BEGIN
                SELECT prod_grp, prod_sub_grp
                  INTO lv_prod_group, lv_prod_sub_group
                  FROM xxhil_om_prod_v
                 WHERE prod_cd = dl.item_Id;


                IF UPPER (DL.SALE_CATEGORY) IN ('EXPORT', 'SAMPLE EXPORT')
                THEN
                    RAISE ex_export_case;
                END IF;

                /*IF lv_prod_sub_group IN ('GOLD', 'SLVR')
                THEN
                    RAISE ex_gold_slvr_case;
                END IF;*/

                --AND XWD.DOCUMENT_TYPE IN ('FPR', 'OFR')

                LV_DRIVER_MOBILE := GET_DRIVER_MOBILE (DL.TREN_ID, DL.ORG_CD);

                /* handeled through PRAGMA AUTONOMOUS_TRANSACTION;
                BEGIN
                    SELECT DRIVER_MOBILE
                      INTO LV_DRIVER_MOBILE
                      FROM XXHIL_WEIGHBRIDGE_DETAILS
                     WHERE     TREN_ID = DL.TREN_ID
                           AND SOURCE_LOCATION = DL.ORG_CD;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        LV_DRIVER_MOBILE := NULL;
                END;
                */

                BEGIN
                    SELECT DISTINCT CNSG_NAME
                      INTO LV_BILL_TO_NAME
                      FROM XXHIL_OM_SITE_V
                     WHERE     CNSG_CD = DL.AGEN_CD
                           AND CNSG_AGEN_CD = DL.PARTY_NUMBER;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        LV_BILL_TO_NAME := NULL;
                END;

                BEGIN
                    SELECT DISTINCT CNSG_NAME
                      INTO LV_SHIP_TO_NAME
                      FROM XXHIL_OM_SITE_V
                     WHERE     CNSG_CD = DL.CONS_CD
                           AND CNSG_AGEN_CD = DL.PARTY_NUMBER;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        LV_SHIP_TO_NAME := NULL;
                END;

                BEGIN
                    SELECT DISTINCT CARRIER_NAME
                      INTO LV_CARRIER_NAME
                      FROM XXHIL_OM_TRANS_V
                     WHERE     CARRIER_ID = DL.TRANS_CD
                           AND DL.TRANS_CD IS NOT NULL;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        LV_CARRIER_NAME := DL.TRANSPORTER_NAME;
                END;

                lv_msg_text := '<!DOCTYPE html>';
                lv_msg_text := lv_msg_text || '<HTML>';
                lv_msg_text := lv_msg_text || '<HEAD>';
                lv_msg_text :=
                       lv_msg_text
                    || '<STYLE> table, th, td {border-collapse:collapse;border:1px solid black;} th, td {padding:1px;} td {vertical-align:top;} th {text-align:left; background-color:#85C8FC;} </STYLE>';
                lv_msg_text := lv_msg_text || '</HEAD>';

                lv_msg_text := lv_msg_text || '<BODY>';
                lv_msg_text :=
                    lv_msg_text || 'We have despatched material as attached.';
                lv_msg_text := lv_msg_text || '<BR>';

                --lv_msg_text := lv_msg_text || 'Original Document Copy will be sent by our Regional Office.';
                lv_msg_text := lv_msg_text || '<BR><BR>';

                LV_MSG_TEXT := LV_MSG_TEXT || '<TABLE>';        --width=600>';
                LV_MSG_TEXT :=
                       LV_MSG_TEXT
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">Customer</TD>'
                    || '<TD>'
                    || DL.PARTY_NUMBER
                    || '-'
                    || LV_BILL_TO_NAME
                    || '</TD>'
                    || '</TR>';
                LV_MSG_TEXT :=
                       LV_MSG_TEXT
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">Consignee</TD>'
                    || '<TD>'
                    || DL.CONS_CD
                    || '-'
                    || LV_SHIP_TO_NAME
                    || '</TD>'
                    || '</TR>';
                LV_MSG_TEXT :=
                       LV_MSG_TEXT
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">Transporter</TD>'
                    || '<TD>'
                    || LV_CARRIER_NAME
                    || '</TD>'
                    || '</TR>';
                LV_MSG_TEXT :=
                       LV_MSG_TEXT
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">Driver Mobile</TD>'
                    || '<TD>'
                    || LV_DRIVER_MOBILE
                    || '</TD>'
                    || '</TR>';
                LV_MSG_TEXT :=
                       LV_MSG_TEXT
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">Document No</TD>'
                    || '<TD>'
                    || DL.INVOICE_NUM
                    || '</TD>'
                    || '</TR>';
                LV_MSG_TEXT :=
                       LV_MSG_TEXT
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">Document Date</TD>'
                    || '<TD>'
                    || TO_CHAR (DL.INVOICE_DATE, 'DD-MON-RRRR')
                    || '</TD>'
                    || '</TR>';
                LV_MSG_TEXT :=
                       LV_MSG_TEXT
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">Sales Order</TD>'
                    || '<TD>'
                    || DL.ORDER_NUMBER
                    || '/'
                    || DL.ORDER_TYPE
                    || '</TD>'
                    || '</TR>';
                LV_MSG_TEXT :=
                       LV_MSG_TEXT
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">PO</TD>'
                    || '<TD>'
                    || DL.CUST_PO_NUMBER
                    || '</TD>'
                    || '</TR>';
                LV_MSG_TEXT :=
                       LV_MSG_TEXT
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">Vehicle No</TD>'
                    || '<TD>'
                    || DL.VEH_NO
                    || '</TD>'
                    || '</TR>';
                LV_MSG_TEXT :=
                       LV_MSG_TEXT
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">LR No</TD>'
                    || '<TD>'
                    || DL.LR_NO
                    || '</TD>'
                    || '</TR>';
                LV_MSG_TEXT :=
                       LV_MSG_TEXT
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">LR Date</TD>'
                    || '<TD>'
                    || DL.LR_DT
                    || '</TD>'
                    || '</TR>';
                LV_MSG_TEXT :=
                       LV_MSG_TEXT
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">Product</TD>'
                    || '<TD>'
                    || XXHIL_OM_LIB_PKG.PROD_NAME (DL.ITEM_ID)
                    || '</TD>'
                    || '</TR>';
                LV_MSG_TEXT :=
                       LV_MSG_TEXT
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">Quantity</TD>'
                    || '<TD>'
                    || DL.INV_QTY
                    || '</TD>'
                    || '</TR>';
                LV_MSG_TEXT :=
                       LV_MSG_TEXT
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">Destination</TD>'
                    || '<TD>'
                    || DL.INVH_DEST
                    || '</TD>'
                    || '</TR>';

                /* BEGIN
                     SELECT FND.USER_ID,
                            FRESP.RESPONSIBILITY_ID,
                            FRESP.APPLICATION_ID
                       INTO LV_USER_ID, LV_RESP_ID, LV_RESP_APPL_ID
                       FROM APPS.FND_USER               FND,
                            APPS.FND_RESPONSIBILITY_TL  FRESP
                      WHERE     1 = 1
                            AND FND.USER_NAME = 'HILOTC'
                            AND FRESP.RESPONSIBILITY_NAME LIKE
                                    'HIL OM OTC EINV';
                 EXCEPTION
                     WHEN OTHERS
                     THEN
                         LV_USER_ID := 0;
                         LV_RESP_ID := 20419;
                         LV_RESP_APPL_ID := 0;
                 END;

                 FND_GLOBAL.APPS_INITIALIZE (USER_ID        => LV_USER_ID, --NVL (fnd_profile.VALUE ('USER_ID'), 1232), --0
                                             RESP_ID        => LV_RESP_ID, --NVL (fnd_profile.VALUE ('RESP_ID'), 50798), --20419
                                             RESP_APPL_ID   => LV_RESP_APPL_ID); --NVL (fnd_profile.VALUE ('RESP_APPL_ID'), 50001));  --0

                 IF UPPER (DL.SALE_CATEGORY) IN ('EXPORT', 'SAMPLE EXPORT')
                 THEN
                     --For Export TAX Invoice
                     lv_xml_layout :=
                         fnd_request.add_layout (
                             template_appl_name   => 'XXHIL',
                             template_code        => 'XXHIL_OM_GSTINVEXP',
                             template_language    => 'en',
                             template_territory   => 'US',
                             output_format        => 'PDF');

                     LV_REQUEST_ID :=
                         fnd_request.submit_request (
                             application   => 'XXHIL',
                             program       => 'XXHIL_OM_GSTINVEXP', --'XXHIL_OM_TAXINVMETDOM',
                             description   => 'XXHIL OM Invoice Exports',
                             start_time    => NULL,
                             sub_request   => FALSE,
                             argument1     => DL.IO_ID,            --<P_ORG_ID>
                             argument2     =>
                                 TO_CHAR (DL.invoice_date, 'DD-MON-RRRR'), --<P_FROM_EXCISE_INV_DT>
                             argument3     =>
                                 TO_CHAR (DL.invoice_date, 'DD-MON-RRRR'), --<P_TO_EXCISE_INV_DT>
                             argument4     => dl.invoice_num, --<P_FROM_EXCISE_INV_NO>
                             argument5     => dl.invoice_num, --<P_TO_EXCISE_INV_NO>
                             argument6     => 'Y'                    --<P_TYPE>
                                                 );
                 ELSE
                     --Other then Export Case
                     lv_xml_layout :=
                         fnd_request.add_layout (
                             template_appl_name   => 'XXHIL',
                             template_code        => 'XXHIL_OM_GSTINVDOM',
                             template_language    => 'en',
                             template_territory   => 'US',
                             output_format        => 'PDF');


                     LV_REQUEST_ID :=
                         fnd_request.submit_request (
                             application   => 'XXHIL',
                             program       => 'XXHIL_OM_GSTINVDOM', --'XXHIL_OM_TAXINVMETDOM',
                             description   => 'XXHIL OM Invoice Domestic',
                             start_time    => NULL,
                             sub_request   => FALSE,
                             argument1     => DL.IO_ID,            --<P_ORG_ID>
                             argument2     =>
                                 TO_CHAR (DL.invoice_date, 'DD-MON-RRRR'), --<P_FROM_EXCISE_INV_DT>
                             argument3     =>
                                 TO_CHAR (DL.invoice_date, 'DD-MON-RRRR'), --<P_TO_EXCISE_INV_DT>
                             argument4     => DL.invoice_num, --<P_FROM_EXCISE_INV_NO>
                             argument5     => DL.invoice_num, --<P_TO_EXCISE_INV_NO>
                             argument6     => 'Y'                    --<P_TYPE>
                                                 );
                 END IF;
 */

                SELECT MAX (REQUEST_ID)
                  INTO LV_REQUEST_ID
                  FROM FND_CONC_REQ_SUMMARY_V
                 WHERE     STATUS_CODE = 'C'
                       AND PROGRAM_SHORT_NAME = 'XXHIL_OM_METINVDOM_DHJ'
                       AND ARGUMENT_TEXT LIKE '%' || DL.INVOICE_NUM || '%';


                msg ('LV_REQUEST_ID = ' || LV_REQUEST_ID);

                lv_msg_text := lv_msg_text || '</TABLE>';
                lv_msg_text :=
                       lv_msg_text
                    || '<BR><BR>This is a computer generated information.';
                lv_msg_text := lv_msg_text || '<BR><BR>';
                lv_msg_text := lv_msg_text || '</BODY>';
                lv_msg_text := lv_msg_text || '</HTML>';

                SELECT name INTO lv_db_name FROM v$database;

                MSG ('lv_db_name = ' || lv_db_name);

                IF lv_db_name NOT IN ('EBSPROD', 'EBSPRD')
                THEN
                    IF     dl.order_source_id <> 10
                       AND lv_prod_sub_group NOT IN ('GOLD', 'SLVR')
                    THEN
                        BEGIN
                            SELECT LISTAGG (agen_email_id, ', ')
                                       WITHIN GROUP (ORDER BY agen_email_id)
                              INTO lv_msg_to
                              FROM xxhil_om_customer_contact_v
                             WHERE agen_cd = dl.party_number;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                lv_msg_to := 'darshankumar.s@adityabirla.com';
                        END;
                    ELSIF lv_prod_sub_group IN ('GOLD', 'SLVR')
                    THEN
                        lv_msg_to :=
                            xxhil_om_mail_alerts_pkg.get_role_mail (
                                p_mdlid       => 'INVOICE_MAIL_PMR',
                                p_ou          => NULL,
                                p_mail_type   => 'TO');
                    ELSE
                        BEGIN
                            SELECT LISTAGG (PARM_EMAIL, ', ')
                                       WITHIN GROUP (ORDER BY PARM_EMAIL)
                              INTO lv_msg_to
                              FROM xxhil_om_org_v
                             WHERE parm_loc_cd = dl.stk_trans_locn;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                lv_msg_to := 'darshankumar.s@adityabirla.com';
                        END;
                    END IF;
                ELSE
                    lv_msg_to := 'darshankumar.s@adityabirla.com';
                END IF;

                --

                IF lv_prod_group = 'COPR'
                THEN
                    lv_msg_cc :=
                        xxhil_om_mail_alerts_pkg.get_role_Mail (
                            'INVOICE_MAIL_COPR',
                            xxhil_om_lib_pkg.get_ou_name (dl.ou_id),
                            'CC');

                    IF lv_msg_cc IS NULL
                    THEN
                        lv_msg_cc :=
                            xxhil_om_mail_alerts_pkg.mail_list (
                                NULL,
                                NULL,                              --v_region,
                                'INVOICE_MAIL',
                                NULL,
                                'Cc');
                    ELSE
                        lv_msg_cc :=
                               lv_msg_cc
                            || ','
                            || xxhil_om_mail_alerts_pkg.mail_list (
                                   NULL,
                                   NULL,                           --v_region,
                                   'INVOICE_MAIL',
                                   NULL,
                                   'Cc');
                    END IF;
                END IF;

                lv_msg_bcc := NULL;

                lv_to_file := dl.delivery_id;

                lv_subject := 'Invoice Information :' || dl.invoice_num;

                PUSH_MAIL (
                    p_request_id    => lv_request_id,
                    p_msg_from      => lv_msg_from,
                    p_msg_to        => lv_msg_to,
                    p_msg_cc        => lv_msg_cc,
                    p_msg_bcc       => lv_msg_bcc,
                    p_msg_subject   => lv_subject,
                    p_msg_text      => lv_msg_text,
                    p_from_file     => lv_from_file,
                    p_to_file       => lv_to_file,
                    p_to_extn       => 'PDF',
                    p_wait_flg      => NULL,
                    p_called_from   => 'XXHIL_OM_MAIL_ALERTS_PKG.INVOICE');
            EXCEPTION
                WHEN ex_gold_slvr_case
                THEN
                    msg ('Gold and Silver not covered.');
                WHEN ex_export_case
                THEN
                    msg ('Export Case not covered.');
                WHEN OTHERS
                THEN
                    NULL;
            END;
        END LOOP;

        --DECLARE
        --    lv_errbuf    VARCHAR2 (32767);
        --    lv_retcode   VARCHAR2 (32767);
        --BEGIN
        --    MSG ('POP MAIL START');
        --    XXHIL_OM_MAIL_ALERTS_PKG.POP_MAIL (errbuf    => lv_errbuf,
        --                                       retcode   => lv_retcode);
        --    MSG ('lv_errbuf = ' || lv_errbuf);
        --    MSG ('lv_retcode = ' || lv_retcode);
        --EXCEPTION
        --    WHEN OTHERS
        --    THEN
        --        msg ('EXCEPTION IN POP_MAIL SQLERRM = ' || SQLERRM);
        --END;

        xxhil_om_lib_pkg.msg ('INVOICE END*****');
    EXCEPTION
        WHEN OTHERS
        THEN
            xxhil_om_lib_pkg.msg ('INVOICE EXCEPTION SQLERRM=' || SQLERRM);
    END INVOICE;

    FUNCTION MAIL_LIST (P_USRROLE   IN VARCHAR2,
                        P_ZONE      IN VARCHAR2,
                        P_MDLID     IN VARCHAR2,
                        P_USRNAME   IN VARCHAR2,
                        P_ETYPE     IN VARCHAR2)
        RETURN VARCHAR2
    IS
        m_mail_list   VARCHAR2 (32767);

        CURSOR cur_email IS
            SELECT emailid, emailtype
              FROM       --apps.XXHIL_USRMAIL  --Added below by KUNAL 27052020
                   xxhil_usermail
             WHERE     1 = 1
                   AND mdlid = p_mdlid
                   AND NVL (usrrole, 'X') =
                       NVL (p_usrrole, NVL (usrrole, 'X'))
                   AND NVL (user_name, 'XX') = NVL (p_usrname, 'XX')
                   AND NVL (ZONE, 'XX') = NVL (p_zone, 'XX')
                   AND UPPER (emailtype) = UPPER (p_etype)
                   AND emailid IS NOT NULL
                   AND status = 'ACTIVE'
                   AND NVL (end_date, TRUNC (SYSDATE)) >= TRUNC (SYSDATE);
    BEGIN
        FOR i IN cur_email
        LOOP
            m_mail_list := m_mail_list || i.emailid || ',';
        END LOOP;

        RETURN (RTRIM (m_mail_list, ','));
    END MAIL_LIST;

    PROCEDURE MTM
    AS
    BEGIN
        msg ('MTM START*****');

        FOR i IN (SELECT DISTINCT OU_ID, SALE_TYPE, COMMODITY
                    FROM XXHIL_OM_PRCREQ
                   WHERE COMMODITY = 'COPR')
        LOOP
            DECLARE
                LV_REQUEST_ID    XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
                LV_MSG_FROM      XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                     := G_EMAIL_FROM;
                LV_MSG_TO        XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
                LV_MSG_CC        XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
                LV_MSG_BCC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
                LV_MSG_SUBJECT   XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
                LV_MSG_TEXT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
                LV_FROM_FILE     XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
                LV_TO_FILE       XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
                LV_TO_EXTN       XXHIL_OM_REQ_ATTCH_MAIL.TO_EXTN%TYPE
                                     := 'PDF';
            BEGIN
                LV_REQUEST_ID :=
                    fnd_request.submit_request (
                        application   => 'XXHIL',
                        program       => 'XXHIL_OM_MTM_DBNP_CP',
                        description   => 'Register > MTM DBNP',
                        start_time    => NULL,
                        sub_request   => FALSE,
                        argument1     => i.OU_ID,                  --<P_OU_ID>
                        argument2     => 'UQUP',                --<P_REP_TYPE>
                        argument3     => i.SALE_TYPE           --<P_SALE_TYPE>
                                                    );

                COMMIT;

                msg ('LV_REQUEST_ID = ' || lv_request_id);
                LV_FROM_FILE := 'o' || lv_request_id || '.out';
                MSG ('LV_FROM_FILE = ' || LV_FROM_FILE);
                LV_TO_FILE :=
                       'MTM_DBNP_'
                    || i.ou_id
                    || '_'
                    || i.sale_type
                    || '_'
                    || TO_CHAR (SYSDATE, 'RRRRMMDD');
                MSG ('LV_TO_FILE = ' || LV_TO_FILE);

                lv_msg_to :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'MTM_DBNP',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'To');

                lv_msg_to :=
                       lv_msg_to
                    || ','
                    || xxhil_om_mail_alerts_pkg.get_sbu_role_mail (
                           p_mdlid       => 'MTM_DBNP',
                           p_ou          => xxhil_om_lib_pkg.get_ou_name (i.ou_id),
                           p_mail_type   => 'TO',
                           p_sbu         => 'COPR');

                lv_msg_cc :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'MTM_DBNP',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'Cc');

                lv_msg_cc :=
                       lv_msg_cc
                    || ','
                    || xxhil_om_mail_alerts_pkg.get_sbu_role_mail (
                           p_mdlid       => 'MTM_DBNP',
                           p_ou          => xxhil_om_lib_pkg.get_ou_name (i.ou_id),
                           p_mail_type   => 'CC',
                           p_sbu         => 'COPR');

                lv_msg_bcc :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'MTM_DBNP',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'BCC');

                lv_msg_bcc :=
                       lv_msg_bcc
                    || ','
                    || xxhil_om_mail_alerts_pkg.get_sbu_role_mail (
                           p_mdlid       => 'MTM_DBNP',
                           p_ou          => xxhil_om_lib_pkg.get_ou_name (i.ou_id),
                           p_mail_type   => 'BCC',
                           p_sbu         => 'COPR');

                LV_MSG_SUBJECT :=
                       'MTM DBNP '
                    || xxhil_om_lib_pkg.get_ou_name (i.ou_id)
                    || ' '
                    || i.sale_type
                    || ' as on '
                    || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS');
                LV_MSG_TEXT :=
                    'Dear Sir / Madam, Please find the attachment of MTM DBNP.';

                xxhil_om_mail_alerts_pkg.insert_req_attch_rec (
                    request_id    => lv_request_id,
                    msg_from      => lv_msg_from,
                    msg_to        => lv_msg_to,
                    msg_cc        => lv_msg_cc,
                    msg_bcc       => lv_msg_bcc,
                    msg_subject   => LV_MSG_SUBJECT,
                    msg_text      => LV_MSG_TEXT,
                    from_file     => LV_FROM_FILE,
                    to_file       => LV_TO_FILE,
                    to_extn       => LV_TO_EXTN,
                    wait_flg      => NULL,
                    called_from   => 'XXHIL_OM_MAIL_ALERTS_PKG.MTM');
            EXCEPTION
                WHEN OTHERS
                THEN
                    msg ('REQUEST CALL EXCEPTION');
                    msg ('SQLERRM = ' || SQLERRM);
                    msg ('SQLCODE = ' || SQLCODE);
            END;

            -----------------------------------------------------------------
            DECLARE
                LV_REQUEST_ID    XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
                LV_MSG_FROM      XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                     := G_EMAIL_FROM;
                LV_MSG_TO        XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
                LV_MSG_CC        XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
                LV_MSG_BCC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
                LV_MSG_SUBJECT   XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
                LV_MSG_TEXT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
                LV_FROM_FILE     XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
                LV_TO_FILE       XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
                LV_TO_EXTN       XXHIL_OM_REQ_ATTCH_MAIL.TO_EXTN%TYPE
                                     := 'PDF';
            BEGIN
                LV_REQUEST_ID :=
                    fnd_request.submit_request (
                        application   => 'XXHIL',
                        program       => 'XXHIL_OM_MTM_PBND',
                        description   => 'XXHIL OM Register > MTM PBND',
                        start_time    => NULL,
                        sub_request   => FALSE,
                        argument1     => i.COMMODITY,            --<COMMODITY>
                        argument2     => NULL,        --<ANALYSIS ON EXCHANGE>
                        argument3     => NULL,            --<ANALYSIS ON LMEn>
                        argument4     => NULL,                     --<QP TYPE>
                        argument5     => i.OU_ID,                       --<OU>
                        argument6     => 'ALL',               --<REPORT TYPE >
                        argument7     => i.SALE_TYPE             --<SALE_TYPE>
                                                    );

                COMMIT;

                msg ('LV_REQUEST_ID = ' || lv_request_id);
                LV_FROM_FILE := 'o' || lv_request_id || '.out';
                MSG ('LV_FROM_FILE = ' || LV_FROM_FILE);
                LV_TO_FILE :=
                       'MTM_PBND_'
                    || i.ou_id
                    || '_'
                    || i.sale_type
                    || '_'
                    || TO_CHAR (SYSDATE, 'RRRRMMDD');
                MSG ('LV_TO_FILE = ' || LV_TO_FILE);

                lv_msg_to :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'MTM_DBNP',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'To');

                lv_msg_to :=
                       lv_msg_to
                    || ','
                    || xxhil_om_mail_alerts_pkg.get_sbu_role_mail (
                           p_mdlid       => 'MTM_DBNP',
                           p_ou          => xxhil_om_lib_pkg.get_ou_name (i.ou_id),
                           p_mail_type   => 'TO',
                           p_sbu         => 'COPR');

                lv_msg_cc :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'MTM_DBNP',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'Cc');

                lv_msg_cc :=
                       lv_msg_cc
                    || ','
                    || xxhil_om_mail_alerts_pkg.get_sbu_role_mail (
                           p_mdlid       => 'MTM_DBNP',
                           p_ou          => xxhil_om_lib_pkg.get_ou_name (i.ou_id),
                           p_mail_type   => 'CC',
                           p_sbu         => 'COPR');

                lv_msg_bcc :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'MTM_DBNP',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'BCC');

                lv_msg_bcc :=
                       lv_msg_bcc
                    || ','
                    || xxhil_om_mail_alerts_pkg.get_sbu_role_mail (
                           p_mdlid       => 'MTM_DBNP',
                           p_ou          => xxhil_om_lib_pkg.get_ou_name (i.ou_id),
                           p_mail_type   => 'BCC',
                           p_sbu         => 'COPR');

                LV_MSG_SUBJECT :=
                       'MTM PBND '
                    || xxhil_om_lib_pkg.get_ou_name (i.ou_id)
                    || ' '
                    || i.sale_type
                    || ' as on '
                    || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS');
                LV_MSG_TEXT :=
                    'Dear Sir / Madam, Please find the attachment of MTM PBND';

                xxhil_om_mail_alerts_pkg.insert_req_attch_rec (
                    request_id    => lv_request_id,
                    msg_from      => lv_msg_from,
                    msg_to        => lv_msg_to,
                    msg_cc        => lv_msg_cc,
                    msg_bcc       => lv_msg_bcc,
                    msg_subject   => LV_MSG_SUBJECT,
                    msg_text      => LV_MSG_TEXT,
                    from_file     => LV_FROM_FILE,
                    to_file       => LV_TO_FILE,
                    to_extn       => LV_TO_EXTN,
                    wait_flg      => NULL,
                    called_from   => 'XXHIL_OM_MAIL_ALERTS_PKG.MTM');
            EXCEPTION
                WHEN OTHERS
                THEN
                    msg ('REQUEST CALL EXCEPTION');
                    msg ('SQLERRM = ' || SQLERRM);
                    msg ('SQLCODE = ' || SQLCODE);
            END;
        -----------------------------------------------------------------


        END LOOP;


        msg ('MTM END*****');
    END MTM;

    PROCEDURE ONE_PAGE_CCR
    AS
        lv_report_date   DATE := TRUNC (SYSDATE) - 1;
    BEGIN
        msg ('ONE_PAGE_CCR START*****');

        DECLARE
            lv_onhand_record_found   NUMBER;
            lv_opening_dt            DATE;
        BEGIN
            SELECT COUNT (1)
              INTO lv_onhand_record_found
              FROM xxhil_om_onhand_stock                              --_plant
             WHERE     prod_sub_grp = 'CCRD'
                   AND xxhil_om_lib_pkg.get_org_cd (organization_id) IN
                           ('DHJ', 'B12')
                   AND report_dt = lv_report_date;

            IF NVL (lv_onhand_record_found, 0) = 0
            THEN
                --
                -- Onhand record insertion
                --
                DECLARE
                    lv_errbuf    VARCHAR2 (32767);
                    lv_retcode   VARCHAR2 (32767);
                BEGIN
                    XXHIL_OM_STOCK_PKG.ONHAND_STOCK (
                        ERRBUF         => lv_errbuf,
                        RETCODE        => lv_retcode,
                        P_REPORT_DT    => lv_report_date,
                        P_DELETE_FLG   => 'N');
                END;
            --INSERT INTO xxbc_om_onhand_stock_plant (query_no,
            --                                        inventory_item_id,
            --                                        lot,
            --                                        organization_code,
            --                                        organization_id,
            --                                        prod_legacy_cd,
            --                                        prod_sub_grp,
            --                                        refinery_no,
            --                                        subinventory_code,
            --                                        total_qoh,
            --                                        transaction_date,
            --                                        stock_plant,
            --                                        runsqnce,
            --                                        creation_dt,
            --                                        report_dt,
            --                                        grade,
            --                                        prem_grd_flg)
            --    SELECT query_no,
            --           inventory_item_id,
            --           lot,
            --           organization_code,
            --           organization_id,
            --           prod_legacy_cd,
            --           prod_sub_grp,
            --           refinery_no,
            --           subinventory_code,
            --           total_qoh,
            --           transaction_date,
            --           stock_plant,
            --           -1,
            --           SYSDATE,
            --           TRUNC (SYSDATE) - 1,
            --           prdgrd,
            --           prem_grd_flg
            --      FROM apps.xxhil_om_onhand_stock_plant_v
            --     WHERE     prod_sub_grp = 'CCRD'
            --           AND xxom.get_org_cd (organization_id) IN
            --                   ('DHJ', 'B12')
            --           AND transaction_date <= TRUNC (SYSDATE) - 1; -- Jayant, 07MAR2014, Due to DATA are based on Shift Basis.



            --
            -- Correction of status in Rejected stock not charged but was in Opening of the month
            --
              /*  UPDATE xxhil_om_onhand_stock a                      --_plant a
                   SET subinventory_code = 'Interface Pending-Not Assigned'
                 WHERE     subinventory_code LIKE
                               'Interface%Pending%Assign%CCR%'
                       AND report_dt = lv_report_date        --and grade = 'X'
                       AND EXISTS
                               (SELECT 'x'
                                  FROM xxhil_om_open_stock_ccrd b
                                 WHERE     a.lot = b.lot
                                       AND b.as_on =
                                           TRUNC (lv_report_date, 'MM'));
*/
            --
            -- Correction of status in CCR-1/2 as they are not rejected
            --
            /* UPDATE xxhil_om_onhand_stock a                      --_plant a
                SET subinventory_code =
                        subinventory_code || '-Not Rejected'
              WHERE     a.report_dt =
                        (SELECT MAX (b.report_dt)
                           FROM xxhil_om_onhand_stock b          --_plant b
                          WHERE     b.report_dt <= lv_report_date
                                AND b.prod_sub_grp = 'CCRD')
                    AND subinventory_code IN ('CCR-1', 'CCR-2', 'CCR-3')
                    AND grade <> 'X'
                    AND (   EXISTS
                                (SELECT 1
                                   FROM xxhil_om_open_stock_ccrd b
                                  WHERE     as_on =
                                            TRUNC (lv_report_date, 'mm')
                                        AND a.lot = b.lot)
                         OR EXISTS
                                (SELECT 1
                                   FROM xxhil_om_dt_prod_MV
                                  WHERE     lot_no = a.lot
                                        AND recd_shift_dt IS NOT NULL
                                        AND prdcd = a.prod_legacy_cd))
                    AND a.prod_sub_grp = 'CCRD';

             COMMIT;*/


            --IF TO_CHAR (SYSDATE, 'DD') = '01'
            ----AND NVL (fnd_profile.VALUE ('XXBC_OM_DOM_CU_MKTG_ROLE'), 'XX') IN
            ----                                             ('LOG-SI', 'ADMIN')
            ---- To allow running process only on 1st of the month, added by Gaurav / Jayant on 06-Aug-2015
            --THEN
            --    lv_opening_dt := TRUNC (SYSDATE);
            --
            --    -- Only rejected stock
            --    INSERT INTO xxhil_om_open_stock_ccrd (as_on,
            --                                          subgrp,
            --                                          flag,
            --                                          head,
            --                                          sftdt,
            --                                          lot,
            --                                          total_qoh,
            --                                          c01_d,
            --                                          c01_e,
            --                                          c02,
            --                                          c03,
            --                                          c04,
            --                                          c06,
            --                                          c11,
            --                                          c12,
            --                                          c18,
            --                                          c19,
            --                                          inventory_item_id,
            --                                          subinventory,
            --                                          creation_date,
            --                                          plant_no)
            --        SELECT lv_opening_dt,
            --               'CCRD',
            --               7,
            --               'Rejected Stock',
            --               transaction_date,
            --               lot,
            --               NET_QTY,                           --total_qoh,
            --               DECODE (prod_legacy_cd, 'C01', NET_QTY, 0) --total_qoh, 0)
            --                   c01_d,
            --               0
            --                   c01_e,
            --               DECODE (prod_legacy_cd, 'C02', NET_QTY, 0) --total_qoh, 0)
            --                   c02,
            --               DECODE (prod_legacy_cd, 'C03', NET_QTY, 0) --total_qoh, 0)
            --                   c03,
            --               DECODE (prod_legacy_cd, 'C04', NET_QTY, 0) --total_qoh, 0)
            --                   c04,
            --               DECODE (prod_legacy_cd, 'C06', NET_QTY, 0) --total_qoh, 0)
            --                   c06,
            --               DECODE (prod_legacy_cd, 'C11', NET_QTY, 0) --total_qoh, 0)
            --                   c11,
            --               DECODE (prod_legacy_cd, 'C12', NET_QTY, 0) --total_qoh, 0)
            --                   c12,
            --               DECODE (prod_legacy_cd, 'C18', NET_QTY, 0) --total_qoh, 0)
            --                   c18,
            --               DECODE (prod_legacy_cd, 'C19', NET_QTY, 0) --total_qoh, 0)
            --                   c19,
            --               inventory_item_id,
            --               'Refinery',
            --               SYSDATE,
            --               refinery_no
            --          FROM xxhil_om_onhand_stock                  --_plant
            --         WHERE     prod_sub_grp = 'CCRD'
            --               AND report_dt = lv_opening_dt - 1
            --               AND subinventory_code NOT LIKE 'Inter%CCR%'
            --               AND subinventory_code NOT LIKE 'CCR-%'
            --               AND stock_plant = 'CCR'
            --               AND grade = 'X';
            --
            --    COMMIT;
            --END IF;
            END IF;
        END;

        DECLARE
            LV_REQUEST_ID    XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
            LV_MSG_FROM      XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                 := G_EMAIL_FROM;
            LV_MSG_TO        XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
            LV_MSG_CC        XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
            LV_MSG_BCC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
            LV_MSG_SUBJECT   XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
            LV_MSG_TEXT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
            LV_FROM_FILE     XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
            LV_TO_FILE       XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
            LV_TO_EXTN       XXHIL_OM_REQ_ATTCH_MAIL.TO_EXTN%TYPE := 'PDF';
        BEGIN
            LV_REQUEST_ID :=
                fnd_request.submit_request (
                    application   => 'XXHIL',
                    program       => 'XXHIL_OM_ONE_PAGE_CCR_CP',
                    description   => 'Register > One Page - CCR [Copper]',
                    start_time    => NULL,
                    sub_request   => FALSE,
                    argument1     =>
                        TO_CHAR (lv_report_date, 'RRRR/MM/DD HH24:MI:SS'), --<P_TODT>
                    argument2     => NULL,                         --<P_PLANT>
                    argument3     => 'N',                           --<P_FLAG>
                    argument4     => 'Y',                    --<P_INSERT_DATA>
                    argument5     => NULL                       --<P_SEQUENCE>
                                         );

            COMMIT;

            msg ('LV_REQUEST_ID = ' || lv_request_id);
            LV_FROM_FILE := 'o' || lv_request_id || '.out';
            MSG ('LV_FROM_FILE = ' || LV_FROM_FILE);
            LV_TO_FILE :=
                'ONE_PAGE_CCR' || TO_CHAR (lv_report_date, 'RRRRHHDD');
            MSG ('LV_TO_FILE = ' || LV_TO_FILE);

            lv_msg_to :=
                xxhil_om_mail_alerts_pkg.mail_list (P_USRROLE   => NULL,
                                                    P_ZONE      => NULL,
                                                    P_MDLID     => 'ONE_PAGE',
                                                    P_USRNAME   => NULL,
                                                    P_ETYPE     => 'To');

            lv_msg_cc :=
                xxhil_om_mail_alerts_pkg.mail_list (P_USRROLE   => NULL,
                                                    P_ZONE      => NULL,
                                                    P_MDLID     => 'ONE_PAGE',
                                                    P_USRNAME   => NULL,
                                                    P_ETYPE     => 'Cc');

            lv_msg_bcc :=
                xxhil_om_mail_alerts_pkg.mail_list (P_USRROLE   => NULL,
                                                    P_ZONE      => NULL,
                                                    P_MDLID     => 'ONE_PAGE',
                                                    P_USRNAME   => NULL,
                                                    P_ETYPE     => 'BCC');

            lv_msg_bcc :=
                   lv_msg_bcc
                || ','
                || xxhil_om_mail_alerts_pkg.get_role_mail (
                       p_mdlid       => 'ONE_PAGE',
                       p_ou          => NULL,
                       p_mail_type   => 'BCC');

            LV_MSG_SUBJECT :=
                   'One Page CCR as on '
                || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS');
            LV_MSG_TEXT :=
                'Dear Sir / Madam, Please find the attachment of one page of CCRD.';

            xxhil_om_mail_alerts_pkg.insert_req_attch_rec (
                request_id    => lv_request_id,
                msg_from      => lv_msg_from,
                msg_to        => lv_msg_to,
                msg_cc        => lv_msg_cc,
                msg_bcc       => lv_msg_bcc,
                msg_subject   => LV_MSG_SUBJECT,
                msg_text      => LV_MSG_TEXT,
                from_file     => LV_FROM_FILE,
                to_file       => LV_TO_FILE,
                to_extn       => LV_TO_EXTN,
                wait_flg      => NULL,
                called_from   => 'XXHIL_OM_MAIL_ALERTS_PKG.ONE_PAGE_CCR');
        EXCEPTION
            WHEN OTHERS
            THEN
                msg ('REQUEST CALL EXCEPTION');
                msg ('SQLERRM = ' || SQLERRM);
                msg ('SQLCODE = ' || SQLCODE);
        END;

        DECLARE
            LV_REQUEST_ID    XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
            LV_MSG_FROM      XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                 := G_EMAIL_FROM;
            LV_MSG_TO        XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
            LV_MSG_CC        XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
            LV_MSG_BCC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
            LV_MSG_SUBJECT   XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
            LV_MSG_TEXT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
            LV_FROM_FILE     XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
            LV_TO_FILE       XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
            LV_TO_EXTN       XXHIL_OM_REQ_ATTCH_MAIL.TO_EXTN%TYPE := 'PDF';
        BEGIN
            LV_REQUEST_ID :=
                fnd_request.submit_request (
                    application   => 'XXHIL',
                    program       => 'XXHIL_OM_ONE_PAGE_CCR_CP',
                    description   =>
                        'Register > One Page - CCR [Copper] for plant 3',
                    start_time    => NULL,
                    sub_request   => FALSE,
                    argument1     =>
                        TO_CHAR (lv_report_date, 'RRRR/MM/DD HH24:MI:SS'), --<P_TODT>
                    argument2     => 3,                            --<P_PLANT>
                    argument3     => 'N',                           --<P_FLAG>
                    argument4     => 'Y',                    --<P_INSERT_DATA>
                    argument5     => NULL                       --<P_SEQUENCE>
                                         );

            COMMIT;

            msg ('LV_REQUEST_ID = ' || lv_request_id);
            LV_FROM_FILE := 'o' || lv_request_id || '.out';
            MSG ('LV_FROM_FILE = ' || LV_FROM_FILE);
            LV_TO_FILE :=
                'ONE_PAGE_CCR' || TO_CHAR (lv_report_date, 'RRRRHHDD');
            MSG ('LV_TO_FILE = ' || LV_TO_FILE);

            lv_msg_to :=
                xxhil_om_mail_alerts_pkg.mail_list (P_USRROLE   => NULL,
                                                    P_ZONE      => NULL,
                                                    P_MDLID     => 'ONE_PAGE',
                                                    P_USRNAME   => NULL,
                                                    P_ETYPE     => 'To');

            lv_msg_cc :=
                xxhil_om_mail_alerts_pkg.mail_list (P_USRROLE   => NULL,
                                                    P_ZONE      => NULL,
                                                    P_MDLID     => 'ONE_PAGE',
                                                    P_USRNAME   => NULL,
                                                    P_ETYPE     => 'Cc');

            lv_msg_bcc :=
                xxhil_om_mail_alerts_pkg.mail_list (P_USRROLE   => NULL,
                                                    P_ZONE      => NULL,
                                                    P_MDLID     => 'ONE_PAGE',
                                                    P_USRNAME   => NULL,
                                                    P_ETYPE     => 'BCC');

            lv_msg_bcc :=
                   lv_msg_bcc
                || ','
                || xxhil_om_mail_alerts_pkg.get_role_mail (
                       p_mdlid       => 'ONE_PAGE',
                       p_ou          => NULL,
                       p_mail_type   => 'BCC');

            LV_MSG_SUBJECT :=
                   'One Page CCR3 as on '
                || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS');
            LV_MSG_TEXT :=
                'Dear Sir / Madam, Please find the attachment of one page of CCR 3.';

            xxhil_om_mail_alerts_pkg.insert_req_attch_rec (
                request_id    => lv_request_id,
                msg_from      => lv_msg_from,
                msg_to        => lv_msg_to,
                msg_cc        => lv_msg_cc,
                msg_bcc       => lv_msg_bcc,
                msg_subject   => LV_MSG_SUBJECT,
                msg_text      => LV_MSG_TEXT,
                from_file     => LV_FROM_FILE,
                to_file       => LV_TO_FILE,
                to_extn       => LV_TO_EXTN,
                wait_flg      => NULL,
                called_from   => 'XXHIL_OM_MAIL_ALERTS_PKG.ONE_PAGE_CCR');
        EXCEPTION
            WHEN OTHERS
            THEN
                msg ('REQUEST CALL EXCEPTION');
                msg ('SQLERRM = ' || SQLERRM);
                msg ('SQLCODE = ' || SQLCODE);
        END;

        msg ('ONE_PAGE_CCR END*****');
    EXCEPTION
        WHEN OTHERS
        THEN
            msg ('ONE_PAGE_CCR EXCEPTION');
            msg ('SQLERRM = ' || SQLERRM);
            msg ('SQLCODE = ' || SQLCODE);
    END ONE_PAGE_CCR;

    PROCEDURE ONE_PAGE_CATHODE
    AS
        lv_report_date   DATE := TRUNC (SYSDATE) - 1;
    BEGIN
        msg ('ONE_PAGE_CATHODE START*****');

        DECLARE
            lv_onhand_stock_count   NUMBER;
        BEGIN
            SELECT COUNT (1)
              INTO LV_ONHAND_STOCK_COUNT
              FROM XXHIL_OM_ONHAND_STOCK                              --_PLANT
             WHERE     PROD_SUB_GRP = 'CATH'
                   AND XXHIL_OM_LIB_PKG.GET_ORG_CD (ORGANIZATION_ID) IN
                           ('DHJ', 'B12')
                   AND REPORT_DT = LV_REPORT_DATE;

            IF NVL (lv_onhand_stock_count, 0) = 0
            THEN
                --
                -- OnHand record insertion
                --
                DECLARE
                    lv_errbuf    VARCHAR2 (32767);
                    lv_retcode   VARCHAR2 (32767);
                BEGIN
                    XXHIL_OM_STOCK_PKG.ONHAND_STOCK (
                        ERRBUF         => lv_errbuf,
                        RETCODE        => lv_retcode,
                        P_REPORT_DT    => lv_report_date,
                        P_DELETE_FLG   => 'N');
                END;
            --INSERT INTO xxbc_om_onhand_stock_plant (query_no,
            --                                        inventory_item_id,
            --                                        lot,
            --                                        organization_code,
            --                                        organization_id,
            --                                        prod_legacy_cd,
            --                                        prod_sub_grp,
            --                                        refinery_no,
            --                                        subinventory_code,
            --                                        total_qoh,
            --                                        transaction_date,
            --                                        stock_plant,
            --                                        runsqnce,
            --                                        creation_dt,
            --                                        report_dt,
            --                                        grade)
            --    SELECT query_no,
            --           inventory_item_id,
            --           lot,
            --           organization_code,
            --           organization_id,
            --           prod_legacy_cd,
            --           prod_sub_grp,
            --           refinery_no,
            --           subinventory_code,
            --           total_qoh,
            --           transaction_date,
            --           stock_plant,
            --           -1,
            --           SYSDATE,
            --           TRUNC (SYSDATE) - 1,
            --           prdgrd
            --      FROM apps.xx_vw_onhand_stock_plant
            --     WHERE     prod_sub_grp = 'CATH'
            --           AND xxom.get_org_cd (organization_id) = 'DHJ'
            --           AND transaction_date <= TRUNC (SYSDATE) - 1; -- Jayant, 07MAR2014, Due to DATA are based on Shift Basis.;
            --
            --COMMIT;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                msg ('ONHAND_STOCK EXCEPTION');
                msg ('SQLERRM = ' || SQLERRM);
                msg ('SQLCODE = ' || SQLCODE);
        END;

        DECLARE
            LV_REQUEST_ID    XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
            LV_MSG_FROM      XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                 := G_EMAIL_FROM; --:= 'hilerp.alert@adityabirla.com'; --'bc.automail@adityabirla.com';
            LV_MSG_TO        XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
            LV_MSG_CC        XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
            LV_MSG_BCC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
            LV_MSG_SUBJECT   XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
            LV_MSG_TEXT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
            LV_FROM_FILE     XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
            LV_TO_FILE       XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
            LV_TO_EXTN       XXHIL_OM_REQ_ATTCH_MAIL.TO_EXTN%TYPE := 'PDF';
        BEGIN
            LV_REQUEST_ID :=
                fnd_request.submit_request (
                    application   => 'XXHIL',
                    program       => 'XXHIL_OM_ONE_PAGE_CATH_CP',
                    description   =>
                        'XXHIL OM Register > One Page - Cathode [Copper]',
                    start_time    => NULL,
                    sub_request   => FALSE,
                    argument1     =>
                        TO_CHAR (lv_report_date, 'RRRR/MM/DD HH24:MI:SS'), --<P_TODT>
                    argument2     => NULL,                         --<P_PLANT>
                    argument3     => 'N',                           --<P_FLAG>
                    argument4     => 'Y',                    --<P_INSERT_DATA>
                    argument5     => NULL                     --<P_SESSION_ID>
                                         );

            COMMIT;

            msg ('LV_REQUEST_ID = ' || lv_request_id);
            LV_FROM_FILE := 'o' || lv_request_id || '.out';
            MSG ('LV_FROM_FILE = ' || LV_FROM_FILE);
            LV_TO_FILE :=
                'ONE_PAGE_CATH' || TO_CHAR (lv_report_date, 'RRRRHHDD');
            MSG ('LV_TO_FILE = ' || LV_TO_FILE);

            lv_msg_to :=
                xxhil_om_mail_alerts_pkg.mail_list (P_USRROLE   => NULL,
                                                    P_ZONE      => NULL,
                                                    P_MDLID     => 'ONE_PAGE',
                                                    P_USRNAME   => NULL,
                                                    P_ETYPE     => 'To');

            lv_msg_cc :=
                xxhil_om_mail_alerts_pkg.mail_list (P_USRROLE   => NULL,
                                                    P_ZONE      => NULL,
                                                    P_MDLID     => 'ONE_PAGE',
                                                    P_USRNAME   => NULL,
                                                    P_ETYPE     => 'Cc');

            lv_msg_bcc :=
                xxhil_om_mail_alerts_pkg.mail_list (P_USRROLE   => NULL,
                                                    P_ZONE      => NULL,
                                                    P_MDLID     => 'ONE_PAGE',
                                                    P_USRNAME   => NULL,
                                                    P_ETYPE     => 'BCC');

            lv_msg_bcc :=
                   lv_msg_bcc
                || ','
                || xxhil_om_mail_alerts_pkg.get_role_mail (
                       p_mdlid       => 'ONE_PAGE',
                       p_ou          => NULL,
                       p_mail_type   => 'BCC');

            LV_MSG_SUBJECT :=
                   'One Page Cathode as on '
                || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS');
            LV_MSG_TEXT :=
                'Dear Sir / Madam, Please find the attachment of one page of CATHODE.';

            xxhil_om_mail_alerts_pkg.insert_req_attch_rec (
                request_id    => lv_request_id,
                msg_from      => lv_msg_from,
                msg_to        => lv_msg_to,
                msg_cc        => lv_msg_cc,
                msg_bcc       => lv_msg_bcc,
                msg_subject   => LV_MSG_SUBJECT,
                msg_text      => LV_MSG_TEXT,
                from_file     => LV_FROM_FILE,
                to_file       => LV_TO_FILE,
                to_extn       => LV_TO_EXTN,
                wait_flg      => NULL,
                called_from   => 'XXHIL_OM_MAIL_ALERTS_PKG.ONE_PAGE_CATHODE');
        EXCEPTION
            WHEN OTHERS
            THEN
                msg ('REQUEST CALL EXCEPTION');
                msg ('SQLERRM = ' || SQLERRM);
                msg ('SQLCODE = ' || SQLCODE);
        END;

        msg ('ONE_PAGE_CATHODE END*****');
    EXCEPTION
        WHEN OTHERS
        THEN
            msg ('ONE_PAGE_CATHODE EXCEPTION');
            msg ('SQLERRM = ' || SQLERRM);
            msg ('SQLCODE = ' || SQLCODE);
    END ONE_PAGE_CATHODE;

    PROCEDURE ONE_PAGE_WIRE
    AS
        lv_report_date   DATE := TRUNC (SYSDATE) - 1;
    BEGIN
        msg ('ONE_PAGE_WIRE START*****');

        DECLARE
            lv_onhand_stock_count   NUMBER;
        BEGIN
            SELECT COUNT (1)
              INTO lv_onhand_stock_count
              FROM xxhil_om_onhand_stock                              --_plant
             WHERE     prod_sub_grp = 'WIRE'
                   AND xxhil_om_lib_pkg.get_org_cd (organization_id) IN
                           ('DHJ', 'B12')
                   AND report_dt = lv_report_date;

            IF NVL (lv_onhand_stock_count, 0) = 0
            THEN
                --
                -- OnHand record insertion
                --
                DECLARE
                    lv_errbuf    VARCHAR2 (32767);
                    lv_retcode   VARCHAR2 (32767);
                BEGIN
                    XXHIL_OM_STOCK_PKG.ONHAND_STOCK (
                        ERRBUF         => lv_errbuf,
                        RETCODE        => lv_retcode,
                        P_REPORT_DT    => lv_report_date,
                        P_DELETE_FLG   => 'N');
                END;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                msg ('ONHAND_STOCK EXCEPTION');
                msg ('SQLERRM = ' || SQLERRM);
                msg ('SQLCODE = ' || SQLCODE);
        END;

        DECLARE
            LV_REQUEST_ID    XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
            LV_MSG_FROM      XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                 := G_EMAIL_FROM; --:= 'hilerp.alert@adityabirla.com'; --'bc.automail@adityabirla.com';
            LV_MSG_TO        XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
            LV_MSG_CC        XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
            LV_MSG_BCC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
            LV_MSG_SUBJECT   XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
            LV_MSG_TEXT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
            LV_FROM_FILE     XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
            LV_TO_FILE       XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
            LV_TO_EXTN       XXHIL_OM_REQ_ATTCH_MAIL.TO_EXTN%TYPE := 'PDF';
        BEGIN
            LV_REQUEST_ID :=
                fnd_request.submit_request (
                    application   => 'XXHIL',
                    program       => 'XXHIL_OM_ONE_PAGE_WIRE_CP',
                    description   =>
                        'XXHIL OM Register > One Page - Wire [Copper]',
                    start_time    => NULL,
                    sub_request   => FALSE,
                    argument1     =>
                        TO_CHAR (lv_report_date, 'RRRR/MM/DD HH24:MI:SS'), --<P_TODT>
                    argument2     => NULL,                         --<P_PLANT>
                    argument3     => 'N',                           --<P_FLAG>
                    argument4     => 'Y',                    --<P_INSERT_DATA>
                    argument5     => NULL                     --<P_SESSION_ID>
                                         );

            COMMIT;

            msg ('LV_REQUEST_ID = ' || lv_request_id);
            LV_FROM_FILE := 'o' || lv_request_id || '.out';
            MSG ('LV_FROM_FILE = ' || LV_FROM_FILE);
            LV_TO_FILE :=
                'ONE_PAGE_WIRE' || TO_CHAR (lv_report_date, 'RRRRHHDD');
            MSG ('LV_TO_FILE = ' || LV_TO_FILE);

            lv_msg_to :=
                xxhil_om_mail_alerts_pkg.mail_list (P_USRROLE   => NULL,
                                                    P_ZONE      => NULL,
                                                    P_MDLID     => 'ONE_PAGE',
                                                    P_USRNAME   => NULL,
                                                    P_ETYPE     => 'TO');

            lv_msg_cc :=
                xxhil_om_mail_alerts_pkg.mail_list (P_USRROLE   => NULL,
                                                    P_ZONE      => NULL,
                                                    P_MDLID     => 'ONE_PAGE',
                                                    P_USRNAME   => NULL,
                                                    P_ETYPE     => 'CC');

            lv_msg_bcc :=
                xxhil_om_mail_alerts_pkg.mail_list (P_USRROLE   => NULL,
                                                    P_ZONE      => NULL,
                                                    P_MDLID     => 'ONE_PAGE',
                                                    P_USRNAME   => NULL,
                                                    P_ETYPE     => 'BCC');

            lv_msg_bcc :=
                   lv_msg_bcc
                || ','
                || xxhil_om_mail_alerts_pkg.get_role_mail (
                       p_mdlid       => 'ONE_PAGE',
                       p_ou          => NULL,
                       p_mail_type   => 'BCC');

            LV_MSG_SUBJECT :=
                   'One Page WIRE as on '
                || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS');
            LV_MSG_TEXT :=
                'Dear Sir / Madam, Please find the attachment of one page of WIRE.';

            xxhil_om_mail_alerts_pkg.insert_req_attch_rec (
                request_id    => lv_request_id,
                msg_from      => lv_msg_from,
                msg_to        => lv_msg_to,
                msg_cc        => lv_msg_cc,
                msg_bcc       => lv_msg_bcc,
                msg_subject   => LV_MSG_SUBJECT,
                msg_text      => LV_MSG_TEXT,
                from_file     => LV_FROM_FILE,
                to_file       => LV_TO_FILE,
                to_extn       => LV_TO_EXTN,
                wait_flg      => NULL,
                called_from   => 'XXHIL_OM_MAIL_ALERTS_PKG.ONE_PAGE_WIRE');
        EXCEPTION
            WHEN OTHERS
            THEN
                msg ('REQUEST CALL EXCEPTION');
                msg ('SQLERRM = ' || SQLERRM);
                msg ('SQLCODE = ' || SQLCODE);
        END;

        msg ('ONE_PAGE_WIRE END*****');
    EXCEPTION
        WHEN OTHERS
        THEN
            msg ('ONE_PAGE_WIRE EXCEPTION');
            msg ('SQLERRM = ' || SQLERRM);
            msg ('SQLCODE = ' || SQLCODE);
    END ONE_PAGE_WIRE;

    PROCEDURE ONE_PAGE_SCRAP
    AS
        lv_report_date   DATE := TRUNC (SYSDATE) - 1;
    BEGIN
        msg ('ONE_PAGE_SCRAP START*****');

        DECLARE
            LV_REQUEST_ID    XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
            LV_MSG_FROM      XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                 := G_EMAIL_FROM; --:= 'hilerp.alert@adityabirla.com'; --'bc.automail@adityabirla.com';
            LV_MSG_TO        XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
            LV_MSG_CC        XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
            LV_MSG_BCC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
            LV_MSG_SUBJECT   XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
            LV_MSG_TEXT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
            LV_FROM_FILE     XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
            LV_TO_FILE       XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
            LV_TO_EXTN       XXHIL_OM_REQ_ATTCH_MAIL.TO_EXTN%TYPE := 'PDF';
        BEGIN
            LV_REQUEST_ID :=
                fnd_request.submit_request (
                    application   => 'XXHIL',
                    program       => 'XXHIL_OM_ONE_PAGE_SCRAP_CP',
                    description   =>
                        'XXHIL OM Register > One Page - Scrap [Copper]',
                    start_time    => NULL,
                    sub_request   => FALSE,
                    argument1     =>
                        TO_CHAR (lv_report_date, 'RRRR/MM/DD HH24:MI:SS'), --<P_REPORT_DT>
                    argument2     => NULL,                       --<P_USER_ID>
                    argument3     => 'Y'                     --<P_INSERT_FLAG>
                                        );

            COMMIT;

            msg ('LV_REQUEST_ID = ' || lv_request_id);
            LV_FROM_FILE := 'o' || lv_request_id || '.out';
            MSG ('LV_FROM_FILE = ' || LV_FROM_FILE);
            LV_TO_FILE :=
                'ONE_PAGE_SCRAP' || TO_CHAR (lv_report_date, 'RRRRHHDD');
            MSG ('LV_TO_FILE = ' || LV_TO_FILE);

            lv_msg_to :=
                xxhil_om_mail_alerts_pkg.mail_list (P_USRROLE   => NULL,
                                                    P_ZONE      => NULL,
                                                    P_MDLID     => 'ONE_PAGE',
                                                    P_USRNAME   => NULL,
                                                    P_ETYPE     => 'TO');

            lv_msg_cc :=
                xxhil_om_mail_alerts_pkg.mail_list (P_USRROLE   => NULL,
                                                    P_ZONE      => NULL,
                                                    P_MDLID     => 'ONE_PAGE',
                                                    P_USRNAME   => NULL,
                                                    P_ETYPE     => 'CC');

            lv_msg_bcc :=
                xxhil_om_mail_alerts_pkg.mail_list (P_USRROLE   => NULL,
                                                    P_ZONE      => NULL,
                                                    P_MDLID     => 'ONE_PAGE',
                                                    P_USRNAME   => NULL,
                                                    P_ETYPE     => 'BCC');

            lv_msg_bcc :=
                   lv_msg_bcc
                || ','
                || xxhil_om_mail_alerts_pkg.get_role_mail (
                       p_mdlid       => 'ONE_PAGE',
                       p_ou          => NULL,
                       p_mail_type   => 'BCC');

            LV_MSG_SUBJECT :=
                   'One Page Scrap as on '
                || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS');
            LV_MSG_TEXT :=
                'Dear Sir / Madam, Please find the attachment of one page of Scrap.';

            xxhil_om_mail_alerts_pkg.insert_req_attch_rec (
                request_id    => lv_request_id,
                msg_from      => lv_msg_from,
                msg_to        => lv_msg_to,
                msg_cc        => lv_msg_cc,
                msg_bcc       => lv_msg_bcc,
                msg_subject   => LV_MSG_SUBJECT,
                msg_text      => LV_MSG_TEXT,
                from_file     => LV_FROM_FILE,
                to_file       => LV_TO_FILE,
                to_extn       => LV_TO_EXTN,
                wait_flg      => NULL,
                called_from   => 'XXHIL_OM_MAIL_ALERTS_PKG.ONE_PAGE_SCRAP');
        EXCEPTION
            WHEN OTHERS
            THEN
                msg ('REQUEST CALL EXCEPTION');
                msg ('SQLERRM = ' || SQLERRM);
                msg ('SQLCODE = ' || SQLCODE);
        END;

        msg ('ONE_PAGE_SCRAP END*****');
    EXCEPTION
        WHEN OTHERS
        THEN
            msg ('ONE_PAGE_SCRAP EXCEPTION');
            msg ('SQLERRM = ' || SQLERRM);
            msg ('SQLCODE = ' || SQLCODE);
    END ONE_PAGE_SCRAP;

    /* PROCEDURE CCR_METALAC
     AS
         lv_report_date   DATE := TRUNC (SYSDATE) - 1;
     BEGIN
         msg ('CCR_METALAC START*****');

         DECLARE
             LV_REQUEST_ID    XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
             LV_MSG_FROM      XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                  := G_EMAIL_FROM; --:= 'hilerp.alert@adityabirla.com'; --'bc.automail@adityabirla.com';
             LV_MSG_TO        XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
             LV_MSG_CC        XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
             LV_MSG_BCC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
             LV_MSG_SUBJECT   XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
             LV_MSG_TEXT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
             LV_FROM_FILE     XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
             LV_TO_FILE       XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
             LV_TO_EXTN       XXHIL_OM_REQ_ATTCH_MAIL.TO_EXTN%TYPE := 'PDF';
         BEGIN
             LV_REQUEST_ID :=
                 fnd_request.submit_request (
                     application   => 'XXHIL',
                     program       => 'XXHIL_OM_<>_CP',
                     description   => 'XXHIL OM <Report Name>',
                     start_time    => NULL,
                     sub_request   => FALSE,
                     argument1     => NULL,                       --<argument1>
                     argument2     => NULL,                       --<argument2>
                     argument3     => NULL,                       --<argument3>
                     argument4     => NULL,                       --<argument4>
                     argument5     => NULL                        --<argument5>
                                          );

             COMMIT;

             msg ('LV_REQUEST_ID = ' || lv_request_id);
             LV_FROM_FILE := 'o' || lv_request_id || '.out';
             MSG ('LV_FROM_FILE = ' || LV_FROM_FILE);
             LV_TO_FILE := 'BCDEPO_' || TO_CHAR (lv_report_date, 'RRRRHHDD');
             MSG ('LV_TO_FILE = ' || LV_TO_FILE);

             lv_msg_to :=
                 xxhil_om_mail_alerts_pkg.mail_list (
                     P_USRROLE   => NULL,
                     P_ZONE      => NULL,
                     P_MDLID     => 'CCR_METALAC',
                     P_USRNAME   => NULL,
                     P_ETYPE     => 'TO');

             lv_msg_cc :=
                 xxhil_om_mail_alerts_pkg.mail_list (
                     P_USRROLE   => NULL,
                     P_ZONE      => NULL,
                     P_MDLID     => 'CCR_METALAC',
                     P_USRNAME   => NULL,
                     P_ETYPE     => 'CC');

             lv_msg_bcc :=
                 xxhil_om_mail_alerts_pkg.mail_list (
                     P_USRROLE   => NULL,
                     P_ZONE      => NULL,
                     P_MDLID     => 'CCR_METALAC',
                     P_USRNAME   => NULL,
                     P_ETYPE     => 'BCC');

             lv_msg_bcc :=
                    lv_msg_bcc
                 || ','
                 || xxhil_om_mail_alerts_pkg.get_role_mail (
                        p_mdlid       => 'CCR_METALAC',
                        p_ou          => NULL,
                        p_mail_type   => 'BCC');

             LV_MSG_SUBJECT :=
                    'CCR Metal Balancing as on '
                 || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS');
             LV_MSG_TEXT :=
                 'Dear Sir / Madam, Please find the attachment of CCR Metal Balancing.';

             xxhil_om_mail_alerts_pkg.insert_req_attch_rec (
                 request_id    => lv_request_id,
                 msg_from      => lv_msg_from,
                 msg_to        => lv_msg_to,
                 msg_cc        => lv_msg_cc,
                 msg_bcc       => lv_msg_bcc,
                 msg_subject   => LV_MSG_SUBJECT,
                 msg_text      => LV_MSG_TEXT,
                 from_file     => LV_FROM_FILE,
                 to_file       => LV_TO_FILE,
                 to_extn       => LV_TO_EXTN,
                 wait_flg      => NULL,
                 called_from   => 'XXHIL_OM_MAIL_ALERTS_PKG.CCR_METALAC');
         EXCEPTION
             WHEN OTHERS
             THEN
                 msg ('REQUEST CALL EXCEPTION');
                 msg ('SQLERRM = ' || SQLERRM);
                 msg ('SQLCODE = ' || SQLCODE);
         END;

         msg ('CCR_METALAC END*****');
     EXCEPTION
         WHEN OTHERS
         THEN
             msg ('CCR_METALAC EXCEPTION');
             msg ('SQLERRM = ' || SQLERRM);
             msg ('SQLCODE = ' || SQLCODE);
     END CCR_METALAC;

     PROCEDURE RBD_METALAC
     AS
         lv_report_date   DATE := TRUNC (SYSDATE) - 1;
     BEGIN
         msg ('RBD_METALAC START*****');

         DECLARE
             LV_REQUEST_ID    XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
             LV_MSG_FROM      XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                  := G_EMAIL_FROM; --:= 'hilerp.alert@adityabirla.com'; --'bc.automail@adityabirla.com';
             LV_MSG_TO        XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
             LV_MSG_CC        XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
             LV_MSG_BCC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
             LV_MSG_SUBJECT   XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
             LV_MSG_TEXT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
             LV_FROM_FILE     XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
             LV_TO_FILE       XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
             LV_TO_EXTN       XXHIL_OM_REQ_ATTCH_MAIL.TO_EXTN%TYPE := 'PDF';
         BEGIN
             LV_REQUEST_ID :=
                 fnd_request.submit_request (
                     application   => 'XXHIL',
                     program       => 'XXHIL_OM_<>_CP',
                     description   => 'XXHIL OM <Report Name>',
                     start_time    => NULL,
                     sub_request   => FALSE,
                     argument1     => NULL,                       --<argument1>
                     argument2     => NULL,                       --<argument2>
                     argument3     => NULL,                       --<argument3>
                     argument4     => NULL,                       --<argument4>
                     argument5     => NULL                        --<argument5>
                                          );

             COMMIT;

             msg ('LV_REQUEST_ID = ' || lv_request_id);
             LV_FROM_FILE := 'o' || lv_request_id || '.out';
             MSG ('LV_FROM_FILE = ' || LV_FROM_FILE);
             LV_TO_FILE := 'BCDEPO_' || TO_CHAR (lv_report_date, 'RRRRHHDD');
             MSG ('LV_TO_FILE = ' || LV_TO_FILE);

             lv_msg_to :=
                 xxhil_om_mail_alerts_pkg.mail_list (
                     P_USRROLE   => NULL,
                     P_ZONE      => NULL,
                     P_MDLID     => 'RBD_METALAC',
                     P_USRNAME   => NULL,
                     P_ETYPE     => 'TO');

             lv_msg_cc :=
                 xxhil_om_mail_alerts_pkg.mail_list (
                     P_USRROLE   => NULL,
                     P_ZONE      => NULL,
                     P_MDLID     => 'RBD_METALAC',
                     P_USRNAME   => NULL,
                     P_ETYPE     => 'CC');

             lv_msg_bcc :=
                 xxhil_om_mail_alerts_pkg.mail_list (
                     P_USRROLE   => NULL,
                     P_ZONE      => NULL,
                     P_MDLID     => 'RBD_METALAC',
                     P_USRNAME   => NULL,
                     P_ETYPE     => 'BCC');

             lv_msg_bcc :=
                    lv_msg_bcc
                 || ','
                 || xxhil_om_mail_alerts_pkg.get_role_mail (
                        p_mdlid       => 'RBD_METALAC',
                        p_ou          => NULL,
                        p_mail_type   => 'BCC');

             LV_MSG_SUBJECT :=
                    'RBD Metal Balancing as on '
                 || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS');
             LV_MSG_TEXT :=
                 'Dear Sir / Madam, Please find the attachment of RBD Metal Balancing.';

             xxhil_om_mail_alerts_pkg.insert_req_attch_rec (
                 request_id    => lv_request_id,
                 msg_from      => lv_msg_from,
                 msg_to        => lv_msg_to,
                 msg_cc        => lv_msg_cc,
                 msg_bcc       => lv_msg_bcc,
                 msg_subject   => LV_MSG_SUBJECT,
                 msg_text      => LV_MSG_TEXT,
                 from_file     => LV_FROM_FILE,
                 to_file       => LV_TO_FILE,
                 to_extn       => LV_TO_EXTN,
                 wait_flg      => NULL,
                 called_from   => 'XXHIL_OM_MAIL_ALERTS_PKG.RBD_METALAC');
         EXCEPTION
             WHEN OTHERS
             THEN
                 msg ('REQUEST CALL EXCEPTION');
                 msg ('SQLERRM = ' || SQLERRM);
                 msg ('SQLCODE = ' || SQLCODE);
         END;

         msg ('RBD_METALAC END*****');
     EXCEPTION
         WHEN OTHERS
         THEN
             msg ('RBD_METALAC EXCEPTION');
             msg ('SQLERRM = ' || SQLERRM);
             msg ('SQLCODE = ' || SQLCODE);
     END RBD_METALAC;

 */
    PROCEDURE ONE_PAGE_COBR
    AS
        lv_report_date   DATE := TRUNC (SYSDATE) - 1;
    BEGIN
        msg ('ONE_PAGE_COBR START*****');

        DECLARE
            lv_onhand_stock_count   NUMBER;
        BEGIN
            SELECT COUNT (1)
              INTO lv_onhand_stock_count
              FROM xxhil_om_onhand_stock                              --_plant
             WHERE     prod_sub_grp = 'COBR'
                   AND organization_code IN ('DHJ', 'B12')
                   AND report_dt = lv_report_date;

            IF NVL (lv_onhand_stock_count, 0) = 0
            THEN
                --
                -- OnHand record insertion
                --
                DECLARE
                    lv_errbuf    VARCHAR2 (32767);
                    lv_retcode   VARCHAR2 (32767);
                BEGIN
                    XXHIL_OM_STOCK_PKG.ONHAND_STOCK (
                        ERRBUF         => lv_errbuf,
                        RETCODE        => lv_retcode,
                        P_REPORT_DT    => lv_report_date,
                        P_DELETE_FLG   => 'N');
                END;
            --INSERT INTO xxbc_om_onhand_stock_plant (query_no,
            --                                        inventory_item_id,
            --                                        lot,
            --                                        organization_code,
            --                                        organization_id,
            --                                        prod_legacy_cd,
            --                                        prod_sub_grp,
            --                                        refinery_no,
            --                                        subinventory_code,
            --                                        total_qoh,
            --                                        transaction_date,
            --                                        stock_plant,
            --                                        runsqnce,
            --                                        creation_dt,
            --                                        report_dt,
            --                                        grade)
            --    SELECT query_no,
            --           inventory_item_id,
            --           lot,
            --           organization_code,
            --           organization_id,
            --           prod_legacy_cd,
            --           prod_sub_grp,
            --           refinery_no,
            --           subinventory_code,
            --           total_qoh,
            --           transaction_date,
            --           stock_plant,
            --           -1,
            --           SYSDATE,
            --           TRUNC (SYSDATE) - 1,
            --           prdgrd
            --      FROM apps.xx_vw_onhand_stock_plant
            --     WHERE     prod_sub_grp = 'COBR'
            --           AND transaction_date <= TRUNC (SYSDATE) - 1;
            --
            --COMMIT;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                msg ('ONHAND_STOCK EXCEPTION');
                msg ('SQLERRM = ' || SQLERRM);
                msg ('SQLCODE = ' || SQLCODE);
        END;

        FOR i
            IN (SELECT DISTINCT
                       organization_id       organization_id,
                       organization_code     organization_code
                  FROM xxhil_om_onhand_stock                          --_plant
                 WHERE prod_sub_grp = 'COBR' AND organization_code = 'B12')
        LOOP
            DECLARE
                LV_REQUEST_ID    XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
                LV_MSG_FROM      XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                     := G_EMAIL_FROM; --:= 'hilerp.alert@adityabirla.com'; --'bc.automail@adityabirla.com';
                LV_MSG_TO        XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
                LV_MSG_CC        XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
                LV_MSG_BCC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
                LV_MSG_SUBJECT   XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
                LV_MSG_TEXT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
                LV_FROM_FILE     XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
                LV_TO_FILE       XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
                LV_TO_EXTN       XXHIL_OM_REQ_ATTCH_MAIL.TO_EXTN%TYPE
                                     := 'PDF';
            BEGIN
                LV_REQUEST_ID :=
                    fnd_request.submit_request (
                        application   => 'XXHIL',
                        program       => 'XXHIL_OM_ONE_PAGE_OTHER_CP',
                        description   =>
                            'XXHIL OM Register > One Page - Cu Bar [Copper]',
                        start_time    => NULL,
                        sub_request   => FALSE,
                        argument1     =>
                            TO_CHAR (lv_report_date, 'RRRR/MM/DD HH24:MI:SS'), --<P_TODT>
                        argument2     => i.organization_id, --<P_ORGANIZATION_ID>
                        argument3     => 'COBR',            --<P_PROD_SUB_GRP>
                        argument4     => 'Y',                --<P_INSERT_DATA>
                        argument5     => NULL                 --<P_SESSION_ID>
                                             );

                COMMIT;

                msg ('LV_REQUEST_ID = ' || lv_request_id);
                LV_FROM_FILE := 'o' || lv_request_id || '.out';
                MSG ('LV_FROM_FILE = ' || LV_FROM_FILE);
                LV_TO_FILE :=
                    'ONE_PAGE_COBR' || TO_CHAR (lv_report_date, 'RRRRHHDD');
                MSG ('LV_TO_FILE = ' || LV_TO_FILE);

                lv_msg_to :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'ONE_PAGE',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'TO');

                lv_msg_cc :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'ONE_PAGE',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'CC');

                lv_msg_bcc :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'ONE_PAGE',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'BCC');

                lv_msg_bcc :=
                       lv_msg_bcc
                    || ','
                    || xxhil_om_mail_alerts_pkg.get_role_mail (
                           p_mdlid       => 'ONE_PAGE',
                           p_ou          => NULL,
                           p_mail_type   => 'BCC');

                LV_MSG_SUBJECT :=
                       'One Page Copper BAR as on '
                    || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS');
                LV_MSG_TEXT :=
                    'Dear Sir / Madam, Please find the attachment of one page of Copper BAR.';

                xxhil_om_mail_alerts_pkg.insert_req_attch_rec (
                    request_id    => lv_request_id,
                    msg_from      => lv_msg_from,
                    msg_to        => lv_msg_to,
                    msg_cc        => lv_msg_cc,
                    msg_bcc       => lv_msg_bcc,
                    msg_subject   => LV_MSG_SUBJECT,
                    msg_text      => LV_MSG_TEXT,
                    from_file     => LV_FROM_FILE,
                    to_file       => LV_TO_FILE,
                    to_extn       => LV_TO_EXTN,
                    wait_flg      => NULL,
                    called_from   => 'XXHIL_OM_MAIL_ALERTS_PKG.ONE_PAGE_COBR');
            EXCEPTION
                WHEN OTHERS
                THEN
                    msg ('REQUEST CALL EXCEPTION');
                    msg ('SQLERRM = ' || SQLERRM);
                    msg ('SQLCODE = ' || SQLCODE);
            END;
        END LOOP;

        msg ('ONE_PAGE_COBR END*****');
    EXCEPTION
        WHEN OTHERS
        THEN
            msg ('ONE_PAGE_COBR EXCEPTION');
            msg ('SQLERRM = ' || SQLERRM);
            msg ('SQLCODE = ' || SQLCODE);
    END ONE_PAGE_COBR;

    PROCEDURE ONE_PAGE_GOLD
    AS
        lv_report_date   DATE := TRUNC (SYSDATE) - 1;
    BEGIN
        msg ('ONE_PAGE_GOLD START*****');

        DECLARE
            lv_onhand_stock_count   NUMBER;
        BEGIN
            SELECT COUNT (1)
              INTO lv_onhand_stock_count
              FROM xxhil_om_onhand_stock                              --_plant
             WHERE     prod_sub_grp = 'GOLD'
                   AND organization_code IN ('PMR', 'B13')
                   AND report_dt = lv_report_date;

            IF NVL (lv_onhand_stock_count, 0) = 0
            THEN
                --
                -- OnHand record insertion
                --
                DECLARE
                    lv_errbuf    VARCHAR2 (32767);
                    lv_retcode   VARCHAR2 (32767);
                BEGIN
                    XXHIL_OM_STOCK_PKG.ONHAND_STOCK (
                        ERRBUF         => lv_errbuf,
                        RETCODE        => lv_retcode,
                        P_REPORT_DT    => lv_report_date,
                        P_DELETE_FLG   => 'N');
                END;
            --INSERT INTO xxbc_om_onhand_stock_plant (query_no,
            --                                        inventory_item_id,
            --                                        lot,
            --                                        organization_code,
            --                                        organization_id,
            --                                        prod_legacy_cd,
            --                                        prod_sub_grp,
            --                                        refinery_no,
            --                                        subinventory_code,
            --                                        total_qoh,
            --                                        transaction_date,
            --                                        stock_plant,
            --                                        runsqnce,
            --                                        creation_dt,
            --                                        report_dt,
            --                                        grade)
            --    SELECT query_no,
            --           inventory_item_id,
            --           lot,
            --           organization_code,
            --           organization_id,
            --           prod_legacy_cd,
            --           prod_sub_grp,
            --           refinery_no,
            --           subinventory_code,
            --           total_qoh,
            --           transaction_date,
            --           stock_plant,
            --           -1,
            --           SYSDATE,
            --           TRUNC (SYSDATE) - 1,
            --           prdgrd
            --      FROM apps.xx_vw_onhand_stock_plant
            --     WHERE     prod_sub_grp = 'COBR'
            --           AND transaction_date <= TRUNC (SYSDATE) - 1;
            --
            --COMMIT;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                msg ('ONHAND_STOCK EXCEPTION');
                msg ('SQLERRM = ' || SQLERRM);
                msg ('SQLCODE = ' || SQLCODE);
        END;

        FOR i
            IN (SELECT DISTINCT
                       organization_id       organization_id,
                       organization_code     organization_code
                  FROM xxhil_om_onhand_stock                          --_plant
                 WHERE prod_sub_grp = 'GOLD' AND organization_code = 'B13')
        LOOP
            DECLARE
                LV_REQUEST_ID    XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
                LV_MSG_FROM      XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                     := G_EMAIL_FROM; --:= 'hilerp.alert@adityabirla.com'; --'bc.automail@adityabirla.com';
                LV_MSG_TO        XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
                LV_MSG_CC        XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
                LV_MSG_BCC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
                LV_MSG_SUBJECT   XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
                LV_MSG_TEXT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
                LV_FROM_FILE     XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
                LV_TO_FILE       XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
                LV_TO_EXTN       XXHIL_OM_REQ_ATTCH_MAIL.TO_EXTN%TYPE
                                     := 'PDF';
            BEGIN
                LV_REQUEST_ID :=
                    fnd_request.submit_request (
                        application   => 'XXHIL',
                        program       => 'XXHIL_OM_ONE_PAGE_OTHER_CP',
                        description   => 'XXHIL OM Register > One Page - Gold',
                        start_time    => NULL,
                        sub_request   => FALSE,
                        argument1     =>
                            TO_CHAR (lv_report_date, 'RRRR/MM/DD HH24:MI:SS'), --<P_TODT>
                        argument2     => i.organization_id, --<P_ORGANIZATION_ID>
                        argument3     => 'GOLD',            --<P_PROD_SUB_GRP>
                        argument4     => 'Y',                --<P_INSERT_DATA>
                        argument5     => NULL                 --<P_SESSION_ID>
                                             );

                COMMIT;

                msg ('LV_REQUEST_ID = ' || lv_request_id);
                LV_FROM_FILE := 'o' || lv_request_id || '.out';
                MSG ('LV_FROM_FILE = ' || LV_FROM_FILE);
                LV_TO_FILE :=
                    'ONE_PAGE_GOLD' || TO_CHAR (lv_report_date, 'RRRRHHDD');
                MSG ('LV_TO_FILE = ' || LV_TO_FILE);

                lv_msg_to :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'ONE_PAGE_PMR',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'TO');

                lv_msg_cc :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'ONE_PAGE_PMR',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'CC');

                lv_msg_bcc :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'ONE_PAGE_PMR',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'BCC');

                lv_msg_bcc :=
                       lv_msg_bcc
                    || ','
                    || xxhil_om_mail_alerts_pkg.get_role_mail (
                           p_mdlid       => 'ONE_PAGE_PMR',
                           p_ou          => NULL,
                           p_mail_type   => 'BCC');

                LV_MSG_SUBJECT :=
                       'One Page GOLD as on '
                    || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS');
                LV_MSG_TEXT :=
                    'Dear Sir / Madam, Please find the attachment of one page of GOLD.';

                xxhil_om_mail_alerts_pkg.insert_req_attch_rec (
                    request_id    => lv_request_id,
                    msg_from      => lv_msg_from,
                    msg_to        => lv_msg_to,
                    msg_cc        => lv_msg_cc,
                    msg_bcc       => lv_msg_bcc,
                    msg_subject   => LV_MSG_SUBJECT,
                    msg_text      => LV_MSG_TEXT,
                    from_file     => LV_FROM_FILE,
                    to_file       => LV_TO_FILE,
                    to_extn       => LV_TO_EXTN,
                    wait_flg      => NULL,
                    called_from   => 'XXHIL_OM_MAIL_ALERTS_PKG.ONE_PAGE_GOLD');
            EXCEPTION
                WHEN OTHERS
                THEN
                    msg ('REQUEST CALL EXCEPTION');
                    msg ('SQLERRM = ' || SQLERRM);
                    msg ('SQLCODE = ' || SQLCODE);
            END;
        END LOOP;

        msg ('ONE_PAGE_GOLD END*****');
    EXCEPTION
        WHEN OTHERS
        THEN
            msg ('ONE_PAGE_GOLD EXCEPTION');
            msg ('SQLERRM = ' || SQLERRM);
            msg ('SQLCODE = ' || SQLCODE);
    END ONE_PAGE_GOLD;

    PROCEDURE ONE_PAGE_SLVR
    AS
        lv_report_date   DATE := TRUNC (SYSDATE) - 1;
    BEGIN
        msg ('ONE_PAGE_SLVR START*****');

        DECLARE
            lv_onhand_stock_count   NUMBER;
        BEGIN
            SELECT COUNT (1)
              INTO lv_onhand_stock_count
              FROM xxhil_om_onhand_stock                              --_plant
             WHERE     prod_sub_grp = 'SLVR'
                   AND organization_code IN ('PMR', 'B13')
                   AND report_dt = lv_report_date;

            IF NVL (lv_onhand_stock_count, 0) = 0
            THEN
                --
                -- OnHand record insertion
                --
                DECLARE
                    lv_errbuf    VARCHAR2 (32767);
                    lv_retcode   VARCHAR2 (32767);
                BEGIN
                    XXHIL_OM_STOCK_PKG.ONHAND_STOCK (
                        ERRBUF         => lv_errbuf,
                        RETCODE        => lv_retcode,
                        P_REPORT_DT    => lv_report_date,
                        P_DELETE_FLG   => 'N');
                END;
            --INSERT INTO xxbc_om_onhand_stock_plant (query_no,
            --                                        inventory_item_id,
            --                                        lot,
            --                                        organization_code,
            --                                        organization_id,
            --                                        prod_legacy_cd,
            --                                        prod_sub_grp,
            --                                        refinery_no,
            --                                        subinventory_code,
            --                                        total_qoh,
            --                                        transaction_date,
            --                                        stock_plant,
            --                                        runsqnce,
            --                                        creation_dt,
            --                                        report_dt,
            --                                        grade)
            --    SELECT query_no,
            --           inventory_item_id,
            --           lot,
            --           organization_code,
            --           organization_id,
            --           prod_legacy_cd,
            --           prod_sub_grp,
            --           refinery_no,
            --           subinventory_code,
            --           total_qoh,
            --           transaction_date,
            --           stock_plant,
            --           -1,
            --           SYSDATE,
            --           TRUNC (SYSDATE) - 1,
            --           prdgrd
            --      FROM apps.xx_vw_onhand_stock_plant
            --     WHERE     prod_sub_grp = 'COBR'
            --           AND transaction_date <= TRUNC (SYSDATE) - 1;
            --
            --COMMIT;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                msg ('ONHAND_STOCK EXCEPTION');
                msg ('SQLERRM = ' || SQLERRM);
                msg ('SQLCODE = ' || SQLCODE);
        END;

        FOR i
            IN (SELECT DISTINCT
                       organization_id       organization_id,
                       organization_code     organization_code
                  FROM xxhil_om_onhand_stock                          --_plant
                 WHERE prod_sub_grp = 'SLVR' AND organization_code IN ('B13'))
        LOOP
            DECLARE
                LV_REQUEST_ID    XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
                LV_MSG_FROM      XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                     := G_EMAIL_FROM; --:= 'hilerp.alert@adityabirla.com'; --'bc.automail@adityabirla.com';
                LV_MSG_TO        XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
                LV_MSG_CC        XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
                LV_MSG_BCC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
                LV_MSG_SUBJECT   XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
                LV_MSG_TEXT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
                LV_FROM_FILE     XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
                LV_TO_FILE       XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
                LV_TO_EXTN       XXHIL_OM_REQ_ATTCH_MAIL.TO_EXTN%TYPE
                                     := 'PDF';
            BEGIN
                LV_REQUEST_ID :=
                    fnd_request.submit_request (
                        application   => 'XXHIL',
                        program       => 'XXHIL_OM_ONE_PAGE_OTHER_CP',
                        description   =>
                            'XXHIL OM Register > One Page - Silver',
                        start_time    => NULL,
                        sub_request   => FALSE,
                        argument1     =>
                            TO_CHAR (lv_report_date, 'RRRR/MM/DD HH24:MI:SS'), --<P_TODT>
                        argument2     => i.organization_id, --<P_ORGANIZATION_ID>
                        argument3     => 'SLVR',            --<P_PROD_SUB_GRP>
                        argument4     => 'Y',                --<P_INSERT_DATA>
                        argument5     => NULL                 --<P_SESSION_ID>
                                             );

                COMMIT;

                msg ('LV_REQUEST_ID = ' || lv_request_id);
                LV_FROM_FILE := 'o' || lv_request_id || '.out';
                MSG ('LV_FROM_FILE = ' || LV_FROM_FILE);
                LV_TO_FILE :=
                    'ONE_PAGE_SLVR' || TO_CHAR (lv_report_date, 'RRRRHHDD');
                MSG ('LV_TO_FILE = ' || LV_TO_FILE);

                lv_msg_to :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'ONE_PAGE_PMR',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'TO');

                lv_msg_cc :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'ONE_PAGE_PMR',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'CC');

                lv_msg_bcc :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'ONE_PAGE_PMR',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'BCC');

                lv_msg_bcc :=
                       lv_msg_bcc
                    || ','
                    || xxhil_om_mail_alerts_pkg.get_role_mail (
                           p_mdlid       => 'ONE_PAGE_PMR',
                           p_ou          => NULL,
                           p_mail_type   => 'BCC');

                LV_MSG_SUBJECT :=
                       'One Page Silver as on '
                    || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS');
                LV_MSG_TEXT :=
                    'Dear Sir / Madam, Please find the attachment of one page of Silver.';

                xxhil_om_mail_alerts_pkg.insert_req_attch_rec (
                    request_id    => lv_request_id,
                    msg_from      => lv_msg_from,
                    msg_to        => lv_msg_to,
                    msg_cc        => lv_msg_cc,
                    msg_bcc       => lv_msg_bcc,
                    msg_subject   => LV_MSG_SUBJECT,
                    msg_text      => LV_MSG_TEXT,
                    from_file     => LV_FROM_FILE,
                    to_file       => LV_TO_FILE,
                    to_extn       => LV_TO_EXTN,
                    wait_flg      => NULL,
                    called_from   => 'XXHIL_OM_MAIL_ALERTS_PKG.ONE_PAGE_SLVR');
            EXCEPTION
                WHEN OTHERS
                THEN
                    msg ('REQUEST CALL EXCEPTION');
                    msg ('SQLERRM = ' || SQLERRM);
                    msg ('SQLCODE = ' || SQLCODE);
            END;
        END LOOP;

        msg ('ONE_PAGE_SLVR END*****');
    EXCEPTION
        WHEN OTHERS
        THEN
            msg ('ONE_PAGE_SLVR EXCEPTION');
            msg ('SQLERRM = ' || SQLERRM);
            msg ('SQLCODE = ' || SQLCODE);
    END ONE_PAGE_SLVR;

    PROCEDURE DEPO_STOCK_STATUS
    AS
        lv_report_date   DATE := TRUNC (SYSDATE) - 1;
    BEGIN
        msg ('DEPO_STOCK_STATUS START*****');

        DECLARE
            lv_onhand_stock_count   NUMBER;
        BEGIN
            SELECT COUNT (1)
              INTO LV_ONHAND_STOCK_COUNT
              FROM XXHIL_OM_ONHAND_STOCK
             WHERE IS_TRADING = 'Y' AND REPORT_DT = LV_REPORT_DATE;

            IF NVL (lv_onhand_stock_count, 0) = 0
            THEN
                --
                -- OnHand record insertion
                --
                DECLARE
                    lv_errbuf    VARCHAR2 (32767);
                    lv_retcode   VARCHAR2 (32767);
                BEGIN
                    XXHIL_OM_STOCK_PKG.ONHAND_STOCK (
                        ERRBUF         => lv_errbuf,
                        RETCODE        => lv_retcode,
                        P_REPORT_DT    => lv_report_date,
                        P_DELETE_FLG   => 'N');
                END;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                msg ('ONHAND_STOCK EXCEPTION');
                msg ('SQLERRM = ' || SQLERRM);
                msg ('SQLCODE = ' || SQLCODE);
        END;


        DECLARE
            LV_REQUEST_ID    XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
            LV_MSG_FROM      XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                 := G_EMAIL_FROM; --:= 'hilerp.alert@adityabirla.com'; --'bc.automail@adityabirla.com';
            LV_MSG_TO        XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
            LV_MSG_CC        XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
            LV_MSG_BCC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
            LV_MSG_SUBJECT   XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
            LV_MSG_TEXT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
            LV_FROM_FILE     XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
            LV_TO_FILE       XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
            LV_TO_EXTN       XXHIL_OM_REQ_ATTCH_MAIL.TO_EXTN%TYPE := 'xls';
            LV_XML_LAYOUT    BOOLEAN;
        BEGIN
            lv_xml_layout :=
                fnd_request.add_layout (
                    template_appl_name   => 'XXHIL',
                    template_code        => 'XXHIL_OM_DEPO_STATUS_CP',
                    template_language    => 'en',
                    template_territory   => '00',
                    output_format        => 'EXCEL');

            LV_REQUEST_ID :=
                fnd_request.submit_request (
                    application   => 'XXHIL',
                    program       => 'XXHIL_OM_DEPO_STATUS_CP',
                    description   => NULL,
                    start_time    => NULL,
                    sub_request   => FALSE,
                    argument1     => 'Y',                      --<Insert Data>
                    argument2     => NULL,                       --<argument2>
                    argument3     => NULL,                       --<argument3>
                    argument4     => NULL,                       --<argument4>
                    argument5     => NULL                        --<argument5>
                                         );

            COMMIT;

            msg ('LV_REQUEST_ID = ' || lv_request_id);
            LV_FROM_FILE := 'o' || lv_request_id || '.out';
            MSG ('LV_FROM_FILE = ' || LV_FROM_FILE);
            LV_TO_FILE := 'BCDEPO_' || TO_CHAR (lv_report_date, 'RRRRHHDD');
            MSG ('LV_TO_FILE = ' || LV_TO_FILE);

            lv_msg_to :=
                xxhil_om_mail_alerts_pkg.mail_list (
                    P_USRROLE   => NULL,
                    P_ZONE      => NULL,
                    P_MDLID     => 'DEPO_STATUS',
                    P_USRNAME   => NULL,
                    P_ETYPE     => 'TO');
            lv_msg_to :=
                   lv_msg_to
                || ','
                || xxhil_om_mail_alerts_pkg.get_role_mail (
                       p_mdlid       => 'DEPO_STATUS',
                       p_ou          => NULL,
                       p_mail_type   => 'TO');

            lv_msg_cc :=
                xxhil_om_mail_alerts_pkg.mail_list (
                    P_USRROLE   => NULL,
                    P_ZONE      => NULL,
                    P_MDLID     => 'DEPO_STATUS',
                    P_USRNAME   => NULL,
                    P_ETYPE     => 'CC');
            lv_msg_cc :=
                   lv_msg_cc
                || ','
                || xxhil_om_mail_alerts_pkg.get_role_mail (
                       p_mdlid       => 'DEPO_STATUS',
                       p_ou          => NULL,
                       p_mail_type   => 'CC');

            lv_msg_bcc :=
                xxhil_om_mail_alerts_pkg.mail_list (
                    P_USRROLE   => NULL,
                    P_ZONE      => NULL,
                    P_MDLID     => 'DEPO_STATUS',
                    P_USRNAME   => NULL,
                    P_ETYPE     => 'BCC');

            lv_msg_bcc :=
                   lv_msg_bcc
                || ','
                || xxhil_om_mail_alerts_pkg.get_role_mail (
                       p_mdlid       => 'DEPO_STATUS',
                       p_ou          => NULL,
                       p_mail_type   => 'BCC');

            LV_MSG_SUBJECT :=
                   'Depot Stock Status as on '
                || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS');
            LV_MSG_TEXT :=
                'Dear Sir / Madam, Please find the attachment of Depot Status Report >>';

            xxhil_om_mail_alerts_pkg.insert_req_attch_rec (
                request_id    => lv_request_id,
                msg_from      => lv_msg_from,
                msg_to        => lv_msg_to,
                msg_cc        => lv_msg_cc,
                msg_bcc       => lv_msg_bcc,
                msg_subject   => LV_MSG_SUBJECT,
                msg_text      => LV_MSG_TEXT,
                from_file     => LV_FROM_FILE,
                to_file       => LV_TO_FILE,
                to_extn       => LV_TO_EXTN,
                wait_flg      => NULL,
                called_from   => 'XXHIL_OM_MAIL_ALERTS_PKG.DEPO_STOCK_STATUS');
        EXCEPTION
            WHEN OTHERS
            THEN
                msg ('REQUEST CALL EXCEPTION');
                msg ('SQLERRM = ' || SQLERRM);
                msg ('SQLCODE = ' || SQLCODE);
        END;

        msg ('DEPO_STOCK_STATUS END*****');
    EXCEPTION
        WHEN OTHERS
        THEN
            msg ('DEPO_STOCK_STATUS EXCEPTION');
            msg ('SQLERRM = ' || SQLERRM);
            msg ('SQLCODE = ' || SQLCODE);
    END DEPO_STOCK_STATUS;

    PROCEDURE STOCK_AGING_DETAIL
    AS
    BEGIN
        msg ('STOCK_AGING_DETAIL START*****');

        FOR si IN (SELECT 'FG' sub_inv FROM DUAL
                   UNION ALL
                   SELECT 'Return' sub_inv FROM DUAL)
        LOOP
            DECLARE
                LV_REQUEST_ID    XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
                LV_MSG_FROM      XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                     := G_EMAIL_FROM;
                LV_MSG_TO        XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
                LV_MSG_CC        XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
                LV_MSG_BCC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
                LV_MSG_SUBJECT   XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
                LV_MSG_TEXT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
                LV_FROM_FILE     XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
                LV_TO_FILE       XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
                LV_TO_EXTN       XXHIL_OM_REQ_ATTCH_MAIL.TO_EXTN%TYPE
                                     := 'PDF';
                LV_REPORT_DT     DATE := TRUNC (SYSDATE) - 1;
            BEGIN
                LV_REQUEST_ID :=
                    fnd_request.submit_request (
                        application   => 'XXHIL',
                        program       => 'XXHIL_OM_DEPOTSTK_AGING_CP',
                        description   =>
                            'XXHIL OM Register > Stock Aging Product Wise [All Locations]',
                        start_time    => NULL,
                        sub_request   => FALSE,
                        argument1     => 'COPPER',                   --<P_SBU>
                        argument2     => 'COPR',                --<P_PROD_GRP>
                        argument3     => TO_CHAR (LV_REPORT_DT, 'RRRR/MM/DD'), --<P_REPORT_DT>
                        argument4     => si.sub_inv               --<P_SUBINV>
                                                   );

                COMMIT;

                msg ('LV_REQUEST_ID = ' || lv_request_id);
                LV_FROM_FILE := 'o' || lv_request_id || '.out';
                MSG ('LV_FROM_FILE = ' || LV_FROM_FILE);
                LV_TO_FILE :=
                       'BCAGING_'
                    || si.sub_inv
                    || '_'
                    || TO_CHAR (SYSDATE, 'RRRRMMDD');
                MSG ('LV_TO_FILE = ' || LV_TO_FILE);

                lv_msg_to :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'DEPO_STATUS',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'TO');

                lv_msg_to :=
                       lv_msg_to
                    || ','
                    || xxhil_om_mail_alerts_pkg.get_role_mail (
                           p_mdlid       => 'DEPO_STATUS',
                           p_ou          => NULL,
                           p_mail_type   => 'TO');

                lv_msg_cc :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'DEPO_STATUS',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'CC');

                lv_msg_cc :=
                       lv_msg_cc
                    || ','
                    || xxhil_om_mail_alerts_pkg.get_role_mail (
                           p_mdlid       => 'DEPO_STATUS',
                           p_ou          => NULL,
                           p_mail_type   => 'CC');

                lv_msg_bcc :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'DEPO_STATUS',
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'BCC');

                lv_msg_bcc :=
                       lv_msg_bcc
                    || ','
                    || xxhil_om_mail_alerts_pkg.get_role_mail (
                           p_mdlid       => 'DEPO_STATUS',
                           p_ou          => NULL,
                           p_mail_type   => 'BCC');

                LV_MSG_SUBJECT :=
                       'Product wise Aging Status ('
                    || si.sub_inv
                    || ') as on '
                    || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS');
                LV_MSG_TEXT :=
                       'Dear Sir / Madam, Please find the attachment of '
                    || si.sub_inv
                    || ' Stock Aging Status Report.';

                xxhil_om_mail_alerts_pkg.insert_req_attch_rec (
                    request_id    => lv_request_id,
                    msg_from      => lv_msg_from,
                    msg_to        => lv_msg_to,
                    msg_cc        => lv_msg_cc,
                    msg_bcc       => lv_msg_bcc,
                    msg_subject   => LV_MSG_SUBJECT,
                    msg_text      => LV_MSG_TEXT,
                    from_file     => LV_FROM_FILE,
                    to_file       => LV_TO_FILE,
                    to_extn       => LV_TO_EXTN,
                    wait_flg      => NULL,
                    called_from   =>
                        'XXHIL_OM_MAIL_ALERTS_PKG.STOCK_AGING_DETAIL');
            EXCEPTION
                WHEN OTHERS
                THEN
                    msg ('REQUEST CALL EXCEPTION');
                    msg ('SQLERRM = ' || SQLERRM);
                    msg ('SQLCODE = ' || SQLCODE);
            END;
        END LOOP;

        msg ('STOCK_AGING_DETAIL END*****');
    EXCEPTION
        WHEN OTHERS
        THEN
            msg ('STOCK_AGING_DETAIL EXCEPTION');
            msg ('SQLERRM = ' || SQLERRM);
            msg ('SQLCODE = ' || SQLCODE);
    END STOCK_AGING_DETAIL;


    PROCEDURE DISPATCH_MAIL (P_PROD_SUB_GRP VARCHAR2)
    AS
    BEGIN
        MSG ('DISPATCH_MAIL START*****');
        MSG ('PARAMETERS...');
        MSG ('P_PROD_SUB_GRP = ' || P_PROD_SUB_GRP);

        FOR i
            IN (SELECT DISTINCT
                       DECODE (p.prod_sub_grp, 'SAP', sub_inv, 'FG')
                           invh_sub_inv,
                       item_id
                           invh_prod_cd,
                       p.prod_sub_grp,
                       i.org_id
                           invh_doc_locn,
                       DECODE (sub_inv,
                               'COPPER-1', 'SAP - 1',
                               'COPPER-2', 'SAP - 2',
                               --'SA2', 'SAP - 2',
                               'COPPER-3', 'SAP - 3',
                               p.prod_long_desc)
                           prod_desc,
                       p.prod_uom
                  FROM xxhil_om_invoice_hdr i, xxhil_om_prod_v p
                 WHERE     p.prod_sub_grp = p_prod_sub_grp
                       AND NOT EXISTS
                               (SELECT 'x'
                                  FROM XXHIL_AR_INVOICE_CANCELLATION
                                 WHERE     PROCESS_FLAG <> 'E'
                                       AND return_to = 'WITHIN PLANT'
                                       AND SHIPMENT_NUMBER =
                                           TO_CHAR (i.delivery_id))
                       AND i.sub_inv <> 'Return'
                       AND invh_dt >= ADD_MONTHS (SYSDATE, -1)
                       AND xxhil_om_lib_pkg.org_type (i.org_id) = 'M'
                       --AND xxhil_om_lib_pkg.org_type (i.org_id) = 'M'
                       AND i.item_id = p.prod_cd)
        LOOP
            DECLARE
                LV_TO_DT             DATE := TRUNC (SYSDATE - 1);
                lv_dom_today         NUMBER;
                lv_dom_cum           NUMBER;
                lv_exp_today         NUMBER;
                lv_exp_cum           NUMBER;
                lv_dom_today_count   NUMBER;
                lv_dom_cum_count     NUMBER;
                LV_REQUEST_ID        XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
                LV_MSG_FROM          XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                         := G_EMAIL_FROM;
                LV_MSG_TO            XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
                LV_MSG_CC            XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
                LV_MSG_BCC           XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
                LV_MSG_SUBJECT       XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
                LV_MSG_TEXT          XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
                LV_FROM_FILE         XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
                LV_TO_FILE           XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
                LV_TO_EXTN           XXHIL_OM_REQ_ATTCH_MAIL.TO_EXTN%TYPE
                                         := 'PDF';
            BEGIN
                LV_MSG_SUBJECT :=
                       'Dispatch Quantity in '
                    || i.prod_uom
                    || ' for '
                    || i.prod_desc
                    || ' for period '
                    || TO_CHAR (TRUNC (lv_to_dt, 'MM'), 'dd/mm/rrrr')
                    || ' to '
                    || TO_CHAR (lv_to_dt, 'dd/mm/rrrr');

                SELECT TO_CHAR (NVL (SUM (INV_QTY), 0)), TO_CHAR (COUNT (*))
                  INTO lv_dom_today, lv_dom_today_count
                  FROM xxhil_om_invoice_hdr
                 WHERE     sale_category <> 'Export'
                       AND (   (    sub_inv = i.invh_sub_inv
                                AND p_prod_sub_grp = 'SAP')
                            OR p_prod_sub_grp <> 'SAP')
                       AND invh_dt = lv_to_dt
                       AND NOT EXISTS
                               (SELECT 'x'
                                  FROM XXHIL_AR_INVOICE_CANCELLATION
                                 WHERE     PROCESS_FLAG <> 'E'
                                       AND return_to = 'WITHIN PLANT'
                                       AND SHIPMENT_NUMBER =
                                           TO_CHAR (delivery_id))
                       AND item_id = i.invh_prod_cd;

                SELECT TO_CHAR (NVL (SUM (INV_QTY), 0))
                  INTO lv_exp_today
                  FROM xxhil_om_invoice_hdr
                 WHERE     sale_category = 'Export'
                       AND (   (    sub_inv = i.invh_sub_inv
                                AND p_prod_sub_grp = 'SAP')
                            OR p_prod_sub_grp <> 'SAP')
                       AND invh_dt = lv_to_dt
                       AND NOT EXISTS
                               (SELECT 'x'
                                  FROM XXHIL_AR_INVOICE_CANCELLATION
                                 WHERE     PROCESS_FLAG <> 'E'
                                       AND return_to = 'WITHIN PLANT'
                                       AND SHIPMENT_NUMBER =
                                           TO_CHAR (delivery_id))
                       AND item_id = i.invh_prod_cd;

                SELECT TO_CHAR (NVL (SUM (INV_QTY), 0)), TO_CHAR (COUNT (*))
                  INTO lv_dom_cum, lv_dom_cum_count
                  FROM xxhil_om_invoice_hdr
                 WHERE     sale_category <> 'Export'
                       AND (   (    sub_inv = i.invh_sub_inv
                                AND p_prod_sub_grp = 'SAP')
                            OR p_prod_sub_grp <> 'SAP')
                       AND NOT EXISTS
                               (SELECT 'x'
                                  FROM XXHIL_AR_INVOICE_CANCELLATION
                                 WHERE     PROCESS_FLAG <> 'E'
                                       AND return_to = 'WITHIN PLANT'
                                       AND SHIPMENT_NUMBER =
                                           TO_CHAR (delivery_id))
                       AND invh_dt BETWEEN TRUNC (lv_to_dt, 'MM')
                                       AND lv_to_dt
                       AND item_id = i.invh_prod_cd;

                SELECT TO_CHAR (NVL (SUM (INV_QTY), 0))
                  INTO lv_exp_cum
                  FROM xxhil_om_invoice_hdr
                 WHERE     sale_category = 'Export'
                       AND (   (    sub_inv = i.invh_sub_inv
                                AND p_prod_sub_grp = 'SAP')
                            OR p_prod_sub_grp <> 'SAP')
                       AND NOT EXISTS
                               (SELECT 'x'
                                  FROM XXHIL_AR_INVOICE_CANCELLATION
                                 WHERE     PROCESS_FLAG <> 'E'
                                       AND return_to = 'WITHIN PLANT'
                                       AND SHIPMENT_NUMBER =
                                           TO_CHAR (delivery_id))
                       AND invh_dt BETWEEN TRUNC (lv_to_dt, 'MM')
                                       AND lv_to_dt
                       AND item_id = i.invh_prod_cd;

                MSG ('Subject created.');

                lv_msg_text := '<!DOCTYPE html>';
                lv_msg_text := lv_msg_text || '<HTML>';
                lv_msg_text := lv_msg_text || '<HEAD>';
                lv_msg_text :=
                       lv_msg_text
                    || '<STYLE> table, th, td {border-collapse:collapse;border:1px solid black;} th, td {padding:1px;} td {vertical-align:top;} th {text-align:left; background-color:#85C8FC;} </STYLE>';
                lv_msg_text := lv_msg_text || '</HEAD>';

                lv_msg_text := lv_msg_text || '<BODY>';
                lv_msg_text :=
                       lv_msg_text
                    || 'Dispatched Quantity for '
                    || i.prod_desc
                    || ' for period '
                    || TO_CHAR (TRUNC (lv_to_dt, 'MM'), 'dd/mm/rrrr')
                    || ' to '
                    || TO_CHAR (lv_to_dt, 'dd/mm/rrrr');

                lv_msg_text := lv_msg_text || '<BR>';

                lv_msg_text := lv_msg_text || '<TABLE>';

                lv_msg_text :=
                       lv_msg_text
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">Product</TD>'
                    || '<TD>'
                    || i.prod_desc
                    || '</TD>'
                    || '</TR>';

                lv_msg_text :=
                       lv_msg_text
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">Domestic Today Qty</TD>'
                    || '<TD>'
                    || lv_dom_today
                    || '</TD>'
                    || '</TR>';

                lv_msg_text :=
                       lv_msg_text
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">Domestic Cummu. Qty</TD>'
                    || '<TD>'
                    || lv_dom_cum
                    || '</TD>'
                    || '</TR>';


                IF lv_exp_today > 0 OR lv_exp_cum > 0
                THEN
                    lv_msg_text :=
                           lv_msg_text
                        || '<TR>'
                        || '<TD bgcolor="#FDF2F2">Export Today Qty</TD>'
                        || '<TD>'
                        || lv_exp_today
                        || '</TD>'
                        || '</TR>';

                    lv_msg_text :=
                           lv_msg_text
                        || '<TR>'
                        || '<TD bgcolor="#FDF2F2">Export Cummu. Qty</TD>'
                        || '<TD>'
                        || lv_exp_cum
                        || '</TD>'
                        || '</TR>';
                END IF;

                IF i.invh_sub_inv IN ('COPPER-1', 'COPPER-3')
                THEN
                    lv_msg_text :=
                           lv_msg_text
                        || '<TR>'
                        || '<TD bgcolor="#FDF2F2">Today Tankers</TD>'
                        || '<TD>'
                        || lv_dom_today_count
                        || '</TD>'
                        || '</TR>';


                    lv_msg_text :=
                           lv_msg_text
                        || '<TR>'
                        || '<TD bgcolor="#FDF2F2">Cummu. Tankers</TD>'
                        || '<TD>'
                        || lv_dom_cum_count
                        || '</TD>'
                        || '</TR>';
                END IF;


                lv_msg_text :=
                       lv_msg_text
                    || '<TR>'
                    || '<TD bgcolor="#FDF2F2">Sent Date and Time</TD>'
                    || '<TD>'
                    || TO_CHAR (SYSDATE, 'DD/MM/RRRR HH24:MI:SS')
                    || '</TD>'
                    || '</TR>';

                lv_msg_text := lv_msg_text || '</TABLE>';

                lv_msg_text :=
                       lv_msg_text
                    || 'Note : All figures based on Invoice date basis (12 to 12).';

                lv_msg_text := lv_msg_text || '</BODY>';
                lv_msg_text := lv_msg_text || '</HTML>';

                LV_MSG_TO :=
                    xxhil_om_mail_alerts_pkg.mail_list (
                        P_USRROLE   => NULL,
                        P_ZONE      => NULL,
                        P_MDLID     => 'DESP_' || i.prod_sub_grp,
                        P_USRNAME   => NULL,
                        P_ETYPE     => 'To');

                LV_MSG_cc :=
                    xxhil_om_mail_alerts_pkg.get_role_mail (
                        'DESP_' || I.prod_sub_grp,
                        NULL,
                        'CC');

                LV_MSG_cc :=
                       LV_MSG_cc
                    || ','
                    || xxhil_om_mail_alerts_pkg.mail_list (
                           P_USRROLE   => NULL,
                           P_ZONE      => NULL,
                           P_MDLID     => 'DESP_' || i.prod_sub_grp,
                           P_USRNAME   => NULL,
                           P_ETYPE     => 'Cc');

                LV_MSG_bcc :=
                    xxhil_om_mail_alerts_pkg.get_role_mail (
                        'DESP_' || I.prod_sub_grp,
                        NULL,
                        'BCC');
                LV_MSG_bcc :=
                       LV_MSG_bcc
                    || ','
                    || xxhil_om_mail_alerts_pkg.mail_list (
                           P_USRROLE   => NULL,
                           P_ZONE      => NULL,
                           P_MDLID     => 'DESP_' || i.prod_sub_grp,
                           P_USRNAME   => NULL,
                           P_ETYPE     => 'Bcc');

                PUSH_MAIL (
                    p_request_id    => lv_request_id,
                    p_msg_from      => lv_msg_from,
                    p_msg_to        => lv_msg_to,
                    p_msg_cc        => lv_msg_cc,
                    p_msg_bcc       => lv_msg_bcc,
                    p_msg_subject   => LV_MSG_SUBJECT,
                    p_msg_text      => lv_msg_text,
                    p_from_file     => lv_from_file,
                    p_to_file       => lv_to_file,
                    p_to_extn       => 'PDF',
                    p_wait_flg      => NULL,
                    p_called_from   =>
                        'XXHIL_OM_MAIL_ALERTS_PKG.DISPATCH_MAIL');
            END;
        END LOOP;

        msg ('DISPATCH_MAIL END*****');
    EXCEPTION
        WHEN OTHERS
        THEN
            msg ('DISPATCH_MAIL EXCEPTION');
            msg ('SQLERRM = ' || SQLERRM);
            msg ('SQLCODE = ' || SQLCODE);
    END DISPATCH_MAIL;

    PROCEDURE NONC_REALIZATION
    AS
    BEGIN
        MSG ('NONC_REALIZATION START*****');

        DECLARE
            LV_REQUEST_ID   XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
            LV_MSG_FROM     XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                := G_EMAIL_FROM;
            LV_MSG_TO       XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
            LV_MSG_CC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
            LV_MSG_BCC      XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
            LV_SUBJECT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
            LV_MSG_TEXT     XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
            LV_FROM_FILE    XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
            LV_TO_FILE      XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
            LV_TO_EXTN      XXHIL_OM_REQ_ATTCH_MAIL.TO_EXTN%TYPE := 'PDF';
            LV_FROM_DATE    DATE := TRUNC (SYSDATE - 1, 'mm');
            LV_TO_DATE      DATE := TRUNC (SYSDATE) - 1;
        BEGIN
            LV_REQUEST_ID :=
                fnd_request.submit_request (
                    application   => 'XXHIL',
                    program       => 'XXHIL_OM_NONC_REALIZATION_CP',
                    description   => 'Register > Non Copper Realization',
                    start_time    => NULL,
                    sub_request   => FALSE,
                    argument1     => TO_CHAR (LV_FROM_DATE, 'RRRR/MM/DD'), --<P_FROM_DATE>
                    argument2     => TO_CHAR (LV_TO_DATE, 'RRRR/MM/DD'), --<P_TO_DATE>
                    argument3     => 'N'                     --<P_SHIP_TO_FLG>
                                        );
            COMMIT;
            MSG ('LV_REQUEST_ID = ' || lv_request_id);
            LV_FROM_FILE := 'o' || lv_request_id || '.out';
            MSG ('LV_FROM_FILE = ' || LV_FROM_FILE);
            LV_TO_FILE := 'BCRELZ_' || TO_CHAR (SYSDATE, 'DDMMRR');
            MSG ('LV_TO_FILE = ' || LV_TO_FILE);

            lv_msg_to :=
                xxhil_om_mail_alerts_pkg.mail_list (
                    P_USRROLE   => NULL,
                    P_ZONE      => NULL,
                    P_MDLID     => 'NONC_REALIZATION',
                    P_USRNAME   => NULL,
                    P_ETYPE     => 'To');

            lv_msg_to :=
                   lv_msg_to
                || ','
                || XXHIL_OM_MAIL_ALERTS_PKG.GET_ROLE_MAIL (
                       p_mdlid       => 'NONC_REALIZATION',
                       p_ou          => NULL,
                       p_mail_type   => 'TO');

            lv_msg_cc :=
                xxhil_om_mail_alerts_pkg.mail_list (
                    P_USRROLE   => NULL,
                    P_ZONE      => NULL,
                    P_MDLID     => 'NONC_REALIZATION',
                    P_USRNAME   => NULL,
                    P_ETYPE     => 'Cc');

            lv_msg_cc :=
                   lv_msg_cc
                || ','
                || XXHIL_OM_MAIL_ALERTS_PKG.GET_ROLE_MAIL (
                       p_mdlid       => 'NONC_REALIZATION',
                       p_ou          => NULL,
                       p_mail_type   => 'CC');

            lv_msg_bcc :=
                xxhil_om_mail_alerts_pkg.mail_list (
                    P_USRROLE   => NULL,
                    P_ZONE      => NULL,
                    P_MDLID     => 'NONC_REALIZATION',
                    P_USRNAME   => NULL,
                    P_ETYPE     => 'BCC');
            lv_msg_bcc :=
                   lv_msg_bcc
                || ','
                || XXHIL_OM_MAIL_ALERTS_PKG.GET_ROLE_MAIL (
                       p_mdlid       => 'NONC_REALIZATION',
                       p_ou          => NULL,
                       p_mail_type   => 'BCC');
            LV_SUBJECT :=
                   'Non Copper Realization as on '
                || TO_CHAR (SYSDATE, 'DD-MON-RRRR');
            LV_MSG_TEXT :=
                'Dear Sir / Madam, Please find the attachment of Realization Report';

            XXHIL_OM_MAIL_ALERTS_PKG.INSERT_REQ_ATTCH_REC (
                REQUEST_ID    => LV_REQUEST_ID,
                MSG_FROM      => LV_MSG_FROM,
                MSG_TO        => LV_MSG_TO,
                MSG_CC        => LV_MSG_CC,
                MSG_BCC       => LV_MSG_BCC,
                MSG_SUBJECT   => LV_SUBJECT,
                MSG_TEXT      => LV_MSG_TEXT,
                FROM_FILE     => LV_FROM_FILE,
                TO_FILE       => LV_TO_FILE,
                TO_EXTN       => LV_TO_EXTN,
                WAIT_FLG      => NULL,
                CALLED_FROM   => 'XXHIL_OM_MAIL_ALERTS_PKG.NONC_REALIZATION');
        EXCEPTION
            WHEN OTHERS
            THEN
                MSG ('EXCEPTION');
                MSG ('SQLERRM = ' || SQLERRM);
                MSG ('SQLCODE = ' || SQLCODE);
        END;

        MSG ('NONC_REALIZATION END*****');
    EXCEPTION
        WHEN OTHERS
        THEN
            MSG ('NONC_REALIZATION EXCEPTION');
            MSG ('SQLERRM = ' || SQLERRM);
            MSG ('SQLCODE = ' || SQLCODE);
    END NONC_REALIZATION;

    PROCEDURE LME_EX_REGISTER
    AS
    BEGIN
        MSG ('LME_EX_REGISTER START*****');

        DECLARE
            LV_REQUEST_ID   XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
            LV_MSG_FROM     XXHIL_OM_REQ_ATTCH_MAIL.MSG_FROM%TYPE
                                := G_EMAIL_FROM;
            LV_MSG_TO       XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
            LV_MSG_CC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
            LV_MSG_BCC      XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
            LV_SUBJECT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
            LV_MSG_TEXT     XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
            LV_FROM_FILE    XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
            LV_TO_FILE      XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
            LV_TO_EXTN      XXHIL_OM_REQ_ATTCH_MAIL.TO_EXTN%TYPE := 'PDF';
            LV_FROM_DATE    DATE := TRUNC (SYSDATE - 1, 'MM');
            LV_TO_DATE      DATE := TRUNC (SYSDATE - 1);
        BEGIN
            LV_REQUEST_ID :=
                fnd_request.submit_request (
                    application   => 'XXHIL',
                    program       => 'XXHIL_OM_LME_EX_CP',
                    description   => 'XXHIL Register > LME Exchange Rate',
                    start_time    => NULL,
                    sub_request   => FALSE,
                    argument1     =>
                        TO_CHAR (LV_FROM_DATE, 'rrrr/mm/dd hh24:mi:ss'), --<P_FROM_DT>
                    argument2     =>
                        TO_CHAR (LV_TO_DATE, 'rrrr/mm/dd hh24:mi:ss'), --<P_TO_DT>
                    argument3     => 'USD',                    --<P_FROM_CURR>
                    argument4     => NULL,                      --<P_PROD_GRP>
                    argument5     => NULL                      --<P_CALL_FROM>
                                         );
            COMMIT;
            MSG ('LV_REQUEST_ID = ' || lv_request_id);
            LV_FROM_FILE := 'o' || lv_request_id || '.out';
            MSG ('LV_FROM_FILE = ' || LV_FROM_FILE);
            LV_TO_FILE := 'LME_EX_' || TO_CHAR (LV_TO_DATE, 'DDMONRR');
            MSG ('LV_TO_FILE = ' || LV_TO_FILE);

            lv_msg_to :=
                xxhil_om_mail_alerts_pkg.mail_list (
                    P_USRROLE   => NULL,
                    P_ZONE      => NULL,
                    P_MDLID     => 'LME_EX_REG',
                    P_USRNAME   => NULL,
                    P_ETYPE     => 'To');

            lv_msg_cc :=
                xxhil_om_mail_alerts_pkg.mail_list (
                    P_USRROLE   => NULL,
                    P_ZONE      => NULL,
                    P_MDLID     => 'LME_EX_REG',
                    P_USRNAME   => NULL,
                    P_ETYPE     => 'Cc');

            lv_msg_bcc :=
                xxhil_om_mail_alerts_pkg.mail_list (
                    P_USRROLE   => NULL,
                    P_ZONE      => NULL,
                    P_MDLID     => 'LME_EX_REG',
                    P_USRNAME   => NULL,
                    P_ETYPE     => 'BCC');

            LV_SUBJECT :=
                   'LME - Exchange Register as on '
                || TO_CHAR (LV_TO_DATE, 'DD-MON-RRRR');
            LV_MSG_TEXT :=
                'Dear Sir / Madam, Please find the attachment for LME, Exchange entries in system.';

            XXHIL_OM_MAIL_ALERTS_PKG.INSERT_REQ_ATTCH_REC (
                REQUEST_ID    => LV_REQUEST_ID,
                MSG_FROM      => LV_MSG_FROM,
                MSG_TO        => LV_MSG_TO,
                MSG_CC        => LV_MSG_CC,
                MSG_BCC       => LV_MSG_BCC,
                MSG_SUBJECT   => LV_SUBJECT,
                MSG_TEXT      => LV_MSG_TEXT,
                FROM_FILE     => LV_FROM_FILE,
                TO_FILE       => LV_TO_FILE,
                TO_EXTN       => LV_TO_EXTN,
                WAIT_FLG      => NULL,
                CALLED_FROM   => 'XXHIL_OM_MAIL_ALERTS_PKG.LME_EX_REGISTER');
        EXCEPTION
            WHEN OTHERS
            THEN
                MSG ('EXCEPTION');
                MSG ('SQLERRM = ' || SQLERRM);
                MSG ('SQLCODE = ' || SQLCODE);
        END;

        MSG ('LME_EX_REGISTER END*****');
    EXCEPTION
        WHEN OTHERS
        THEN
            MSG ('NONC_REALIZATION EXCEPTION');
            MSG ('SQLERRM = ' || SQLERRM);
            MSG ('SQLCODE = ' || SQLCODE);
    END LME_EX_REGISTER;

    PROCEDURE EXPIRY_SANCTION_STATUS
    AS
        l_from_email      VARCHAR2 (1000) := NULL;
        l_to_email        VARCHAR2 (2000) := NULL;
        l_cc_email        VARCHAR2 (2000) := NULL;
        l_bcc_email       VARCHAR2 (2000) := NULL;
        l_subject         VARCHAR2 (1000) := NULL;
        l_message         VARCHAR2 (32000) := NULL;

        l_attachment1     VARCHAR2 (1000) := NULL;
        l_attachment2     VARCHAR2 (1000) := NULL;
        l_attachment3     VARCHAR2 (1000) := NULL;
        l_attachment4     VARCHAR2 (1000) := NULL;
        v_error           VARCHAR2 (1000) := NULL;
        text              VARCHAR2 (32000);
        vpresent_status   VARCHAR2 (250) := 'XX';
        p_date            DATE := SYSDATE - 1;

        CURSOR c1_comm IS
            SELECT DISTINCT
                   xxhil_om_lib_pkg.get_ou_name (ou_id)     ou_name,
                   ou_id,
                   a.sbu                                    comm -- b.attribute4     comm
              FROM xxhil_om_sanction a              --, fnd_lookup_values_vl b
             WHERE     sanction_status = 'APPROVED'
                   AND sanction_term_to_dt BETWEEN TRUNC (SYSDATE) - 10
                                               AND TRUNC (SYSDATE) + 30
                   AND a.sbu = 'COPR' /*AND TO_CHAR (a.sanction_present_level) = b.meaning
                                                                                           AND LOOKUP_TYPE = 'XXHIL_OM_SANCTION_BY_ROLE'
                                                                                           AND b.attribute4 IS NOT NULL*/
                                     ;

        CURSOR c1 (p_comm VARCHAR2, p_ou NUMBER)
        IS
              SELECT xxhil_om_lib_pkg.get_ou_name (ou_id)
                         ou_name,
                     COUNT (*)
                         nos,
                     DECODE (
                         sanction_term_site_id,
                         NULL, xxhil_om_lib_pkg.customer_name (
                                   sanction_term_group_id,
                                   'CD'),
                         xxhil_om_lib_pkg.customer_name (sanction_term_site_id,
                                                         'CD'))
                         name,
                     RTRIM (
                         XMLAGG (
                             XMLELEMENT (
                                 e,
                                    sanction_header_id
                                 || ' ['
                                 || sanction_term_to_dt
                                 || ']'
                                 || ', ')).EXTRACT ('//text()'),
                         ', ')
                         sanction_nos,
                     a.sbu                                     -- b.attribute4
                FROM xxhil_om_sanction a            --, fnd_lookup_values_vl b
               WHERE     sanction_status = 'APPROVED'
                     AND sanction_term_to_dt BETWEEN TRUNC (SYSDATE) - 10
                                                 AND TRUNC (SYSDATE) + 30
                     --AND TO_CHAR (a.sanction_present_level) = b.meaning
                     -- AND b.attribute4 = p_comm
                     AND a.sbu = p_comm
                     AND a.ou_id = p_ou
            GROUP BY xxhil_om_lib_pkg.get_ou_name (ou_id),
                     DECODE (
                         sanction_term_site_id,
                         NULL, xxhil_om_lib_pkg.customer_name (
                                   sanction_term_group_id,
                                   'CD'),
                         xxhil_om_lib_pkg.customer_name (
                             sanction_term_site_id,
                             'CD')),
                     a.sbu                                    --  b.attribute4
            ORDER BY xxhil_om_lib_pkg.get_ou_name (ou_id) DESC;
    BEGIN
        l_from_email := G_EMAIL_FROM;

        FOR x IN c1_comm
        LOOP
            --l_bcc_email := 'jayant.khandelwal@adityabirla.com';
            l_message := NULL;
            text := NULL;
            l_subject :=
                   'Expiring Sanctions List for '
                || x.comm
                || ' as on '
                || p_date;

            l_message :=
                   l_message
                || '<font face = "Calibri"><b>Dear All,</b><BR>Please find herewith list of sanctions which are expiring soon or have expired recently: ';

            text :=
                   text
                || '<STYLE> table,th,td {border:1px solid Black; font-family:calibri;}</STYLE>';


            text := text || '<TABLE width="870">';

            text := text || '<TR>';

            text :=
                   text
                || '<Td width=100 align="Center" bgcolor="#C0C0C0" >OU</Td>';
            text :=
                   text
                || '<Td width=30 align="Center" bgcolor="#C0C0C0" >Nos</Td>';
            text :=
                   text
                || '<Td width=120 align="Center" bgcolor="#C0C0C0" >Customer</Td>';
            text :=
                   text
                || '<Td width=520 align="Center" bgcolor="#C0C0C0" >Sanction IDs</Td>';

            text := text || '</TR>';

            l_to_email := NULL;
            l_cc_email := NULL;
            l_bcc_email := NULL;

            MSG ('x.comm = ' || x.comm);

            l_to_email :=
                XXHIL_OM_MAIL_ALERTS_PKG.GET_sbu_ROLE_MAIL (
                    p_mdlid       => 'PEND_SANC_' || x.comm,
                    p_ou          => x.ou_name,
                    p_mail_type   => 'TO',
                    p_sbu         => x.comm);

            l_to_email :=
                   l_to_email
                || ','
                || xxhil_om_mail_alerts_pkg.mail_list (
                       P_USRROLE   => NULL,
                       P_ZONE      => NULL,
                       P_MDLID     => 'PEND_SANC_' || x.comm,
                       P_USRNAME   => NULL,
                       P_ETYPE     => 'To');
            l_cc_email :=
                XXHIL_OM_MAIL_ALERTS_PKG.GET_sbu_ROLE_MAIL (
                    p_mdlid       => 'PEND_SANC_' || x.comm,
                    p_ou          => x.ou_name,
                    p_mail_type   => 'CC',
                    p_sbu         => x.comm);

            l_cc_email :=
                   l_cc_email
                || ','
                || xxhil_om_mail_alerts_pkg.mail_list (
                       P_USRROLE   => NULL,
                       P_ZONE      => NULL,
                       P_MDLID     => 'PEND_SANC_' || x.comm,
                       P_USRNAME   => NULL,
                       P_ETYPE     => 'CC');
            l_bcc_email :=
                XXHIL_OM_MAIL_ALERTS_PKG.GET_sbu_ROLE_MAIL (
                    p_mdlid       => 'PEND_SANC_' || x.comm,
                    p_ou          => x.ou_name,
                    p_mail_type   => 'BCC',
                    p_sbu         => x.comm);
            l_bcc_email :=
                   l_bcc_email
                || ','
                || xxhil_om_mail_alerts_pkg.mail_list (
                       P_USRROLE   => NULL,
                       P_ZONE      => NULL,
                       P_MDLID     => 'PEND_SANC_' || x.comm,
                       P_USRNAME   => NULL,
                       P_ETYPE     => 'BCC');

            --IF x.comm = 'COPR'
            --THEN
            --    /*xxbc_om_mail_alerts.add_profile_email (
            --       'XXBC_OM_DOM_CU_MKTG_ROLE',
            --       'MKTG-RM',
            --       l_to_email,
            --       NULL);
            --    xxbc_om_mail_alerts.add_profile_email (
            --       'XXBC_OM_DOM_CU_MKTG_ROLE',
            --       'MKTG-MHO',
            --       l_cc_email,
            --       NULL);
            --
            --    xxbc_om_mail_alerts.add_profile_email (
            --       'XXBC_OM_DOM_CU_MKTG_ROLE',
            --       'DOM-HEAD',
            --       l_cc_email,
            --       NULL);
            --
            --    xxbc_om_mail_alerts.add_profile_email (
            --       'XXBC_OM_DOM_CU_MKTG_ROLE',
            --       'CMO',
            --       l_cc_email,
            --       NULL);
            --
            --    xxbc_om_mail_alerts.add_profile_email (
            --       'XXBC_OM_DOM_CU_MKTG_ROLE',
            --       'FIN-MHO',
            --       l_cc_email,
            --       NULL);
            --
            --
            --    xxbc_om_mail_alerts.add_profile_email (
            --       'XXBC_OM_DOM_CU_MKTG_ROLE',
            --       'ADMIN',
            --       l_bcc_email,
            --       NULL);*/
            --
            --    l_to_email :=
            --        XXHIL_OM_MAIL_ALERTS_PKG.GET_ROLE_MAIL (
            --            p_mdlid       => 'PEND_SANC_COPR',
            --            p_ou          => NULL,
            --            p_mail_type   => 'TO');
            --
            --    l_to_email :=
            --           l_to_email
            --        || ','
            --        || xxhil_om_mail_alerts_pkg.mail_list (
            --               P_USRROLE   => NULL,
            --               P_ZONE      => NULL,
            --               P_MDLID     => 'PEND_SANC_COPR',
            --               P_USRNAME   => NULL,
            --               P_ETYPE     => 'To');
            --    l_cc_email :=
            --        XXHIL_OM_MAIL_ALERTS_PKG.get_role_Mail (
            --            p_mdlid       => 'PEND_SANC_COPR',
            --            p_ou          => NULL,
            --            p_mail_type   => 'CC');
            --
            --    l_cc_email :=
            --           l_cc_email
            --        || ','
            --        || xxhil_om_mail_alerts_pkg.mail_list (
            --               P_USRROLE   => NULL,
            --               P_ZONE      => NULL,
            --               P_MDLID     => 'PEND_SANC_COPR',
            --               P_USRNAME   => NULL,
            --               P_ETYPE     => 'CC');
            --    l_bcc_email :=
            --        XXHIL_OM_MAIL_ALERTS_PKG.GET_ROLE_MAIL (
            --            p_mdlid       => 'PEND_SANC_COPR',
            --            p_ou          => NULL,
            --            p_mail_type   => 'BCC');
            --    l_bcc_email :=
            --           l_bcc_email
            --        || ','
            --        || xxhil_om_mail_alerts_pkg.mail_list (
            --               P_USRROLE   => NULL,
            --               P_ZONE      => NULL,
            --               P_MDLID     => 'PEND_SANC_COPR',
            --               P_USRNAME   => NULL,
            --               P_ETYPE     => 'BCC');
            --ELSE
            --    /*xxbc_om_mail_alerts.add_profile_email (
            --       'XXBC_OM_DOM_CU_MKTG_ROLE',
            --       'MKTG-NONC-RM',
            --       l_to_email,
            --       NULL);
            --
            --    xxbc_om_mail_alerts.add_profile_email (
            --       'XXBC_OM_DOM_CU_MKTG_ROLE',
            --       'MKTG-NONC-OTHER',
            --       l_cc_email,
            --       NULL);
            --
            --    xxbc_om_mail_alerts.add_profile_email (
            --       'XXBC_OM_DOM_CU_MKTG_ROLE',
            --       'MKTG-NONC',
            --       l_cc_email,
            --       NULL);
            --
            --
            --    xxbc_om_mail_alerts.add_profile_email (
            --       'XXBC_OM_DOM_CU_MKTG_ROLE',
            --       'ADMIN',
            --       l_bcc_email,
            --       NULL);*/
            --    l_to_email :=
            --        XXHIL_OM_MAIL_ALERTS_PKG.GET_ROLE_MAIL (
            --            p_mdlid       => 'PEND_SANC_NONC',
            --            p_ou          => NULL,
            --            p_mail_type   => 'TO');
            --    l_cc_email :=
            --        XXHIL_OM_MAIL_ALERTS_PKG.get_role_Mail (
            --            p_mdlid       => 'PEND_SANC_NONC',
            --            p_ou          => NULL,
            --            p_mail_type   => 'CC');
            --    l_bcc_email :=
            --        XXHIL_OM_MAIL_ALERTS_PKG.GET_ROLE_MAIL (
            --            p_mdlid       => 'PEND_SANC_NONC',
            --            p_ou          => NULL,
            --            p_mail_type   => 'BCC');
            --END IF;

            FOR i IN c1 (x.comm, x.ou_id)
            LOOP
                /*IF i.present_status <> vpresent_status
                THEN
                   vpresent_status := i.present_status;
                   text := text || '<TR>';
                   text :=
                         text
                      || '<TD Rowspan = '
                      || i.row_cnt
                      || ' align = "Left"BgColor = "#FFFF99"><I>'
                      || vpresent_status
                      || '</I></TD>';
                END IF;*/

                --Text := Text || '<TD align="Left">' || i.PRESENT_STATUS || '</TD>';
                text := text || '<TD>' || i.ou_name || '</TD>';
                text := text || '<TD align="Center">' || i.nos || '</TD>';
                text := text || '<TD align="Center">' || i.name || '</TD>';
                text :=
                       text
                    || '<TD align="Left">'
                    || LTRIM (RTRIM (i.sanction_nos))
                    || '</TD>';


                text := text || '</TR>';
            END LOOP;

            text := text || '</TABLE><BR>';

            l_message :=
                   l_message
                || text
                || '<BR>Thank You,</font><BR><BR> NOTE: This is a System Generated Mail, Please do not reply.<BR><BR>';

            XXHIL_OM_MAIL_ALERTS_PKG.INSERT_REQ_ATTCH_REC (
                REQUEST_ID    => NULL,
                MSG_FROM      => L_FROM_EMAIL,
                MSG_TO        => L_TO_EMAIL,
                MSG_CC        => L_CC_EMAIL,
                MSG_BCC       => L_BCC_EMAIL,
                MSG_SUBJECT   => L_SUBJECT,
                MSG_TEXT      => L_MESSAGE,
                FROM_FILE     => NULL,
                TO_FILE       => NULL,
                TO_EXTN       => NULL,
                WAIT_FLG      => NULL,
                CALLED_FROM   =>
                    'XXHIL_OM_MAIL_ALERTS_PKG.EXPIRY_SANCTION_STATUS');
        --xxsendmail ('XX_SCH_DIR',
        --            l_from_email,
        --            l_to_email,
        --            l_cc_email,
        --            l_bcc_email,
        --            l_subject,
        --            l_message,
        --            l_attachment1);
        END LOOP;
    END EXPIRY_SANCTION_STATUS;

    PROCEDURE DELETE_UNDERLOAD
    IS
        CURSOR c_record IS
            SELECT ls_no, org_id, inv.tren_id
              FROM xxhil_om_invoice_hdr inv
             WHERE     delivery_id IS NULL
                   AND (   (    rr_lr_dt < TRUNC (SYSDATE) - 15
                            AND NVL (tren_id, 1) = 1)
                        OR (    tren_id <> 1
                            AND EXISTS
                                    (SELECT 'x'
                                       FROM XXHIL_WEIGHBRIDGE_DETAILS trk
                                      WHERE     1 = 1
                                            AND trk.tren_id = inv.tren_id
                                            AND SOURCE_LOCATION =
                                                xxhil_om_lib_pkg.get_org_cd (
                                                    inv.Org_id)
                                            AND OUTER_GATE_OUT_TIMESTAMP
                                                    IS NOT NULL))
                        OR NOT EXISTS
                               (SELECT 'x'
                                  FROM xxhil_om_pending_do_v
                                 WHERE dohd_id = source_header_id));
    BEGIN
        XXHIL_OM_LIB_PKG.MSG ('DELETE_UNDERLOAD START');

        FOR i IN c_record
        LOOP
            DELETE FROM xxhil_om_invoice_dtl
                  WHERE ls_no = i.ls_no AND org_id = i.org_id;

            DELETE FROM xxhil_om_invoice_hdr
                  WHERE ls_no = i.ls_no AND org_id = i.org_id;
        END LOOP;

        COMMIT;
        XXHIL_OM_LIB_PKG.MSG ('DELETE_UNDERLOAD END');
    EXCEPTION
        WHEN OTHERS
        THEN
            XXHIL_OM_LIB_PKG.MSG (
                'DELETE_UNDERLOAD EXCEPTION SQLERRM:' || SQLERRM);
    END DELETE_UNDERLOAD;

    PROCEDURE SALES_AGREEMENT_EXPIRY
    IS
        is_mailable      BOOLEAN;
        l_mail_subject   VARCHAR2 (4000);
        l_html_txt       VARCHAR2 (4000);
        l_to_mail        VARCHAR2 (4000);
        l_cc_mail        VARCHAR2 (4000);
        l_bcc_mail       VARCHAR2 (4000);
        l_from_mail      VARCHAR2 (4000) := G_EMAIL_FROM;
        l_expiry_days    NUMBER;
        l_cnt            NUMBER;
    BEGIN
        is_mailable := TRUE;
        l_expiry_days := 5;

        l_mail_subject :=
               'Sales Agreement Expires Within '
            || l_expiry_days
            || ' Days from '
            || TO_CHAR (SYSDATE, 'DD-MON-RRRR');

        l_html_txt := '<!DOCTYPE html>';
        l_html_txt := l_html_txt || '<html>';
        l_html_txt := l_html_txt || '<head>';
        l_html_txt := l_html_txt || '<style type=text/css>';
        l_html_txt := l_html_txt || 'table{border-collapse:collapse;}';
        l_html_txt :=
               l_html_txt
            || 'th{background-color:#cfe0f1;text-indent:1;border: 1px solid black;vertical-align:top;}';
        l_html_txt :=
               l_html_txt
            || 'td{background-color:#f2f2f5;border:1px solid black;vertical-align:top;}';
        l_html_txt := l_html_txt || '</style>';
        l_html_txt := l_html_txt || '</head>';
        l_html_txt := l_html_txt || '<body>';

        l_html_txt := l_html_txt || '<table>';

        l_html_txt :=
               l_html_txt
            || '<tr><th colspan=5 align="center">Sales Agreement Expires Within '
            || l_expiry_days
            || ' Days from '
            || TO_CHAR (SYSDATE, 'DD-MON-RRRR')
            || '</th></tr>';

        l_html_txt := l_html_txt || '<tr>';
        l_html_txt :=
            l_html_txt || '<th width=50>Sales Agreement Number</th>';
        l_html_txt := l_html_txt || '<th>Customer</td>';
        l_html_txt := l_html_txt || '<th>Item</td>';
        l_html_txt := l_html_txt || '<th>Activation Date</td>';
        l_html_txt := l_html_txt || '<th>Expiration Date</td>';
        l_html_txt := l_html_txt || '</tr>';

        l_cnt := 0;

        FOR i
            IN (SELECT a.order_number,
                       xxhil_om_lib_pkg.customer_name (a.sold_to_org_id,
                                                       'ACC')
                           customer_name,
                       prd.prod_short_desc,
                       c.start_date_active,
                       c.end_date_active,
                       prd.prod_grp
                           prod_grp
                  FROM oe_blanket_headers_all  a,
                       oe_blanket_lines_all    b,
                       oe_blanket_lines_ext    c,
                       xxhil_om_prod_v         prd
                 WHERE     a.header_id = b.header_id
                       AND b.line_id = c.line_id(+)
                       AND b.inventory_item_id = prd.prod_cd
                       --AND prd.prod_grp = 'SCRAP'
                       AND c.end_date_active IS NOT NULL
                       AND TRUNC (c.end_date_active) BETWEEN TRUNC (SYSDATE)
                                                         AND   TRUNC (
                                                                   SYSDATE)
                                                             + l_expiry_days)
        LOOP
            l_html_txt := l_html_txt || '<tr>';
            l_html_txt := l_html_txt || '<td>' || i.order_number || '</td>';
            l_html_txt := l_html_txt || '<td>' || i.customer_name || '</td>';
            l_html_txt :=
                l_html_txt || '<td>' || i.prod_short_desc || '</td>';
            l_html_txt :=
                   l_html_txt
                || '<td>'
                || TO_CHAR (TRUNC (i.start_date_active), 'DD-MON-RRRR')
                || '</td>';
            l_html_txt :=
                   l_html_txt
                || '<td>'
                || TO_CHAR (TRUNC (i.end_date_active), 'DD-MON-RRRR')
                || '</td>';
            l_html_txt := l_html_txt || '</tr>';
            l_cnt := l_cnt + 1;
        END LOOP;

        IF l_cnt = 0
        THEN
            l_html_txt :=
                   l_html_txt
                || '<tr><td colspan=5 align="center">No Sales Agreement Expires Within '
                || l_expiry_days
                || ' Days</td></tr>';
        END IF;

        l_html_txt := l_html_txt || '</table>';

        /*xxbc_om_mail_alerts.add_profile_email ('XXBC_OM_DOM_CU_MKTG_ROLE',
                                               'SCRAP',
                                               l_to_mail,
                                               NULL);*/

        l_to_mail :=
            xxhil_om_mail_alerts_pkg.get_role_mail ('SCRAP_AGREEMENT_EXPIRY',
                                                    NULL,
                                                    'TO');
        l_cc_mail := NULL;
        /*xxbc_om_mail_alerts.add_profile_email ('XXBC_OM_DOM_CU_MKTG_ROLE',
                                               'ADMIN',
                                               l_bcc_mail,
                                               NULL);*/

        xxhil_om_mail_alerts_pkg.insert_req_attch_rec (
            request_id    => NULL,
            msg_from      => l_from_mail,
            msg_to        => l_to_mail,
            msg_cc        => l_cc_mail,
            msg_bcc       => l_bcc_mail,
            msg_subject   => l_mail_subject,
            msg_text      => l_html_txt,
            from_file     => NULL,
            to_file       => NULL,
            to_extn       => NULL,
            wait_flg      => NULL,
            called_from   => 'XXHIL_OM_MAIL_ALERTS_PKG.SALES_AGREEMENT_EXPIRY');
    END SALES_AGREEMENT_EXPIRY;

    PROCEDURE OPEN_EXCHANGE_RATE (p_commodity VARCHAR2)
    IS
        l_cnt            NUMBER;
        l_mail_subject   VARCHAR2 (1000);
        l_html_txt       VARCHAR2 (4000);
        l_from_id        VARCHAR2 (4000);
        l_to_id          VARCHAR2 (4000);
        l_cc_id          VARCHAR2 (4000);
        l_bcc_id         VARCHAR2 (4000);
        l_dt_qty         VARCHAR2 (1000);
    BEGIN
        l_mail_subject :=
               'Open Exchange Rate Option for '
            || p_commodity
            || ' As On '
            || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI');

        l_html_txt :=
               '<!DOCTYPE html>'
            || '<html>'
            || '<head>'
            || '<style type=text/css>table{border-collapse:collapse;} th{background-color:#cfe0f1;text-indent:1;border: 1px solid black;vertical-align:top;} td{background-color:#f2f2f5;border:1px solid black;vertical-align:top;}</style>'
            || '</head>'
            || '<body>';

        l_html_txt := l_html_txt || '<table>';

        l_html_txt :=
               l_html_txt
            || '<tr><th colspan=7 align="Left">Forex Not Entered By Marketing</th></tr>';

        l_html_txt := l_html_txt || '<tr>';
        l_html_txt := l_html_txt || '<th>Region</th>';
        l_html_txt := l_html_txt || '<th>Commodity</th>';
        l_html_txt := l_html_txt || '<th>QP Number</th>';
        l_html_txt := l_html_txt || '<th>QP Date</th>';
        l_html_txt := l_html_txt || '<th>Quantity</th>';
        l_html_txt := l_html_txt || '<th>Price</th>';
        l_html_txt := l_html_txt || '<th>Customer</th>';
        l_html_txt := l_html_txt || '</tr>';

        l_cnt := 0;

        FOR i IN (  SELECT *
                      FROM xxHIL_om_prcreq a
                     WHERE     fx_req_flg = 'Y'
                           --AND commodity = 'COPR'  -- Commented by Gaurav on 04-Nov
                           AND commodity = p_commodity
                           AND status <> 'CANCEL'
                           AND request_date >= ADD_MONTHS (SYSDATE, -36)
                           AND NOT EXISTS
                                   (SELECT 'x'
                                      FROM xxhil_om_fxreq b
                                     WHERE a.request_id = b.request_id)
                           AND ref_request_id IS NULL
                  ORDER BY commodity, region, request_date)
        LOOP
            l_cnt := l_cnt + 1;
            l_html_txt := l_html_txt || '<tr>';

            l_html_txt := l_html_txt || '<td>' || i.region || '</td>';
            l_html_txt := l_html_txt || '<td>' || i.commodity || '</td>';
            l_html_txt := l_html_txt || '<td>' || i.request_id || '</td>';
            l_html_txt := l_html_txt || '<td>' || i.request_date || '</td>';
            l_html_txt :=
                l_html_txt || '<td align=right>' || i.informed_qty || '</td>';
            l_html_txt :=
                   l_html_txt
                || '<td align=right>'
                || NVL (i.request_lme_rate, i.qp_price)
                || '</td>';
            l_html_txt :=
                   l_html_txt
                || '<td>'
                || i.party_id
                || '-'
                || xxhil_om_lib_pkg.customer_name (i.party_id, 'CD')
                || '</td>';
            l_html_txt := l_html_txt || '</tr>';
        END LOOP;

        IF l_cnt = 0
        THEN
            l_html_txt :=
                   l_html_txt
                || '<tr><td colspan=7 align="center">No Data Available.</td></tr>';
        END IF;

        l_html_txt := l_html_txt || '</table>';

        l_html_txt := l_html_txt || '<br>';

        l_html_txt := l_html_txt || '<table>';

        l_html_txt :=
               l_html_txt
            || '<tr><th colspan=7 align="Left">Confirmation Pending From Risk Management.</th></tr>';

        l_html_txt := l_html_txt || '<tr>';
        l_html_txt := l_html_txt || '<th>Region</th>';
        l_html_txt := l_html_txt || '<th>Commodity</th>';
        l_html_txt := l_html_txt || '<th>QP Number</th>';
        l_html_txt := l_html_txt || '<th>QP Date</th>';
        l_html_txt := l_html_txt || '<th>Quantity</th>';
        l_html_txt := l_html_txt || '<th>Price</th>';
        l_html_txt := l_html_txt || '<th>Customer</th>';
        l_html_txt := l_html_txt || '</tr>';

        l_cnt := 0;

        FOR i
            IN (  SELECT *
                    FROM xxhil_om_prcreq a
                   WHERE     fx_req_flg = 'Y'
                         --AND commodity = 'COPR'
                         AND commodity = p_commodity
                         AND status <> 'CANCEL'
                         AND EXISTS
                                 (SELECT 'x'
                                    FROM xxhil_om_fxreq b
                                   WHERE     a.request_id = b.request_id
                                         AND b.fx_status IN ('OPEN', 'FINAL'))
                         AND ref_request_id IS NULL
                ORDER BY commodity, region, request_date)
        LOOP
            l_cnt := l_cnt + 1;
            l_html_txt := l_html_txt || '<tr>';

            l_html_txt := l_html_txt || '<td>' || i.region || '</td>';
            l_html_txt := l_html_txt || '<td>' || i.commodity || '</td>';
            l_html_txt := l_html_txt || '<td>' || i.request_id || '</td>';
            l_html_txt := l_html_txt || '<td>' || i.request_date || '</td>';
            l_html_txt :=
                l_html_txt || '<td align=right>' || i.informed_qty || '</td>';
            l_html_txt :=
                   l_html_txt
                || '<td align=right>'
                || NVL (i.request_lme_rate, i.qp_price)
                || '</td>';
            l_html_txt :=
                   l_html_txt
                || '<td>'
                || i.party_id
                || '-'
                || xxhil_om_lib_pkg.customer_name (i.party_id, 'CD')
                || '</td>';
            l_html_txt := l_html_txt || '</tr>';
        END LOOP;

        IF l_cnt = 0
        THEN
            l_html_txt :=
                   l_html_txt
                || '<tr><td colspan=7 align="center">No Data Available.</td></tr>';
        END IF;

        l_html_txt := l_html_txt || '</table>';
        l_html_txt := l_html_txt || '</body>';
        l_html_txt := l_html_txt || '</html>';


        l_to_id :=
            xxhil_om_mail_alerts_pkg.get_role_mail ('UNWIND_COPR',
                                                    NULL,
                                                    'TO');

        l_to_id :=
               l_to_id
            || ','
            || xxhil_om_mail_alerts_pkg.mail_list (NULL,
                                                   NULL,
                                                   'UNWIND_COPR',
                                                   NULL,
                                                   'To');

        l_cc_id :=
            xxhil_om_mail_alerts_pkg.get_role_mail ('UNWIND_COPR',
                                                    NULL,
                                                    'CC');
        l_bcc_id :=
            xxhil_om_mail_alerts_pkg.get_role_mail ('UNWIND_COPR',
                                                    NULL,
                                                    'BCC');

        SELECT G_EMAIL_FROM --DBMS_RANDOM.string ('X', 7) || '@adityabirla.com'     str
                           INTO l_from_id FROM DUAL;

        xxhil_om_mail_alerts_pkg.insert_req_attch_rec (
            request_id    => NULL,
            msg_from      => l_from_id,
            msg_to        => l_to_id,
            msg_cc        => l_cc_id,
            msg_bcc       => l_bcc_id,
            msg_subject   => l_mail_subject,
            msg_text      => l_html_txt,
            from_file     => NULL,
            to_file       => NULL,
            to_extn       => NULL,
            wait_flg      => NULL,
            called_from   => 'XXHIL_OM_MAIL_ALERTS_PKG.OPEN_EXCHANGE_RATE');
    END OPEN_EXCHANGE_RATE;

    PROCEDURE RECO
    AS
    BEGIN
        MSG ('RECO START');

        DELETE FROM XXHIL_OM_SYS_RECO
              WHERE TRUNC (CREATION_DATE) = TRUNC (SYSDATE);

        DECLARE
            LV_ERRBUF    VARCHAR2 (32767);
            LV_RETCODE   VARCHAR2 (32767);
        BEGIN
            XXHIL_OM_SYS_RECO_PKG.MAIN_P (ERRBUF    => LV_ERRBUF,
                                          RETCODE   => LV_RETCODE,
                                          P_TYPE    => 'ALL');
        END;


        DECLARE
            LV_REQUEST_ID   XXHIL_OM_REQ_ATTCH_MAIL.REQUEST_ID%TYPE;
            LV_MSG_TO       XXHIL_OM_REQ_ATTCH_MAIL.MSG_TO%TYPE;
            LV_MSG_CC       XXHIL_OM_REQ_ATTCH_MAIL.MSG_CC%TYPE;
            LV_MSG_BCC      XXHIL_OM_REQ_ATTCH_MAIL.MSG_BCC%TYPE;
            LV_SUBJECT      XXHIL_OM_REQ_ATTCH_MAIL.MSG_SUBJECT%TYPE;
            LV_MSG_TEXT     XXHIL_OM_REQ_ATTCH_MAIL.MSG_TEXT%TYPE;
            LV_FROM_FILE    XXHIL_OM_REQ_ATTCH_MAIL.FROM_FILE%TYPE;
            LV_TO_FILE      XXHIL_OM_REQ_ATTCH_MAIL.TO_FILE%TYPE;
            LV_XML_LAYOUT   BOOLEAN;
        BEGIN
            LV_XML_LAYOUT :=
                FND_REQUEST.ADD_LAYOUT (
                    TEMPLATE_APPL_NAME   => 'XXHIL',
                    TEMPLATE_CODE        => 'XXHIL_OM_SYS_RECO_CP',
                    TEMPLATE_LANGUAGE    => 'en',
                    TEMPLATE_TERRITORY   => 'US',
                    OUTPUT_FORMAT        => 'EXCEL');

            LV_REQUEST_ID :=
                fnd_request.submit_request (
                    application   => 'XXHIL',
                    program       => 'XXHIL_OM_SYS_RECO_CP',
                    description   => 'XXHIL OTC Register > System Reco',
                    start_time    => NULL,
                    sub_request   => FALSE,
                    argument1     => NULL                             --<P_DT>
                                         );

            LV_MSG_TO :=
                XXHIL_OM_MAIL_ALERTS_PKG.MAIL_LIST (
                    P_USRROLE   => NULL,
                    P_ZONE      => NULL,
                    P_MDLID     => 'OM_CORE_USER',
                    P_USRNAME   => NULL,
                    P_ETYPE     => 'TO');

            LV_MSG_CC :=
                XXHIL_OM_MAIL_ALERTS_PKG.MAIL_LIST (
                    P_USRROLE   => NULL,
                    P_ZONE      => NULL,
                    P_MDLID     => 'OM_CORE_USER',
                    P_USRNAME   => NULL,
                    P_ETYPE     => 'CC');

            LV_MSG_BCC :=
                XXHIL_OM_MAIL_ALERTS_PKG.MAIL_LIST (
                    P_USRROLE   => NULL,
                    P_ZONE      => NULL,
                    P_MDLID     => 'OM_CORE_USER',
                    P_USRNAME   => NULL,
                    P_ETYPE     => 'BCC');

            LV_SUBJECT := 'System Reco Status as on ' || SYSDATE;
            LV_MSG_TEXT :=
                'Dear Sir / Madam, Please find the attachment of System Status Report ';

            LV_FROM_FILE := '' || 'o' || LV_REQUEST_ID || '.out' || '';

            LV_TO_FILE :=
                '' || 'HILSYSRECO_' || TO_CHAR (SYSDATE, 'DDMMRR') || '';

            XXHIL_OM_MAIL_ALERTS_PKG.INSERT_REQ_ATTCH_REC (
                REQUEST_ID    => LV_REQUEST_ID,
                MSG_FROM      => G_EMAIL_FROM,
                MSG_TO        => LV_MSG_TO,
                MSG_CC        => LV_MSG_CC,
                MSG_BCC       => LV_MSG_BCC,
                MSG_SUBJECT   => LV_SUBJECT,
                MSG_TEXT      => LV_MSG_TEXT,
                FROM_FILE     => LV_FROM_FILE,
                TO_FILE       => LV_TO_FILE,
                TO_EXTN       => 'xls',
                WAIT_FLG      => NULL,
                CALLED_FROM   => 'XXHIL_OM_MAIL_ALERTS_PKG.RECO');
        END;

        MSG ('RECO END');
    END RECO;
END XXHIL_OM_MAIL_ALERTS_PKG;
/
SHOW ERROR;
EXIT;
