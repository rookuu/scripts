#!/bin/bash

# Banner
echo "__________                            "
echo "\\______   \\ ____   ____  ____   ____  "
echo " |       _// __ \\_/ ___\\/  _ \\ /    \\ "
echo " |    |   \\  ___/\\  \\__(  <_> )   |  \\"
echo " |____|_  /\\___  >\\___  >____/|___|  /"
echo "        \\/     \\/     \\/           \\/ "
echo ""

log=False


# argparsing
while getopts ":l:u" opt; do
	case $opt in
	    l)
		echo "[*] Creating Direcotry $PWD/$2"
		mkdir $PWD/$2
		echo "[*] Logging is enabled."
		echo		
		log=True
		;;
	    u)
		echo "[*] UDP scanning is enabled."
		echo
		udp=True
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

# Network Adapters
ipa=$(ifconfig)
hosts=($echo $(echo "$ipa" | grep 'inet ' | cut -d ' ' -f 10))
adapters=($echo $(echo "$ipa" | grep 'flags' | cut -d ' ' -f 1 | sed "s/://g"))
i="0"
echo "[*] Displaying network interfaces."
while [ $i -lt ${#hosts[@]} ]
do
	[ "$log" = 'True' ] && (echo "${adapters[$i]}: ${hosts[$i]}" >> $PWD/$2/interfaces)
	echo "${adapters[$i]}: ${hosts[$i]}"
	i=$[$i+1]
done
echo 

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
[ "$log" = 'True' ] && (echo "$arp" >> $PWD/$2/arp-scan-$interface)
echo "$arp"
echo ""

# Quick Nmap Scan
echo "[?] Target IP?"
read ip
echo
echo "[*] Creating Directory $PWD/$2/$ip"
mkdir $PWD/$2/$ip
echo

echo "[*] Running quick nmap scan - $ip"
qnmap=$(nmap $ip -T5)
[ "$log" = 'True' ] && (echo "$qnmap" >> $PWD/$2/$ip/quick-scan)
echo "$qnmap"
echo

if [ "$udp" = 'True' ]; then
	echo "[*] Running quick udp nmap scan - $ip"
	uqnmap=$(nmap -sU $ip -T5)
	[ "$log" = 'True' ] && (echo "$uqnmap" >> $PWD/$2/$ip/udp-scan)
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
		nikto -h $ip -Format txt -o $PWD/$2/$ip/nikto-web-scan -ask no
	fi
	
	echo
	echo "[*] Displaying robots.txt - $ip"
	robots=$(wget http://$ip/robots.txt -qO-)
	echo "$robots"
	[ "$log" = 'True' ] && (echo "$robots" >> $PWD/$2/$ip/robots-txt)
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
	nmap -sV $ip -p- -A -T5 -oN $PWD/$2/$ip/full-nmap-scan --stats-every 10s
	echo 
	echo "[*] Logs created."
	echo "[*] $PWD/$2"
	ls -Al $PWD/$2
	echo
	echo "[*] $PWD/$2/$ip"
	ls -Al $PWD/$2/$ip
fi

# Finished!
echo
echo "[*] All done!"
echo

#end
