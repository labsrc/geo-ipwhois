#!/usr/bin/bash

##################################################################################
### Script:		geo-ipwhois.sh
### Version:	1.00
### Date:		2026-09-06
### Function:	Uses https://ipwho.is to provide GeoIP lookups (1000/day Free)
##################################################################################

### If no IP given, will lookup external IP
ipaddr=""


### Check for arguments
if [ $# -ne 0 ]; then
	if [[ ${@: -1} != -* ]]; then
		ipaddr=${@: -1}
	fi
fi


### Font Styling
gdcolor='\033[0;38;5;39m'
gdcolorbold='\033[1;38;5;39m'
graybold='\033[1;38;5;248m'
nocolor='\033[0m'
bold='\033[1m'
italics='\033[3m'
underline='\e[4m'
bullet='\xE2\x80\xA2'


### Help / Usage Display
function usage_display {
	echo -e "\n${gdcolorbold}geo-ipwhois.sh${nocolor} - A GeoIP Lookup Script

  ${gdcolorbold}Function:${nocolor} Uses https://ipwho.is to provide GeoIP lookups (1000/day Free)

  ${gdcolorbold}Usage:${nocolor} geo-ipwhois.sh [${gdcolorbold}-flags${nocolor}] ${italics}ipaddress
  ${gdcolorbold}${bullet}${nocolor} If no IP is given, user's external IP will be used${nocolor}

  ${gdcolorbold}Flags:${nocolor}
	-a	Display all GeoIP output
	-h 	Show this help screen"
}


### Handle Flags
while getopts ":ah" opt; do
	case $opt in
		a) unfiltered=true ;;
		h) usage_display; exit 1;;
		?) echo "Invalid option: -$OPTARG" 
			usage_display
			exit 1;;
	esac
done


### GeoIP Lookup URL
geoipURL="https://ipwho.is/$ipaddr"


### Lookup IP
ipwhoisJSON=$(curl -s $geoipURL)


### Echo Unfiltered GeoIP Result
#echo $ipwhoisJSON | jq -r '.'


### Loop through JSON Output
for i in "$(echo $ipwhoisJSON | jq -r '.')"; do
	success=$(echo $i | jq -r '.success')
	if [ $success == "true" ]; then
		### Unfiltered Output
		if [ "$unfiltered" = true ]; then

		    echo -e "${gdcolorbold}\n# ALL GEOIP INFO${nocolor}"
		    echo -e "${gdcolorbold}###################${nocolor}\n"

			### Loop through all GeoIP Output
			jq -r 'to_entries | map(.key + "|" + (.value | tostring)) | .[]' <<< "$ipwhoisJSON" | \
				while IFS='|' read key value; do
					if [ "$key" != "success" ]; then
						valueFormat=""
						if [ -z "$value" ]; then
							value="--no info--"
							valueFormat="${italics}${graybold}"
						fi
						if [[ $key == @(flag|connection|timezone) ]]; then
							echo -e "${gdcolorbold}${key^^}${nocolor}"
							jq -r 'to_entries | map(.key + "|" + (.value | tostring)) | .[]' <<< "$value" | \
								while IFS='|' read key value; do
									printf "   ${gdcolorbold}%-18s${nocolor}${bold}${valueFormat}%s${nocolor}\n" "${key}:" "$value"
									#printf $output
								done
						else
							printf "${gdcolorbold}%-21s${nocolor}${bold}${valueFormat}%s${nocolor}\n" "${key^^}:" "$value" 
						fi
					fi
				done
		else
			echo -e "${gdcolorbold}\n# Basic GeoIP Info    ${nocolor}"
		    echo -e "${gdcolorbold}#####################${nocolor}\n"

			### Loop through selected fields
			selectFields=("ip" "city" "region" "country" "postal")
			for selectField in "${selectFields[@]}"; do
				selectValue=$(echo $i | jq -r .$selectField)
				echo -e "${gdcolorbold}${selectField^^}:${nocolor}^\t${bold}$selectValue${nocolor}"
			done | column -s "^" -t
		fi
	else
		errormsg=$(echo $i | jq -r '.message')
		echo -e "${gdcolorbold}\nERROR:${nocolor}\t$errormsg"
	fi
done
