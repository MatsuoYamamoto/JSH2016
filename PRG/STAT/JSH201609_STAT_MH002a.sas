**********************************************************************;
* Project           : JSH201609
*
* Program name      : JSH201609_STAT_MH002a.sas
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
%LET FILE = MH002a;

%INCLUDE "&_PATH2.\JSH201609_STAT_LIBNAME.sas";

/*** Template Open ***/
/*%XLSOPEN(JSH201609_STAT_RES_&FILE..xlsx);*/

/*** ADS read ***/
%MACRO DS_READ(LIB,DS);
  DATA  &DS.;
    SET  &LIB..&DS.;
    FORMAT _ALL_;
    INFORMAT _ALL_;
    IF SCAN(MHSTDTC,1,"/") IN("2012","2013","2014","2015");
  RUN ;
%MEND ;
%DS_READ(LIBADS,ADS);

DATA  MAIN;
  SET  ADS;
  CNT=1;
  TRTPN=SEX+1;
  OUTPUT;
  MHDECOD=0;
  MHTERM="Total";
  OUTPUT;
RUN ; 

%MACRO MH ( WHE , DS ) ;

  %DO I = 1 %TO 2 ;
    PROC SORT DATA = MAIN OUT = SRT %IF &I = 1 %THEN NODUPKEY ; ;
      BY &WHE SUBJID TRTPN;
    RUN ;

    PROC MEANS DATA = SRT NWAY NOPRINT ;
      CLASS &WHE TRTPN ;
      VAR CNT ;
      OUTPUT OUT = N&I N = N&I ;
    RUN ;
  %END ;

  DATA WORK.MRG ;
    MERGE WORK.N1
          WORK.N2 ;
    BY &WHE TRTPN ;
  RUN ;

  DATA WORK.OUT&DS ;
    FORMAT &WHE VAR1 - VAR2;
    MERGE MRG ( WHERE = ( TRTPN = 1 ) RENAME = ( N1 = VAR1  ) )
          MRG ( WHERE = ( TRTPN = 2 ) RENAME = ( N1 = VAR2  ) ) ;
    %IF &DS ^= 1 %THEN BY &WHE ; ;
    ARRAY BEF(*) VAR1-VAR2 ;
    DO I = 1 TO DIM( BEF ) ;
      IF BEF(I) = . THEN BEF(I) = 0 ;
    END ;
  RUN ;
%MEND ;

%MH( %STR( AGECAT1N MHDECOD MHTERM ) , 2 )

DATA WK01;
  SET  OUT2;
  MALE = VAR1 * -1;
  FEMALE = VAR2;
RUN ; 

PROC FORMAT ; PICTURE _PCTF LOW - HIGH = "000009" ; RUN ;
PROC FORMAT;
 VALUE AGEF  19='0-4 y.o.'
             18='5-9'
             17='10-14'
             16='15-19'
             15='20-24'
             14='25-29'
             13='30-34'
             12='35-39'
             11='40-44'
             10='45-49'
             9='50-54'
             8='55-59'
             7='60-64'
             6='65-69'
             5='70-74'
             4='75-79'
             3='80-84'
             2='85-89'
             1='Over 90 y.o.';
RUN ;

%MACRO BUTT(ID,LEN1=&SCALE.,LEN2=&MINVAL.,LEN3=&MAXVAL.,TIT=&TERM.);
  %LET TERM=;
  %LET MINVAL=;
  %LET MAXVAL=;
  %LET SCALE=;

  DATA BUTTFY&ID.;
    SET  WK01;
    IF  MHDECOD = &ID.;
    ZERO=0;
    CALL SYMPUT('TERM',MHTERM);
    FORMAT MALE FEMALE _PCTF. AGECAT1N AGEF.;
  RUN ;

  /*SCALE*/
  DATA A1;
    SET BUTTFY&ID. END=EOF;
    RETAIN M 0;
    IF MAX(MALE*-1,FEMALE)>M THEN M=MAX(MALE*-1,FEMALE);
    IF EOF;
    KEEP M;
  RUN;

  DATA  _NULL_;
    SET  A1;
    IF  M<10         THEN M=(INT((M+10)/10))*10;
    ELSE IF M<100    THEN M=(INT((M+100)/100))*100;
    ELSE IF M<1000   THEN M=(INT((M+1000)/1000))*1000;
    ELSE IF M<10000  THEN M=(INT((M+10000)/10000))*10000;
    ELSE IF M<100000 THEN M=(INT((M+100000)/100000))*100000;
    STRM1=PUT(M,BEST.);
    STRM2=PUT(M * -1 ,BEST.);
    STRM3=PUT(M * 0.1,BEST.);
    CALL SYMPUT('MAXVAL',STRM1);
    CALL SYMPUT('MINVAL',STRM2);
    CALL SYMPUT('SCALE',STRM3);
    %PUT &MAXVAL. &MINVAL. &SCALE.;
  RUN ;

  DATA  DMY;
    MHDECOD = &ID.;
    DO AGECAT1N=1 TO 19;
      MALE=0;
      FEMALE=0;
      ZERO=0;
      OUTPUT;
    END;
  RUN ;

  PROC SORT DATA=BUTTFY&ID.; BY AGECAT1N; RUN ;
  PROC SORT DATA=DMY; BY AGECAT1N; RUN ;

  DATA  BUTTFY&ID.;
    MERGE  DMY BUTTFY&ID.;
    BY  AGECAT1N;
  RUN ;

  *** ALL;
  ODS GRAPHICS ON / HEIGHT = 9CM WIDTH = 12CM IMAGENAME = "&FILE.&ID."
    OUTPUTFMT = PNG RESET = INDEX   ANTIALIASMAX=96100;
  ODS LISTING GPATH = "&OUTG.\BUTTERFLY" IMAGE_DPI = 300 ;

  TITLE &TIT.;
  PROC SGPLOT DATA=BUTTFY&ID.;
    HBARPARM CATEGORY=AGECAT1N RESPONSE=MALE /
      DATALABEL=MALE DATALABELATTRS=(SIZE=8);
    HBARPARM CATEGORY=AGECAT1N RESPONSE=FEMALE / 
      DATALABEL=FEMALE DATALABELATTRS=(SIZE=8);
    XAXIS VALUES=(&LEN2. TO &LEN3. BY &LEN1.) DISPLAY=(NOLABEL) /*GRID*/;
    YAXIS DISPLAY=(NOLABEL);
  RUN;

%MEND;
%BUTT(0);
%BUTT(1);
%BUTT(2);
%BUTT(3);
%BUTT(4);
%BUTT(5);
%BUTT(6);
%BUTT(7);
%BUTT(8);
%BUTT(9);
%BUTT(10);
%BUTT(11);
%BUTT(12);
%BUTT(13);
%BUTT(14);
%BUTT(15);
%BUTT(16);
%BUTT(17);
%BUTT(18);
%BUTT(19);
%BUTT(20);
%BUTT(21);
%BUTT(22);
%BUTT(23);
%BUTT(24);
%BUTT(25);
%BUTT(26);
%BUTT(27);
%BUTT(28);
%BUTT(29);
%BUTT(30);
%BUTT(31);
%BUTT(32);
%BUTT(33);
%BUTT(34);
%BUTT(35);
%BUTT(36);
%BUTT(37);
%BUTT(38);
%BUTT(39);
%BUTT(40);
%BUTT(41);
%BUTT(42);
%BUTT(43);
%BUTT(44);
%BUTT(45);
%BUTT(46);
%BUTT(47);
%BUTT(48);
%BUTT(49);
%BUTT(50);
%BUTT(51);
%BUTT(52);
%BUTT(53);
%BUTT(54);
%BUTT(55);
%BUTT(56);
%BUTT(57);
%BUTT(58);
%BUTT(59);
%BUTT(60);
%BUTT(61);
%BUTT(62);
%BUTT(63);
%BUTT(64);
%BUTT(65);
%BUTT(66);
%BUTT(67);
%BUTT(68);
%BUTT(69);
%BUTT(70);
%BUTT(71);
%BUTT(72);
%BUTT(73);
%BUTT(74);
%BUTT(75);
%BUTT(76);
%BUTT(77);
%BUTT(78);
%BUTT(79);
%BUTT(80);
%BUTT(81);
%BUTT(82);
%BUTT(83);
%BUTT(84);
%BUTT(85);
%BUTT(86);
%BUTT(87);
%BUTT(88);
%BUTT(89);
%BUTT(90);
%BUTT(91);
%BUTT(92);
%BUTT(93);
%BUTT(94);
%BUTT(95);
%BUTT(96);
%BUTT(97);
%BUTT(98);
%BUTT(99);
%BUTT(100);
%BUTT(101);
%BUTT(102);
%BUTT(103);
%BUTT(104);
%BUTT(105);
%BUTT(106);
%BUTT(107);
%BUTT(108);
%BUTT(109);
%BUTT(110);
%BUTT(111);
%BUTT(112);
%BUTT(113);
%BUTT(114);
%BUTT(115);
%BUTT(116);
%BUTT(117);
%BUTT(118);
%BUTT(119);
%BUTT(120);
%BUTT(121);
%BUTT(122);
%BUTT(123);
%BUTT(124);
%BUTT(125);
%BUTT(126);
%BUTT(127);
%BUTT(128);
%BUTT(129);
%BUTT(130);
%BUTT(131);
%BUTT(132);
%BUTT(133);
%BUTT(134);
%BUTT(135);
%BUTT(136);
%BUTT(137);
%BUTT(138);
%BUTT(139);
%BUTT(140);
%BUTT(141);
%BUTT(142);
%BUTT(143);
%BUTT(144);
%BUTT(145);
%BUTT(146);
%BUTT(147);
%BUTT(148);
%BUTT(149);
%BUTT(150);
%BUTT(151);
%BUTT(152);
%BUTT(153);
%BUTT(154);
%BUTT(155);

/*** Excel Output ***/

/*FILENAME SYS DDE "EXCEL | SYSTEM " ;*/
/*DATA _NULL_;*/
/*  FILE SYS;*/
/*  PUT '[SELECT("R4C1")]';*/
/*  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.0.png"")]";*/
/*  PUT '[SELECT("R27C1")]';*/
/*  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.1.png"")]";*/
/*  PUT '[SELECT("R50C1")]';PUT '[SET.PAGE.BREAK()]';*/
/*  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.2.png"")]";*/
/*  PUT '[SELECT("R73C1")]';*/
/*  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.3.png"")]";*/
/*  PUT '[SELECT("R96C1")]';PUT '[SET.PAGE.BREAK()]';*/
/*  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.4.png"")]";*/
/*  PUT '[SELECT("R119C1")]';*/
/*  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.5.png"")]";*/
/*  PUT '[SELECT("R142C1")]';PUT '[SET.PAGE.BREAK()]';*/
/*  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.6.png"")]";*/
/*  PUT '[SELECT("R165C1")]';*/
/*  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.7.png"")]";*/
/*  PUT '[SELECT("R188C1")]';PUT '[SET.PAGE.BREAK()]';*/
/*  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.8.png"")]";*/
/*  PUT '[SELECT("R211C1")]';*/
/*  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.9.png"")]";*/
/*  PUT '[SELECT("R234C1")]';PUT '[SET.PAGE.BREAK()]';*/
/*  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.10.png"")]";*/
/*  PUT '[SELECT("R257C1")]';*/
/*  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.11.png"")]";*/
/*  PUT '[SELECT("R280C1")]';PUT '[SET.PAGE.BREAK()]';*/
/*  PUT "[INSERT.PICTURE(""&OUTG.\&FILE.12.png"")]";*/
/*RUN;*/
/**/
/**** Font;*/
/*FILENAME SYS DDE 'EXCEL|SYSTEM';*/
/**/
/*DATA _NULL_;*/
/*   FILE SYS;*/
/*   PUT "[WORKBOOK.ACTIVATE(""[JSH201609_STAT_RES_&FILE..xlsx]&FILE."")]";*/
/*   PUT '[SELECT("R1")]';*/
/*   PUT '[FONT.PROPERTIES("�l�r ����",,11)]';*/
/*   PUT '[FONT.PROPERTIES("Times New Roman",,11)]';*/
/**/
/*   PUT '[SELECT("R2:R1048576")]';*/
/*   PUT '[FONT.PROPERTIES("�l�r ����",,9)]';*/
/*   PUT '[FONT.PROPERTIES("Times New Roman",,9)]';*/
/*RUN;*/
/**/
/**** Footnote;*/
/*DATA TMP;*/
/*   RUNTIME = TRIM(TRANSLATE(PUT(DATE(),YYMMDD10.),"/","-"));*/
/*RUN;*/
/**/
/*DATA _NULL_;*/
/*   FILE SYS;*/
/*   SET TMP ;*/
/*   PUT "[WORKBOOK.ACTIVATE(%BQUOTE("[JSH201609_STAT_RES_&FILE..xlsx]&FILE."))]";*/
/*   PUT '[PAGE.SETUP(, "&C &""Times New Roman"" &8 &P/&N &R &""Times New Roman"" &8 ' RUNTIME '")]';*/
/*   PUT '[SELECT("R1C1")]';*/
/*RUN;*/
/**/
/**** Close;*/
/*DATA _NULL_;*/
/*   FILE SYS;*/
/*   PUT "[WORKBOOK.ACTIVATE(""[JSH201609_STAT_RES_&FILE..xlsx]&FILE."")]";*/
/*   PUT '[SELECT("R1C1")]';*/
/*   PUT '[ERROR(FALSE)]';*/
/*   PUT "[SAVE.AS(""&OUT.\JSH201609_STAT_RES_&FILE..xlsx"")]";*/
/*   PUT '[CLOSE("FALSE")]';*/
/*   PUT '[QUIT()]';*/
/*RUN;*/

%STAT_FIN;

/*** END ***/
