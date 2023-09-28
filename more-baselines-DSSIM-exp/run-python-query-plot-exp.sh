#!/bin/bash

#export READ_METHOD=rawQuery # rawQuery/mac/cpv/minmax/lttb/minmax_lsm
export HOME_PATH=/root/ubuntu
export M4_VISUALIZATION_EXP=${HOME_PATH}/M4-visualization-exp
export IOTDB_HOME_PATH=${HOME_PATH}/moreBaselinesExp # the dir is already populated after running run-more-baselines.sh

# below are local client configurations
export PYTHON_READ_PLOT_PATH=$M4_VISUALIZATION_EXP/more-baselines-DSSIM-exp/python-read-plot.py
export EXPERIMENT_PATH=$M4_VISUALIZATION_EXP/more-baselines-DSSIM-exp/python_query_plot_experiment.sh
export PROCESS_QUERY_PLOT_JAVA_PATH=$M4_VISUALIZATION_EXP/more-baselines-DSSIM-exp/ProcessQueryPlotResult.java
export tqs=0
export tqe=4259092178974
export device='root.game'
export measurement='s6'
#export local_FILE_PATH=$M4_VISUALIZATION_EXP/more-baselines-DSSIM-exp/localData_${READ_METHOD}.csv

# below are remote data server configurations
export IOTDB_SBIN_HOME=$IOTDB_HOME_PATH/iotdb-server-0.12.4/sbin
export IOTDB_CONF_PATH=$IOTDB_HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
export IOTDB_START=$IOTDB_SBIN_HOME/start-server.sh
export IOTDB_STOP=$IOTDB_SBIN_HOME/stop-server.sh
export IOTDB_EXPORT_CSV_TOOL=$IOTDB_HOME_PATH/iotdb-cli-0.12.4/tools
export iotdb_port=6667
export iotdb_username=root
export iotdb_passwd=root
export tool_bash=$M4_VISUALIZATION_EXP/more-baselines-DSSIM-exp/tool.sh
export CSV_DIR=$M4_VISUALIZATION_EXP/more-baselines-DSSIM-exp
# ${IOTDB_EXPORT_CSV_TOOL}/dump0.csv

echo "begin"

sed -i -e 's/\r$//' $tool_bash

# prepare ProcessQueryPlotResult tool
sed '/^package/d' ProcessQueryPlotResult.java > ProcessQueryPlotResult2.java
rm ProcessQueryPlotResult.java
mv ProcessQueryPlotResult2.java ProcessQueryPlotResult.java
javac ProcessQueryPlotResult.java

for w in 1 2 50
do
	echo "w=$w"
	export w=$w
	$EXPERIMENT_PATH
done

echo "ALL FINISHED!"
echo 3 |sudo tee /proc/sys/vm/drop_caches
free -m