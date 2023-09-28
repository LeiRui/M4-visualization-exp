#!/bin/bash

echo 3 | sudo tee /proc/sys/vm/drop_caches

methodArray=("rawQuery" "mac" "cpv" "minmax" "lttb"); # rawQuery/mac/cpv/minmax/lttb/minmax_lsm
for method in ${methodArray[@]};
do

if [ $method == "cpv" ] || [ $method == "minmax_lsm" ]
then
    bash $tool_bash enable_CPV true $IOTDB_CONF_PATH
fi

# start server
bash ${IOTDB_START} >/dev/null 2>&1 &
sleep 10s

# query and plot
python3 ${M4_VISUALIZATION_EXP}/more-baselines-DSSIM-exp/query-plot.py -r $method -f ${CSV_DIR} -s ${tqs} -e ${tqe} -w ${w} -t ${remote_IOTDB_EXPORT_CSV_TOOL} -d ${device} -m ${measurement}

# stop server
bash ${IOTDB_STOP}
sleep 3s

echo 3 | sudo tee /proc/sys/vm/drop_caches
sleep 3s

done;

# compare DSSIM
