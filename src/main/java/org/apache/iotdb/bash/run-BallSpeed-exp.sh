#!/bin/bash

HOME_PATH=/data/rl/v2

############################
# extract small data for fast exp
# java ExtractBallSpeedData inPath outPath timeIdx valueIdx lineNum
# lineNum=-1 means extracting total lines
############################
cd $HOME_PATH/BallSpeed
# java ExtractBallSpeedData /data3/raw_data/data/full-game BallSpeed.csv 1 5 8 2000000 3200000


############################
# generate out-of-order source data
# java OverlapGenerator inPath outPath timeIdx valueIdx overlapPercentage overlapDepth
# overlapPercentage [0,100]
# overlapDepth [0,50]
############################
cp BallSpeed.csv BallSpeed-O_0_0

java OverlapGenerator BallSpeed.csv BallSpeed-O_10_10 0 1 10 10
java OverlapGenerator BallSpeed.csv BallSpeed-O_30_10 0 1 30 10
java OverlapGenerator BallSpeed.csv BallSpeed-O_50_10 0 1 50 10
java OverlapGenerator BallSpeed.csv BallSpeed-O_70_10 0 1 70 10
java OverlapGenerator BallSpeed.csv BallSpeed-O_90_10 0 1 90 10


############################
# Experimental parameter design:
# [EXP1] Varying the number of time spans w
# (1) w: 1,2,5,10,20,50,100,200,500,1000,2000,4000,8000
# (2) uery range: totalRange
# (3) overlap percentage: 10%
# (4) delete percentage: 0%
# (5) delete time range: 0
# [EXP2] Varying query time range
# (1) w: 100
# (2) query range: k*w*totalRange/(pointNum/chunkSize).
# - target estimated chunks per interval = k
# - range = k*w*totalRange/(pointNum/chunkSize)
# - kMax=(pointNum/chunkSize)/w, that is, range=totalRange.
# - E.g. k=0.2,0.5,1,2.5,5,12
# (3) overlap percentage: 10%
# (4) delete percentage: 0%
# (5) delete time range: 0
# [EXP3] Varying chunk overlap percentage
# (1) w: 100
# (2) query range: totalRange
# (3) overlap percentage: 0%, 10%, 30%, 50%, 70%, 90%
# (4) delete percentage: 0%
# (5) delete time range: 0
# [EXP4] Varying delete percentage
# (1) w: 100
# (2) query range: totalRange
# (3) overlap percentage: 10%
# (4) delete percentage: 0%, 9%, 29%, 49%, 69%, 89%
# (5) delete time range: 10% of chunk time interval, that is 0.1*totalRange/(pointNum/chunkSize)
# [EXP5] Varying delete time range
# (1) w: 100
# (2) query range: totalRange
# (3) overlap percentage: 10%
# (4) delete percentage: 49%
# (5) delete time range: 10%, 30%, 50%, 70%, 90% of chunk time interval, that is x%*totalRange/(pointNum/chunkSize)
############################

############################
# [EXP1]
############################

cd $HOME_PATH/BallSpeed_testspace
mkdir O_10_10_D_0_0
cd O_10_10_D_0_0

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_0_0/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_0_0/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_0_0/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold 1000 ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
############################
echo "Writing O_10_10_D_0_0"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 3s
java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar $HOME_PATH/BallSpeed/BallSpeed-O_10_10 0 0 0 1
sleep 3s
./stop-server.sh
sleep 3s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_0_0 with varied w"

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_0_0
mkdir vary_w
cd vary_w

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 1 2 >> result_1.txt
java ProcessResult result_1.txt result_1.out ../sumResultMOC.csv
./../../../query_experiment.sh 617426057627 2 2 >> result_2.txt
java ProcessResult result_2.txt result_2.out ../sumResultMOC.csv
./../../../query_experiment.sh 617426057627 5 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv
./../../../query_experiment.sh 617426057627 10 2 >> result_4.txt
java ProcessResult result_4.txt result_4.out ../sumResultMOC.csv
./../../../query_experiment.sh 617426057627 20 2 >> result_5.txt
java ProcessResult result_5.txt result_5.out ../sumResultMOC.csv
./../../../query_experiment.sh 617426057627 50 2 >> result_6.txt
java ProcessResult result_6.txt result_6.out ../sumResultMOC.csv
./../../../query_experiment.sh 617426057627 100 2 >> result_7.txt
java ProcessResult result_7.txt result_7.out ../sumResultMOC.csv
./../../../query_experiment.sh 617426057627 200 2 >> result_8.txt
java ProcessResult result_8.txt result_8.out ../sumResultMOC.csv
./../../../query_experiment.sh 617426057627 500 2 >> result_9.txt
java ProcessResult result_9.txt result_9.out ../sumResultMOC.csv
./../../../query_experiment.sh 617426057627 1000 2 >> result_10.txt
java ProcessResult result_10.txt result_10.out ../sumResultMOC.csv
./../../../query_experiment.sh 617426057627 2000 2 >> result_11.txt
java ProcessResult result_11.txt result_11.out ../sumResultMOC.csv
./../../../query_experiment.sh 617426057627 4000 2 >> result_12.txt
java ProcessResult result_12.txt result_12.out ../sumResultMOC.csv
./../../../query_experiment.sh 617426057627 8000 2 >> result_13.txt
java ProcessResult result_13.txt result_13.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 1 1 >> result_1.txt
java ProcessResult result_1.txt result_1.out ../sumResultMAC.csv
./../../../query_experiment.sh 617426057627 2 1 >> result_2.txt
java ProcessResult result_2.txt result_2.out ../sumResultMAC.csv
./../../../query_experiment.sh 617426057627 5 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv
./../../../query_experiment.sh 617426057627 10 1 >> result_4.txt
java ProcessResult result_4.txt result_4.out ../sumResultMAC.csv
./../../../query_experiment.sh 617426057627 20 1 >> result_5.txt
java ProcessResult result_5.txt result_5.out ../sumResultMAC.csv
./../../../query_experiment.sh 617426057627 50 1 >> result_6.txt
java ProcessResult result_6.txt result_6.out ../sumResultMAC.csv
./../../../query_experiment.sh 617426057627 100 1 >> result_7.txt
java ProcessResult result_7.txt result_7.out ../sumResultMAC.csv
./../../../query_experiment.sh 617426057627 200 1 >> result_8.txt
java ProcessResult result_8.txt result_8.out ../sumResultMAC.csv
./../../../query_experiment.sh 617426057627 500 1 >> result_9.txt
java ProcessResult result_9.txt result_9.out ../sumResultMAC.csv
./../../../query_experiment.sh 617426057627 1000 1 >> result_10.txt
java ProcessResult result_10.txt result_10.out ../sumResultMAC.csv
./../../../query_experiment.sh 617426057627 2000 1 >> result_11.txt
java ProcessResult result_11.txt result_11.out ../sumResultMAC.csv
./../../../query_experiment.sh 617426057627 4000 1 >> result_12.txt
java ProcessResult result_12.txt result_12.out ../sumResultMAC.csv
./../../../query_experiment.sh 617426057627 8000 1 >> result_13.txt
java ProcessResult result_13.txt result_13.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 1 3 >> result_1.txt
java ProcessResult result_1.txt result_1.out ../sumResultCPV.csv
./../../../query_experiment.sh 617426057627 2 3 >> result_2.txt
java ProcessResult result_2.txt result_2.out ../sumResultCPV.csv
./../../../query_experiment.sh 617426057627 5 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv
./../../../query_experiment.sh 617426057627 10 3 >> result_4.txt
java ProcessResult result_4.txt result_4.out ../sumResultCPV.csv
./../../../query_experiment.sh 617426057627 20 3 >> result_5.txt
java ProcessResult result_5.txt result_5.out ../sumResultCPV.csv
./../../../query_experiment.sh 617426057627 50 3 >> result_6.txt
java ProcessResult result_6.txt result_6.out ../sumResultCPV.csv
./../../../query_experiment.sh 617426057627 100 3 >> result_7.txt
java ProcessResult result_7.txt result_7.out ../sumResultCPV.csv
./../../../query_experiment.sh 617426057627 200 3 >> result_8.txt
java ProcessResult result_8.txt result_8.out ../sumResultCPV.csv
./../../../query_experiment.sh 617426057627 500 3 >> result_9.txt
java ProcessResult result_9.txt result_9.out ../sumResultCPV.csv
./../../../query_experiment.sh 617426057627 1000 3 >> result_10.txt
java ProcessResult result_10.txt result_10.out ../sumResultCPV.csv
./../../../query_experiment.sh 617426057627 2000 3 >> result_11.txt
java ProcessResult result_11.txt result_11.out ../sumResultCPV.csv
./../../../query_experiment.sh 617426057627 4000 3 >> result_12.txt
java ProcessResult result_12.txt result_12.out ../sumResultCPV.csv
./../../../query_experiment.sh 617426057627 8000 3 >> result_13.txt
java ProcessResult result_13.txt result_13.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# [EXP2]
############################
echo "Querying O_10_10_D_0_0 with varied tqe"

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_0_0
mkdir vary_tqe
cd vary_tqe

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 13096043655 100 2 >> result_1.txt # 0.2
java ProcessResult result_1.txt result_1.out ../sumResultMOC.csv
./../../../query_experiment.sh 26192087310 100 2 >> result_2.txt # 0.5
java ProcessResult result_2.txt result_2.out ../sumResultMOC.csv
./../../../query_experiment.sh 52384174620 100 2 >> result_3.txt # 1
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv
./../../../query_experiment.sh 130960436550 100 2 >> result_4.txt # 2.5
java ProcessResult result_4.txt result_4.out ../sumResultMOC.csv
./../../../query_experiment.sh 261920873100 100 2 >> result_5.txt # 5
java ProcessResult result_5.txt result_5.out ../sumResultMOC.csv
./../../../query_experiment.sh 617426057627 100 2 >> result_6.txt # 12
java ProcessResult result_6.txt result_6.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 13096043655 100 1 >> result_1.txt
java ProcessResult result_1.txt result_1.out ../sumResultMAC.csv
./../../../query_experiment.sh 26192087310 100 1 >> result_2.txt
java ProcessResult result_2.txt result_2.out ../sumResultMAC.csv
./../../../query_experiment.sh 52384174620 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv
./../../../query_experiment.sh 130960436550 100 1 >> result_4.txt
java ProcessResult result_4.txt result_4.out ../sumResultMAC.csv
./../../../query_experiment.sh 261920873100 100 1 >> result_5.txt
java ProcessResult result_5.txt result_5.out ../sumResultMAC.csv
./../../../query_experiment.sh 617426057627 100 1 >> result_6.txt
java ProcessResult result_6.txt result_6.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 13096043655 100 3 >> result_1.txt
java ProcessResult result_1.txt result_1.out ../sumResultCPV.csv
./../../../query_experiment.sh 26192087310 100 3 >> result_2.txt
java ProcessResult result_2.txt result_2.out ../sumResultCPV.csv
./../../../query_experiment.sh 52384174620 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv
./../../../query_experiment.sh 130960436550 100 3 >> result_4.txt
java ProcessResult result_4.txt result_4.out ../sumResultCPV.csv
./../../../query_experiment.sh 261920873100 100 3 >> result_5.txt
java ProcessResult result_5.txt result_5.out ../sumResultCPV.csv
./../../../query_experiment.sh 617426057627 100 3 >> result_6.txt
java ProcessResult result_6.txt result_6.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

# [EXP3]
# ---- O_0_0_D_0_0:
# ---- ---- iotdb-engine-enableCPVtrue.properties
# ---- ---- iotdb-engine-enableCPVfalse.properties
# ---- ---- write_data.sh
# ---- ---- fix
# ---- ---- ---- moc
# ---- ---- ---- ---- change_interval_experiments.sh
# ---- ---- ---- ---- ProcessResult.class
# ---- ---- ---- ---- ProcessResult.java
# ---- ---- ---- mac
# ---- ---- ---- ---- change_interval_experiments.sh
# ---- ---- ---- ---- ProcessResult.class
# ---- ---- ---- ---- ProcessResult.java
# ---- ---- ---- cpv
# ---- ---- ---- ---- change_interval_experiments.sh
# ---- ---- ---- ---- ProcessResult.class
# ---- ---- ---- ---- ProcessResult.java
# ---- O_30_10_D_0_0
# ---- O_50_10_D_0_0
# ---- O_70_10_D_0_0
# ---- O_90_10_D_0_0

############################
# O_0_0_D_0_0
############################

cd $HOME_PATH/BallSpeed_testspace
mkdir O_0_0_D_0_0
cd O_0_0_D_0_0

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/BallSpeed_O_0_0_D_0_0/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/BallSpeed_O_0_0_D_0_0/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/BallSpeed_O_0_0_D_0_0/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold 1000 ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_0_0_D_0_0"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 3s
java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar $HOME_PATH/BallSpeed/BallSpeed-O_0_0 0 0 0 1
sleep 3s
./stop-server.sh
sleep 3s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_0_0_D_0_0"

cd $HOME_PATH/BallSpeed_testspace/O_0_0_D_0_0
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_30_10_D_0_0
############################

cd $HOME_PATH/BallSpeed_testspace
mkdir O_30_10_D_0_0
cd O_30_10_D_0_0

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/BallSpeed_O_30_10_D_0_0/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/BallSpeed_O_30_10_D_0_0/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/BallSpeed_O_30_10_D_0_0/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold 1000 ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_30_10_D_0_0"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 3s
java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar $HOME_PATH/BallSpeed/BallSpeed-O_30_10 0 0 0 1
sleep 3s
./stop-server.sh
sleep 3s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_30_10_D_0_0"

cd $HOME_PATH/BallSpeed_testspace/O_30_10_D_0_0
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_50_10_D_0_0
############################

cd $HOME_PATH/BallSpeed_testspace
mkdir O_50_10_D_0_0
cd O_50_10_D_0_0

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/BallSpeed_O_50_10_D_0_0/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/BallSpeed_O_50_10_D_0_0/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/BallSpeed_O_50_10_D_0_0/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold 1000 ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_50_10_D_0_0"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 3s
java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar $HOME_PATH/BallSpeed/BallSpeed-O_50_10 0 0 0 1
sleep 3s
./stop-server.sh
sleep 3s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_50_10_D_0_0"

cd $HOME_PATH/BallSpeed_testspace/O_50_10_D_0_0
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_70_10_D_0_0
############################

cd $HOME_PATH/BallSpeed_testspace
mkdir O_70_10_D_0_0
cd O_70_10_D_0_0

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/BallSpeed_O_70_10_D_0_0/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/BallSpeed_O_70_10_D_0_0/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/BallSpeed_O_70_10_D_0_0/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold 1000 ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_70_10_D_0_0"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 3s
java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar $HOME_PATH/BallSpeed/BallSpeed-O_70_10 0 0 0 1
sleep 3s
./stop-server.sh
sleep 3s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_70_10_D_0_0"

cd $HOME_PATH/BallSpeed_testspace/O_70_10_D_0_0
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_90_10_D_0_0
############################

cd $HOME_PATH/BallSpeed_testspace
mkdir O_90_10_D_0_0
cd O_90_10_D_0_0

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/BallSpeed_O_90_10_D_0_0/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/BallSpeed_O_90_10_D_0_0/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/BallSpeed_O_90_10_D_0_0/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold 1000 ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_90_10_D_0_0"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 3s
java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar $HOME_PATH/BallSpeed/BallSpeed-O_90_10 0 0 0 1
sleep 3s
./stop-server.sh
sleep 3s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_90_10_D_0_0"

cd $HOME_PATH/BallSpeed_testspace/O_90_10_D_0_0
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

# [EXP4]
# ---- O_10_10_D_0_0
# ---- O_10_10_D_9_10
# ---- O_10_10_D_29_10
# ---- O_10_10_D_49_10
# ---- O_10_10_D_69_10
# ---- O_10_10_D_89_10

############################
# O_10_10_D_9_10
############################

cd $HOME_PATH/BallSpeed_testspace
mkdir O_10_10_D_9_10
cd O_10_10_D_9_10

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_9_10/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_9_10/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_9_10/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold 1000 ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_9_10"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 3s
java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar $HOME_PATH/BallSpeed/BallSpeed-O_10_10 9 10 0 1
sleep 3s
./stop-server.sh
sleep 3s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_9_10"

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_9_10
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_10_10_D_29_10
############################

cd $HOME_PATH/BallSpeed_testspace
mkdir O_10_10_D_29_10
cd O_10_10_D_29_10

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_29_10/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_29_10/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_29_10/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold 1000 ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_29_10"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 3s
java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar $HOME_PATH/BallSpeed/BallSpeed-O_10_10 29 10 0 1
sleep 3s
./stop-server.sh
sleep 3s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_29_10"

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_29_10
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_10_10_D_49_10
############################

cd $HOME_PATH/BallSpeed_testspace
mkdir O_10_10_D_49_10
cd O_10_10_D_49_10

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_49_10/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_49_10/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_49_10/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold 1000 ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_49_10"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 3s
java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar $HOME_PATH/BallSpeed/BallSpeed-O_10_10 49 10 0 1
sleep 3s
./stop-server.sh
sleep 3s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_49_10"

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_49_10
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_10_10_D_69_10
############################

cd $HOME_PATH/BallSpeed_testspace
mkdir O_10_10_D_69_10
cd O_10_10_D_69_10

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_69_10/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_69_10/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_69_10/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold 1000 ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_69_10"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 3s
java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar $HOME_PATH/BallSpeed/BallSpeed-O_10_10 69 10 0 1
sleep 3s
./stop-server.sh
sleep 3s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_69_10"

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_69_10
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_10_10_D_89_10
############################

cd $HOME_PATH/BallSpeed_testspace
mkdir O_10_10_D_89_10
cd O_10_10_D_89_10

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_89_10/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_89_10/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_89_10/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold 1000 ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_89_10"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 3s
java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar $HOME_PATH/BallSpeed/BallSpeed-O_10_10 89 10 0 1
sleep 3s
./stop-server.sh
sleep 3s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_89_10"

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_89_10
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

# [EXP5-2]
# ---- O_10_10_D_49_30
# ---- O_10_10_D_49_50
# ---- O_10_10_D_49_70
# ---- O_10_10_D_49_90

############################
# O_10_10_D_49_30
############################
cd $HOME_PATH/BallSpeed_testspace
mkdir O_10_10_D_49_30
cd O_10_10_D_49_30

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_49_30/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_49_30/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_49_30/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold 1000 ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_49_30"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 3s
java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar $HOME_PATH/BallSpeed/BallSpeed-O_10_10 49 30 0 1
sleep 3s
./stop-server.sh
sleep 3s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_49_30"

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_49_30
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_10_10_D_49_50
############################
cd $HOME_PATH/BallSpeed_testspace
mkdir O_10_10_D_49_50
cd O_10_10_D_49_50

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_49_50/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_49_50/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_49_50/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold 1000 ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_49_50"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 3s
java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar $HOME_PATH/BallSpeed/BallSpeed-O_10_10 49 50 0 1
sleep 3s
./stop-server.sh
sleep 3s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_49_50"

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_49_50
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_10_10_D_49_70
############################
cd $HOME_PATH/BallSpeed_testspace
mkdir O_10_10_D_49_70
cd O_10_10_D_49_70

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_49_70/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_49_70/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_49_70/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold 1000 ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_49_70"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 3s
java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar $HOME_PATH/BallSpeed/BallSpeed-O_10_10 49 70 0 1
sleep 3s
./stop-server.sh
sleep 3s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_49_70"

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_49_70
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

############################
# O_10_10_D_49_90
############################
cd $HOME_PATH/BallSpeed_testspace
mkdir O_10_10_D_49_90
cd O_10_10_D_49_90

############################
# prepare iotdb-engine-enableCPVtrue.properties and iotdb-engine-enableCPVfalse.properties
############################
./../../tool.sh enable_CPV true ../../iotdb-engine-example.properties
./../../tool.sh system_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_49_90/system ../../iotdb-engine-example.properties
./../../tool.sh data_dirs $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_49_90/data ../../iotdb-engine-example.properties
./../../tool.sh wal_dir $HOME_PATH/dataSpace/BallSpeed_O_10_10_D_49_90/wal ../../iotdb-engine-example.properties
./../../tool.sh timestamp_precision ns ../../iotdb-engine-example.properties

./../../tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh avg_series_point_number_threshold 1000 ../../iotdb-engine-example.properties
./../../tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
./../../tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
./../../tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
./../../tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
./../../tool.sh rpc_port 6667 ../../iotdb-engine-example.properties

cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties

./../../tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

############################
# run write_data.sh
# java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar filePath deleteFreq deleteLen timeIdx valueIdx
############################
echo "Writing O_10_10_D_49_90"

cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh &
sleep 3s
java -jar $HOME_PATH/BallSpeed_testspace/WriteBallSpeed-0.12.4.jar $HOME_PATH/BallSpeed/BallSpeed-O_10_10 49 90 0 1
sleep 3s
./stop-server.sh
sleep 3s
echo 3 | sudo tee /proc/sys/vm/drop_caches


############################
# run change_interval_experiments.sh for each approach
# ./../../../query_experiment.sh tqe w approach
############################
echo "Querying O_10_10_D_49_90"

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_49_90
mkdir fix
cd fix

echo "moc"
mkdir moc
cd moc
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 2 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

echo "mac"
cd ..
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 1 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

echo "cpv"
cd ..
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
./../../../query_experiment.sh 617426057627 100 3 >> result_3.txt
java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

cd ..
cp $HOME_PATH/SumResultUnify.* .
java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv

#########################
# export results
#########################
# [EXP1]
# w: 1,2,5,10,20,50,100,200,500,1000,2000,4000,8000
# query range: totalRange
# overlap percentage: 10%
# delete percentage: 0%
# delete time range: 0
cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_0_0
cd vary_w
cat result.csv >$HOME_PATH/BallSpeed_testspace/exp1.csv

# [EXP2]
# w: 100
# query range: k*w*totalRange/(pointNum/chunkSize).
# - target estimated chunks per interval = k
# - range = k*w*totalRange/(pointNum/chunkSize)
# - kMax=(pointNum/chunkSize)/w, that is, range=totalRange.
# - E.g. k=0.2,0.5,1,2.5,5,12
# overlap percentage: 10%
# delete percentage: 0%
# delete time range: 0
cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_0_0
cd vary_tqe
cat result.csv >$HOME_PATH/BallSpeed_testspace/exp2.csv

# [EXP3]
# w: 100
# query range: totalRange
# overlap percentage: 0%, 10%, 30%, 50%, 70%, 90%
# delete percentage: 0%
# delete time range: 0
cd $HOME_PATH/BallSpeed_testspace/O_0_0_D_0_0
cd fix
cat result.csv >>$HOME_PATH/BallSpeed_testspace/exp3.csv #带表头

# 把exp1.csv里的w=100那一行复制到exp3.csv里作为overlap percentage 10%的结果
# ATTENTION: 这里日后改成自动判断取出那一行参数是100的，而不是写死的行数
sed -n '8,8p' $HOME_PATH/BallSpeed_testspace/exp1.csv >> $HOME_PATH/BallSpeed_testspace/exp3.csv

cd $HOME_PATH/BallSpeed_testspace/O_30_10_D_0_0
cd fix
# cat result.csv >>$HOME_PATH/BallSpeed_testspace/exp3.csv
sed -n '2,2p' result.csv >>$HOME_PATH/BallSpeed_testspace/exp3.csv

cd $HOME_PATH/BallSpeed_testspace/O_50_10_D_0_0
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/BallSpeed_testspace/exp3.csv

cd $HOME_PATH/BallSpeed_testspace/O_70_10_D_0_0
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/BallSpeed_testspace/exp3.csv

cd $HOME_PATH/BallSpeed_testspace/O_90_10_D_0_0
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/BallSpeed_testspace/exp3.csv

# [EXP4]
# w: 100
# query range: totalRange
# overlap percentage: 10%
# delete percentage: 0%, 9%, 29%, 49%, 69%, 89%
# delete time range: 10% of chunk time interval, that is 0.1*totalRange/(pointNum/chunkSize)
cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_9_10
cd fix
cat result.csv >>$HOME_PATH/BallSpeed_testspace/exp4.csv #带表头

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_29_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/BallSpeed_testspace/exp4.csv

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_49_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/BallSpeed_testspace/exp4.csv

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_69_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/BallSpeed_testspace/exp4.csv

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_89_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/BallSpeed_testspace/exp4.csv

# [EXP5]
# w: 100
# query range: totalRange
# overlap percentage: 10%
# delete percentage: 49%
# delete time range: 10%, 30%, 50%, 70%, 90% of chunk time interval, that is x%*totalRange/(pointNum/chunkSize)
cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_49_10
cd fix
cat result.csv >>$HOME_PATH/BallSpeed_testspace/exp5.csv #带表头

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_49_30
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/BallSpeed_testspace/exp5.csv

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_49_50
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/BallSpeed_testspace/exp5.csv

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_49_70
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/BallSpeed_testspace/exp5.csv

cd $HOME_PATH/BallSpeed_testspace/O_10_10_D_49_90
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/BallSpeed_testspace/exp5.csv
