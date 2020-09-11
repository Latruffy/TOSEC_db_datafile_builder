#!/bin/bash
set +x

#===============================================================================
# Licensing :
# Below script is under copyleft considerations.
# Mainly, feel free to use, study, copy, share, modify, and distribute modified
# and therefore derivative works, as long as it keeps and inherits copyleft status.
#===============================================================================

#===============================================================================
# Purpose		: Scan either a TOSEC formated ROM datfile or a repository of TOSEC named ROM files
#				  to build database flat files according to TOSEC naming convention v4 (2015/03/23)
#				  (https://www.tosecdev.org/tosec-naming-convention
#				   pdf at https://www.tosecdev.org/downloads/category/5-tosec-naming-convention?download=65:tosec-naming-convention-2015-03-23)
# Autor			: Latruffe
# Script name	: TOSEC_db_datafile_builder.sh
# Inputs	:
#	Parameters	:
#		Fullpath either of a TOSEC formated ROM datfile or a repository containing TOSEC named ROM files
#	Internal variables	:
#		CSV_SEPARATOR		: Character used to separate fields in the generated CSV file
#		OUTPUT_DIRECTORY	: Full path dirname created to contain output files
#		ROM_LIST			: Full path filename of created ROMs list file built from script parameter
#		CSV_FILE			: Full path filename of CSV formated generated data file
#		JSON_FILE			: Full path filename of JSON formated generated data file
# Outputs	:
#	Files	:
#		ROMs list processed			: Located and named as configured in ROM_LIST internal variable
#		CSV data file generated		: Located, named and designed as configured in CSV_FILE and CSV_SEPARATOR internal variables
#		JSON data file generated	: Located and named as configured in JSON_FILE internal variable
#	Return codes	:
#		O	: INFO : Successful execution of the script !
#		1	: ERROR : Function argument is either not a directory or has not sufficient permissions to be accessed at least in read-only mode !
#		2	: ERROR : Function argument is either not a normal file or has not sufficient permissions to be accessed at least in read-only mode !
#		3	: ERROR : Script is run with exactly one parameter !
#		4	: ERROR : Output directory can't be created !
#		5	: ERROR : Script parameter is neither a ROM files repository nor a datfile !
# Known limitations :
#	- Process only "Single Image Sets" and not "Multi"
#	- Not able to manage several types of media in the same Media Type flag (example : "Tape 2 of 2 Side B")
#	- When dealing with 2 countries, only check in the list the first one and accept any 2 alphabetic characters for the 2nd one.
#	- The same for language
#	- Surely a lot to discover...
# ------------------------------------------------------------------------------
# History	:
# ------------
# Version		Date			Author					Description
# -------       ----------      -----------------       ------------------------
#	0.0.1		2020/04/18		Latruffe				Draft Version 
#	1.0.0		2020/04/26		Latruffe				Initial Release Version 
#	1.0.1		2020/05/01		Latruffe				Fix &amp; in datfiles rom names
#===============================================================================

#===============================================================================
# VARIABLES
#===============================================================================

# Freely customizable
CSV_SEPARATOR=";"
OUTPUT_DIRECTORY=$HOME/TOSEC_ROM_$(date "+%F_%T")
ROM_LIST=$OUTPUT_DIRECTORY/roms.list
CSV_FILE=$OUTPUT_DIRECTORY/roms.csv
JSON_FILE=$OUTPUT_DIRECTORY/roms.json

# Return codes
typeset -i RCOK=0										# INFO : Successful execution of the script !
typeset -i RCKO_notareadonlydirectory=1					# ERROR : Function argument is either not a directory or has not sufficient permissions to be accessed at least in read-only mode !
typeset -i RCKO_notareadonlyfile=2						# ERROR : Function argument is either not a normal file or has not sufficient permissions to be accessed at least in read-only mode !
typeset -i RCKO_notexactlyoneparameter=3				# ERROR : Script is run with exactly one parameter !
typeset -i RCKO_cannotcreateoutputdirectory=4			# ERROR : Output directory can't be created !
typeset -i RCKO_parameterneitherrepositorynordatfile=5	# ERROR : Script parameter is neither a ROM files repository nor a datfile !

#===============================================================================
# FUNCTIONS
#===============================================================================

# Function printing Usage
Usage () {
	TAB="$(printf '\t')"
	cat <<HELP_USAGE

Syntax :

	$0 <ROMs source>

		Parameter <ROMs source> :
			- is mandatory
			- is either path of the directory containing all TOSEC named ROMs (only one level depth is scanned)
			- or a TOSEC dat file listing ROMs
			- a full path
			- must be put between quotation marks in case of spaces,...

Examples :

	$0 \$HOME/Downloads/my_roms_directory
			To scan all the ROM files contained in the indicated directory.

	$0 "\$HOME/Downloads/Commodore Amiga - Games - [ADF] (TOSEC-v2019-12-19_CM).dat"
			To scan all the ROMs files listed in the indicated TOSEC datfile.

HELP_USAGE
}

# Function checking its argument is an existing directory which can be accessed in read-only mode
Check_directory_ro () {
	RC=$RCKO_notareadonlydirectory
	if [ -d "$1" ] && [ -x "$1" ] && [ -r "$1" ]; then
		RC=$RCOK
	else
		echo "ERROR : $1 is either not a directory or has not sufficient permissions to be accessed at least in read-only mode !"
	fi
	return $RC
}

# Function checking its argument is an existing file which can be accessed in read-only mode
Check_file_ro () {
	RC=$RCKO_notareadonlyfile
	if [ -f "$1" ] && [ -r "$1" ]; then
		RC=$RCOK
	else
		echo "ERROR : $1 is either not a normal file or has not sufficient permissions to be accessed at least in read-only mode !"
	fi
	return $RC
}

#===============================================================================
# MAIN
#===============================================================================

# Check script is run with exactly one parameter
if [ $# -ne 1 ]; then
	Usage
	exit $RCKO_notexactlyoneparameter
fi

# Create output directory
mkdir -p "$OUTPUT_DIRECTORY"
if [ $? -ne 0 ]; then
	echo "ERROR : Output directory $OUTPUT_DIRECTORY can't be created !"
	exit $RCKO_cannotcreateoutputdirectory
fi

# Build ROMs list
if [ -d "$1" ]; then
	Check_directory_ro "$1"
	if [ $? -ne 0 ]; then
		exit $?
	else
		ls "$1"/ | sed -e "s%^$1/%%" > $ROM_LIST
	fi
elif [ -f "$1" ]; then
	Check_file_ro "$1"
	if [ $? -ne 0 ]; then
		exit $?
	else
		grep "\<rom name=" "$1" | sed -e 's/^[	 ]*<rom name="//' | sed -e 's/".*$//' | sed -e 's/\&amp;/\&/g' > $ROM_LIST
	fi
else
	echo "ERROR : Script parameter $1 is neither a ROM files repository nor a datfile !"
	exit $RCKO_parameterneitherrepositorynordatfile
fi

# Initiate CSV file
echo "ROM${CSV_SEPARATOR}TITLE${CSV_SEPARATOR}VERSION_FLAG${CSV_SEPARATOR}DEMO_FLAG${CSV_SEPARATOR}DATE_FLAG${CSV_SEPARATOR}PUBLISHER_FLAG${CSV_SEPARATOR}SYSTEM_FLAG${CSV_SEPARATOR}VIDEO_FLAG${CSV_SEPARATOR}COUNTRY_REGION_FLAG${CSV_SEPARATOR}LANGUAGE_FLAG${CSV_SEPARATOR}COPYRIGHT_STATUS_FLAG${CSV_SEPARATOR}DEVELOPMENT_STATUS_FLAG${CSV_SEPARATOR}MEDIA_TYPE_FLAG${CSV_SEPARATOR}MEDIA_LABEL_FLAG${CSV_SEPARATOR}UNKNOWN_FLAGS${CSV_SEPARATOR}CRACKED_DUMP_FLAG${CSV_SEPARATOR}FIXED_DUMP_FLAG${CSV_SEPARATOR}HACKED_DUMP_FLAG${CSV_SEPARATOR}MODIFIED_DUMP_FLAG${CSV_SEPARATOR}PIRATED_DUMP_FLAG${CSV_SEPARATOR}TRAINED_DUMP_FLAG${CSV_SEPARATOR}TRANSLATED_DUMP_FLAG${CSV_SEPARATOR}OVER_DUMP_FLAG${CSV_SEPARATOR}UNDER_DUMP_FLAG${CSV_SEPARATOR}VIRUS_DUMP_FLAG${CSV_SEPARATOR}BAD_DUMP_FLAG${CSV_SEPARATOR}ALTERNATE_DUMP_FLAG${CSV_SEPARATOR}KNOWN_VERIFIED_DUMP_FLAG${CSV_SEPARATOR}MORE_INFO_DUMP_FLAGS${CSV_SEPARATOR}UNKNOWN_DUMP_FLAGS" > "$CSV_FILE"

# Initiate JSON file
echo -e "{
	\"ROMS\" :
	[" >> $JSON_FILE

# Loop on each ROM filename
cat $ROM_LIST | while read ROM_FLAG
do

	# Reset all ROM fields
	unset	ROM \
			TITLE_VERSION \
			FLAGS \
			VERSION_FLAG \
			TITLE_FLAG \
			DEMO_FLAG \
			DATE_FLAG \
			PUBLISHER_FLAG \
			SYSTEM_FLAG \
			VIDEO_FLAG \
			COUNTRY_REGION_FLAG \
			LANGUAGE_FLAG \
			COPYRIGHT_STATUS_FLAG \
			DEVELOPMENT_STATUS_FLAG \
			MEDIA_TYPE_FLAG \
			MEDIA_LABEL_FLAG \
			UNKNOWN_FLAGS \
			DUMP_FLAGS \
			CRACKED_DUMP_FLAG \
			FIXED_DUMP_FLAG \
			HACKED_DUMP_FLAG \
			MODIFIED_DUMP_FLAG \
			PIRATED_DUMP_FLAG \
			TRAINED_DUMP_FLAG \
			TRANSLATED_DUMP_FLAG \
			OVER_DUMP_FLAG \
			UNDER_DUMP_FLAG \
			VIRUS_DUMP_FLAG \
			BAD_DUMP_FLAG \
			ALTERNATE_DUMP_FLAG \
			KNOWN_VERIFIED_DUMP_FLAG \
			MORE_INFO_DUMP_FLAGS \
			UNKNOWN_DUMP_FLAGS

	# Remove potentially ending file extension from ROM filename
	ROM="$(echo "$ROM_FLAG" |sed -e 's/\.[^\.]*$//')"

	# Get strings before the first bracket
	TITLE_VERSION="$(echo "$ROM" | cut -f1 -d\()"

	# Get ROM Title and Version flags
	for word in $TITLE_VERSION
	do
		case $word in
			[vV][\.0-9]*)
				VERSION_FLAG="$word";;

			[Rr][Ee][Vv][\.0-9]*)
				VERSION_FLAG="$word";;

			*)
				TITLE_FLAG="$(echo "$TITLE_FLAG $word" | sed -e 's/^ //')" ;;
		esac
	done

	# Get ROM software specifications flags
	# Get strings after the first bracket but before the first square bracket and cut on multi lines
	FLAGS="($(echo "$(echo "$ROM" | cut -f2- -d\( | cut -f1 -d\[)" | sed -e 's/)/)\n/g')"

	# Loop on each flag between brackets
	while read word
	do
		case $word in

			# Get Demo flag
			\(demo\) | \(demo-kiosk\) | \(demo-playable\) | \(demo-rolling\) | \(demo-slideshow\) )
				DEMO_FLAG="$(echo "$word" | sed -e 's/(//' | sed -e 's/)//')" ;;

			# Get Date flag
			\([12][90][x0-9][x0-9]\) | \([12][90][x0-9][x0-9]-[x0-9][x0-9]\) | \([12][90][x0-9][x0-9]-[x0-9][x0-9]-[x0-9][x0-9]\) )
				DATE_FLAG="$(echo "$word" | sed -e 's/(//' | sed -e 's/)//')" ;;

			# Get System flag
			\(+2\) | \(+2a\) | \(+3\) | \(130XE\) | \(A1000\) | \(A1200\) | \(A1200-A4000\) | \(A2000\) | \(A2000-A3000\) | \(A2024\) | \(A2500-A3000UX\) | \(A3000\) | \(A4000\) | \(A4000T\) | \(A500\) | \(A500+\) | \(A500-A1000-A2000\) | \(A500-A1000-A2000-CDTV\) | \(A500-A1200\) | \(A500-A1200-A2000-A4000\) | \(A500-A2000\) | \(A500-A600-A2000\) | \(A570\) | \(A600\) | \(A600HD\) | \(AGA\) | \(AGA-CD32\) | "(Aladdin Deck Enhancer)" | \(CD32\) | \(CDTV\) | \(Computrainer\) | "(Doctor PC Jr.)" | \(ECS\) | \(ECS-AGA\) | \(Executive\) | "(Mega ST)" | \(Mega-STE\) | \(OCS\) | \(OCS-AGA\) | \(ORCH80\) | "(Osbourne 1)" | \(PIANO90\) | \(PlayChoice-10\) | \(Plus4\) | \(Primo-A\) | \(Primo-A64\) | \(Primo-B\) | \(Primo-B64\) | \(Pro-Primo\) | \(ST\) | \(STE\) | \(STE-Falcon\) | \(TT\) | "(TURBO-R GT)" | "(TURBO-R ST)" | "(VS DualSystem)" | "(VS UniSystem)" ) 
				SYSTEM_FLAG="$(echo "$word" | sed -e 's/(//' | sed -e 's/)//')" ;;

			# Get Video flag
			\(CGA\) | \(EGA\) | \(HGC\) | \(MCGA\) | \(MDA\) | \(NTSC\) | \(NTSC-PAL\) | \(PAL\) | \(PAL-60\) | \(PAL-NTSC\) | \(SVGA\) | \(VGA\) | \(XGA\) )
				VIDEO_FLAG="$(echo "$word" | sed -e 's/(//' | sed -e 's/)//')" ;;

			# Get Country/Region flag for one
			\(AE\) | \(AL\) | \(AS\) | \(AT\) | \(AU\) | \(BA\) | \(BE\) | \(BG\) | \(BR\) | \(CA\) | \(CH\) | \(CL\) | \(CN\) | \(CS\) | \(CY\) | \(CZ\) | \(DE\) | \(DK\) | \(EE\) | \(EG\) | \(ES\) | \(EU\) | \(FI\) | \(FR\) | \(GB\) | \(GR\) | \(HK\) | \(HR\) | \(HU\) | \(ID\) | \(IE\) | \(IL\) | \(IN\) | \(IR\) | \(IS\) | \(IT\) | \(JO\) | \(JP\) | \(KR\) | \(LT\) | \(LU\) | \(LV\) | \(MN\) | \(MX\) | \(MY\) | \(NL\) | \(NO\) | \(NP\) | \(NZ\) | \(OM\) | \(PE\) | \(PH\) | \(PL\) | \(PT\) | \(QA\) | \(RO\) | \(RU\) | \(SE\) | \(SG\) | \(SI\) | \(SK\) | \(TH\) | \(TR\) | \(TW\) | \(US\) | \(VN\) | \(YU\) | \(ZA\) )
				COUNTRY_REGION_FLAG="$(echo "$word" | sed -e 's/(//' | sed -e 's/)//')" ;;

			# Get Country/Region flag for several
			\(AE-[A-Z][A-Z]\) | \(AL-[A-Z][A-Z]\) | \(AS-[A-Z][A-Z]\) | \(AT-[A-Z][A-Z]\) | \(AU-[A-Z][A-Z]\) | \(BA-[A-Z][A-Z]\) | \(BE-[A-Z][A-Z]\) | \(BG-[A-Z][A-Z]\) | \(BR-[A-Z][A-Z]\) | \(CA-[A-Z][A-Z]\) | \(CH-[A-Z][A-Z]\) | \(CL-[A-Z][A-Z]\) | \(CN-[A-Z][A-Z]\) | \(CS-[A-Z][A-Z]\) | \(CY-[A-Z][A-Z]\) | \(CZ-[A-Z][A-Z]\) | \(DE-[A-Z][A-Z]\) | \(DK-[A-Z][A-Z]\) | \(EE-[A-Z][A-Z]\) | \(EG-[A-Z][A-Z]\) | \(ES-[A-Z][A-Z]\) | \(EU-[A-Z][A-Z]\) | \(FI-[A-Z][A-Z]\) | \(FR-[A-Z][A-Z]\) | \(GB-[A-Z][A-Z]\) | \(GR-[A-Z][A-Z]\) | \(HK-[A-Z][A-Z]\) | \(HR-[A-Z][A-Z]\) | \(HU-[A-Z][A-Z]\) | \(ID-[A-Z][A-Z]\) | \(IE-[A-Z][A-Z]\) | \(IL-[A-Z][A-Z]\) | \(IN-[A-Z][A-Z]\) | \(IR-[A-Z][A-Z]\) | \(IS-[A-Z][A-Z]\) | \(IT-[A-Z][A-Z]\) | \(JO-[A-Z][A-Z]\) | \(JP-[A-Z][A-Z]\) | \(KR-[A-Z][A-Z]\) | \(LT-[A-Z][A-Z]\) | \(LU-[A-Z][A-Z]\) | \(LV-[A-Z][A-Z]\) | \(MN-[A-Z][A-Z]\) | \(MX-[A-Z][A-Z]\) | \(MY-[A-Z][A-Z]\) | \(NL-[A-Z][A-Z]\) | \(NO-[A-Z][A-Z]\) | \(NP-[A-Z][A-Z]\) | \(NZ-[A-Z][A-Z]\) | \(OM-[A-Z][A-Z]\) | \(PE-[A-Z][A-Z]\) | \(PH-[A-Z][A-Z]\) | \(PL-[A-Z][A-Z]\) | \(PT-[A-Z][A-Z]\) | \(QA-[A-Z][A-Z]\) | \(RO-[A-Z][A-Z]\) | \(RU-[A-Z][A-Z]\) | \(SE-[A-Z][A-Z]\) | \(SG-[A-Z][A-Z]\) | \(SI-[A-Z][A-Z]\) | \(SK-[A-Z][A-Z]\) | \(TH-[A-Z][A-Z]\) | \(TR-[A-Z][A-Z]\) | \(TW-[A-Z][A-Z]\) | \(US-[A-Z][A-Z]\) | \(VN-[A-Z][A-Z]\) | \(YU-[A-Z][A-Z]\) | \(ZA-[A-Z][A-Z]\) )
				COUNTRY_REGION_FLAG="$(echo "$word" | sed -e 's/(//' | sed -e 's/)//')" ;;

			# Get Language flag for one
			\(M[0-9]\) | \(ar\) | \(bg\) | \(bs\) | \(cs\) | \(cy\) | \(da\) | \(de\) | \(el\) | \(en\) | \(eo\) | \(es\) | \(et\) | \(fa\) | \(fi\) | \(fr\) | \(ga\) | \(gu\) | \(he\) | \(hi\) | \(hr\) | \(hu\) | \(is\) | \(it\) | \(ja\) | \(ko\) | \(lt\) | \(lv\) | \(ms\) | \(nl\) | \(no\) | \(pl\) | \(pt\) | \(ro\) | \(ru\) | \(sk\) | \(sl\) | \(sq\) | \(sr\) | \(sv\) | \(th\) | \(tr\) | \(ur\) | \(vi\) | \(yi\) | \(zh\) )
				LANGUAGE_FLAG="$(echo "$word" | sed -e 's/(//' | sed -e 's/)//')" ;;

			# Get Language flag for several
			\(M[0-9]-[a-z][a-z]\) | \([a-z][a-z]-M[0-9]\) | \(ar-[a-z][a-z]\) | \(bg-[a-z][a-z]\) | \(bs-[a-z][a-z]\) | \(cs-[a-z][a-z]\) | \(cy-[a-z][a-z]\) | \(da-[a-z][a-z]\) | \(de-[a-z][a-z]\) | \(el-[a-z][a-z]\) | \(en-[a-z][a-z]\) | \(eo-[a-z][a-z]\) | \(es-[a-z][a-z]\) | \(et-[a-z][a-z]\) | \(fa-[a-z][a-z]\) | \(fi-[a-z][a-z]\) | \(fr-[a-z][a-z]\) | \(ga-[a-z][a-z]\) | \(gu-[a-z][a-z]\) | \(he-[a-z][a-z]\) | \(hi-[a-z][a-z]\) | \(hr-[a-z][a-z]\) | \(hu-[a-z][a-z]\) | \(is-[a-z][a-z]\) | \(it-[a-z][a-z]\) | \(ja-[a-z][a-z]\) | \(ko-[a-z][a-z]\) | \(lt-[a-z][a-z]\) | \(lv-[a-z][a-z]\) | \(ms-[a-z][a-z]\) | \(nl-[a-z][a-z]\) | \(no-[a-z][a-z]\) | \(pl-[a-z][a-z]\) | \(pt-[a-z][a-z]\) | \(ro-[a-z][a-z]\) | \(ru-[a-z][a-z]\) | \(sk-[a-z][a-z]\) | \(sl-[a-z][a-z]\) | \(sq-[a-z][a-z]\) | \(sr-[a-z][a-z]\) | \(sv-[a-z][a-z]\) | \(th-[a-z][a-z]\) | \(tr-[a-z][a-z]\) | \(ur-[a-z][a-z]\) | \(vi-[a-z][a-z]\) | \(yi-[a-z][a-z]\) | \(zh-[a-z][a-z]\) )
				LANGUAGE_FLAG="$(echo "$word" | sed -e 's/(//' | sed -e 's/)//')" ;;

			# Get Copyright Status flag
			\(CW\) | \(CW-R\) | \(FW\) | \(GW\) | \(GW-R\) | \(LW\) | \(PD\) | \(SW\) | \(SW-R\) ) 
				COPYRIGHT_STATUS_FLAG="$(echo "$word" | sed -e 's/(//' | sed -e 's/)//')" ;;

			# Get Development Status flag
			\(alpha\) | \(beta\) | \(preview\) | \(pre-release\) | \(proto\) ) 
				DEVELOPMENT_STATUS_FLAG="$(echo "$word" | sed -e 's/(//' | sed -e 's/)//')" ;;

			# Get Media Type flag
			\(Disc\) | "(Disc "[0-9A-Za-z]*")" | "(Disc "[0-9A-Za-z]*" of "[0-9A-Za-z]*")" | "(Disc "[0-9A-Za-z]*-[0-9A-Za-z]*" of "[0-9A-Za-z]*")" | \(Disk\) | "(Disk "[0-9A-Za-z]*")" | "(Disk "[0-9A-Za-z]*" of "[0-9A-Za-z]*")" | "(Disk "[0-9A-Za-z]*-[0-9A-Za-z]*" of "[0-9A-Za-z]*")" | \(File\) | "(File "[0-9A-Za-z]*")" | "(File "[0-9A-Za-z]*" of "[0-9A-Za-z]*")" | "(File "[0-9A-Za-z]*-[0-9A-Za-z]*" of "[0-9A-Za-z]*")" | \(Part\) | "(Part "[0-9A-Za-z]*")" | "(Part "[0-9A-Za-z]*" of "[0-9A-Za-z]*")" | "(Part "[0-9A-Za-z]*-[0-9A-Za-z]*" of "[0-9A-Za-z]*")" | \(Side\) | "(Side "[0-9A-Za-z]*")" | "(Side "[0-9A-Za-z]*" of "[0-9A-Za-z]*")" | "(Side "[0-9A-Za-z]*-[0-9A-Za-z]*" of "[0-9A-Za-z]*")" | \(Tape\) | "(Tape "[0-9A-Za-z]*")" | "(Tape "[0-9A-Za-z]*" of "[0-9A-Za-z]*")" | "(Tape "[0-9A-Za-z]*-[0-9A-Za-z]*" of "[0-9A-Za-z]*")" )
				MEDIA_TYPE_FLAG="$(echo "$word" | sed -e 's/(//' | sed -e 's/)//')" ;;

			# Get Publisher and Media Label flag
			\(*\) ) 
				# If the only flag between brackets found until now is the Date flag, consider this one is the next, that is to say the Publisher flag
				if [ ! -z $DATE_FLAG ] && [ -z "$PUBLISHER_FLAG$SYSTEM_FLAG$VIDEO_FLAG$COUNTRY_REGION_FLAG$LANGUAGE_FLAG$COPYRIGHT_STATUS_FLAG$DEVELOPMENT_STATUS_FLAG$MEDIA_TYPE_FLAG$MEDIA_LABEL_FLAG" ]; then
					PUBLISHER_FLAG="$(echo "$word" | sed -e 's/(//' | sed -e 's/)//')"
				else
				# Otherwise consider it is the Media Label flag
					MEDIA_LABEL_FLAG="$(echo "$word" | sed -e 's/(//' | sed -e 's/)//')"
				fi ;;

			# Any other flag(s) which is/are not between brackets but seen after at least one bracket is/are get and considered as Unknown flag(s)
			* )
				UNKNOWN_FLAGS="$(echo "$UNKNOWN_FLAGS $word" | sed -e 's/^ //')" ;;
				
		esac
	done <<<"$(echo -e "$FLAGS")"

	# Get ROM dump specifications flags
	# Check if ROM shows dump flags
	echo "$ROM" | grep "\[" > /dev/null
	if [ $? -eq 0 ]; then
		# Get strings after the first square bracket and cut on multi lines
		DUMP_FLAGS="[$(echo "$(echo "$ROM" | cut -f2- -d\[)" | sed -e 's/\]/\]\n/g')"

		# Loop on each dump flag between square brackets
		while read word
		do
			case $word in

				# Get Cracked flag
				\[cr\] | \[cr[0-9]\] | \[cr[0-9][0-9]\] | "[cr "*"]" | "[cr"[0-9]" "*"]" | "[cr"[0-9][0-9]" "*"]" )
					CRACKED_DUMP_FLAG="$(echo "$word" | sed -e 's/\[//' | sed -e 's/\]//')" ;;

				# Get Fixed flag
				\[f\] | \[f[0-9]\] | \[f[0-9][0-9]\] | "[f "*"]" | "[f"[0-9]" "*"]" | "[f"[0-9][0-9]" "*"]" )
					FIXED_DUMP_FLAG="$(echo "$word" | sed -e 's/\[//' | sed -e 's/\]//')" ;;

				# Get Hacked flag
				\[h\] | \[h[0-9]\] | \[h[0-9][0-9]\] | "[h "*"]" | "[h"[0-9]" "*"]" | "[h"[0-9][0-9]" "*"]" )
					HACKED_DUMP_FLAG="$(echo "$word" | sed -e 's/\[//' | sed -e 's/\]//')" ;;

				# Get Modified flag
				\[m\] | \[m[0-9]\] | \[m[0-9][0-9]\] | "[m "*"]" | "[m"[0-9]" "*"]" | "[m"[0-9][0-9]" "*"]" )
					MODIFIED_DUMP_FLAG="$(echo "$word" | sed -e 's/\[//' | sed -e 's/\]//')" ;;

				# Get Pirated flag
				\[p\] | \[p[0-9]\] | \[p[0-9][0-9]\] | "[p "*"]" | "[p"[0-9]" "*"]" | "[p"[0-9][0-9]" "*"]" )
					PIRATED_DUMP_FLAG="$(echo "$word" | sed -e 's/\[//' | sed -e 's/\]//')" ;;

				# Get Trained flag
				\[t\] | \[t[0-9]\] | \[t[0-9][0-9]\] | "[t "*"]" | "[t"[0-9]" "*"]" | "[t"[0-9][0-9]" "*"]" )
					TRAINED_DUMP_FLAG="$(echo "$word" | sed -e 's/\[//' | sed -e 's/\]//')" ;;

				# Get Translated flag
				\[tr\] | \[tr[0-9]\] | \[tr[0-9][0-9]\] | "[tr "*"]" | "[tr"[0-9]" "*"]" | "[tr"[0-9][0-9]" "*"]" )
					TRANSLATED_DUMP_FLAG="$(echo "$word" | sed -e 's/\[//' | sed -e 's/\]//')" ;;

				# Get Over Dump flag
				\[o\] | \[o[0-9]\] | \[o[0-9][0-9]\] | "[o "*"]" | "[o"[0-9]" "*"]" | "[o"[0-9][0-9]" "*"]" )
					OVER_DUMP_FLAG="$(echo "$word" | sed -e 's/\[//' | sed -e 's/\]//')" ;;

				# Get Under Dump flag
				\[u\] | \[u[0-9]\] | \[u[0-9][0-9]\] | "[u "*"]" | "[u"[0-9]" "*"]" | "[u"[0-9][0-9]" "*"]" )
					UNDER_DUMP_FLAG="$(echo "$word" | sed -e 's/\[//' | sed -e 's/\]//')" ;;

				# Get Virus flag
				\[v\] | \[v[0-9]\] | \[v[0-9][0-9]\] | "[v "*"]" | "[v"[0-9]" "*"]" | "[v"[0-9][0-9]" "*"]" )
					VIRUS_DUMP_FLAG="$(echo "$word" | sed -e 's/\[//' | sed -e 's/\]//')" ;;

				# Get Bad Dump flag
				\[b\] | \[b[0-9]\] | \[b[0-9][0-9]\] | "[b "*"]" | "[b"[0-9]" "*"]" | "[b"[0-9][0-9]" "*"]" )
					BAD_DUMP_FLAG="$(echo "$word" | sed -e 's/\[//' | sed -e 's/\]//')" ;;

				# Get Alternate Dump flag
				\[a\] | \[a[0-9]\] | \[a[0-9][0-9]\] | "[a "*"]" | "[a"[0-9]" "*"]" | "[a"[0-9][0-9]" "*"]" )
					ALTERNATE_DUMP_FLAG="$(echo "$word" | sed -e 's/\[//' | sed -e 's/\]//')" ;;

				# Get Known Verified Dump flag
				\[!\] )
					KNOW_VERIFIED_DUMP_FLAG="$(echo "$word" | sed -e 's/\[//' | sed -e 's/\]//')" ;;

				# Get More Info Dump flags
				\(*\) ) 
					MORE_INFO_DUMP_FLAGS="$(echo "$MORE_INFO_DUMP_FLAGS $word" | sed -e 's/^ //')" ;;

				# Any other flag(s) which is/are not between brackets but seen after at least one bracket is/are get and considered as Unknown flag(s)
				* )
					UNKNOWN_DUMP_FLAGS="$(echo "$UNKNOWN_DUMP_FLAGS $word" | sed -e 's/^ //')" ;;
				
			esac
		done <<<"$(echo -e "$DUMP_FLAGS")"
	fi

	# Write ROM record in CSV file
	echo -e "${ROM_FLAG}${CSV_SEPARATOR}${TITLE_FLAG}${CSV_SEPARATOR}${VERSION_FLAG}${CSV_SEPARATOR}${DEMO_FLAG}${CSV_SEPARATOR}${DATE_FLAG}${CSV_SEPARATOR}${PUBLISHER_FLAG}${CSV_SEPARATOR}${SYSTEM_FLAG}${CSV_SEPARATOR}${VIDEO_FLAG}${CSV_SEPARATOR}${COUNTRY_REGION_FLAG}${CSV_SEPARATOR}${LANGUAGE_FLAG}${CSV_SEPARATOR}${COPYRIGHT_STATUS_FLAG}${CSV_SEPARATOR}${DEVELOPMENT_STATUS_FLAG}${CSV_SEPARATOR}${MEDIA_TYPE_FLAG}${CSV_SEPARATOR}${MEDIA_LABEL_FLAG}${CSV_SEPARATOR}${UNKNOWN_FLAGS}${CSV_SEPARATOR}${CRACKED_DUMP_FLAG}${CSV_SEPARATOR}${FIXED_DUMP_FLAG}${CSV_SEPARATOR}${HACKED_DUMP_FLAG}${CSV_SEPARATOR}${MODIFIED_DUMP_FLAG}${CSV_SEPARATOR}${PIRATED_DUMP_FLAG}${CSV_SEPARATOR}${TRAINED_DUMP_FLAG}${CSV_SEPARATOR}${TRANSLATED_DUMP_FLAG}${CSV_SEPARATOR}${OVER_DUMP_FLAG}${CSV_SEPARATOR}${UNDER_DUMP_FLAG}${CSV_SEPARATOR}${VIRUS_DUMP_FLAG}${CSV_SEPARATOR}${BAD_DUMP_FLAG}${CSV_SEPARATOR}${ALTERNATE_DUMP_FLAG}${CSV_SEPARATOR}${KNOWN_VERIFIED_DUMP_FLAG}${CSV_SEPARATOR}${MORE_INFO_DUMP_FLAGS}${CSV_SEPARATOR}${UNKNOWN_DUMP_FLAGS}" >> "$CSV_FILE"

	# Write ROM record in JSON file
	echo -e "		{
			\"rom file\" : \"$ROM_FLAG\",
			\"title\" : \"$TITLE_FLAG\",
			\"version_flag\" : \"$VERSION_FLAG\",
			\"demo_flag\" : \"$DEMO_FLAG\",
			\"date_flag\" : \"$DATE_FLAG\",
			\"publisher_flag\" : \"$PUBLISHER_FLAG\",
			\"system_flag\" : \"$SYSTEM_FLAG\",
			\"video_flag\" : \"$VIDEO_FLAG\",
			\"country_region_flag\" : \"$COUNTRY_REGION_FLAG\",
			\"language_flag\" : \"$LANGUAGE_FLAG\",
			\"copyright_status_flag\" : \"$COPYRIGHT_STATUS_FLAG\",
			\"development_status_flag\" : \"$DEVELOPMENT_STATUS_FLAG\",
			\"media_type_flag\" : \"$MEDIA_TYPE_FLAG\",
			\"media_label_flag\" : \"$MEDIA_LABEL_FLAG\",
			\"unknown_flags\" : \"$UNKNOWN_FLAGS\",
			\"cracked_dump_flag\" : \"$CRACKED_DUMP_FLAG\",
			\"fixed_dump_flag\" : \"$FIXED_DUMP_FLAG\",
			\"hacked_dump_flag\" : \"$HACKED_DUMP_FLAG\",
			\"modified_dump_flag\" : \"$MODIFIED_DUMP_FLAG\",
			\"pirated_dump_flag\" : \"$PIRATED_DUMP_FLAG\",
			\"trained_dump_flag\" : \"$TRAINED_DUMP_FLAG\",
			\"translated_dump_flag\" : \"$TRANSLATED_DUMP_FLAG\",
			\"over_dump_flag\" : \"$OVER_DUMP_FLAG\",
			\"under_dump_flag\" : \"$UNDER_DUMP_FLAG\",
			\"virus_dump_flag\" : \"$VIRUS_DUMP_FLAG\",
			\"bad_dump_flag\" : \"$BAD_DUMP_FLAG\",
			\"alternative_dump_flag\" : \"$ALTERNATE_DUMP_FLAG\",
			\"known_verified_dump_flag\" : \"$KNOWN_VERIFIED_DUMP_FLAG\",
			\"more_info_dump_flags\" : \"$MORE_INFO_DUMP_FLAGS\",
			\"unknown_dump_flags\" : \"$UNKNOWN_DUMP_FLAGS\"
		}," >> $JSON_FILE

done

# Terminate JSON file
sed -i '$ s/,$//' "$JSON_FILE"
echo -e "	]
}" >> $JSON_FILE

# Successful execution of the script !
exit $RCOK
