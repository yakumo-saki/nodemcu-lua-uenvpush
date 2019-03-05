#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
LOG_DIR=${SCRIPT_DIR}/../log
SERIAL=/dev/tty.wchusbserial141310
MAX_NUM=99

rm ${LOG_DIR}/*.log

function download_log () {
    echo "Downloading $1"
    cd ${SCRIPT_DIR}/../log
    nodemcu-tool --port $SERIAL download $1

    if [ $? -gt 0 ]; then
        # retry
        echo "failed. retry once."
        nodemcu-tool --port $SERIAL download $1
    fi
}

for i in `seq 0 ${MAX_NUM}`; do
    NUMSTR=`printf "%02d" $i`

    download_log log-$NUMSTR.log
done

