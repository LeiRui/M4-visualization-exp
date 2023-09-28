#!/bin/bash

echo 3 | sudo tee /proc/sys/vm/drop_caches

if [ $rawQueryExecuted == false ]
then
  methodArray=("rawQuery" "mac" "cpv" "minmax" "lttb"); # rawQuery/mac/cpv/minmax/lttb/minmax_lsm
  export rawQueryExecuted=true
else
  methodArray=("mac" "cpv" "minmax" "lttb"); # rawQuery/mac/cpv/minmax/lttb/minmax_lsm
fi

for method in ${methodArray[@]};
do
echo "[[[[[[[[[[[[[$method]]]]]]]]]]]]]"
if [ $method == "cpv" ] || [ $method == "minmax_lsm" ]
then
    bash $tool_bash enable_CPV true $IOTDB_CONF_PATH
fi

# start server
bash ${IOTDB_START} >/dev/null 2>&1 &
sleep 10s

# query and plot
python3 ${QUERY_PLOT_PATH} -r $method -o ${EXP_DIR} -s ${tqs} -e ${tqe} -w ${w} \
-t ${IOTDB_EXPORT_CSV_TOOL} -d ${device} -m ${measurement}

# stop server
bash ${IOTDB_STOP}
sleep 3s

echo 3 | sudo tee /proc/sys/vm/drop_caches
sleep 3s

done;

# compare DSSIM
