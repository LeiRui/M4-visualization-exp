#!/bin/bash

export HOME_PATH=/root/ubuntu

# below are exp directory configurations
export M4_VISUALIZATION_EXP=${HOME_PATH}/M4-visualization-exp
export EXP_DIR=$M4_VISUALIZATION_EXP/more-baselines-DSSIM-exp
export EXPERIMENT_PATH=$EXP_DIR/python_query_plot_experiment.sh
export tool_bash=$EXP_DIR/tool.sh
export QUERY_PLOT_PATH=$EXP_DIR/query-plot.py

# below are data server configurations
export IOTDB_HOME_PATH=${HOME_PATH}/moreBaselinesExp # the dir is already populated after running run-more-baselines.sh
export IOTDB_SBIN_HOME=$IOTDB_HOME_PATH/iotdb-server-0.12.4/sbin
export IOTDB_CONF_PATH=$IOTDB_HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
export IOTDB_START=$IOTDB_SBIN_HOME/start-server.sh
export IOTDB_STOP=$IOTDB_SBIN_HOME/stop-server.sh
export IOTDB_EXPORT_CSV_TOOL=$IOTDB_HOME_PATH/iotdb-cli-0.12.4/tools
export iotdb_port=6667
export iotdb_username=root
export iotdb_passwd=root

# below are data parameters
export tqs=0
export tqe=4259092178974
export device='root.game'
export measurement='s6'

echo "begin"

sed -i -e 's/\r$//' $tool_bash

for w in 1 2 50
do
	echo "w=$w"
	export w=$w
	$EXPERIMENT_PATH
done

echo "ALL FINISHED!"
echo 3 |sudo tee /proc/sys/vm/drop_caches
free -m