#!/usr/bin/env bash

PFSTATSFILE=/tmp/postfix_statsfile.dat
TEMPFILE=$(mktemp)
PFLOGSUMM=/usr/sbin/pflogsumm
DOCKER_LOGS="docker logs --since=720h 74f2a9031d0f" #TODO: Time delta from config

# list of values we are interested in
PFVALS=( 'received' 'delivered' 'forwarded' 'deferred' 'bounced' 'rejected' 'held' 'discarded' 'reject_warnings' 'bytes_received' 'bytes_delivered' 'senders' 'recipients' )

# write result of running this script
write_result () {

        echo "$2"
        exit $1

}

# check for binaries/containers we need to run the script
if [ ! -x ${PFLOGSUMM} ] ; then
        echo "ERROR: ${PFLOGSUMM} not found"
        exit 1
fi

if [ -z $(docker ps -qf name=postfix-mailcow) ] ; then
        echo "ERROR: ID for container 'postfix-mailcow' not found"
        exit 1
fi


# read specific value from data file and print it
readvalue () {
        local $key
        key=$(echo ${PFVALS[@]} | grep -wo $1)
        if [ -n "${key}" ]; then
                value=$(grep -e "^${key};" "${PFSTATSFILE}" | cut -d ";" -f2)
                echo "${value}"

        else
                rm "${TEMPFILE}"
                result_text="ERROR: could not get value \"$1\" from ${PFSTATSFILE}"
                result_code="1"
                write_result "${result_code}" "${result_text}"
        fi
}

# update value  in data file
writevalue() {
        local $key
        local $pfkey

        key=$1
        pfkey=$(echo "$1" | tr '_' ' ')

        # convert value to bytes
        value=$(grep -m 1 "$pfkey" $TEMPFILE | awk '{print $1}' | awk '/k|m/{p = /k/?1:2}{printf "%d\n", int($1) * 1024 ^ p}')

        # put values in data file
        echo "${key};${value}" >> "${PFSTATSFILE}"
}

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

        # put values in data file
        echo "${key};${value}" >> "${PFSTATSFILE}"
}

# is there a requests for specific value or do we update all values ?
if [ -n "$1" ]; then
        readvalue "$1"
else
        # read the new part of mail log and read it with pflogsumm to get the summary

        # check whether file exists and the write permissions are granted
        rm -f "${PFSTATSFILE}" > /dev/null 2>&1
        if [ -f "${PFSTATSFILE}" ]; then

                result_text="ERROR: could not cleanup statfile ${PFSTATSFILE}"
                result_code="1"
                write_result "${result_code}" "${result_text}"

        fi
        touch "${PFSTATSFILE}" > /dev/null 2>&1

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
        ${DOCKER_LOGS} | "${PFLOGSUMM}" ${pflog_flags} > "${TEMPFILE}" 2>/dev/null

        if [ ! $? -eq 0 ]; then
                result_text="ERROR: wrong exit code returned while running  ${DOCKER_LOGS} | ${PFLOGSUMM} ${pflog_flags} > ${TEMPFILE} 2>/dev/null"
                result_code="1"
                write_result "${result_code}" "${result_text}"
        fi

        # write all values from pflogsumm summary
        for i in "${PFVALS[@]}"; do
                writevalue "$i"
        done

        # add bounced domains if any
        writebounces

        result_text="OK: statistics saved"
        result_code="0"
        write_result "${result_code}" "${result_text}"
fi

rm "${TEMPFILE}"
