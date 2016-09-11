﻿**********************************************************************;
* Project           : JSH201609
*
* Program name      : JSH201609_STAT_MH001.sas
*
* Author            : MATSUO YAMAMOTO
*
* Date created      : 20160908
*
* Purpose           :
*
* Revision History  :
*
* Date        Author           Ref    Revision (Date in YYYYMMDD format)
* YYYYMMDD    XXXXXX XXXXXXXX  1      XXXXXXXXXXXXXXXXXXXXXXXXXXXX
*
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
%LET FILE = MH001;

%INCLUDE "&_PATH2.\JSH201609_STAT_LIBNAME.sas";

/*** Template Open ***/
%XLSOPEN(JSH201609_STAT_RES_&FILE..xlsx);

/*** ADS read ***/
%MACRO DS_READ(LIB,DS);
  DATA  &DS.;
    SET  &LIB..&DS.;
    FORMAT _ALL_;
    INFORMAT _ALL_;
  RUN ;
%MEND ;
%DS_READ(LIBADS,ADS);

*** ALL;
ODS GRAPHICS ON / HEIGHT = 9CM WIDTH = 12CM IMAGENAME = "&FILE."
  OUTPUTFMT = PNG RESET = INDEX   ANTIALIASMAX=96100;
ODS LISTING GPATH = "&OUTG." IMAGE_DPI = 300 ;

PROC TEMPLATE;
  DEFINE STATGRAPH MYPIECHART;
    DYNAMIC _X;
    BEGINGRAPH;
    ENTRYTITLE "全体";
      LAYOUT REGION;
        PIECHART CATEGORY=_X 
          /   NAME="MHGRPTERM"
              DATALABELCONTENT=(PERCENT)
              DATALABELLOCATION=CALLOUT
              OTHERSLICE=TRUE
              OTHERSLICEOPTS=(TYPE=MAXSLICES MAXSLICES=9);
              DISCRETELEGEND 'MHGRPTERM' ;
      ENDLAYOUT;
    ENDGRAPH;
  END;
RUN;

PROC SGRENDER DATA=ADS TEMPLATE=MYPIECHART;
  DYNAMIC _X='MHGRPTERM';
RUN;

*** SUB;

%MACRO PIE(TIT,ID);

  DATA  PIE&ID.;
    SET  ADS;
    IF MHGRPCOD=&ID.;
  RUN ;

  ODS GRAPHICS ON / HEIGHT = 9CM WIDTH = 12CM IMAGENAME = "&FILE.&ID."
    OUTPUTFMT = PNG RESET = INDEX   ANTIALIASMAX=96100;
  ODS LISTING GPATH = "&OUTG." IMAGE_DPI = 300 ;

  PROC TEMPLATE;
    DEFINE STATGRAPH MYPIECHART;
      DYNAMIC _X;
      BEGINGRAPH;
        ENTRYTITLE "&TIT.";
        LAYOUT REGION;
          PIECHART CATEGORY=_X 
            /   NAME="MHTERM"
                DATALABELCONTENT=(PERCENT)
                DATALABELLOCATION=CALLOUT
                OTHERSLICE=TRUE
                OTHERSLICEOPTS=(TYPE=MAXSLICES MAXSLICES=6);
                DISCRETELEGEND 'MHTERM' ;
        ENDLAYOUT;
      ENDGRAPH;
    END;
  RUN;

  PROC SGRENDER DATA=PIE&ID. TEMPLATE=MYPIECHART;
    DYNAMIC _X='MHTERM';
  RUN;

%MEND;

%PIE(骨髄増殖性腫瘍,1);
%PIE(ＰＤＧＦＲＡ、ＰＤＧＦＲＢ、ＦＧＦＲ１異常症,2);
%PIE(骨髄異形成・骨髄増殖性腫瘍,3);
%PIE(骨髄異形成症候群,4);
%PIE(急性骨髄性白血病および関連腫瘍,5);
%PIE(系統不明急性白血病,6);
%PIE(前駆リンパ球系腫瘍,7);
%PIE(成熟Ｂ細胞腫瘍（リンパ腫・骨髄腫）,8);
%PIE(成熟Ｔ・ＮＫ細胞腫瘍,9);
%PIE(ホジキンリンパ腫,10);
%PIE(組織球・樹状細胞腫瘍,11);
%PIE(移植後リンパ増殖性疾患,12);

/*** Excel Output ***/

FILENAME SYS DDE "EXCEL | SYSTEM " ;
DATA _NULL_;
  FILE SYS;
  PUT '[SELECT("R4C1")]';
  PUT "[INSERT.PICTURE(""&OUTG.\&FILE..png"")]";
  PUT '[SELECT("R27C1")]';
  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.1.png"")]";
  PUT '[SELECT("R50C1")]';
  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.2.png"")]";
  PUT '[SELECT("R73C1")]';
  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.3.png"")]";
  PUT '[SELECT("R96C1")]';
  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.4.png"")]";
  PUT '[SELECT("R119C1")]';
  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.5.png"")]";
  PUT '[SELECT("R142C1")]';
  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.6.png"")]";
  PUT '[SELECT("R165C1")]';
  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.7.png"")]";
  PUT '[SELECT("R188C1")]';
  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.8.png"")]";
  PUT '[SELECT("R211C1")]';
  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.9.png"")]";
  PUT '[SELECT("R234C1")]';
  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.10.png"")]";
  PUT '[SELECT("R257C1")]';
  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.11.png"")]";
  PUT '[SELECT("R280C1")]';
  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.12.png"")]";
RUN;

*** Font;
FILENAME SYS DDE 'EXCEL|SYSTEM';

DATA _NULL_;
   FILE SYS;
   PUT "[WORKBOOK.ACTIVATE(""[JSH201609_STAT_RES_&FILE..xlsx]&FILE."")]";
   PUT '[SELECT("R1")]';
   PUT '[FONT.PROPERTIES("ＭＳ 明朝",,11)]';
   PUT '[FONT.PROPERTIES("Times New Roman",,11)]';

   PUT '[SELECT("R2:R1048576")]';
   PUT '[FONT.PROPERTIES("ＭＳ 明朝",,9)]';
   PUT '[FONT.PROPERTIES("Times New Roman",,9)]';
RUN;

*** Footnote;
DATA TMP;
   RUNTIME = TRIM(TRANSLATE(PUT(DATE(),YYMMDD10.),"/","-"));
RUN;

DATA _NULL_;
   FILE SYS;
   SET TMP ;
   PUT "[WORKBOOK.ACTIVATE(%BQUOTE("[JSH201609_STAT_RES_&FILE..xlsx]&FILE."))]";
   PUT '[PAGE.SETUP(, "&C &""Times New Roman"" &8 &P/&N &R &""Times New Roman"" &8 ' RUNTIME '")]';
   PUT '[SELECT("R1C1")]';
RUN;

*** Close;
DATA _NULL_;
   FILE SYS;
   PUT "[WORKBOOK.ACTIVATE(""[JSH201609_STAT_RES_&FILE..xlsx]&FILE."")]";
   PUT '[SELECT("R1C1")]';
   PUT '[ERROR(FALSE)]';
   PUT "[SAVE.AS(""&OUT.\JSH201609_STAT_RES_&FILE..xlsx"")]";
   PUT '[CLOSE("FALSE")]';
   PUT '[QUIT()]';
RUN;

%STAT_FIN;

/*** END ***/
