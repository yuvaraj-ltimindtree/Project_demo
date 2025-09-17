CREATE PROCEDURE APPS.XXHIL_DBA_AZURE_TEST_PRC_03 (p_name VARCHAR2)
IS
    m_srno        NUMBER(4);
BEGIN
    m_srno := 0;
    SELECT    APPS.XXHIL_DBA_AZURE_TEST_SEQ_03.NEXTVAL
    INTO    m_srno 
    FROM    DUAL;

   INSERT INTO XXHIL_DBA_AZURE_TEST_TAB_03
--       (srno, 
--        name)
   VALUES
        (m_srno,
        p_name);
        COMMIT;
END;
/
exit