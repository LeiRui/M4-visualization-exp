#!/bin/bash

export READ_METHOD=rawQuery # rawQuery/mac/cpv/minmax/lttb/minmax_lsm
export HOME_PATH=/root/ubuntu
export M4_VISUALIZATION_EXP=${HOME_PATH}/M4-visualization-exp
export remote_M4_VISUALIZATION_EXP=${HOME_PATH}/M4-visualization-exp
export remote_IOTDB_HOME_PATH=${HOME_PATH}/moreBaselinesExp # note the dir, already populated after running run-more-baselines.sh
export remote_ip=127.0.0.1
export remote_user_name=mltest
export remote_passwd='mltest' # do not use double quotes

# below are local client configurations
export PYTHON_READ_PLOT_PATH=$M4_VISUALIZATION_EXP/more-baselines-DSSIM-exp/python-read-plot.py
export EXPERIMENT_PATH=$M4_VISUALIZATION_EXP/more-baselines-DSSIM-exp/python_query_plot_experiment.sh
export repetition=1
export PROCESS_QUERY_PLOT_JAVA_PATH=$M4_VISUALIZATION_EXP/more-baselines-DSSIM-exp/ProcessQueryPlotResult.java
export tqs=0
export tqe=4259092178974
export device='root.game'
export measurement='s6'
export local_FILE_PATH=$M4_VISUALIZATION_EXP/more-baselines-DSSIM-exp/localData_${READ_METHOD}.csv

# below are remote data server configurations
export remote_IOTDB_SBIN_HOME=$remote_IOTDB_HOME_PATH/iotdb-server-0.12.4/sbin
export remote_IOTDB_CONF_PATH=$remote_IOTDB_HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
export remote_IOTDB_START=$remote_IOTDB_SBIN_HOME/start-server.sh
export remote_IOTDB_STOP=$remote_IOTDB_SBIN_HOME/stop-server.sh
export remote_IOTDB_EXPORT_CSV_TOOL=$remote_IOTDB_HOME_PATH/iotdb-cli-0.12.4/tools
export remote_iotdb_port=6667
export remote_iotdb_username=root
export remote_iotdb_passwd=root
export remote_tool_bash=$remote_M4_VISUALIZATION_EXP/more-baselines-DSSIM-exp/tool.sh
export remote_M4_FILE_PATH=$remote_M4_VISUALIZATION_EXP/more-baselines-DSSIM-exp/data.csv

echo "begin"

# prepare ProcessQueryPlotResult tool
sed '/^package/d' ProcessQueryPlotResult.java > ProcessQueryPlotResult2.java
rm ProcessQueryPlotResult.java
mv ProcessQueryPlotResult2.java ProcessQueryPlotResult.java
javac ProcessQueryPlotResult.java

for w in 1 2 50
do
	echo "w=$w"
	export w=$w

	$EXPERIMENT_PATH >result-${READ_METHOD}_${w}.txt #> is overwrite, >> is append

	java ProcessQueryPlotResult result-${READ_METHOD}_${w}.txt result-${READ_METHOD}_${w}.out sumResult-${READ_METHOD}.csv ${w}
done

echo "ALL FINISHED!"
echo 3 |sudo tee /proc/sys/vm/drop_caches
free -m