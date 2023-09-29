#!/bin/bash

export HOME_PATH=/root/ubuntu

# below are data parameters
export tqs=511996 # tqs=0 export-csv tool first point no value
export tqe=4259092178974
export device='root.game'
export measurement='s6'

# below are exp directory configurations
export M4_VISUALIZATION_EXP=${HOME_PATH}/M4-visualization-exp
export EXP_DIR=$M4_VISUALIZATION_EXP/more-baselines-DSSIM-exp
export EXPERIMENT_PATH=$EXP_DIR/python_query_save_experiment.sh
export tool_bash=$EXP_DIR/tool.sh
export QUERY_SAVE_PATH=$EXP_DIR/query-save.py
export DSSIM_PATH=$EXP_DIR/computeDSSIM.py
export PLOT_QUERY_RES_PATH=$EXP_DIR/plot-query-exp-res.py

# below are data server configurations
export IOTDB_HOME_PATH=${HOME_PATH}/moreBaselinesQueryExp # make sure the dir is already populated after running run-more-baselines.sh
export IOTDB_SBIN_HOME=$IOTDB_HOME_PATH/iotdb-server-0.12.4/sbin
export IOTDB_CONF_PATH=$IOTDB_HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
export IOTDB_START=$IOTDB_SBIN_HOME/start-server.sh
export IOTDB_STOP=$IOTDB_SBIN_HOME/stop-server.sh
export IOTDB_EXPORT_CSV_TOOL=$IOTDB_HOME_PATH/iotdb-cli-0.12.4/tools
export iotdb_port=6667
export iotdb_username=root
export iotdb_passwd=root

echo "begin"

sed -i -e 's/\r$//' $tool_bash

# ----------query and save csv----------
# rawQuery
echo 3 | sudo tee /proc/sys/vm/drop_caches
method='rawQuery'
echo "[[[[[[[[[[[[[$method]]]]]]]]]]]]]"
# start server
bash ${IOTDB_START} >/dev/null 2>&1 &
sleep 10s
# query and save csv
python3 ${QUERY_SAVE_PATH} -r $method -o ${EXP_DIR} -s ${tqs} -e ${tqe} -w 1 \
-t ${IOTDB_EXPORT_CSV_TOOL} -d ${device} -m ${measurement}
# stop server
bash ${IOTDB_STOP}
sleep 3s
echo 3 | sudo tee /proc/sys/vm/drop_caches
sleep 3s

# mac/cpv/minmax/lttb/minmax_lsm under different w parameters
for w in 10 20 50 100 200 400 800 1200 1600 2000 3000 4000
#for w in 10 50
do
	echo "[[[[[[[[[[[[[w=$w]]]]]]]]]]]]]"
	export w=$w
	$EXPERIMENT_PATH
done

# ----------plot and compute DSSIM----------
echo 3 |sudo tee /proc/sys/vm/drop_caches
free -m
sleep 3s
python3 ${DSSIM_PATH} -i ${EXP_DIR}

# ----------plot query exp res by the way----------
echo 3 |sudo tee /proc/sys/vm/drop_caches
free -m
sleep 3s
python3 ${PLOT_QUERY_RES_PATH} -i ${IOTDB_HOME_PATH}/res.csv -o ${EXP_DIR}

echo "ALL FINISHED!"
echo 3 |sudo tee /proc/sys/vm/drop_caches
free -m