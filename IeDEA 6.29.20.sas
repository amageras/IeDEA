libname final 'C:\Users\magera01\Desktop\IeDEA\Final Data';
libname dhs 'C:\Users\magera01\Desktop\IeDEA\DHS Data';
libname iedea 'C:\Users\magera01\Desktop\IeDEA\IeDEA Data\Data\IeDEA';
libname burw 'C:\Users\magera01\Desktop\IeDEA\IeDEA Data\Data\October 2018 Data';
libname buraw 'C:\Users\magera01\Desktop\IeDEA\IeDEA Data\Data\October 2018 Data\April 2019 Pregnancy Data';


***FORMATS;
proc format;
value sex
      1 = 'Male'
      2 = 'Female';
value agegrp
      1 = '15-19'
      2 = '20-24'
      3 = '25-29'
      4 = '30-34'
      5 = '35-39'
      6 = '40-44'
      7 = '45-49'
      8 = '50-54'
      9 = '55-59'
      10 = '60-64'
      11 = '65-69'
      12 = '70-74'
      13 = '>= 75'
      14 = '< 5'
      15 = '5-9'
      16 = '10-14';
value bmi
      1 = 'Underweight'
      2 = 'Normal range'
      3 = 'Overweight'
      4 = 'Obese';
value yesno
      0 = 'No'
      1 = 'Yes';
value urban
      1 = 'Urban'
      2 = 'Rural';
value marital
      0 = 'Single'
      1 = 'Married or living with partner'
      2 = 'Widowed'
      3 = 'Divorced or separated';
value dataset
      0 = 'IeDEA'
      1 = 'DHS';
run;


***DATA PREPARATION AND CLEANING;

**Call datasets, drop DRC records, deduplicate identical records, rename all date variables pertaining to visits as "visit_date", and sort for merge;

data iedea_admission1;
set burw.admission_date;
keep varid admission_date lastupdate;
if cohort_name ne 'COD' and '01JAN2000'd le admission_date le lastupdate then output; 
run;
proc sort data=iedea_admission1;
by varid admission_date;
run;

data iedea_admission;
set iedea_admission1;
by varid admission_date;
if first.admission_date then output; *Keep earliest admission date between January 1, 2000, and database close;
run;
proc sort data=iedea_admission;
by varid admission_date;
run;

data iedea_enroll1;
set burw.enrollment_date;
keep varid enrollment_date program_id_decoded lastupdate;
if cohort_name ne 'COD' and '01JAN2000'd le enrollment_date le lastupdate then output;
run;

*Keep only earliest enrollment date;
proc sql;
create table iedea_enroll as
select varid, MIN(enrollment_date)AS enrollment_date
from iedea_enroll1
group by varid;
quit;
proc sort data=iedea_enroll;
by varid enrollment_date;
run;

data iedea_pers; 
set burw.person;
keep varid site cohort_name birth_date xdeath_date sex lastupdate;
if cohort_name ne 'COD' and birth_date le lastupdate then output; *No duplicate varids in tis dataset;
run;
proc sort data=iedea_pers;
by varid;
run;


data iedea_transfer_in;
set burw.transfer_in_date;
keep varid transfer_in_date site lastupdate; *No lastupdate variable in source dataset;
*Code last update  by  site;
if site = 'ANSS' or site = 'CHUK' or site = 'HPRC' then lastupdate = '16AUG2018'd;
else if site = 'BETHSAIDA' or site = 'BUSANZA' or site = 'GAHANGA' or site = 'GIKONDO' or site = 'KABUGA' or site = 'KICUKIRO' or site = 'MASAKA' or site = 'NYARUGUNGA' or site = 'WEACTX' then lastupdate = '21SEP2018'd;
else if site = 'KANOMBE' then lastupdate = '15JAN2018'd;
format lastupdate ddmmyys10.;
if cohort_name ne 'COD' and '01JAN2000'd le transfer_in_date le lastupdate then output;
run;

*Keep only earliest transfer-in date;
proc sql;
create table iedea_trans_in as
select varid, MIN(transfer_in_date)AS transfer_in_date
from iedea_transfer_in
group by varid;
quit;
proc sort data=iedea_trans_in;
by varid transfer_in_date;
run;


data iedea_transfer_out;
set burw.transfer_out_date;
keep varid transfer_out_date; 
if cohort_name ne 'COD' then output;
run;

*Keep only latest transfer-out date;
proc sql;
create table iedea_trans_out as
select varid, MAX(transfer_out_date)AS transfer_out_date
from iedea_transfer_out
group by varid;
quit;
proc sort data=iedea_trans_out;
by varid transfer_out_date;
run;

data iedea_arv (rename=(arv_start_date=visit_date));
set burw.arv_with_prophylaxis;
keep varid arv_start_date site lastupdate;
*Code last update  by  site;
if site = 'ANSS' or site = 'CHUK' or site = 'HPRC' then lastupdate = '16AUG2018'd;
else if site = 'BETHSAIDA' or site = 'BUSANZA' or site = 'GAHANGA' or site = 'GIKONDO' or site = 'KABUGA' or site = 'KICUKIRO' or site = 'MASAKA' or site = 'NYARUGUNGA' or site = 'WEACTX' then lastupdate = '21SEP2018'd;
else if site = 'KANOMBE' then lastupdate = '15JAN2018'd;
format lastupdate ddmmyys10.;
if cohort_name ne 'COD' and '01JAN2000'd le arv_start_date le lastupdate then output; 
run;
proc sort data=iedea_arv
noduprecs;
by varid visit_date;
run;


data iedea_cd4 (rename=(cd4_date=visit_date));
set burw.cd4_count;
keep varid cd4_date site lastupdate;
*Code last update  by  site;
if site = 'ANSS' or site = 'CHUK' or site = 'HPRC' then lastupdate = '16AUG2018'd;
else if site = 'BETHSAIDA' or site = 'BUSANZA' or site = 'GAHANGA' or site = 'GIKONDO' or site = 'KABUGA' or site = 'KICUKIRO' or site = 'MASAKA' or site = 'NYARUGUNGA' or site = 'WEACTX' then lastupdate = '21SEP2018'd;
else if site = 'KANOMBE' then lastupdate = '15JAN2018'd;
format lastupdate ddmmyys10.;
if cohort_name ne 'COD' and '01JAN2000'd le cd4_date le lastupdate then output;
run;
proc sort data=iedea_cd4
noduprecs;
by varid visit_date;
run;


data iedea_height1 (rename=(height_cm_date=visit_date height_cm_value=height));
set burw.height_cm;
keep varid height_cm_date height_cm_value site lastupdate;
*Code last update  by  site;
if site = 'ANSS' or site = 'CHUK' or site = 'HPRC' then lastupdate = '16AUG2018'd;
else if site = 'BETHSAIDA' or site = 'BUSANZA' or site = 'GAHANGA' or site = 'GIKONDO' or site = 'KABUGA' or site = 'KICUKIRO' or site = 'MASAKA' or site = 'NYARUGUNGA' or site = 'WEACTX' then lastupdate = '21SEP2018'd;
else if site = 'KANOMBE' then lastupdate = '15JAN2018'd;
format lastupdate ddmmyys10.;
if cohort_name ne 'COD' and '01JAN2000'd le height_cm_date le lastupdate then output;
run;
proc sort data=iedea_height1
noduprecs;
by varid visit_date;
run;
*Output observations with two or more height measurements on same visit date;
proc sql;
create table height_dup as
select * from iedea_height1
group by varid, visit_date
having count(*) >= 2;
*Output mode of height measurement on single day, if tie then choose higher value;
create table height_mode as
select *
from (select varid, visit_date, max(height) as mode_hh
from (select *
from (select * , count(*) as many
from height_dup
group by varid, visit_date, height
)
group by varid, visit_date
having many EQ max(many)
)
group by varid, visit_date
having height EQ min(height)
)
;
quit;
*Deduplicate modes;
proc sort data=height_mode
nodupkey;
by varid visit_date;
run;
*Remerge modes with height data, replacing spurious values by reading in modes data second (see documentation for SAS merges);
data iedea_height;
merge iedea_height1 height_mode;
by varid visit_date;
if mode_hh ne . then height = mode_hh;
drop lastupdate mode_hh;
run;
proc sort data=iedea_height
noduprecs;
by varid visit_date;
run;


data iedea_weight1 (rename=(weight_kg_date=visit_date weight_kg_value = weight));
set burw.weight_kg;
keep varid weight_kg_date weight_kg_value site lastupdate;
*Code last update  by  site;
if site = 'ANSS' or site = 'CHUK' or site = 'HPRC' then lastupdate = '16AUG2018'd;
else if site = 'BETHSAIDA' or site = 'BUSANZA' or site = 'GAHANGA' or site = 'GIKONDO' or site = 'KABUGA' or site = 'KICUKIRO' or site = 'MASAKA' or site = 'NYARUGUNGA' or site = 'WEACTX' then lastupdate = '21SEP2018'd;
else if site = 'KANOMBE' then lastupdate = '15JAN2018'd;
format lastupdate ddmmyys10.;
if cohort_name ne 'COD' and '01JAN2000'd le weight_kg_date le lastupdate then output;
run;
proc sort data=iedea_weight1
noduprecs;
by varid visit_date;
run;
*Output observations with two or more weight measurements on same visit date;
proc sql;
create table weight_dup as
select * from iedea_weight1
group by varid, visit_date
having count(*) >= 2;
*Output mode of weight measurement on single day, if tie then choose higher value;
create table weight_mode as
select *
from (select varid, visit_date, max(weight) as mode_ww
from (select *
from (select * , count(*) as many
from weight_dup
group by varid, visit_date, weight
)
group by varid, visit_date
having many EQ max(many)
)
group by varid, visit_date
having weight EQ min(weight)
)
;
quit;
*Deduplicate modes;
proc sort data=weight_mode
nodupkey;
by varid visit_date;
run;
*Remerge modes with weight data, replacing spurious values by reading in modes data second (see documentation for SAS merges);
data iedea_weight;
merge iedea_weight1 weight_mode;
by varid visit_date;
if mode_ww ne . then weight = mode_ww;
drop lastupdate mode_ww;
run;
proc sort data=iedea_weight
noduprecs;
by varid visit_date;
run;


data iedea_mar (rename=(xobs_datetime=visit_date marital_status=mar_stat));
set burw.marital_status;
keep varid xobs_datetime marital_status site lastupdate;
*Recode marital status for observations where multiple different values are recorded on the same date per Dedupe syntax, if unclear which is correct set missing;
if varid = 'RWDBETHSAIDA00121217510' then marital_status = 1057;
if varid = 'RWDBUSANZA00121212224' then marital_status = 1060;
if varid = 'RWDBUSANZA00121212727' then marital_status = 1058;
if varid = 'RWDBUSANZA00121216664' then marital_status = .;
if varid = 'RWDBUSANZA00121217547' then marital_status = .;
if varid = 'RWDGAHANGA00121212779' then marital_status = 5555;
if varid = 'RWDGIKONDO00121217535' then marital_status = .;
if varid = 'RWDKABUGA00121212666' then marital_status = .;
if varid = 'RWDKICUKIRO00121213675' then marital_status = 3347;
if varid = 'RWDKICUKIRO00121213676' then marital_status = 3347;
*Code last update  by  site;
if site = 'ANSS' or site = 'CHUK' or site = 'HPRC' then lastupdate = '16AUG2018'd;
else if site = 'BETHSAIDA' or site = 'BUSANZA' or site = 'GAHANGA' or site = 'GIKONDO' or site = 'KABUGA' or site = 'KICUKIRO' or site = 'MASAKA' or site = 'NYARUGUNGA' or site = 'WEACTX' then lastupdate = '21SEP2018'd;
else if site = 'KANOMBE' then lastupdate = '15JAN2018'd;
format lastupdate ddmmyys10.;
if cohort_name ne 'COD' and '01JAN2000'd le xobs_datetime le lastupdate then output;
run;
proc sort data=iedea_mar
nodupkey;
by varid visit_date;
run;


data iedea_visit;
set burw.visit_date;
keep varid visit_date lastupdate;
if cohort_name ne 'COD' and '01JAN2000'd le visit_date le lastupdate then output; 
run;
proc sort data=iedea_visit
nodupkey;
by varid visit_date;
run;


data iedea_vload (rename=(vload_date=visit_date));
set burw.vload;
keep varid vload_date site lastupdate;
*Code last update  by  site;
if site = 'ANSS' or site = 'CHUK' or site = 'HPRC' then lastupdate = '16AUG2018'd;
else if site = 'BETHSAIDA' or site = 'BUSANZA' or site = 'GAHANGA' or site = 'GIKONDO' or site = 'KABUGA' or site = 'KICUKIRO' or site = 'MASAKA' or site = 'NYARUGUNGA' or site = 'WEACTX' then lastupdate = '21SEP2018'd;
else if site = 'KANOMBE' then lastupdate = '15JAN2018'd;
format lastupdate ddmmyys10.;
if cohort_name ne 'COD' and '01JAN2000'd le vload_date le lastupdate then output;
run;
proc sort data=iedea_vload
nodupkey;
by varid visit_date;
run;


data iedea_whostage (rename=(who_stage_date=visit_date));
set burw.whostage;
keep varid who_stage_date site lastupdate;
*Code last update  by  site;
if site = 'ANSS' or site = 'CHUK' or site = 'HPRC' then lastupdate = '16AUG2018'd;
else if site = 'BETHSAIDA' or site = 'BUSANZA' or site = 'GAHANGA' or site = 'GIKONDO' or site = 'KABUGA' or site = 'KICUKIRO' or site = 'MASAKA' or site = 'NYARUGUNGA' or site = 'WEACTX' then lastupdate = '21SEP2018'd;
else if site = 'KANOMBE' then lastupdate = '15JAN2018'd;
format lastupdate ddmmyys10.;
if cohort_name ne 'COD' and '01JAN2000'd le who_stage_date le lastupdate then output;
run;
proc sort data=iedea_whostage
nodupkey;
by varid visit_date;
run;


data iedea_labtest (rename=(labtest_date=visit_date));
set burw.labtest;
keep varid labtest_date site lastupdate;
*Code last update  by  site;
if site = 'ANSS' or site = 'CHUK' or site = 'HPRC' then lastupdate = '16AUG2018'd;
else if site = 'BETHSAIDA' or site = 'BUSANZA' or site = 'GAHANGA' or site = 'GIKONDO' or site = 'KABUGA' or site = 'KICUKIRO' or site = 'MASAKA' or site = 'NYARUGUNGA' or site = 'WEACTX' then lastupdate = '21SEP2018'd;
else if site = 'KANOMBE' then lastupdate = '15JAN2018'd;
format lastupdate ddmmyys10.;
if cohort_name ne 'COD' and '01JAN2000'd le labtest_date le lastupdate then output; 
run;
proc sort data=iedea_labtest
nodupkey;
by varid visit_date;
run;


*Create "site" variable to include in concatenated varid for pregnancy data below and assign cohort name;
data iedea_raw;
set buraw.tb_admission_patient;
patient_ID = put(input(codeidpatient,10.),z10.);
if codeinstut = '003BDI017S010101' or codeinstut = '003BDI017s010101' then site = 'HPRC';
if codeinstut = '003BDI017S020201'  or codeinstut = '003BDI017S020205' then site = 'CHUK';
if codeinstut = '003BDI017S020204' then site = 'ANSS';
run;

*Deduplicate pregnancy data;
data iedea_preg_raw;
set buraw.femmeenceinte;
*Convert character variables to numeric;
patient_ID = put(input(codepatientsuiviptme, 10.), z10.);
visit_datetime = input(datevisitesuiviptme, anydtdtm.);
period_datetime = input(dateregle, anydtdtm.);
delivery_datetime = input(DATEACCOUCHESUIVIPTME, anydtdtm.);
due_datetime = input(dateprobable, anydtdtm.);
format visit_datetime period_datetime delivery_datetime due_datetime datetime7.;
keep ID patient_ID visit_datetime period_datetime delivery_datetime due_datetime;
run;
proc sort data=iedea_preg_raw
noduprecs;
by patient_id visit_datetime;
run;

*Add missing period and delivery dates to pregnancy dataset by adding or deducting 280 days;
data iedea_preg_raw;
set iedea_preg_raw;
*Remove spurious duplicate records based on manual review (checking observations from the same patient with the same visit, period, or delivery date but not all three being the same);
if patient_id = '0000002765' and datepart(delivery_datetime) = '23OCT18'd then delete;
if patient_id = '0000007048' and datepart(delivery_datetime) = '26DEC11'd then delete;
if patient_id = '0000017176' and datepart(period_datetime) = '28AUG18'd then delete;
if patient_id = '0000019244' and datepart(delivery_datetime) = '19DEC12'd then delete;
if patient_id = '0000020269' and datepart(visit_datetime) = '01MAR19'd then delete;
if patient_id = '0000020475' and datepart(delivery_datetime) = '27APR18'd then delete;
if patient_id = '0000015576' and datepart(visit_datetime) = '15SEP11'd then delete;
if patient_id = '0000006409' and datepart(period_datetime) = '25MAR18'd then delivery_datetime = .;
if patient_id = '0000019053' and datepart(visit_datetime) = '09AUG07'd then delete;
if patient_id = '0000019503' and datepart(visit_datetime) = '10FEB05'd then delete;
if patient_id = '0000019669' and datepart(visit_datetime) = '11JUL18'd then delete;
if patient_id = '0000019255' and datepart(visit_datetime) = '08JUL10'd and delivery_date = . then delete;
if patient_id = '0000019405' and datepart(visit_datetime) = '11NOV10'd and delivery_date = . then delete;
if patient_id = '0000020342' and datepart(visit_datetime) = '17JUN15'd and delivery_date = . then delete;
if patient_id = '0000020703' and datepart(visit_datetime) = '04FEB10'd and delivery_date = . then delete;
*Keep only datepart of datetime variables;
visit_date = datepart(visit_datetime);
if period_datetime ne . then period_date = datepart(period_datetime);
else if period_datetime = . and delivery_datetime ne . then period_date = (datepart(delivery_datetime) - 280);
else if period_datetime = . and delivery_datetime = . and due_datetime ne . then period_date = (datepart(due_datetime) - 280);
else if period_datetime = . and delivery_datetime = . and due_datetime = . then period_date = .;
if delivery_datetime ne . then delivery_date = datepart(delivery_datetime);
else if delivery_datetime = . and period_datetime ne . then delivery_date = (datepart(period_datetime) + 280);
else if delivery_datetime = . and period_datetime = . and due_datetime ne . then delivery_date = datepart(due_datetime);
else if delivery_datetime = . and period_datetime = . and due_datetime = . then delivery_date = .;
format period_date delivery_date visit_date ddmmyys10.;
run;
proc sort data=iedea_raw
nodupkey;
by patient_ID; 
run;
proc sort data=iedea_preg_raw
nodupkey;
by patient_ID visit_date;
run;

*Merge pregnancy data with site data on patient ID to create varid and prepare pregnancy data for merge with other files;
data iedea_pregnant;
merge iedea_raw iedea_preg_raw;
by patient_ID;
if ID = . then delete;
keep patient_ID varid period_date delivery_date visit_date sexe; *period_year;
*Create patient ID variable to match other datasets, according to Data Solutions's Excel sheet;
varid=left(compress('BUR'||site||patient_ID));
*period_year = year(period_date);
run;
proc sort data=iedea_pregnant
noduprecs;
by varid visit_date;
run;


*Create new variable called xenroll_date, which is earliest engagement date, i.e., earliest date among enrollment_date, admission_date, and transfer_in_date;
data iedea_xenroll1;
merge iedea_admission iedea_enroll iedea_trans_in;
by varid;
run;

proc sql;
create table iedea_xenroll as
select varid, MIN(enrollment_date, admission_date, transfer_in_date) as xenroll_date
from iedea_xenroll1;
quit;

/*proc print data = iedea_xenroll1;
where enrollment_date=. or admission_date=. or transfer_in_date=.; run;*/



*Delete temporary files EXCEPT those needed for next merges;
proc datasets lib=work memtype=data nolist;
	delete iedea_enroll iedea_enroll1 iedea_enroll2 iedea_admission iedea_trans_in iedea_transfer_in iedea_transfer_out iedea_raw iedea_preg_raw;
quit;

**Merge datasets with visit dates;
data iedea_merge;
length varid $ 30;
merge iedea_arv iedea_cd4 iedea_whostage iedea_labtest iedea_visit iedea_vload iedea_pregnant iedea_mar iedea_height iedea_weight; 
by varid visit_date;
run;
proc sort data=iedea_merge
noduprecs;
by varid;
run;

*Deduplicate records with same varid and multiple same visit dates;
proc sql;
create table iedea_merge_dedup as
select distinct (varid),   
visit_date, weight, height, delivery_date, period_date, mar_stat
from iedea_merge
order by varid;
quit;

*Delete all temporary files EXCEPT those needed for next merge;
proc datasets lib=work memtype=data nolist;
	delete iedea_arv iedea_cd4 iedea_labtest iedea_visit iedea_vload iedea_whostage iedea_pregnant iedea_mar iedea_height iedea_weight; 
	quit;

*Merge with remaining datasets (that don't have visit date);
data iedea1;
length varid $ 30;
merge iedea_merge_dedup /*iedea_trans_out*/ iedea_xenroll iedea_pers;
by varid;
run;

*Delete all temporary files EXCEPT Iedea1;
proc datasets lib=work memtype=data nolist;
	delete iedea_ :;
quit;


*Clean data and apply exclusion criteria and prepare for merge with DHS data;
data iedea2;
set iedea1;
*Prepare for merge with DHS data by adding relevant variables;
dataset = 0;
wgt = 1;
cluster = 500;
stratum = 500;
HIV = 1;
HIV_result = 1;
*Code marital status to match DHS surveys;
if mar_stat=0 or mar_stat=3347 or mar_stat=3628 or mar_stat=1057 then marital_status=0;
if mar_stat=1 or mar_stat=4 or mar_stat=5555 or mar_stat=1060 then marital_status=1;
if mar_stat=2 or mar_stat=1059 then marital_status=2;
if mar_stat=3 or mar_stat=1056 or mar_stat=1058 then marital_status=3;
if mar_stat=5 or mar_stat=1067 or mar_stat=6139 or mar_stat=3346 or mar_stat=5622 then marital_status=.;
*Create numerical gender variable and recode all patients in pregnancy dataset as female because males must be incorrectly coded;
if sex = 'M' then gender = 1;
if sex = 'F' or delivery_date ne . then gender = 2;
*Create new urban/rural variable, based on where IeDEA clinics are located;
urban = 1;
*Clean data and apply exclusion criteria; 
if xenroll_date = . then delete; *drop anyone without an enrollment date;
if visit_date = . then visit_date = xenroll_date; *set engagement date as visit date for patients without a visit date; 
if birth_date = . then delete; *drop anyone without a birth date;
if xenroll_date le birth_date then delete; *drop anyone with enrollment date earlier than birth date (must be error);
if birth_date > xdeath_date > . then delete;
if xenroll_date > xdeath_date > . then delete; *drop anyone with enrollment date after death date (must be error);
*if xenroll_date > transfer_out_date > . then delete; *drop anyone with enrollment date after transfer-out date (must be error);
if . < visit_date < xenroll_date then delete; *drop observations where visit date is earlier than enrollment date 
to avoid including visits at non-IeDEA sites;
if . < visit_date < birth_date then delete;
if visit_date > xdeath_date > . then delete; *drop visits later than death date (must be error);
*if visit_date > transfer_out_date > . then delete; *drop visits later than transfer-out date (must be error);
*Retain only necessary variables;
keep varid cohort_name site urban visit_date weight height delivery_date period_date marital_status xenroll_date
birth_date gender xdeath_date transfer_out_date dataset wgt stratum cluster hiv hiv_result;
*Formats;
attrib gender format = sex. label = "Sex";
attrib urban format = urban. label = "Location of Clinic";
attrib marital_status format = marital. label = "Marital Status";
format dataset dataset.;
format visit_date xenroll_date birth_date xdeath_date transfer_out_date period_date delivery_date ddmmyys10.;
run;



/*Prepare IeDEA datasets by respective DHS survey dates*/

*A Survey (Rwanda 2005);
data iedea_a;
set iedea2;
*Create survey start and end date variables;
if cohort_name='RWD' then survey_start_d=MDY(02, 28, 2005);
if cohort_name='RWD' then survey_end_d=MDY(07, 13, 2005);
if cohort_name='RWD' then survey_mid_d=MDY(05, 07, 2005);
*Create variable that measures time difference between visit date and survey mid date;
Vis_Diff=abs(survey_mid_d-visit_date);
*Drop Burundi patients;
if cohort_name='BUR' then delete;
*Exclude patients not enrolled during relevant DHS survey, based on engagement, death, and transfer-out dates;
*if xenroll_date > survey_end_d then delete;
*if . < xdeath_date < survey_start_d then delete;
*if . < transfer_out_date < survey_start_d then delete;
*Calculate age at survey mid date and create categorical agegrp variable to match DHS surveys;
age = .;
age = INT(INTCK('MONTH', birth_date, survey_mid_d)/12);
if MONTH(birth_date) = MONTH(survey_mid_d) then age = age -(DAY(birth_date)>DAY(survey_mid_d));
agegrp = .;
if age < 0 then agegrp = .;
if 15 <= age =< 19 then agegrp = 1;
if 20 <= age =< 24 then agegrp = 2;
if 25 <= age =< 29 then agegrp = 3;
if 30 <= age =< 34 then agegrp = 4;
if 35 <= age =< 39 then agegrp = 5;
if 40 <= age =< 44 then agegrp = 6;
if 45 <= age =< 49 then agegrp = 7;
if 50 <= age =< 54 then agegrp = 8;
if 55 <= age =< 59 then agegrp = 9;
*Remove children and older adults to match DHS datasets--no HIV testing for children in respective survey;
if age < 15 then delete;
if gender = 1 and age > 59 then delete;
if gender = 2 and age > 49 then delete;
*Create adult variable to exclude children under 15;
if age > 14 then adult = 1;
else if age < 15 then adult = 0; 
*Exclude population-level height and weight outliers based on comparison to entire adult DHS cohort, per Welch 2011 paper, see IeDEA outliers syntax AND remove weight values recorded more than 365 days before or after survey mid date;
*if vis_diff > 365 then height = .;
if vis_diff > 365 then weight = .;
if height < 80.64 then height = .;
if height > 205.7 then height = .;
if weight < 22.77 then weight = .;
if weight > 162.8 then weight = .;
*Create pregnancy variable;
pregnant = .; *because Rwanda survey only;
*Formats;
format survey_end_d survey_start_d survey_mid_d ddmmyys10.;
attrib pregnant format = yesno. label = "Pregnant Status during Survey";
attrib agegrp format = agegrp. label = "Age Group";
run;


**Impute missing data from closest visit date;
proc sort data=iedea_a;
by varid DESCENDING visit_date;
run;

data iedea_back_a;
set iedea_a;
by varid DESCENDING visit_date;
*Weight;
retain BackDate_w BackWard_w;
if first.varid then do; BackDate_w=.; BackWard_w=.; end;
if weight ne . then do; BackDate_w=visit_date;BackWard_w= weight;end;
if (weight = . and BackDate_w ne .) then BackDiff_w=BackDate_w-visit_date;
*Height;
retain BackDate_h BackWard_h;
if first.varid then do; BackDate_h=.; BackWard_h=.; end;
if height ne . then do; BackDate_h=visit_date;BackWard_h= height;end;
if (height = . and BackDate_h ne .) then BackDiff_h=BackDate_h-visit_date;
*Marital Status;
retain BackDate_m BackWard_m;
if first.varid then do; BackDate_m=.; BackWard_m=.; end;
if marital_status ne . then do; BackDate_m=visit_date;BackWard_m= marital_status;end;
if (marital_status =. and BackDate_m ne .) then BackDiff_m=BackDate_m-visit_date;
run;

proc sort data=iedea_back_a;
by varid visit_date;
run;

data iedea_forward_a;
set iedea_back_a;
by varid visit_date;
*Weight;
retain ForwardDate_w ForWard_w;
if first.varid then do; ForwardDate_w=.; ForWard_w=.; end;
if weight ne . then do; ForwardDate_w= visit_date; ForWard_w= weight;end;
if (weight = . and ForwardDate_w ne .) then ForwardDiff_w= visit_date-ForwardDate_w;
*Height;
retain ForwardDate_h ForWard_h;
if first.varid then do; ForwardDate_h=.; ForWard_h=.; end;
if height ne . then do; ForwardDate_h= visit_date; ForWard_h= height;end;
if (height = . and ForwardDate_h ne .) then ForwardDiff_h= visit_date-ForwardDate_h;
*Marital Status;
retain ForwardDate_m ForWard_m;
if first.varid then do; ForwardDate_m=.; ForWard_m=.; end;
if marital_status ne . then do; ForwardDate_m= visit_date; ForWard_m= marital_status;end;
if (marital_status =. and ForwardDate_m ne .) then ForwardDiff_m= visit_date-ForwardDate_m;
RUN;


DATA iedea_3a;
set iedea_forward_a;
*Weight;
if (weight = . and ForWard_w ne . and BackWard_w ne .) then /*middle*/
 do;
if ForwardDiff_w<=BackDiff_w then weight =ForWard_w;
else weight=BackWard_w;
 end;
else if (weight = . and ForWard_w ne . and BackWard_w = .) then weight =ForWard_w; /*top*/
else if (weight = . and ForWard_w = . and BackWard_w ne .) then weight =BackWard_w; /*bottom*/
*Height;
if (height = . and ForWard_h ne . and BackWard_h ne .) then /*middle*/
 do;
if ForwardDiff_h<=BackDiff_h then height =ForWard_h;
else height=BackWard_h;
 end;
else if (height = . and ForWard_h ne . and BackWard_h = .) then height=ForWard_h; /*top*/
else if (height = . and ForWard_h = . and BackWard_h ne .) then height=BackWard_h; /*bottom*/
*Marital Status;
if (marital_status=. and ForWard_m ne . and BackWard_m ne .) then /*middle*/
 do;
if ForwardDiff_m<=BackDiff_m then marital_status=ForWard_m;
else marital_status =BackWard_m;
 end;
else if (marital_status =. and ForWard_m ne . and BackWard_m = .) then marital_status =ForWard_m; /*top*/
else if (marital_status =. and ForWard_m = . and BackWard_m ne .) then marital_status =BackWard_m; /*bottom*/
run;

proc sort data=iedea_3a;
by varid vis_diff;
run;
**END IMPUTATION;

**Keep only each patient's observation nearest their survey mid date;
data iedea_4a;
set iedea_3a;
by varid vis_diff;
retain vis_diff vis_diff_low;
if first.varid then vis_diff_low = vis_diff;
vis_diff_low = min(vis_diff_low, vis_diff);
if first.varid then output;
run;

**Keep only patients active within 12 months of the middle of the survey mid date;
data iedea_5a;
set iedea_4a;
if vis_diff > 365 then delete;
*Calculate BMI;
bmi = weight/(height*height)*10000;
*Create BMI groups from http://apps.who.int/bmi/index.jsp?introPage=intro_3.html;
if bmi < 18.5 then bmigrp = 1;
if 18.5 <= bmi < 25 then bmigrp = 2;
if 25 <= bmi < 30 then bmigrp = 3;
if bmi >= 30 then bmigrp = 4;
attrib bmigrp format = bmi. label = "BMI Group per WHO";
run;

data iedea.iedea_rw05;
set iedea_5a;
if cohort_name='BUR' then delete;
if cohort_name='RWD' then output iedea.iedea_rw05;
RUN;

*Delete all temporary files;
proc datasets lib=work memtype=data nolist;
	delete iedea_: ;
	quit;


*B Surveys (Burundi 2010-2011 and Rwanda 2010-2011);
data iedea_b;
set iedea2;
*Create survey start and end date variables;
if cohort_name='BUR' then survey_start_d=MDY(08, 29, 2010);
if cohort_name='RWD' then survey_start_d=MDY(09, 26, 2010);
if cohort_name='BUR' then survey_end_d=MDY(01, 30, 2011);
if cohort_name='RWD' then survey_end_d=MDY(03, 10, 2011);
if cohort_name='BUR' then survey_mid_d=MDY(11, 15, 2010);
if cohort_name='RWD' then survey_mid_d=MDY(12, 18, 2010);
*Create variable that measures time difference between visit date and survey mid date;
Vis_Diff=abs(survey_mid_d-visit_date);
*Exclude patients not enrolled during relevant DHS survey, based on engagement, death, and transfer-out dates;
*if xenroll_date > survey_end_d then delete;
*if . < xdeath_date < survey_start_d then delete;
*if . < transfer_out_date < survey_start_d then delete;
*Calculate age at survey mid date and create categorical agegrp variable to match DHS surveys;
age = .;
age = INT(INTCK('MONTH', birth_date, survey_mid_d)/12);
if MONTH(birth_date) = MONTH(survey_mid_d) then age = age -(DAY(birth_date)>DAY(survey_mid_d));
agegrp = .;
if age < 0 then agegrp = .;
if 15 <= age =< 19 then agegrp = 1;
if 20 <= age =< 24 then agegrp = 2;
if 25 <= age =< 29 then agegrp = 3;
if 30 <= age =< 34 then agegrp = 4;
if 35 <= age =< 39 then agegrp = 5;
if 40 <= age =< 44 then agegrp = 6;
if 45 <= age =< 49 then agegrp = 7;
if 50 <= age =< 54 then agegrp = 8;
if 55 <= age =< 59 then agegrp = 9;
*Remove children and older adults to match DHS datasets--no HIV testing for children in respective survey;
if age < 15 then delete;
if gender = 1 and age > 59 then delete;
if gender = 2 and age > 49 then delete;
*Create adult variable to exclude children under 15;
if age > 14 then adult = 1;
else if age < 15 then adult = 0; 
*Exclude population-level height and weight outliers based on comparison to entire adult DHS cohort, per Welch 2011 paper, see IeDEA outliers syntax AND remove weight values recorded more than 365 days before or after survey mid date;
*if vis_diff > 365 then height = .;
if vis_diff > 365 then weight = .;
if cohort_name = 'BUR' and height < 90.36 then height = .;
if cohort_name = 'BUR' and height > 218.57 then height = .;
if cohort_name = 'BUR' and weight < 14.04 then weight = .;
if cohort_name = 'BUR' and weight > 164.12 then weight = .;
if cohort_name = 'RWD' and height < 95.85 then height = .;
if cohort_name = 'RWD' and height > 217.47 then height = .;
if cohort_name = 'RWD' and weight < 16.29 then weight = .;
if cohort_name = 'RWD' and weight > 144.76 then weight = .;
*Create pregnancy variable;
if cohort_name = 'RWD' then pregnant = .;
else if cohort_name = 'BUR' and survey_start_d < period_date < survey_end_d then pregnant = 1;
else if cohort_name = 'BUR' and survey_start_d < delivery_date < survey_end_d then pregnant = 1;
else if cohort_name = 'BUR' and period_date < survey_start_d and delivery_date > survey_end_d then pregnant = 1;
else pregnant = 0;
*Formats;
format survey_end_d survey_start_d survey_mid_d ddmmyys10.;
attrib pregnant format = yesno. label = "Pregnant Status during Survey";
attrib agegrp format = agegrp. label = "Age Group";
run;

**Impute missing data from closest visit date;
proc sort data=iedea_b;
by varid DESCENDING visit_date;
run;

data iedea_back_b;
set iedea_b;
by varid DESCENDING visit_date;
*Weight;
retain BackDate_w BackWard_w;
if first.varid then do; BackDate_w=.; BackWard_w=.; end;
if weight ne . then do; BackDate_w=visit_date;BackWard_w= weight;end;
if (weight = . and BackDate_w ne .) then BackDiff_w=BackDate_w-visit_date;
*Height;
retain BackDate_h BackWard_h;
if first.varid then do; BackDate_h=.; BackWard_h=.; end;
if height ne . then do; BackDate_h=visit_date;BackWard_h= height;end;
if (height = . and BackDate_h ne .) then BackDiff_h=BackDate_h-visit_date;
*Marital Status;
retain BackDate_m BackWard_m;
if first.varid then do; BackDate_m=.; BackWard_m=.; end;
if marital_status ne . then do; BackDate_m=visit_date;BackWard_m= marital_status;end;
if (marital_status =. and BackDate_m ne .) then BackDiff_m=BackDate_m-visit_date;
*Pregnancy;
retain BackDate_p BackWard_p;
if first.varid then do; BackDate_p=.; BackWard_p=.; end;
if pregnant ne . then do; BackDate_p=visit_date;BackWard_p= pregnant;end;
if (pregnant=. and BackDate_p ne .) then BackDiff_p=BackDate_p-visit_date;
format BackDate_w BackDate_h BackDate_m BackDate_p date9.;
run;

PROC SORT data=iedea_back_b;
by varid visit_date;
RUN;


DATA iedea_forward_b;
set iedea_back_b;
by varid visit_date;
*Weight;
retain ForwardDate_w ForWard_w;
if first.varid then do; ForwardDate_w=.; ForWard_w=.; end;
if weight ne . then do; ForwardDate_w= visit_date; ForWard_w= weight;end;
if (weight = . and ForwardDate_w ne .) then ForwardDiff_w= visit_date-ForwardDate_w;
*Height;
retain ForwardDate_h ForWard_h;
if first.varid then do; ForwardDate_h=.; ForWard_h=.; end;
if height ne . then do; ForwardDate_h= visit_date; ForWard_h= height;end;
if (height = . and ForwardDate_h ne .) then ForwardDiff_h= visit_date-ForwardDate_h;
*Marital Status;
retain ForwardDate_m ForWard_m;
if first.varid then do; ForwardDate_m=.; ForWard_m=.; end;
if marital_status ne . then do; ForwardDate_m= visit_date; ForWard_m= marital_status;end;
if (marital_status =. and ForwardDate_m ne .) then ForwardDiff_m= visit_date-ForwardDate_m;
*Pregnancy;
retain ForwardDate_p ForWard_p;
if first.varid then do; ForwardDate_p=.; ForWard_p=.; end;
if pregnant ne . then do; ForwardDate_p= visit_date; ForWard_p= pregnant;end;
if (pregnant=. and ForwardDate_p ne .) then ForwardDiff_p= visit_date-ForwardDate_p;
format ForwardDate_w ForwardDate_h ForwardDate_m ForwardDate_p date9.;
RUN;


DATA iedea_3b;
set iedea_forward_b;
*Weight;
if (weight = . and ForWard_w ne . and BackWard_w ne .) then /*middle*/
 do;
if ForwardDiff_w<=BackDiff_w then weight =ForWard_w;
else weight=BackWard_w;
 end;
else if (weight = . and ForWard_w ne . and BackWard_w = .) then weight =ForWard_w; /*top*/
else if (weight = . and ForWard_w = . and BackWard_w ne .) then weight =BackWard_w; /*bottom*/
*Height;
if (height = . and ForWard_h ne . and BackWard_h ne .) then /*middle*/
 do;
if ForwardDiff_h<=BackDiff_h then height =ForWard_h;
else height=BackWard_h;
 end;
else if (height = . and ForWard_h ne . and BackWard_h = .) then height=ForWard_h; /*top*/
else if (height = . and ForWard_h = . and BackWard_h ne .) then height=BackWard_h; /*bottom*/
*Marital Status;
if (marital_status=. and ForWard_m ne . and BackWard_m ne .) then /*middle*/
 do;
if ForwardDiff_m<=BackDiff_m then marital_status=ForWard_m;
else marital_status =BackWard_m;
 end;
else if (marital_status =. and ForWard_m ne . and BackWard_m = .) then marital_status =ForWard_m; /*top*/
else if (marital_status =. and ForWard_m = . and BackWard_m ne .) then marital_status =BackWard_m; /*bottom*/
*Pregnancy;
if (pregnant=. and ForWard_p ne . and BackWard_p ne .) then /*middle*/
 do;
if ForwardDiff_p<=BackDiff_p then pregnant=ForWard_p;
else pregnant =BackWard_p;
 end;
else if (pregnant =. and ForWard_p ne . and BackWard_p = .) then pregnant =ForWard_p; /*top*/
else if (pregnant =. and ForWard_p = . and BackWard_p ne .) then pregnant =BackWard_p; /*bottom*/
drop backward_w backward_h backward_m backward_p forward_w forward_h forward_m forward_p backdiff_w backdiff_h backdiff_m backdiff_p forwarddiff_w forwarddiff_h forwarddiff_m forwarddiff_p;
run;
**END IMPUTATION;

**Keep only each patient's observation nearest their survey mid date;
proc sort data=iedea_3b;
by varid vis_diff;
run;

data iedea_4b;
set iedea_3b;
by varid vis_diff;
retain vis_diff vis_diff_low;
if first.varid then vis_diff_low = vis_diff;
vis_diff_low = min(vis_diff_low, vis_diff);
if first.varid then output;
run;

**Keep only patients active within 12 months of the middle of the survey;
data iedea_5b;
set iedea_4b;
if vis_diff > 365 then delete;
*Calculate BMI;
bmi = weight/(height*height)*10000;
*Create BMI groups from http://apps.who.int/bmi/index.jsp?introPage=intro_3.html;
if bmi < 18.5 then bmigrp = 1;
if 18.5 <= bmi < 25 then bmigrp = 2;
if 25 <= bmi < 30 then bmigrp = 3;
if bmi >= 30 then bmigrp = 4;
attrib bmigrp format = bmi. label = "BMI Group per WHO";
run;

**Split into datasets by country;
data iedea.iedea_bu11 iedea.iedea_rw11;
set iedea_5b;
if cohort_name='BUR' then output iedea.iedea_bu11;
if cohort_name='RWD' then output iedea.iedea_rw11;
RUN;

**END B SURVEYS;

*Delete all temporary files;
proc datasets lib=work memtype=data nolist;
	delete iedea_: ;
	quit;


*C Surveys (Burundi 2016-2017 and Rwanda 2014-2015);
data iedea_c;
set iedea2;
*Create survey start and end date variables;
if cohort_name='BUR' then survey_start_d=MDY(10, 09, 2016);
if cohort_name='RWD' then survey_start_d=MDY(11, 09, 2014);
if cohort_name='BUR' then survey_end_d=MDY(03, 07, 2017);
if cohort_name='RWD' then survey_end_d=MDY(04, 08, 2015);
if cohort_name='BUR' then survey_mid_d=MDY(12, 23, 2016);
if cohort_name='RWD' then survey_mid_d=MDY(01, 23, 2015);
*Create variable that measures time difference between visit date and survey mid date;
Vis_Diff=abs(survey_mid_d-visit_date);
*Exclude patients not enrolled during relevant DHS survey, based on engagement, death, and transfer-out dates;
*if xenroll_date > survey_end_d then delete;
*if . < xdeath_date < survey_start_d then delete;
*if . < transfer_out_date < survey_start_d then delete;
*Calculate age at survey mid date and create categorical agegrp variable to match DHS surveys;
age = .;
age = INT(INTCK('MONTH', birth_date, survey_mid_d)/12);
if MONTH(birth_date) = MONTH(survey_mid_d) then age = age -(DAY(birth_date)>DAY(survey_mid_d));
agegrp = .;
if age < 0 then agegrp = .;
if 15 <= age =< 19 then agegrp = 1;
if 20 <= age =< 24 then agegrp = 2;
if 25 <= age =< 29 then agegrp = 3;
if 30 <= age =< 34 then agegrp = 4;
if 35 <= age =< 39 then agegrp = 5;
if 40 <= age =< 44 then agegrp = 6;
if 45 <= age =< 49 then agegrp = 7;
if 50 <= age =< 54 then agegrp = 8;
if 55 <= age =< 59 then agegrp = 9;
*Remove children and older adults to match DHS datasets--HIV testing for children in respective survey too limited and sample size too small;
if age < 15 then delete;
if gender = 1 and age > 59 then delete;
if gender = 2 and age > 49 then delete;
*Create adult variable to exclude children under 15;
if age > 14 then adult = 1;
else if age < 15 then adult = 0; 
*Exclude population-level height and weight outliers based on comparison to entire adult DHS cohort, per Welch 2011 paper, see IeDEA outliers syntax AND remove weight values recorded more than 365 days before or after survey mid date;
*if vis_diff > 365 then height = .;
if vis_diff > 365 then weight = .;
if cohort_name = 'BUR' and height < 91.89 then height = .;
if cohort_name = 'BUR' and height > 199.1 then height = .;
if cohort_name = 'BUR' and weight < 21.42 then weight = .;
if cohort_name = 'BUR' and weight > 128.92 then weight = .;
if cohort_name = 'RWD' and height < 108.9 then height = .;
if cohort_name = 'RWD' and height > 220.0 then height = .;
if cohort_name = 'RWD' and weight < 23.94 then weight = .;
if cohort_name = 'RWD' and weight > 158.29 then weight = .;
*Create pregnancy variable;
if cohort_name = 'RWD' then pregnant = .;
else if cohort_name = 'BUR' and survey_start_d < period_date < survey_end_d then pregnant = 1;
else if cohort_name = 'BUR' and survey_start_d < delivery_date < survey_end_d then pregnant = 1;
else if cohort_name = 'BUR' and period_date < survey_start_d and delivery_date > survey_end_d then pregnant = 1;
else pregnant = 0;
*Formats;
format survey_end_d survey_start_d survey_mid_d ddmmyys10.;
attrib pregnant format = yesno. label = "Pregnant Status during Survey";
attrib agegrp format = agegrp. label = "Age Group";
run;

**Impute missing data from closest visit date;
proc sort data=iedea_c;
by varid DESCENDING visit_date;
run;

data iedea_back_c;
set iedea_c;
by varid DESCENDING visit_date;
*Weight;
retain BackDate_w BackWard_w;
if first.varid then do; BackDate_w=.; BackWard_w=.; end;
if weight ne . then do; BackDate_w=visit_date;BackWard_w= weight;end;
if (weight = . and BackDate_w ne .) then BackDiff_w=BackDate_w-visit_date;
*Height;
retain BackDate_h BackWard_h;
if first.varid then do; BackDate_h=.; BackWard_h=.; end;
if height ne . then do; BackDate_h=visit_date;BackWard_h= height;end;
if (height = . and BackDate_h ne .) then BackDiff_h=BackDate_h-visit_date;
*Marital Status;
retain BackDate_m BackWard_m;
if first.varid then do; BackDate_m=.; BackWard_m=.; end;
if marital_status ne . then do; BackDate_m=visit_date;BackWard_m= marital_status;end;
if (marital_status =. and BackDate_m ne .) then BackDiff_m=BackDate_m-visit_date;
*Pregnancy;
retain BackDate_p BackWard_p;
if first.varid then do; BackDate_p=.; BackWard_p=.; end;
if pregnant ne . then do; BackDate_p=visit_date;BackWard_p= pregnant;end;
if (pregnant=. and BackDate_p ne .) then BackDiff_p=BackDate_p-visit_date;
format BackDate_w BackDate_h BackDate_m BackDate_p date9.;
run;

PROC SORT data=iedea_back_c;
by varid visit_date;
RUN;

DATA iedea_forward_c;
set iedea_back_c;
by varid visit_date;
*Weight;
retain ForwardDate_w ForWard_w;
if first.varid then do; ForwardDate_w=.; ForWard_w=.; end;
if weight ne . then do; ForwardDate_w= visit_date; ForWard_w= weight;end;
if (weight = . and ForwardDate_w ne .) then ForwardDiff_w= visit_date-ForwardDate_w;
*Height;
retain ForwardDate_h ForWard_h;
if first.varid then do; ForwardDate_h=.; ForWard_h=.; end;
if height ne . then do; ForwardDate_h= visit_date; ForWard_h= height;end;
if (height = . and ForwardDate_h ne .) then ForwardDiff_h= visit_date-ForwardDate_h;
*Marital Status;
retain ForwardDate_m ForWard_m;
if first.varid then do; ForwardDate_m=.; ForWard_m=.; end;
if marital_status ne . then do; ForwardDate_m= visit_date; ForWard_m= marital_status;end;
if (marital_status =. and ForwardDate_m ne .) then ForwardDiff_m= visit_date-ForwardDate_m;
*Pregnancy;
retain ForwardDate_p ForWard_p;
if first.varid then do; ForwardDate_p=.; ForWard_p=.; end;
if pregnant ne . then do; ForwardDate_p= visit_date; ForWard_p= pregnant;end;
if (pregnant=. and ForwardDate_p ne .) then ForwardDiff_p= visit_date-ForwardDate_p;
format ForwardDate_w ForwardDate_h ForwardDate_m ForwardDate_p date9.;
RUN;


DATA iedea_3c;
set iedea_forward_c;
*Weight;
if (weight = . and ForWard_w ne . and BackWard_w ne .) then /*middle*/
 do;
if ForwardDiff_w<=BackDiff_w then weight =ForWard_w;
else weight=BackWard_w;
 end;
else if (weight = . and ForWard_w ne . and BackWard_w = .) then weight =ForWard_w; /*top*/
else if (weight = . and ForWard_w = . and BackWard_w ne .) then weight =BackWard_w; /*bottom*/
*Height;
if (height = . and ForWard_h ne . and BackWard_h ne .) then /*middle*/
 do;
if ForwardDiff_h<=BackDiff_h then height =ForWard_h;
else height=BackWard_h;
 end;
else if (height = . and ForWard_h ne . and BackWard_h = .) then height=ForWard_h; /*top*/
else if (height = . and ForWard_h = . and BackWard_h ne .) then height=BackWard_h; /*bottom*/
*Marital Status;
if (marital_status=. and ForWard_m ne . and BackWard_m ne .) then /*middle*/
 do;
if ForwardDiff_m<=BackDiff_m then marital_status=ForWard_m;
else marital_status =BackWard_m;
 end;
else if (marital_status =. and ForWard_m ne . and BackWard_m = .) then marital_status =ForWard_m; /*top*/
else if (marital_status =. and ForWard_m = . and BackWard_m ne .) then marital_status =BackWard_m; /*bottom*/
*Pregnancy;
if (pregnant=. and ForWard_p ne . and BackWard_p ne .) then /*middle*/
 do;
if ForwardDiff_p<=BackDiff_p then pregnant=ForWard_p;
else pregnant =BackWard_p;
 end;
else if (pregnant =. and ForWard_p ne . and BackWard_p = .) then pregnant =ForWard_p; /*top*/
else if (pregnant =. and ForWard_p = . and BackWard_p ne .) then pregnant =BackWard_p; /*bottom*/
drop backward_w backward_h backward_m backward_p forward_w forward_h forward_m forward_p backdiff_w backdiff_h backdiff_m backdiff_p forwarddiff_w forwarddiff_h forwarddiff_m forwarddiff_p;
run;
**END IMPUTATION;


**Keep only each patient's observation nearest their survey mid date;
proc sort data=iedea_3c;
by varid vis_diff;
run;

data iedea_4c;
set iedea_3c;
by varid vis_diff;
retain vis_diff vis_diff_low;
if first.varid then vis_diff_low = vis_diff;
vis_diff_low = min(vis_diff_low, vis_diff);
if first.varid then output;
run;

**Keep only patients active within 12 months of the middle of the survey;
data iedea_5c;
set iedea_4c;
if vis_diff > 365 then delete;
*Calculate BMI;
bmi = weight/(height*height)*10000;
*Create BMI groups from http://apps.who.int/bmi/index.jsp?introPage=intro_3.html;
if bmi < 18.5 then bmigrp = 1;
if 18.5 <= bmi < 25 then bmigrp = 2;
if 25 <= bmi < 30 then bmigrp = 3;
if bmi >= 30 then bmigrp = 4;
attrib bmigrp format = bmi. label = "BMI Group per WHO";
run;

**Split into datasets by country;
data iedea.iedea_bu17 iedea.iedea_rw15;
set iedea_5c;
if cohort_name='BUR' then output iedea.iedea_bu17;
if cohort_name='RWD' then output iedea.iedea_rw15;
run;

**END C SURVEYS;

*Delete all temporary files;
proc datasets lib=work memtype=data nolist;
	delete iedea_: ;
	quit;



/*Prepare DHS Data*/


***A Survey;


*RWANDA 2005 DHS DATA CLEANING;

**Household member sample;
data rwhhm05;
set dhs.rwpr53fl;
cluster=hv001;
household=hv002;
line=hvIDX;
stratum=hv024*hv025;
gender=hv104;
age=hv105;
urban=hv025;
weighthh=ha2/10;
heighthh=ha3/10;
bmihh=ha40/100;
keep cluster household line stratum gender age urban weighthh heighthh bmihh;
run;

**Women's sample;
data rwwomen05;
set dhs.rwir53fl;
cluster=v001;
household=v002;
line=v003;
stratum=v024*v025;
pregnant=v213;
mar_stat=v501;
bmiin=v445/100;
hiv_tested=v781;
hiv_result=v828;
keep cluster household line stratum pregnant mar_stat bmiin hiv_tested hiv_result;
run;

**Men's sample;
data rwmen05;
set dhs.rwmr53fl;
cluster=mv001;
household=mv002;
line=mv003;
stratum=mv024*mv025;
pregnant=.;
mar_stat=mv501;
bmiin=.;
hiv_tested=mv781;
hiv_result=mv828;
keep cluster household line stratum pregnant mar_stat bmiin hiv_tested hiv_result;
run;

**Append men's sample to women's sample;
data rwcom05;
set rwwomen05 rwmen05;
run;

**HIV sample;
data rwhiv05;
set dhs.rwar51fl;
cluster=hivclust;
household=hivnumb;
line=hivline;
wgt=hiv05/1000000;
hiv=hiv03;
keep cluster household line hiv wgt;
run;

**Sort datasets before merging;
proc sort data=rwhhm05 out=rwhhm05_2;
by cluster household line;
run;

proc sort data=rwcom05 out=rwcom05_2;
by cluster household line;
run;

proc sort data=rwhiv05 out=rwhiv05_2;
by cluster household line;
run;


**Merge  Individual + Household Member + HIV files, includes all HIV+ and HIV-;
data dhs_rw05;
merge rwhhm05_2 rwcom05_2 rwhiv05_2;
by cluster household line;
dataset=1;
if age ge 15 and age le 19 then agegrp = 1;
if age ge 20 and age le 24 then agegrp = 2;
if age ge 25 and age le 29 then agegrp = 3;
if age ge 30 and age le 34 then agegrp = 4;
if age ge 35 and age le 39 then agegrp = 5;
if age ge 40 and age le 44 then agegrp = 6;
if age ge 45 and age le 49 then agegrp = 7;
if age ge 50 and age le 54 then agegrp = 8;
if age ge 55 and age le 59 then agegrp = 9;
if age ge 60 and age le 64 then agegrp = 10;
if age ge 65 and age le 69 then agegrp = 11;
if age ge 70 and age le 74 then agegrp = 12;
if age ge 75 then agegrp = 13;
if age lt 5 then agegrp = 14;
if age ge 5 and age le 9 then agegrp = 15;
if age ge 10 and age le 14 then agegrp = 16;
*Create adult variable to exclude children under 15;
if age > 14 then adult = 1;
else if age < 15 then adult = 0; 
*Recode marital status to match IeDEA;
if mar_stat=0 then marital_status=0;
if mar_stat=1 or mar_stat=2 then marital_status=1;
if mar_stat=3 then marital_status=2;
if mar_stat=4 or mar_stat=5 then marital_status=3;
if weight > 400 then weight=.;
if height > 220 then height=.;
*Code new BMI variable to use measurement from individual survey unless missing, in which case use BMI from household survey;
if bmiin ne . then bmi = bmiin;
else if bmiin = . then bmi = bmihh;
*Create BMI groups from http://apps.who.int/bmi/index.jsp?introPage=intro_3.html;
if . < bmi < 18.5 then bmigrp = 1;
if 18.5 <= bmi < 25 then bmigrp = 2;
if 25 <= bmi < 30 then bmigrp = 3;
if bmi >= 30 then bmigrp = 4;
drop mar_stat;
format gender sex.;
format adult pregnant yesno.;
format urban urban.;
format marital_status marital.;
format agegrp agegrp.;
attrib bmigrp format = bmi. label = "BMI Group per WHO";
attrib hiv_tested format=yesno. label="Ever been tested for HIV";
attrib hiv_result format=yesno. label="Received result from last HIV test";
run;

*Delete all but final temporary files;
proc datasets lib=work memtype=data nolist;
	delete rw: ;
	quit;




***B Surveys;


*BURUNDI 2011 DHS DATA CLEANING;

**Household member sample;
data buhhm11;
set dhs.bupr61fl;
cluster=hv001;
household=hv002;
line=hvIDX;
stratum=hv022;
gender=hv104;
age=hv105;
urban=hv025;
if gender=1 then weighthh=hb2/10;
if gender=2 then weighthh=ha2/10;
if gender=1 then heighthh=hb3/10;
if gender=2 then heighthh=ha3/10;
if gender=1 then bmihh=hb40/100;
if gender=2 then bmihh=ha40/100;
keep cluster household line stratum gender age urban weighthh heighthh bmihh;
run;

**Women's sample;
data buwomen11;
set dhs.buir61fl;
cluster=v001;
household=v002;
line=v003;
stratum=v022;
pregnant=v213;
mar_stat=v501;
bmiin=v445/100;
hiv_tested=v781;
hiv_result=v828;
keep cluster household line stratum pregnant mar_stat bmiin hiv_tested hiv_result;
run;

**Men's sample;
data bumen11;
set dhs.bumr61fl;
cluster=mv001;
household=mv002;
line=mv003;
stratum=mv022;
pregnant=0;
mar_stat=mv501;
bmiin=.;
hiv_tested=mv781;
hiv_result=mv828;
keep cluster household line stratum pregnant mar_stat bmiin hiv_tested hiv_result;
run;

**Append men's sample to women's sample;
data bucom11;
set buwomen11 bumen11;
run;

**HIV sample;
data buhiv11;
set dhs.buar61fl;
cluster=hivclust;
household=hivnumb;
line=hivline;
wgt=hiv05/1000000;
hiv=hiv03;
keep cluster household line hiv wgt;
run;

**Sort datasets before merging;
proc sort data=buhhm11 out=buhhm11_2;
by cluster household line;
run;

proc sort data=bucom11 out=bucom11_2;
by cluster household line;
run;

proc sort data=buhiv11 out=buhiv11_2;
by cluster household line;
run;

**Merge  Individual + Household Member + HIV files, includes all HIV+ and HIV-;
data dhs_bu11;
merge buhhm11_2 bucom11_2 buhiv11_2;
by cluster household line;
dataset=1;
if age ge 15 and age le 19 then agegrp = 1;
if age ge 20 and age le 24 then agegrp = 2;
if age ge 25 and age le 29 then agegrp = 3;
if age ge 30 and age le 34 then agegrp = 4;
if age ge 35 and age le 39 then agegrp = 5;
if age ge 40 and age le 44 then agegrp = 6;
if age ge 45 and age le 49 then agegrp = 7;
if age ge 50 and age le 54 then agegrp = 8;
if age ge 55 and age le 59 then agegrp = 9;
if age ge 60 and age le 64 then agegrp = 10;
if age ge 65 and age le 69 then agegrp = 11;
if age ge 70 and age le 74 then agegrp = 12;
if age ge 75 then agegrp = 13;
if age lt 5 then agegrp = 14;
if age ge 5 and age le 9 then agegrp = 15;
if age ge 10 and age le 14 then agegrp = 16;
*Create adult variable to exclude children under 15;
if age > 14 then adult = 1;
else if age < 15 then adult = 0; 
*Recode marital status to match IeDEA;
if mar_stat=0 then marital_status=0;
if mar_stat=1 or mar_stat=2 then marital_status=1;
if mar_stat=3 then marital_status=2;
if mar_stat=4 or mar_stat=5 then marital_status=3;
if weight > 400 then weight=.;
if height > 220 then height=.;
*Code new BMI variable to use measurement from individual survey unless missing, in which case use BMI from household survey;
if bmiin ne . then bmi = bmiin;
else if bmiin = . then bmi = bmihh;
*Create BMI groups from http://apps.who.int/bmi/index.jsp?introPage=intro_3.html;
if . < bmi < 18.5 then bmigrp = 1;
if 18.5 <= bmi < 25 then bmigrp = 2;
if 25 <= bmi < 30 then bmigrp = 3;
if bmi >= 30 then bmigrp = 4;
drop mar_stat;
format gender sex.;
format adult pregnant yesno.;
format urban urban.;
format marital_status marital.;
format agegrp agegrp.;
attrib bmigrp format = bmi. label = "BMI Group per WHO";
attrib hiv_tested format=yesno. label="Ever been tested for HIV";
attrib hiv_result format=yesno. label="Received result from last HIV test";
run;

*Delete all but final temporary files;
proc datasets lib=work memtype=data nolist;
	delete bu: ;
	quit;




*RWANDA 2011 DHS DATA CLEANING;

**Household member sample;
data rwhhm11;
set dhs.rwpr61fl;
cluster=hv001;
household=hv002;
line=hvIDX;
stratum=hv023;
gender=hv104;
age=hv105;
urban=hv025;
if gender=1 then weighthh=hb2/10;
if gender=2 then weighthh=ha2/10;
if gender=1 then heighthh=hb3/10;
if gender=2 then heighthh=ha3/10;
if gender=1 then bmihh=hb40/100;
if gender=2 then bmihh=ha40/100;
mar_stat=hv115;
pregnant=HA54;
keep cluster household line stratum gender age urban weighthh heighthh bmihh;
run;


**Women's sample;
data rwwomen11;
set dhs.rwir61fl;
cluster=v001;
household=v002;
line=v003;
stratum=v023;
pregnant=v213;
mar_stat=v501;
bmiin=v445/100;
hiv_tested=v781;
hiv_result=v828;
keep cluster household line stratum pregnant mar_stat bmiin hiv_tested hiv_result;
run;


**Men's sample;
data rwmen11;
set dhs.rwmr61fl;
cluster=mv001;
household=mv002;
line=mv003;
stratum=mv023;
pregnant=.;
mar_stat=mv501;
bmiin=.;
hiv_tested=mv781;
hiv_result=mv828;
keep cluster household line stratum pregnant mar_stat bmiin hiv_tested hiv_result;
run;

**Append men's sample to women's sample;
data rwcom11;
set rwwomen11 rwmen11;
run;


**HIV sample;
data rwhiv11;
set dhs.rwar61fl;
cluster=hivclust;
household=hivnumb;
line=hivline;
wgt=hiv05/1000000;
hiv=hiv03;
keep cluster household line hiv wgt;
run;


**Sort datasets before merging;
proc sort data=rwhhm11 out=rwhhm11_2;
by cluster household line;
run;

proc sort data=rwcom11 out=rwcom11_2;
by cluster household line;
run;

proc sort data=rwhiv11 out=rwhiv11_2;
by cluster household line;
run;


**Merge  Individual + Household Member + HIV files, includes all HIV+ and HIV-;
data dhs_rw11;
merge rwhhm11_2 rwcom11_2 rwhiv11_2;
by cluster household line;
dataset=1;
if age ge 15 and age le 19 then agegrp = 1;
if age ge 20 and age le 24 then agegrp = 2;
if age ge 25 and age le 29 then agegrp = 3;
if age ge 30 and age le 34 then agegrp = 4;
if age ge 35 and age le 39 then agegrp = 5;
if age ge 40 and age le 44 then agegrp = 6;
if age ge 45 and age le 49 then agegrp = 7;
if age ge 50 and age le 54 then agegrp = 8;
if age ge 55 and age le 59 then agegrp = 9;
if age ge 60 and age le 64 then agegrp = 10;
if age ge 65 and age le 69 then agegrp = 11;
if age ge 70 and age le 74 then agegrp = 12;
if age ge 75 then agegrp = 13;
if age lt 5 then agegrp = 14;
if age ge 5 and age le 9 then agegrp = 15;
if age ge 10 and age le 14 then agegrp = 16;
*Create adult variable to exclude children under 15;
if age > 14 then adult = 1;
else if age < 15 then adult = 0; 
*Recode marital status to match IeDEA;
if mar_stat=0 then marital_status=0;
if mar_stat=1 or mar_stat=2 then marital_status=1;
if mar_stat=3 then marital_status=2;
if mar_stat=4 or mar_stat=5 then marital_status=3;
if weight > 400 then weight=.;
if height > 220 then height=.;
*Code new BMI variable to use measurement from individual survey unless missing, in which case use BMI from household survey;
if bmiin ne . then bmi = bmiin;
else if bmiin = . then bmi = bmihh;
*Create BMI groups from http://apps.who.int/bmi/index.jsp?introPage=intro_3.html;
if . < bmi < 18.5 then bmigrp = 1;
if 18.5 <= bmi < 25 then bmigrp = 2;
if 25 <= bmi < 30 then bmigrp = 3;
if bmi >= 30 then bmigrp = 4;
drop mar_stat;
format gender sex.;
format adult pregnant yesno.;
format urban urban.;
format marital_status marital.;
format agegrp agegrp.;
attrib bmigrp format = bmi. label = "BMI Group per WHO";
attrib hiv_tested format=yesno. label="Ever been tested for HIV";
attrib hiv_result format=yesno. label="Received result from last HIV test";
run;

*Delete all but final temporary files;
proc datasets lib=work memtype=data nolist;
	delete rw: ;
	quit;





***C Surveys;


*BURUNDI 2017 DHS DATA CLEANING;
**Household member sample;
data buhhm17;
set dhs.bupr70fl;
cluster=hv001;
household=hv002;
line=hvIDX;
stratum=hv022;
gender=hv104;
age=hv105;
urban=hv025;
if gender=1 and age > 14 then weighthh=hb2/10;
if gender=2 and age > 14 then weighthh=ha2/10;
if gender=1 and age > 14 then heighthh=hb3/10;
if gender=2 and age > 14 then heighthh=ha3/10;
if gender=1 then bmihh=hb40/100;
if gender=2 then bmihh=ha40/100;
mar_stat=hv115;
keep cluster household line stratum gender age urban weighthh heighthh bmihh;
run;

**Women's sample;
data buwomen17;
set dhs.buir70fl;
cluster=v001;
household=v002;
line=v003;
stratum=v022;
pregnant=v213;
mar_stat=v501;
bmiin=v445/100;
hiv_tested=v781;
hiv_result=v828;
keep cluster household line stratum pregnant mar_stat bmiin hiv_tested hiv_result;
run;

**Men's sample;
data bumen17;
set dhs.bumr70fl;
cluster=mv001;
household=mv002;
line=mv003;
stratum=mv022;
pregnant=0;
mar_stat=mv501;
bmiin=.;
hiv_tested=mv781;
hiv_result=mv828;
keep cluster household line stratum pregnant mar_stat bmiin hiv_tested hiv_result;
run;

**Append men's sample to women's sample;
data bucom17;
set buwomen17 bumen17;
run;

**HIV sample;
data buhiv17;
set dhs.buar71fl;
cluster=hivclust;
household=hivnumb;
line=hivline;
wgt=hiv05/1000000;
hiv=hiv03;
keep cluster household line hiv wgt;
run;

**Sort datasets before merging;
proc sort data=buhhm17 out=buhhm17_2;
by cluster household line;
run;

proc sort data=bucom17 out=bucom17_2;
by cluster household line;
run;

proc sort data=buhiv17 out=buhiv17_2;
by cluster household line;
run;

**Merge  Individual + Household Member + HIV files, includes all HIV+ and HIV-;
data dhs_bu17;
merge buhhm17_2 bucom17_2 buhiv17_2;
by cluster household line;
dataset=1;
if age ge 15 and age le 19 then agegrp = 1;
if age ge 20 and age le 24 then agegrp = 2;
if age ge 25 and age le 29 then agegrp = 3;
if age ge 30 and age le 34 then agegrp = 4;
if age ge 35 and age le 39 then agegrp = 5;
if age ge 40 and age le 44 then agegrp = 6;
if age ge 45 and age le 49 then agegrp = 7;
if age ge 50 and age le 54 then agegrp = 8;
if age ge 55 and age le 59 then agegrp = 9;
if age ge 60 and age le 64 then agegrp = 10;
if age ge 65 and age le 69 then agegrp = 11;
if age ge 70 and age le 74 then agegrp = 12;
if age ge 75 then agegrp = 13;
if age lt 5 then agegrp = 14;
if age ge 5 and age le 9 then agegrp = 15;
if age ge 10 and age le 14 then agegrp = 16;
*Create adult variable to exclude children under 15;
if age > 14 then adult = 1;
else if age < 15 then adult = 0; 
*Recode marital status to match IeDEA;
if mar_stat=0 then marital_status=0;
if mar_stat=1 or mar_stat=2 then marital_status=1;
if mar_stat=3 then marital_status=2;
if mar_stat=4 or mar_stat=5 then marital_status=3;
if weight > 400 then weight=.;
if height > 220 then height=.;
*Code new BMI variable to use measurement from individual survey unless missing, in which case use BMI from household survey;
if bmiin ne . then bmi = bmiin;
else if bmiin = . then bmi = bmihh;
*Create BMI groups from http://apps.who.int/bmi/index.jsp?introPage=intro_3.html;
if . < bmi < 18.5 then bmigrp = 1;
if 18.5 <= bmi < 25 then bmigrp = 2;
if 25 <= bmi < 30 then bmigrp = 3;
if bmi >= 30 then bmigrp = 4;
drop mar_stat;
format gender sex.;
format adult pregnant yesno.;
format urban urban.;
format marital_status marital.;
format agegrp agegrp.;
attrib bmigrp format = bmi. label = "BMI Group per WHO";
attrib hiv_tested format=yesno. label="Ever been tested for HIV";
attrib hiv_result format=yesno. label="Received result from last HIV test";
run;


*Delete all but final temporary files;
proc datasets lib=work memtype=data nolist;
	delete bu: ;
	quit;





*RWANDA 2015 DHS DATA CLEANING;
**Household member sample;
data rwhhm15;
set dhs.rwpr70fl;
cluster=hv001;
household=hv002;
line=hvIDX;
stratum=hv022;
gender=hv104;
age=hv105;
urban=hv025;
if gender=1 and age > 14 then weighthh=hb2/10;
if gender=2 and age > 14 then weighthh=ha2/10;
if gender=1 and age > 14 then heighthh=hb3/10;
if gender=2 and age > 14 then heighthh=ha3/10;
if gender=1 and age > 14 then bmihh=hb40/100;
if gender=2 and age > 14 then bmihh=ha40/100;
keep cluster household line gender age stratum urban weighthh heighthh bmihh hiv_result;
run;


**Women's sample;
data rwwomen15;
set dhs.rwir70fl;
cluster=v001;
household=v002;
line=v003;
stratum=v022;
pregnant=v213;
mar_stat=v501;
bmiin=v445/100;
hiv_tested=v781;
hiv_result=v828;
keep cluster household line stratum pregnant mar_stat bmiin hiv_tested hiv_result;
run;


**Men's sample;
data rwmen15;
set dhs.rwmr70fl;
cluster=mv001;
household=mv002;
line=mv003;
stratum=mv022;
pregnant=.;
mar_stat=mv501;
bmiin=.;
hiv_tested=mv781;
hiv_result=mv828;
keep cluster household line stratum pregnant mar_stat bmiin hiv_tested hiv_result;
run;

**Append men's sample to women's sample;
data rwcom15;
set rwwomen15 rwmen15;
run;


**HIV sample;
data rwhiv15;
set dhs.rwar71fl;
cluster=hivclust;
household=hivnumb;
line=hivline;
wgt=hiv05/1000000;
hiv=hiv03;
keep cluster household line hiv wgt;
run;


**Sort datasets before merging;
proc sort data=rwhhm15 out=rwhhm15_2;
by cluster household line;
run;

proc sort data=rwcom15 out=rwcom15_2;
by cluster household line;
run;

proc sort data=rwhiv15 out=rwhiv15_2;
by cluster household line;
run;


**Merge  Individual + Household Member + HIV files, includes all HIV+ and HIV-;
data dhs_rw15;
merge rwhhm15_2 rwcom15_2 rwhiv15_2;
by cluster household line;
dataset=1;
if age ge 15 and age le 19 then agegrp = 1;
if age ge 20 and age le 24 then agegrp = 2;
if age ge 25 and age le 29 then agegrp = 3;
if age ge 30 and age le 34 then agegrp = 4;
if age ge 35 and age le 39 then agegrp = 5;
if age ge 40 and age le 44 then agegrp = 6;
if age ge 45 and age le 49 then agegrp = 7;
if age ge 50 and age le 54 then agegrp = 8;
if age ge 55 and age le 59 then agegrp = 9;
if age ge 60 and age le 64 then agegrp = 10;
if age ge 65 and age le 69 then agegrp = 11;
if age ge 70 and age le 74 then agegrp = 12;
if age ge 75 then agegrp = 13;
if age lt 5 then agegrp = 14;
if age ge 5 and age le 9 then agegrp = 15;
if age ge 10 and age le 14 then agegrp = 16;
*Create adult variable to exclude children under 15;
if age > 14 then adult = 1;
else if age < 15 then adult = 0; 
*Recode marital status to match IeDEA;
if mar_stat=0 then marital_status=0;
if mar_stat=1 or mar_stat=2 then marital_status=1;
if mar_stat=3 then marital_status=2;
if mar_stat=4 or mar_stat=5 then marital_status=3;
if weight > 400 then weight=.;
if height > 220 then height=.;
*Code new BMI variable to use measurement from individual survey unless missing, in which case use BMI from household survey;
if bmiin ne . then bmi = bmiin;
else if bmiin = . then bmi = bmihh;
*Create BMI groups from http://apps.who.int/bmi/index.jsp?introPage=intro_3.html;
if . < bmi < 18.5 then bmigrp = 1;
if 18.5 <= bmi < 25 then bmigrp = 2;
if 25 <= bmi < 30 then bmigrp = 3;
if bmi >= 30 then bmigrp = 4;
drop mar_stat;
format gender sex.;
format adult pregnant yesno.;
format urban urban.;
format marital_status marital.;
format agegrp agegrp.;
attrib bmigrp format = bmi. label = "BMI Group per WHO";
attrib hiv_tested format=yesno. label="Ever been tested for HIV";
attrib hiv_result format=yesno. label="Received result from last HIV test";
run;

*Delete all but final temporary files;
proc datasets lib=work memtype=data nolist;
	delete rw: ;
	quit;



*KNOW STATUS;
***APPEND IEDEA AND DHS DATASETS;

proc format;
	value domain
      0 = 'HIV Negative and/or Dont Know Status and/or Rural'
      1 = 'HIV+ Urban Men Know Status'
      2 = 'HIV+ Urban Women Know Status';
run;

*Burundi;
data final.bu_11;
set iedea.iedea_bu11 dhs_bu11;
*Create domain variable for freq tables;
if gender=1 and adult=1 and urban=1 and HIV=1 and HIV_result=1 then domain=1;
else if gender=2 and adult=1 and urban=1 and HIV=1 and HIV_result=1 then domain=2;
else domain=0;
format domain domain.;
run;


data final.bu_17;
set iedea.iedea_bu17 dhs_bu17;
*Create domain variable for freq tables;
if gender=1 and adult=1 and urban=1 and HIV=1 and HIV_result=1 then domain=1;
else if gender=2 and adult=1 and urban=1 and HIV=1 and HIV_result=1 then domain=2;
else domain=0;
format domain domain.;
run;


*Rwanda;
data final.rw_05;
set iedea.iedea_rw05 dhs_rw05;
*Create domain variable for freq tables;
if gender=1 and adult=1 and urban=1 and HIV=1 and HIV_result=1 then domain=1;
else if gender=2 and adult=1 and urban=1 and HIV=1 and HIV_result=1 then domain=2;
else domain=0;
format domain domain.;
run;

data final.rw_11;
set iedea.iedea_rw11 dhs_rw11;
*Create domain variable for freq tables;
if gender=1 and adult=1 and urban=1 and HIV=1 and HIV_result=1 then domain=1;
else if gender=2 and adult=1 and urban=1 and HIV=1 and HIV_result=1 then domain=2;
else domain=0;
format domain domain.;
run;

data final.rw_15;
set iedea.iedea_rw15 dhs_rw15;
*Create domain variable for freq tables;
if gender=1 and adult=1 and urban=1 and HIV=1 and HIV_result=1 then domain=1;
else if gender=2 and adult=1 and urban=1 and HIV=1 and HIV_result=1 then domain=2;
else domain=0;
format domain domain.;
run;




*ods pdf file = "iedea_output_know.pdf";
***MAIN ANALYSES;
ods excel file='H:\Anna\IeDEA\SAS KNOW STATUS Output.xlsx'
options(embedded_titles ='on');


**BURUNDI 2011 HIV+ knows status;

*Age groups;
proc surveyfreq data=final.bu_11;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*agegrp / row;
title "Burundi 2011 Know Status Age group Z-Test Output";
run;

*Marital Status;
proc surveyfreq data=final.bu_11;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*marital_status / row;
title "Burundi 2011 Know Status Marital Status Z-Test Output";
run;

*BMI groups;
proc surveyfreq data=final.bu_11;
weight wgt;
cluster cluster;
strata stratum;
tables pregnant*dataset*domain*bmigrp / row; *Separating out pregnant people;
title "Burundi 2011 Know Status BMI group Z-Test Output";
run;

*Pregnancy Status;
proc surveyfreq data=final.bu_11;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*pregnant / row;
title "Burundi 2011 Know Status Pregnancy Status Z-Test Output";
run;


**BURUNDI 2017 HIV+ knows status;

*Age groups;
proc surveyfreq data=final.bu_17;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*agegrp / row;
title "Burundi 2017 Know Status Age group Z-Test Output";
run;

*Marital Status;
proc surveyfreq data=final.bu_17;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*marital_status / row;
title "Burundi 2017 Know Status Marital Status Z-Test Output";
run;

*BMI groups;
proc surveyfreq data=final.bu_17;
weight wgt;
cluster cluster;
strata stratum;
tables pregnant*dataset*domain*bmigrp / row; *Separating out pregnant people;
title "Burundi 2017 Know Status BMI group Z-Test Output";
run;

*Pregnancy Status;
proc surveyfreq data=final.bu_17;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*pregnant / row;
title "Burundi 2017 Know Status Pregnancy Status Z-Test Output";
run;




**RWANDA 2005 HIV+ knows status;

*Age groups;
proc surveyfreq data=final.rw_05;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*agegrp / row;
title "Rwanda 2005 Know Status Age group Z-Test Output";
run;


*Marital Status;
proc surveyfreq data= final.rw_05;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*marital_status / row;
title "Rwanda 2005 Know Status Marital Status Z-Test Output";
run;

*BMI groups;
proc surveyfreq data= final.rw_05;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*bmigrp / row;
title "Rwanda 2005 Know Status BMI group Z-Test Output";
run;

*No RWD pregnancy data;



**Rwanda 2011 HIV+ knows status;

*Age groups;
proc surveyfreq data=final.rw_11;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*agegrp / row;
title "Rwanda 2011 Know Status Age group Z-Test Output";
run;

*Marital Status;
proc surveyfreq data=final.rw_11;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*marital_status / row;
title "Rwanda 2011 Know Status Marital Status Z-Test Output";
run;

*BMI groups;
proc surveyfreq data=final.rw_11;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*bmigrp / row;
title "Rwanda 2011 Know Status BMI group Z-Test Output";
run;

*No RWD pregnancy data;


**RWANDA 2015 HIV+ knows status;

*Age groups;
proc surveyfreq data=final.rw_15;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*agegrp / row;
title "Rwanda 2015 Know Status Age group Z-Test Output";
run;

*Marital Status;
proc surveyfreq data= final.rw_15;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*marital_status / row;
title "Rwanda 2015 Know Status Marital Status Z-Test Output";
run;

*BMI groups;
proc surveyfreq data= final.rw_15;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*bmigrp / row;
title "Rwanda 2015 Know Status BMI group Z-Test Output";
run;

*No RWD pregnancy data;
*ods pdf close;
ods excel close;




**ALL HIV+ in DHS DATA;
***APPEND IEDEA AND DHS DATASETS;

proc format;
	value domain
      0 = 'HIV Negative and/or Rural'
      1 = 'HIV+ Urban Men'
      2 = 'HIV+ Urban Women';
run;

*Burundi;
data final.bu_11_all;
set iedea.iedea_bu11 dhs_bu11;
*Create domain variable for freq tables;
if gender=1 and adult=1 and urban=1 and HIV=1 then domain=1;
else if gender=2 and adult=1 and urban=1 and HIV=1 then domain=2;
else domain=0;
format domain domain.;
run;


data final.bu_17_all;
set iedea.iedea_bu17 dhs_bu17;
*Create domain variable for freq tables;
if gender=1 and adult=1 and urban=1 and HIV=1 then domain=1;
else if gender=2 and adult=1 and urban=1 and HIV=1 then domain=2;
else domain=0;
format domain domain.;
run;


*Rwanda;
data final.rw_05_all;
set iedea.iedea_rw05 dhs_rw05;
*Create domain variable for freq tables;
if gender=1 and adult=1 and urban=1 and HIV=1 then domain=1;
else if gender=2 and adult=1 and urban=1 and HIV=1 then domain=2;
else domain=0;
format domain domain.;
run;

data final.rw_11_all;
set iedea.iedea_rw11 dhs_rw11;
*Create domain variable for freq tables;
if gender=1 and adult=1 and urban=1 and HIV=1 then domain=1;
else if gender=2 and adult=1 and urban=1 and HIV=1  then domain=2;
else domain=0;
format domain domain.;
run;

data final.rw_15_all;
set iedea.iedea_rw15 dhs_rw15;
*Create domain variable for freq tables;
if gender=1 and adult=1 and urban=1 and HIV=1 then domain=1;
else if gender=2 and adult=1 and urban=1 and HIV=1 then domain=2;
else domain=0;
format domain domain.;
run;



*ods pdf file = "iedea_output_all.pdf";
ods excel file='H:\Anna\IeDEA\SAS ALL HIV+ Output.xlsx' 
options(embedded_titles='on');
/*MAIN ANALYSES

**BURUNDI 2011 HIV+ all*/
*Age groups;
proc surveyfreq data=final.bu_11_all;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*agegrp / row;
title "Burundi 2011 All HIV+ Age group Z-Test Output";
run;

*Marital Status;
proc surveyfreq data=final.bu_11_all;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*marital_status / row;
title "Burundi 2011 All HIV+ Marital Status Z-Test Output";
run;

*BMI groups;
proc surveyfreq data=final.bu_11_all;
weight wgt;
cluster cluster;
strata stratum;
tables pregnant*dataset*domain*bmigrp / row; *Separating out pregnant people;
title "Burundi 2011 All HIV+ BMI group Z-Test Output";
run;

*Pregnancy Status;
proc surveyfreq data=final.bu_11_all;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*pregnant / row;
title "Burundi 2011 All HIV+ Pregnancy Status Z-Test Output";
run;



**BURUNDI 2017 HIV+ all;

*Age groups;
proc surveyfreq data=final.bu_17_all;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*agegrp / row;
title "Burundi 2017 All HIV+ Age group Z-Test Output";
run;

*Marital Status;
proc surveyfreq data=final.bu_17_all;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*marital_status / row;
title "Burundi 2017 All HIV+ Marital Status Z-Test Output";
run;

*BMI groups;
proc surveyfreq data=final.bu_17_all;
weight wgt;
cluster cluster;
strata stratum;
tables pregnant*dataset*domain*bmigrp / row; *Separating out pregnant people;
title "Burundi 2017 All HIV+ BMI group Z-Test Output";
run;

*Pregnancy Status;
proc surveyfreq data=final.bu_17_all;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*pregnant / row;
title "Burundi 2017 All HIV+ Pregnancy Status Z-Test Output";
run;




**RWANDA 2005 HIV+ all;

*Age groups;
proc surveyfreq data=final.rw_05_all;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*agegrp / row;
title "Rwanda 2005 All HIV+ Age group Z-Test Output";
run;

*Marital Status;
proc surveyfreq data= final.rw_05_all;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*marital_status / row;
title "Rwanda 2005 All HIV+ Marital Status Z-Test Output";
run;

*BMI groups;
proc surveyfreq data= final.rw_05_all;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*bmigrp / row;
title "Rwanda 2005 All HIV+ BMI group Z-Test Output";
run;

*No RWD pregnancy data;



**Rwanda 2011 HIV+ all;

*Age groups;
proc surveyfreq data=final.rw_11_all;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*agegrp / row;
title "Rwanda 2011 All HIV+ Age group Z-Test Output";
run;

*Marital Status;
proc surveyfreq data=final.rw_11_all;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*marital_status / row;
title "Rwanda 2011 All HIV+ Marital Status Z-Test Output";
run;

*BMI groups;
proc surveyfreq data=final.rw_11_all;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*bmigrp / row;
title "Rwanda 2011 All HIV+ BMI group Z-Test Output";
run;

*No RWD pregnancy data;



**RWANDA 2015 HIV+ all;

*Age groups;
proc surveyfreq data=final.rw_15_all;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*agegrp / row;
title "Rwanda 2015 All HIV+ Age group Z-Test Output";
run;

*Marital Status;
proc surveyfreq data= final.rw_15_all;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*marital_status / row;
title "Rwanda 2015 All HIV+ Marital Status Z-Test Output";
run;

*BMI groups;
proc surveyfreq data= final.rw_15_all;
weight wgt;
cluster cluster;
strata stratum;
tables dataset*domain*bmigrp / row;
title "Rwanda 2015 All HIV+ BMI group Z-Test Output";
run;

*No RWD pregnancy data;
*ods pdf close;
ods excel close;



