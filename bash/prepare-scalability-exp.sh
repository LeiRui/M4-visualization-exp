BASE_PATH=/root/github

TRI_VISUALIZATION_EXP=${BASE_PATH}/lts-exp
HOME_PATH=${BASE_PATH}/scalabilityExp

VALUE_ENCODING=PLAIN # RLE for int/long, GORILLA for float/double
TIME_ENCODING=PLAIN # TS_2DIFF
COMPRESSOR=UNCOMPRESSED
DATA_TYPE=double

mkdir -p $HOME_PATH

find $TRI_VISUALIZATION_EXP -type f -iname "*.sh" -exec chmod +x {} \;
find $TRI_VISUALIZATION_EXP -type f -iname "*.sh" -exec sed -i -e 's/\r$//' {} \;

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
cp $TRI_VISUALIZATION_EXP/tools/tool.sh .
cp $TRI_VISUALIZATION_EXP/jars/WriteDataUCR-*.jar . # check TODO
cp $TRI_VISUALIZATION_EXP/jars/QueryDataUCR-*.jar . # check TODO
cp $TRI_VISUALIZATION_EXP/tools/query_experiment.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH $HOME_PATH/query_experiment.sh
scp -r $TRI_VISUALIZATION_EXP/iotdb-server-0.12.4 .
scp -r $TRI_VISUALIZATION_EXP/iotdb-cli-0.12.4 .
cp $TRI_VISUALIZATION_EXP/tools/iotdb-engine-example.properties .
cp $TRI_VISUALIZATION_EXP/tools/ProcessResult.java .
cp $TRI_VISUALIZATION_EXP/tools/SumResultUnify.java .
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

cd $HOME_PATH
cp $TRI_VISUALIZATION_EXP/bash/run-scalability-exp.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH run-scalability-exp.sh
$HOME_PATH/tool.sh DATASET HouseTwenty_TEST run-scalability-exp.sh # TODO check this
$HOME_PATH/tool.sh DEVICE "root.HouseTwenty" run-scalability-exp.sh # TODO check this
$HOME_PATH/tool.sh MEASUREMENT "test" run-scalability-exp.sh # TODO check this
$HOME_PATH/tool.sh DATA_TYPE ${DATA_TYPE} run-scalability-exp.sh
$HOME_PATH/tool.sh TIMESTAMP_PRECISION ms run-scalability-exp.sh
$HOME_PATH/tool.sh DATA_MIN_TIME 1 run-scalability-exp.sh # TODO check this incremental t!!!
$HOME_PATH/tool.sh DATA_MAX_TIME 59999000 run-scalability-exp.sh  # TODO check this incremental t!!!
$HOME_PATH/tool.sh TOTAL_POINT_NUMBER 59999000 run-scalability-exp.sh
$HOME_PATH/tool.sh IOTDB_CHUNK_POINT_SIZE 10000 run-scalability-exp.sh
$HOME_PATH/tool.sh VALUE_ENCODING ${VALUE_ENCODING} run-scalability-exp.sh
$HOME_PATH/tool.sh TIME_ENCODING ${TIME_ENCODING} run-scalability-exp.sh
$HOME_PATH/tool.sh COMPRESSOR ${COMPRESSOR} run-scalability-exp.sh
cp run-scalability-exp.sh run-HouseTwenty_TEST-scalability-exp.sh  # TODO check this

#====prepare directory for each dataset====
datasetArray=("HouseTwenty_TEST");
for value in ${datasetArray[@]};
do
echo "prepare data directory";
cd $HOME_PATH
mkdir $value
cd $value
cp $TRI_VISUALIZATION_EXP/datasets/$value.csv .
cp $TRI_VISUALIZATION_EXP/tools/Enlarge.py .
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
