#!/bin/bash

echo

while getopts ":l:S:i:" opt; do
        case $opt in
            l)
                echo "[*] Creating Direcotry $PWD/$OPTARG"
                mkdir $PWD/$OPTARG
                echo "[*] Logging is enabled."
                log=True
                dir=$OPTARG
                ;;
	    S)
		echo "[*] Using nmap scan as input ($OPTARG)"		
		ports=($(cat "$OPTARG" | grep open | awk '{ print $1 }' | cut -d / -f 1))
		;;
	    i)
		echo "[*] IP of target: $OPTARG"
		ip=$OPTARG
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

echo

for port in "${ports[@]}"
do
	echo "[*] Banner - $ip:$port"

	if [ "$log" = 'True' ]; then
		case $port in
		    80)
			curl -s -D - -o /dev/null http://$ip | tee $PWD/$dir/$port
			;;
		    443)
			curl -k -s -v -D - https://$ip > /dev/null | tee $PWD/$dir/$port
			;;
		    *)
			echo ";" | nc -q 1 -w 1 $ip $port | tee $PWD/$dir/$port
			;;
		esac
	else
		case $port in
		    80)
			curl -s -D - -o /dev/null http://$ip
			;;
		    443)
			curl -k -s -v -D - https://$ip > /dev/null
			;;
		    *)
			echo ";" | nc -q 1 -w 1 $ip $port
			;;
		esac
	fi
	echo
done
