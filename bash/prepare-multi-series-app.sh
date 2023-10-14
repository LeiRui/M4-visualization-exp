BASE_PATH=/root/ubuntu

M4_VISUALIZATION_EXP=$BASE_PATH/M4-visualization-exp
HOME_PATH=$BASE_PATH/multiSeriesAppExp

VALUE_ENCODING=PLAIN # RLE for int/long, GORILLA for float/double
TIME_ENCODING=PLAIN # TS_2DIFF
COMPRESSOR=UNCOMPRESSED #SNAPPY
overlap_percentage=0
DATASET=MF03
DEVICE="root.debs2012"
MEASUREMENT="mf03"
DATA_TYPE=long
TIMESTAMP_PRECISION=ns
DATA_MIN_TIME=1329929188967032000
DATA_MAX_TIME=1330029647713284600
TOTAL_POINT_NUMBER=10000000
IOTDB_CHUNK_POINT_SIZE=10000

mkdir -p $HOME_PATH

find $M4_VISUALIZATION_EXP -type f -iname "*.sh" -exec chmod +x {} \;
find $M4_VISUALIZATION_EXP -type f -iname "*.sh" -exec sed -i -e 's/\r$//' {} \;

# check bc installed
REQUIRED_PKG="bc"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
echo Checking for $REQUIRED_PKG: $PKG_OK
if [ "" = "$PKG_OK" ]; then
  echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
  sudo apt-get --yes install $REQUIRED_PKG
fi

#====prepare general environment====
cd $HOME_PATH
cp $M4_VISUALIZATION_EXP/tools/tool.sh .
cp $M4_VISUALIZATION_EXP/jars/WriteData-*.jar .
cp $M4_VISUALIZATION_EXP/jars/QueryDataMultiSeries*.jar .
cp $M4_VISUALIZATION_EXP/tools/query_experiment_multiseries_app.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH $HOME_PATH/query_experiment_multiseries_app.sh
scp -r $M4_VISUALIZATION_EXP/iotdb-server-0.12.4 .
scp -r $M4_VISUALIZATION_EXP/iotdb-cli-0.12.4 .
cp $M4_VISUALIZATION_EXP/tools/iotdb-engine-example.properties .
cp $M4_VISUALIZATION_EXP/tools/ProcessResultMultiSeries.java .
cp $M4_VISUALIZATION_EXP/tools/SumResultUnify.java .
# remove the line starting with "package" in the java file
sed '/^package/d' ProcessResultMultiSeries.java > ProcessResultMultiSeries2.java
rm ProcessResultMultiSeries.java
mv ProcessResultMultiSeries2.java ProcessResultMultiSeries.java
# then javac it
javac ProcessResultMultiSeries.java
# remove the line starting with "package" in the java file
sed '/^package/d' SumResultUnify.java > SumResultUnify2.java
rm SumResultUnify.java
mv SumResultUnify2.java SumResultUnify.java
# then javac it
javac SumResultUnify.java

#====prepare write bash====
cd $HOME_PATH
cp $M4_VISUALIZATION_EXP/bash/run-motivation-app.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH run-motivation-app.sh
$HOME_PATH/tool.sh DATASET ${DATASET} run-motivation-app.sh
$HOME_PATH/tool.sh DEVICE ${DEVICE} run-motivation-app.sh
$HOME_PATH/tool.sh MEASUREMENT ${MEASUREMENT} run-motivation-app.sh
$HOME_PATH/tool.sh DATA_TYPE ${DATA_TYPE} run-motivation-app.sh
$HOME_PATH/tool.sh TIMESTAMP_PRECISION ${TIMESTAMP_PRECISION} run-motivation-app.sh
$HOME_PATH/tool.sh DATA_MIN_TIME ${DATA_MIN_TIME} run-motivation-app.sh
$HOME_PATH/tool.sh DATA_MAX_TIME ${DATA_MAX_TIME} run-motivation-app.sh
$HOME_PATH/tool.sh TOTAL_POINT_NUMBER ${TOTAL_POINT_NUMBER} run-motivation-app.sh
$HOME_PATH/tool.sh IOTDB_CHUNK_POINT_SIZE ${IOTDB_CHUNK_POINT_SIZE} run-motivation-app.sh
$HOME_PATH/tool.sh VALUE_ENCODING ${VALUE_ENCODING} run-motivation-app.sh # four dataset value types are the same, so can assign the same encodingType
$HOME_PATH/tool.sh TIME_ENCODING ${TIME_ENCODING} run-motivation-app.sh
$HOME_PATH/tool.sh COMPRESSOR ${COMPRESSOR} run-motivation-app.sh
$HOME_PATH/tool.sh overlap_percentage ${overlap_percentage} run-motivation-app.sh

# prepare IoTDB config properties
$HOME_PATH/tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_${workspace}/system iotdb-engine-example.properties
$HOME_PATH/tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_${workspace}/data iotdb-engine-example.properties
$HOME_PATH/tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_${workspace}/wal iotdb-engine-example.properties
$HOME_PATH/tool.sh timestamp_precision ${TIMESTAMP_PRECISION} iotdb-engine-example.properties
$HOME_PATH/tool.sh unseq_tsfile_size 1073741824 iotdb-engine-example.properties
$HOME_PATH/tool.sh seq_tsfile_size 1073741824 iotdb-engine-example.properties
$HOME_PATH/tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} iotdb-engine-example.properties
$HOME_PATH/tool.sh compaction_strategy NO_COMPACTION iotdb-engine-example.properties
$HOME_PATH/tool.sh enable_unseq_compaction false iotdb-engine-example.properties
$HOME_PATH/tool.sh group_size_in_byte 1073741824 iotdb-engine-example.properties
$HOME_PATH/tool.sh page_size_in_byte 1073741824 iotdb-engine-example.properties
$HOME_PATH/tool.sh rpc_address 0.0.0.0 iotdb-engine-example.properties
$HOME_PATH/tool.sh rpc_port 6667 iotdb-engine-example.properties
$HOME_PATH/tool.sh time_encoder ${TIME_ENCODING} iotdb-engine-example.properties
$HOME_PATH/tool.sh compressor ${COMPRESSOR} iotdb-engine-example.properties
# properties for cpv
$HOME_PATH/tool.sh enable_CPV true iotdb-engine-example.properties
cp iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties
# properties for moc
$HOME_PATH/tool.sh enable_CPV false iotdb-engine-example.properties
cp iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

echo "prepare out-of-order source data" >> run-write.sh
echo "cd $HOME_PATH/${DATASET}" >> run-write.sh
echo "cp ${DATASET}.csv ${DATASET}-O_0" >> run-write.sh
echo "java OverlapGenerator ${IOTDB_CHUNK_POINT_SIZE} ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_${overlap_percentage} 0 1 ${overlap_percentage} 10" >> run-write.sh
echo "cp $HOME_PATH/iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties" >> run-write.sh
echo "cd $HOME_PATH/iotdb-server-0.12.4/sbin" >> run-write.sh
echo "./start-server.sh /dev/null 2>&1 &" >> run-write.sh
echo "sleep 8s" >> run-write.sh
for i in {1..50}
do
$HOME_PATH/tool.sh MEASUREMENT "mf03${i}" run-motivation-app.sh
cp run-motivation-app.sh run-write-$i.sh
echo "./run-write-$i.sh &" >> run-write.sh
done;
rm run-motivation-app.sh
find $HOME_PATH -type f -iname "*.sh" -exec chmod +x {} \;

# stop iotdb manually

#====prepare query bash====
cd $HOME_PATH
cp $M4_VISUALIZATION_EXP/bash/run-multi-series-app.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH run-multi-series-app.sh
$HOME_PATH/tool.sh DATASET ${DATASET} run-multi-series-app.sh
$HOME_PATH/tool.sh DEVICE ${DEVICE} run-multi-series-app.sh
$HOME_PATH/tool.sh MEASUREMENT ${MEASUREMENT} run-multi-series-app.sh
$HOME_PATH/tool.sh DATA_TYPE ${DATA_TYPE} run-multi-series-app.sh
$HOME_PATH/tool.sh TIMESTAMP_PRECISION ${TIMESTAMP_PRECISION} run-multi-series-app.sh
$HOME_PATH/tool.sh DATA_MIN_TIME ${DATA_MIN_TIME} run-multi-series-app.sh
$HOME_PATH/tool.sh DATA_MAX_TIME ${DATA_MAX_TIME} run-multi-series-app.sh
$HOME_PATH/tool.sh TOTAL_POINT_NUMBER ${TOTAL_POINT_NUMBER} run-multi-series-app.sh
$HOME_PATH/tool.sh IOTDB_CHUNK_POINT_SIZE ${IOTDB_CHUNK_POINT_SIZE} run-multi-series-app.sh
$HOME_PATH/tool.sh VALUE_ENCODING ${VALUE_ENCODING} run-multi-series-app.sh # four dataset value types are the same, so can assign the same encodingType
$HOME_PATH/tool.sh TIME_ENCODING ${TIME_ENCODING} run-multi-series-app.sh
$HOME_PATH/tool.sh COMPRESSOR ${COMPRESSOR} run-multi-series-app.sh
$HOME_PATH/tool.sh overlap_percentage ${overlap_percentage} run-multi-series-app.sh
mv run-multi-series-app.sh run-query.sh

#====prepare directory for each dataset====
datasetArray=("MF03");
for value in ${datasetArray[@]};
do
echo "prepare data directory";
cd $HOME_PATH
mkdir $value
cd $value
cp $M4_VISUALIZATION_EXP/datasets/$value.csv .
cp $M4_VISUALIZATION_EXP/tools/OverlapGenerator.java .
# remove the line starting with "package" in the java file
sed '/^package/d' OverlapGenerator.java > OverlapGenerator2.java
rm OverlapGenerator.java
mv OverlapGenerator2.java OverlapGenerator.java
# then javac it
javac OverlapGenerator.java

echo "prepare testspace directory";
cd $HOME_PATH
mkdir ${value}_testspace

done;

find $HOME_PATH -type f -iname "*.sh" -exec chmod +x {} \;

echo "finish"
