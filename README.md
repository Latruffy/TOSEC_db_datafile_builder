Licensing :
--
Below script is under copyleft considerations.
Mainly, feel free to use, study, copy, share, modify, and distribute modified
and therefore derivative works, as long as it keeps and inherits copyleft status.

Purpose :
--
Scan either a TOSEC formated ROM datfile or a repository of TOSEC named ROM files
to build database flat files according to TOSEC naming convention v4 (2015/03/23)
(<https://www.tosecdev.org/tosec-naming-convention>
pdf at <https://www.tosecdev.org/downloads/category/5-tosec-naming-convention?download=65:tosec-naming-convention-2015-03-23>)

Autor :
--
Latruffe

Script name	:
--
TOSEC_db_datafile_builder.sh

Inputs :
--
* ###	Parameters :
  * Fullpath either of a TOSEC formated ROM datfile or a repository containing TOSEC named ROM files
  
* ###	Internal variables :
  * CSV_SEPARATOR		: Character used to separate fields in the generated CSV file
  * OUTPUT_DIRECTORY	: Full path dirname created to contain output files
  * ROM_LIST			: Full path filename of created ROMs list file built from script parameter
  * CSV_FILE			: Full path filename of CSV formated generated data file
  * JSON_FILE			: Full path filename of JSON formated generated data file

Outputs :
--
* ### Files :
  * ROMs list processed			: Located and named as configured in ROM_LIST internal variable
  * CSV data file generated		: Located, named and designed as configured in CSV_FILE and CSV_SEPARATOR internal variables
  * JSON data file generated	: Located and named as configured in JSON_FILE internal variable

* ### Return codes :
  * O	: INFO : Successful execution of the script !
  * 1	: ERROR : Function argument is either not a directory or has not sufficient permissions to be accessed at least in read-only mode !
  * 2	: ERROR : Function argument is either not a normal file or has not sufficient permissions to be accessed at least in read-only mode !
  * 3	: ERROR : Script is run with exactly one parameter !
  * 4	: ERROR : Output directory can't be created !
  * 5	: ERROR : Script parameter is neither a ROM files repository nor a datfile !

Known limitations :
--
* Process only "Single Image Sets" and not "Multi"
* Not able to manage several types of media in the same Media Type flag (example : "Tape 2 of 2 Side B")
* When dealing with 2 countries, only check in the list the first one and accept any 2 alphabetic characters for the 2nd one.
* The same for language
* Surely a lot to discover...

History :
--
Version|Date|Author|Description
---:|---:|:---|:---
0.0.1|2020/04/18|Latruffe|Draft Version 
1.0.0|2020/04/26|Latruffe|Initial Release Version 
1.0.1|2020/05/01|Latruffe|Fix \&amp; in datfiles rom names
