#!/bin/bash

function scanarp {
	# ARP Scan
	echo "[?] Interface for ARP scan? (${adapters[0]})"
	read interface
	if [ "$interface" = "" ]
	then
		interface="${adapters[0]}"
	fi
	echo 
	echo "[*] Running ARP scan."
	arp=$(arp-scan -lI $interface | grep -P "(?:\d{1,3}\.){3}\d{1,3}")
	[ "$log" = 'True' ] && (echo "$arp" >> $PWD/$dir/arp-scan-$interface)
	echo "$arp"
	echo ""
}

function scanadapters {
	# Network Adapters
	ipa=$(ifconfig)
	hosts=($echo $(echo "$ipa" | grep 'inet ' | cut -d ' ' -f 10))
	adapters=($echo $(echo "$ipa" | grep 'flags' | cut -d ' ' -f 1 | sed "s/://g"))
	i="0"
	echo "[*] Displaying network interfaces."
	while [ $i -lt ${#hosts[@]} ]
	do
		[ "$log" = 'True' ] && (echo "${adapters[$i]}: ${hosts[$i]}" >> $PWD/$dir/interfaces)
		echo "${adapters[$i]}: ${hosts[$i]}"
		i=$[$i+1]
	done
	echo 
}

function scanip {
	ip=$1	

	# Create IP dir
	if [ "$log" = 'True' ]; then
		echo "[*] Creating Directory $PWD/$dir/$ip"
		mkdir $PWD/$dir/$ip
		echo
	fi

	# Run quick nmap scan
	echo "[*] Running quick nmap scan - $ip"
	qnmap=$(nmap $ip -T5)
	[ "$log" = 'True' ] && (echo "$qnmap" >> $PWD/$dir/$ip/quick-scan)
	echo "$qnmap"
	echo

	if [ "$udp" = 'True' ]; then
		echo "[*] Running quick udp nmap scan - $ip"
		uqnmap=$(nmap -sU $ip -T5)
		[ "$log" = 'True' ] && (echo "$uqnmap" >> $PWD/$dir/$ip/udp-scan)
		echo "$uqnmap"
		echo
	fi

	# Nikto Scan if HTTP is running
	http_check=$(echo "$qnmap" | grep -c -w "http")
	if [ $http_check != 0 ]; then		
		echo "[*] Found HTTP running on $ip"
		echo "[*] Running Nikto scan."
		
		if [ "$log" != 'True' ]; then
			nikto -h $ip -ask no
		else
			nikto -h $ip -Format txt -o $PWD/$dir/$ip/nikto-web-scan -ask no
		fi
		
		echo
		echo "[*] Displaying robots.txt - $ip"
		robots=$(wget http://$ip/robots.txt -qO-)
		echo "$robots"
		[ "$log" = 'True' ] && (echo "$robots" >> $PWD/$dir/$ip/robots-txt)
	else
		echo "[*] HTTP not running on $ip"
		echo "[*] Skipping web related scanning."
	fi

	# Long nmap scan
	echo
	echo "[*] Running full nmap scan - $ip"
	echo "[*] This will take a while..."

	if [ "$log" != 'True' ]; then
		nmap -sV $ip -p- -A -T5 --stats-every 10s
	else
		nmap -sV $ip -p- -A -T5 -oN $PWD/$dir/$ip/full-nmap-scan --stats-every 10s
	fi
}

# Banner
echo "__________                            "
echo "\\______   \\ ____   ____  ____   ____  "
echo " |       _// __ \\_/ ___\\/  _ \\ /    \\ "
echo " |    |   \\  ___/\\  \\__(  <_> )   |  \\"
echo " |____|_  /\\___  >\\___  >____/|___|  /"
echo "        \\/     \\/     \\/           \\/ "
echo ""

log=False

# arg parsing
while getopts ":l:uhi:A" opt; do
	case $opt in
	    l)
		echo "[*] Creating Direcotry $PWD/$OPTARG"
		mkdir $PWD/$OPTARG
		echo "[*] Logging is enabled."
		echo		
		log=True
		dir=$OPTARG
		;;
	    u)
		echo "[*] UDP scanning is enabled."
		echo
		udp=True
		;;
	    i)
		echo "[*] IP target: $OPTARG"
		echo
		target=$OPTARG
		;;
	    A)
		echo "[*] Scanning all alive hosts"
		echo
		target=*
		;;
	    h)
		echo "Recon - Version 1.0"
		echo
		echo "Usage:"
		echo "./recon.sh [-lh] [-l DIRECTORY]"
		echo ""
		echo "Options:"
		echo "  -h		show this message and exit"
		echo "  -l DIRECTORY	create a directory and store logs"
		echo "  -u		enable UDP scanning. (VERY SLOW)"
		echo "  -i IP		scan specific ip"
		echo "  -A		scan all alive hosts"
		echo
		exit 1
		;;
	    \?)
		echo "[!] Invalid options: -$OPTARG"
		exit 1
		;;
	    :)
		echo "[!] Option -$OPTARG requires an argument."
		exit 1
		;;
	esac
done	

scanadapters

if [ "$target" = "" ]; then
	scanarp

	# Ask for IP
	echo "[?] Target IP?"
	read target
	echo

	scanip $target
elif [ "$target" = "*" ]; then
	scanarp

	targets=($(echo "$arp" | awk '{ print $1 }'))

	for target in ${targets[@]}
	do
		scanip ${target}
		echo
	done
else
	scanip $target

fi

if [ "$log" = 'True' ]; then
	echo 
	echo "[*] Logs created."
	echo
	echo "$PWD/$dir:"
	ls -Al $PWD/$dir/*
fi

# Finished!
echo
echo "[*] All done!"
echo

#end
