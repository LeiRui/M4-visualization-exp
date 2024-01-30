BASE_PATH=/root/github

M4_VISUALIZATION_EXP=${BASE_PATH}/lts-exp
HOME_PATH=${BASE_PATH}/efficiencyExp

VALUE_ENCODING=PLAIN # RLE for int/long, GORILLA for float/double
TIME_ENCODING=PLAIN # TS_2DIFF
COMPRESSOR=UNCOMPRESSED
DATA_TYPE=double

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
cp $M4_VISUALIZATION_EXP/jars/WriteDataUCR-*.jar . # check TODO
cp $M4_VISUALIZATION_EXP/jars/QueryDataUCR-*.jar . # check TODO
cp $M4_VISUALIZATION_EXP/tools/query_experiment.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH $HOME_PATH/query_experiment.sh
scp -r $M4_VISUALIZATION_EXP/iotdb-server-0.12.4 .
scp -r $M4_VISUALIZATION_EXP/iotdb-cli-0.12.4 .
cp $M4_VISUALIZATION_EXP/tools/iotdb-engine-example.properties .
cp $M4_VISUALIZATION_EXP/tools/ProcessResult.java .
cp $M4_VISUALIZATION_EXP/tools/SumResultUnify.java .
# remove the line starting with "package" in the java file
sed '/^package/d' ProcessResult.java > ProcessResult2.java
rm ProcessResult.java
mv ProcessResult2.java ProcessResult.java
# then javac it
javac ProcessResult.java
# remove the line starting with "package" in the java file
sed '/^package/d' SumResultUnify.java > SumResultUnify2.java
rm SumResultUnify.java
mv SumResultUnify2.java SumResultUnify.java
# then javac it
javac SumResultUnify.java

#====prepare run bash for query exp====
#cd $HOME_PATH
#cp $M4_VISUALIZATION_EXP/bash/run-efficiency-exp.sh .
#$HOME_PATH/tool.sh HOME_PATH $HOME_PATH run-efficiency-exp.sh
#$HOME_PATH/tool.sh DATASET BallSpeed run-efficiency-exp.sh
#$HOME_PATH/tool.sh DEVICE "root.game" run-efficiency-exp.sh
#$HOME_PATH/tool.sh MEASUREMENT "s6" run-efficiency-exp.sh
#$HOME_PATH/tool.sh DATA_TYPE ${DATA_TYPE} run-efficiency-exp.sh
#$HOME_PATH/tool.sh TIMESTAMP_PRECISION ns run-efficiency-exp.sh
#$HOME_PATH/tool.sh DATA_MIN_TIME 1 run-efficiency-exp.sh # TODO check this incremental t!!!
#$HOME_PATH/tool.sh DATA_MAX_TIME 7193200 run-efficiency-exp.sh  # TODO check this incremental t!!!
#$HOME_PATH/tool.sh TOTAL_POINT_NUMBER 7193200 run-efficiency-exp.sh
#$HOME_PATH/tool.sh IOTDB_CHUNK_POINT_SIZE 1000 run-efficiency-exp.sh
#$HOME_PATH/tool.sh VALUE_ENCODING ${VALUE_ENCODING} run-efficiency-exp.sh
#$HOME_PATH/tool.sh TIME_ENCODING ${TIME_ENCODING} run-efficiency-exp.sh
#$HOME_PATH/tool.sh COMPRESSOR ${COMPRESSOR} run-efficiency-exp.sh
#cp run-efficiency-exp.sh run-BallSpeed-efficiency-exp.sh  # TODO check this

cd $HOME_PATH
cp $M4_VISUALIZATION_EXP/bash/run-efficiency-exp.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH run-efficiency-exp.sh
$HOME_PATH/tool.sh DATASET Wine_TEST run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh DEVICE "root.Wine" run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh MEASUREMENT "test" run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh DATA_TYPE ${DATA_TYPE} run-efficiency-exp.sh
$HOME_PATH/tool.sh TIMESTAMP_PRECISION ms run-efficiency-exp.sh
$HOME_PATH/tool.sh DATA_MIN_TIME 1 run-efficiency-exp.sh # TODO check this incremental t!!!
$HOME_PATH/tool.sh DATA_MAX_TIME 7019000 run-efficiency-exp.sh  # TODO check this incremental t!!!
$HOME_PATH/tool.sh TOTAL_POINT_NUMBER 7019000 run-efficiency-exp.sh
$HOME_PATH/tool.sh IOTDB_CHUNK_POINT_SIZE 1000 run-efficiency-exp.sh
$HOME_PATH/tool.sh VALUE_ENCODING ${VALUE_ENCODING} run-efficiency-exp.sh
$HOME_PATH/tool.sh TIME_ENCODING ${TIME_ENCODING} run-efficiency-exp.sh
$HOME_PATH/tool.sh COMPRESSOR ${COMPRESSOR} run-efficiency-exp.sh
cp run-efficiency-exp.sh run-Wine_TEST-efficiency-exp.sh  # TODO check this

cd $HOME_PATH
cp $M4_VISUALIZATION_EXP/bash/run-efficiency-exp.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH run-efficiency-exp.sh
$HOME_PATH/tool.sh DATASET OliveOil_TEST run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh DEVICE "root.OliveOil" run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh MEASUREMENT "test" run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh DATA_TYPE ${DATA_TYPE} run-efficiency-exp.sh
$HOME_PATH/tool.sh TIMESTAMP_PRECISION ms run-efficiency-exp.sh
$HOME_PATH/tool.sh DATA_MIN_TIME 1 run-efficiency-exp.sh # TODO check this incremental t!!!
$HOME_PATH/tool.sh DATA_MAX_TIME 17099000 run-efficiency-exp.sh  # TODO check this incremental t!!!
$HOME_PATH/tool.sh TOTAL_POINT_NUMBER 17099000 run-efficiency-exp.sh
$HOME_PATH/tool.sh IOTDB_CHUNK_POINT_SIZE 1000 run-efficiency-exp.sh
$HOME_PATH/tool.sh VALUE_ENCODING ${VALUE_ENCODING} run-efficiency-exp.sh
$HOME_PATH/tool.sh TIME_ENCODING ${TIME_ENCODING} run-efficiency-exp.sh
$HOME_PATH/tool.sh COMPRESSOR ${COMPRESSOR} run-efficiency-exp.sh
cp run-efficiency-exp.sh run-OliveOil_TEST-efficiency-exp.sh  # TODO check this

cd $HOME_PATH
cp $M4_VISUALIZATION_EXP/bash/run-efficiency-exp.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH run-efficiency-exp.sh
$HOME_PATH/tool.sh DATASET Mallat_TEST run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh DEVICE "root.Mallat" run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh MEASUREMENT "test" run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh DATA_TYPE ${DATA_TYPE} run-efficiency-exp.sh
$HOME_PATH/tool.sh TIMESTAMP_PRECISION ms run-efficiency-exp.sh
$HOME_PATH/tool.sh DATA_MIN_TIME 1 run-efficiency-exp.sh # TODO check this incremental t!!!
$HOME_PATH/tool.sh DATA_MAX_TIME 30719000 run-efficiency-exp.sh  # TODO check this incremental t!!!
$HOME_PATH/tool.sh TOTAL_POINT_NUMBER 30719000 run-efficiency-exp.sh
$HOME_PATH/tool.sh IOTDB_CHUNK_POINT_SIZE 1000 run-efficiency-exp.sh
$HOME_PATH/tool.sh VALUE_ENCODING ${VALUE_ENCODING} run-efficiency-exp.sh
$HOME_PATH/tool.sh TIME_ENCODING ${TIME_ENCODING} run-efficiency-exp.sh
$HOME_PATH/tool.sh COMPRESSOR ${COMPRESSOR} run-efficiency-exp.sh
cp run-efficiency-exp.sh run-Mallat_TEST-efficiency-exp.sh  # TODO check this

cd $HOME_PATH
cp $M4_VISUALIZATION_EXP/bash/run-efficiency-exp.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH run-efficiency-exp.sh
$HOME_PATH/tool.sh DATASET Lightning7_TEST run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh DEVICE "root.Lightning7" run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh MEASUREMENT "test" run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh DATA_TYPE ${DATA_TYPE} run-efficiency-exp.sh
$HOME_PATH/tool.sh TIMESTAMP_PRECISION ms run-efficiency-exp.sh
$HOME_PATH/tool.sh DATA_MIN_TIME 1 run-efficiency-exp.sh # TODO check this incremental t!!!
$HOME_PATH/tool.sh DATA_MAX_TIME 9569000 run-efficiency-exp.sh  # TODO check this incremental t!!!
$HOME_PATH/tool.sh TOTAL_POINT_NUMBER 9569000 run-efficiency-exp.sh
$HOME_PATH/tool.sh IOTDB_CHUNK_POINT_SIZE 1000 run-efficiency-exp.sh
$HOME_PATH/tool.sh VALUE_ENCODING ${VALUE_ENCODING} run-efficiency-exp.sh
$HOME_PATH/tool.sh TIME_ENCODING ${TIME_ENCODING} run-efficiency-exp.sh
$HOME_PATH/tool.sh COMPRESSOR ${COMPRESSOR} run-efficiency-exp.sh
cp run-efficiency-exp.sh run-Lightning7_TEST-efficiency-exp.sh  # TODO check this

cd $HOME_PATH
cp $M4_VISUALIZATION_EXP/bash/run-efficiency-exp.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH run-efficiency-exp.sh
$HOME_PATH/tool.sh DATASET HouseTwenty_TEST run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh DEVICE "root.HouseTwenty" run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh MEASUREMENT "test" run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh DATA_TYPE ${DATA_TYPE} run-efficiency-exp.sh
$HOME_PATH/tool.sh TIMESTAMP_PRECISION ms run-efficiency-exp.sh
$HOME_PATH/tool.sh DATA_MIN_TIME 1 run-efficiency-exp.sh # TODO check this incremental t!!!
$HOME_PATH/tool.sh DATA_MAX_TIME 59999000 run-efficiency-exp.sh  # TODO check this incremental t!!!
$HOME_PATH/tool.sh TOTAL_POINT_NUMBER 59999000 run-efficiency-exp.sh
$HOME_PATH/tool.sh IOTDB_CHUNK_POINT_SIZE 1000 run-efficiency-exp.sh
$HOME_PATH/tool.sh VALUE_ENCODING ${VALUE_ENCODING} run-efficiency-exp.sh
$HOME_PATH/tool.sh TIME_ENCODING ${TIME_ENCODING} run-efficiency-exp.sh
$HOME_PATH/tool.sh COMPRESSOR ${COMPRESSOR} run-efficiency-exp.sh
cp run-efficiency-exp.sh run-HouseTwenty_TEST-efficiency-exp.sh  # TODO check this

cd $HOME_PATH
cp $M4_VISUALIZATION_EXP/bash/run-efficiency-exp.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH run-efficiency-exp.sh
$HOME_PATH/tool.sh DATASET FreezerRegularTrain_TEST run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh DEVICE "root.FreezerRegularTrain" run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh MEASUREMENT "test" run-efficiency-exp.sh # TODO check this
$HOME_PATH/tool.sh DATA_TYPE ${DATA_TYPE} run-efficiency-exp.sh
$HOME_PATH/tool.sh TIMESTAMP_PRECISION ms run-efficiency-exp.sh
$HOME_PATH/tool.sh DATA_MIN_TIME 1 run-efficiency-exp.sh # TODO check this incremental t!!!
$HOME_PATH/tool.sh DATA_MAX_TIME 9029000 run-efficiency-exp.sh  # TODO check this incremental t!!!
$HOME_PATH/tool.sh TOTAL_POINT_NUMBER 9029000 run-efficiency-exp.sh
$HOME_PATH/tool.sh IOTDB_CHUNK_POINT_SIZE 1000 run-efficiency-exp.sh
$HOME_PATH/tool.sh VALUE_ENCODING ${VALUE_ENCODING} run-efficiency-exp.sh
$HOME_PATH/tool.sh TIME_ENCODING ${TIME_ENCODING} run-efficiency-exp.sh
$HOME_PATH/tool.sh COMPRESSOR ${COMPRESSOR} run-efficiency-exp.sh
cp run-efficiency-exp.sh run-FreezerRegularTrain_TEST-efficiency-exp.sh  # TODO check this

#====prepare directory for each dataset====
datasetArray=("Wine_TEST" "OliveOil_TEST" "Mallat_TEST" "Lightning7_TEST" "HouseTwenty_TEST" "FreezerRegularTrain_TEST");
for value in ${datasetArray[@]};
do
echo "prepare data directory";
cd $HOME_PATH
mkdir $value
cd $value
cp $M4_VISUALIZATION_EXP/datasets/$value.csv .
cp $M4_VISUALIZATION_EXP/tools/Enlarge.py .
python3 Enlarge.py -i $value.csv -o $value-cp.csv -r 1000
rm $value.csv
rm Enlarge.py
mv $value-cp.csv $value.csv

echo "prepare testspace directory";
cd $HOME_PATH
mkdir ${value}_testspace

done;

find $HOME_PATH -type f -iname "*.sh" -exec chmod +x {} \;

echo "finish"
