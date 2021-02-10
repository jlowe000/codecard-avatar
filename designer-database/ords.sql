set define off;

DECLARE

BEGIN
  ORDS.DEFINE_MODULE(
      p_module_name    => 'functions',
      p_base_path      => '/functions/',
      p_items_per_page => 25,
      p_status         => 'PUBLISHED',
      p_comments       => NULL);

  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'functions',
      p_pattern        => 'master',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'functions',
      p_pattern        => 'master',
      p_method         => 'GET',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => '',
      p_comments       => NULL,
      p_source         => 
'declare
	tmp_badgeId VARCHAR2(20);
	tmp_buttonLabel VARCHAR2(2);
	tmp_buttonFunction VARCHAR2(10);
	tmp_template VARCHAR2(12);
	tmp_title VARCHAR2(50);
	tmp_subtitle VARCHAR2(100);
	tmp_bodytext VARCHAR2(200);
	tmp_icon VARCHAR2(200);
	tmp_badge VARCHAR2(5);
	tmp_backgorundImage VARCHAR2(200);
	tmp_backgroundColor VARCHAR2(10);
    tmp_fingerprint VARCHAR2(200);
	tmp_barcode VARCHAR2(50);
    tmp_function VARCHAR2(20);
begin
    select
        BADGEID, BUTTONLABEL, BUTTONFUNCTION, TEMPLATE, TITLE, SUBTITLE, BODYTEXT, ICON, BADGE, BACKGROUNDIMAGE, BACKGROUNDCOLOR, FINGERPRINT, BARCODE
    into
        tmp_badgeId, tmp_buttonLabel, tmp_buttonFunction, tmp_template, tmp_title, tmp_subtitle, tmp_bodytext, tmp_icon, tmp_badge, tmp_backgorundImage, tmp_backgroundColor, tmp_fingerprint, tmp_barcode
    from CODEMAKER
    where upper(BADGEID) = upper(:badgeid) and BUTTONLABEL = :buttonlabel and BUTTONFUNCTION = :buttonfunction;
    
    APEX_JSON.open_object;
    APEX_JSON.write(''template'', tmp_template);
    APEX_JSON.write_raw(''title'', ''"'' || tmp_title || ''"'');
    APEX_JSON.write_raw(''subtitle'', ''"'' || tmp_subtitle || ''"'');
    APEX_JSON.write_raw(''bodytext'', ''"'' ||tmp_bodytext || ''"'');
    APEX_JSON.write(''icon'', tmp_icon);
    APEX_JSON.write(''badge'', tmp_badge);
    APEX_JSON.write(''backgroundImage'', tmp_backgorundImage);
    APEX_JSON.write(''backgroundColor'', tmp_backgroundColor);
    APEX_JSON.write(''fingerprint'', tmp_fingerprint);
    APEX_JSON.write(''barcode'', tmp_barcode);
    APEX_JSON.close_object;
    
    EXCEPTION
        WHEN OTHERS THEN
        
        if :buttonfunction = ''1'' then
            tmp_function := ''Button '' ||  UPPER(:buttonlabel) || '' short press'';
        elsif :buttonfunction = ''2'' then
            tmp_function := ''Button '' ||  UPPER(:buttonlabel) ||'' long press'';
        else
           tmp_function := ''No button pressed''; 
        end if;

        APEX_JSON.open_object;
        APEX_JSON.write(''template'', ''template1'');
        APEX_JSON.write(''title'', ''Uh oh!'');
        APEX_JSON.write(''subtitle'', tmp_function);
        APEX_JSON.write(''bodytext'', ''You have not configured your Code Card'');
        APEX_JSON.write(''icon'', ''fail'');
        APEX_JSON.close_object;        
end;');

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'functions',
      p_pattern            => 'master',
      p_method             => 'GET',
      p_name               => 'X-CODECARD-BUTTON-FUNCTION',
      p_bind_variable_name => 'buttonfunction',
      p_source_type        => 'HEADER',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'functions',
      p_pattern            => 'master',
      p_method             => 'GET',
      p_name               => 'X-CODECARD-BUTTON-LABEL',
      p_bind_variable_name => 'buttonlabel',
      p_source_type        => 'HEADER',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'functions',
      p_pattern            => 'master',
      p_method             => 'GET',
      p_name               => 'X-CODECARD-ID',
      p_bind_variable_name => 'badgeid',
      p_source_type        => 'HEADER',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'functions',
      p_pattern        => 'master',
      p_method         => 'POST',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => 'application/json',
      p_comments       => NULL,
      p_source         => 
'declare
    tmpId number;
    tmpTitle varchar2(1000);
    tmpSubtitle varchar2(1000);
    tmpBody varchar2(1000);
begin

    tmpTitle := regexp_replace(:title, ''<.*?>'');
    tmpSubtitle := regexp_replace(:subtitle, ''<.*?>'');
    tmpBody := regexp_replace(:bodytext, ''<.*?>'');

    insert into CODEMAKER (
        BADGEID, BUTTONLABEL, BUTTONFUNCTION, TEMPLATE, TITLE, SUBTITLE, BODYTEXT, ICON, BADGE, BACKGROUNDIMAGE, BACKGROUNDCOLOR, FINGERPRINT, BARCODE
    ) 
    values (
        upper(:badgeId), :buttonLabel, :buttonFunction, :template, tmpTitle, tmpSubtitle, tmpBody, :icon, :badge, :backgorundImage, :backgroundColor, :fingerprint, :barcode
    )
    returning id into tmpId;
    
    APEX_JSON.open_object;
    APEX_JSON.write(''badgeId'', upper(:badgeId));
    APEX_JSON.write(''status'', ''new'');
    APEX_JSON.write(''recordId'', tmpId);
    APEX_JSON.close_object;
    
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
        update CODEMAKER set 
        TEMPLATE = :template, 
        TITLE = tmpTitle, 
        SUBTITLE = tmpSubtitle, 
        BODYTEXT = tmpBody, 
        ICON = :icon,
        BADGE = :badge,
        BACKGROUNDIMAGE = :backgroundImage,
        BACKGROUNDCOLOR = :backgroundColor,
        FINGERPRINT = :fingerprint,
        BARCODE = :barcode
        where BADGEID = upper(:badgeId) and BUTTONLABEL = :buttonlabel and BUTTONFUNCTION = :buttonfunction
        returning id into tmpId;
        commit;

        APEX_JSON.open_object;
        APEX_JSON.write(''badgeId'', upper(:badgeId));
        APEX_JSON.write(''reacordId'', tmpId);
        APEX_JSON.close_object;
    
end;');

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'functions',
      p_pattern            => 'master',
      p_method             => 'POST',
      p_name               => 'X-CODECARD-BUTTON-FUNCTION',
      p_bind_variable_name => 'buttonFunction',
      p_source_type        => 'HEADER',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'functions',
      p_pattern            => 'master',
      p_method             => 'POST',
      p_name               => 'X-CODECARD-BUTTON-LABEL',
      p_bind_variable_name => 'buttonLabel',
      p_source_type        => 'HEADER',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'functions',
      p_pattern            => 'master',
      p_method             => 'POST',
      p_name               => 'X-CODECARD-ID',
      p_bind_variable_name => 'badgeId',
      p_source_type        => 'HEADER',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'functions',
      p_pattern        => 'register',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'functions',
      p_pattern        => 'register',
      p_method         => 'POST',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => 'application/json',
      p_comments       => NULL,
      p_source         => 
'declare
    tmpBadgeId varchar2(100);
begin
    
    insert into CODECARD (
        BADGEID, NAME, CREATED
    ) 
    values (
        UPPER(:badgeId), INITCAP(:name), systimestamp
    );
    
    APEX_JSON.open_object;
    APEX_JSON.write(''badgeId'', upper(:badgeId));
    APEX_JSON.write(''status'', ''registered'');
    APEX_JSON.close_object;
    
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
        UPDATE CODECARD set NAME = INITCAP(:name) where BADGEID = upper(:badgeId);
        APEX_JSON.open_object;
        APEX_JSON.write(''badgeId'', upper(:badgeId));
        APEX_JSON.write(''status'', ''logged'');
        APEX_JSON.close_object;
    
end;');

COMMIT;

END;
