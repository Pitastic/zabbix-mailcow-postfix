#!/usr/bin/env bash

TEMPFILE=$(mktemp)
PFLOGSUMM=/usr/sbin/pflogsumm
TS_FILE=/tmp/zabbix-postfix.timestamp

# list of values we are interested in
PFVALS=( 'received' 'delivered' 'forwarded' 'deferred' 'bounced' 'rejected' 'held' 'discarded' 'reject_warnings' 'bytes_received' 'bytes_delivered' 'senders' 'recipients' )


# check for binaries/containers we need to run the script
if [ ! -x ${PFLOGSUMM} ] ; then
        echo "{\"error\": \"${PFLOGSUMM} not found\"}"
        exit 1
fi

if [ -z $(docker ps -qf name=postfix-mailcow) ] ; then
        echo "{\"error\": \"ID for container 'postfix-mailcow' not found\"}"
        exit 1
fi

# getting and setting new timestamp
if [ ! -w $TS_FILE ] ; then
        echo "{\"error\": \"Permission on file ${TS_FILE} denied\"}"
        exit 1
fi
if [ -f $TS_FILE ] ; then
        TIMESTAMP="$(cat $TS_FILE)"
else
        TIMESTAMP="6m"
fi
echo $(date +%Y-%m-%dT%T) > $TS_FILE

# fetch logs command with timestamp
DOCKER_LOGS="docker logs --since=${TIMESTAMP} $(docker ps -qf name=postfix-mailcow)"


# write result of running this script
write_result () {

        echo "$2"
        exit $1

}

# generate data point
writevalue() {
        local $key
        local $pfkey

        key=$1
        pfkey=$(echo "$1" | tr '_' ' ')

        # convert value to bytes
        value=$(grep -m 1 "$pfkey" $TEMPFILE | awk '{print $1}' | awk '/k|m/{p = /k/?1:2}{printf "%d\n", int($1) * 1024 ^ p}')

        # put values in json
        echo "\"${key}\": \"${value}\""
}

# add bounces list
writebounces() {
        local $key
        local $pfkey

        # sed-grep for the uniq set of bounced domains
        key='bounced_domains'
        value=$(sed -n '/^message bounce detail/,/^smtp delivery failures/p' $TEMPFILE | \
                head -n-2 | tail +3 | \
                sed -E 's/^\s{2}([0-9A-Za-z\.\-]*).*$/\1/' | \
                grep -v '^$' | sort | uniq | \
                sed -z 's/\n/,/g;s/,$/\n/')

        # put values in json
        echo "\"${key}\": \"${value}\""
}


# read the new part of mail log and read it with pflogsumm to get the summary

#
# -h 0          no tops per Domain
# -u 0          no tops per User
# --zero_fill   fill empty cols with zeros
# --problems_first      list problems on top
#
# No Details on:
#       --no_no_msg_size
#       --bounce-detail=0
#       --deferral-detail=0
#       --reject-detail=0
#       --smtpd-warning-detail=0
#
pflog_flags="-h 0 -u 0 --problems_first --no_no_msg_size --bounce-detail=1 --deferral-detail=0 --reject-detail=0 --smtpd-warning-detail=0"
${DOCKER_LOGS} 2>/dev/null | "${PFLOGSUMM}" ${pflog_flags} > "${TEMPFILE}" 2>/dev/null

if [ ! $? -eq 0 ]; then
        result_text="{\"error\": \"wrong exit code returned while running  ${DOCKER_LOGS} | ${PFLOGSUMM} ${pflog_flags} > ${TEMPFILE} 2>/dev/null\"}"
        result_code="1"
        write_result "${result_code}" "${result_text}"
fi


# Create JSON Response
result_text="{"

# write all values from pflogsumm summary
for i in "${PFVALS[@]}"; do
        result_text="${result_text}$(writevalue "$i"), "
done

# add bounced domains if any
result_text="${result_text}$(writebounces)"
result_text="${result_text}}"

# clean up and return
rm "${TEMPFILE}"

result_code="0"
write_result "${result_code}" "${result_text}"
