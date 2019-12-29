#!/bin/sh

pingTime() {
        local speed=`ping -W1 -c3 "$1" 2> /dev/null|grep -E '^(rtt|round-trip)'|cut -d '/' -f5|cut -d '.' -f1`
        if [ -z "$speed" ]; then
                #echo "ping -W1 -c3 \"$1\" timeout "
                #return ""
                echo ""
        else
                #echo "speed:$speed domain:\"$1"\"
                #return $speed
                echo $speed
        fi
}

domainList="dl-cdn.alpinelinux.org mirrors.aliyun.com"
fastdomain=""
fasttime=""

for domain in $domainList
do
        speed=$(pingTime "$domain")
        if [ -z "$speed" ]; then
                continue
        fi
        if [ -z "$fastdomain" ]; then
                fastdomain="$domain"
                fasttime="$speed"
        fi
        if [ $speed -lt $fasttime ] ;
        then
                fastdomain="$domain"
                fasttime="$speed"
        fi
done

if [ -n "$fasttime" ]; then
        echo $fastdomain
        echo $fasttime
	set -x \
	&& sed -i "s/dl-cdn.alpinelinux.org/$fastdomain/" /etc/apk/repositories
fi