**********************************************************************;
* Author            : Toshiki Saito
* Purpose           : Create MHCOD DataSet
**********************************************************************;

/*** Initial setting ***/
%MACRO CURRENT_DIR;

    %LOCAL _FULLPATH _PATH;
    %LET   _FULLPATH = ;
    %LET   _PATH     = ;

    %IF %LENGTH(%SYSFUNC(GETOPTION(SYSIN))) = 0 %THEN
        %LET _FULLPATH = %SYSGET(SAS_EXECFILEPATH);
    %ELSE
        %LET _FULLPATH = %SYSFUNC(GETOPTION(SYSIN));

    %LET _PATH = %SUBSTR(   &_FULLPATH., 1, %LENGTH(&_FULLPATH.)
                          - %LENGTH(%SCAN(&_FULLPATH.,-1,'\')) -1 );

    &_PATH.

%MEND CURRENT_DIR;

%LET _PATH2 = %CURRENT_DIR;
%LET FILE = ADS;

%INCLUDE "&_PATH2.\JSH201609_ADS_LIBNAME.sas";

/*** CSV read ***/
FILENAME IN "&EXT.\disease_161021.csv" Encoding="utf-8";
PROC IMPORT OUT= MHCOD
  DATAFILE=IN
  DBMS=CSV REPLACE;
  GETNAMES=NO;
  DATAROW=2;
  GUESSINGROWS=2000; 
RUN;
PROC DATASETS;
  MODIFY MHCOD;
  RENAME VAR1=category VAR2=code VAR3=abbr VAR4=name_ja VAR5=name_en VAR6=order VAR7=group_code VAR8=group_abbr VAR9=group_name_ja VAR10=group_name_en VAR11=group_type VAR12=group_order;
  RENAME order=MHDECOD group_code=MHGRPCOD name_ja=MHTERM_J group_name_ja=MHGRPTERM_J abbr=MHTERM group_abbr=MHGRPTERM;
QUIT;