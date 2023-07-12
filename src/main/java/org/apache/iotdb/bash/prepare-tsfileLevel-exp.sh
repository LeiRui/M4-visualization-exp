M4_VISUALIZATION_EXP=/root/ubuntu/M4-visualization-exp
HOME_PATH=/root/ubuntu/tsfileLevelExp

VALUE_ENCODING=PLAIN # RLE for int/long, GORILLA for float/double
TIME_ENCODING=PLAIN # TS_2DIFF
COMPRESSOR=UNCOMPRESSED
use_Mad=true

mkdir -p $HOME_PATH

find $M4_VISUALIZATION_EXP -type f -iname "*.sh" -exec chmod +x {} \;

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
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/tools/tool.sh .
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/jars/WriteDataVaryChunkSize-jar-with-dependencies.jar .
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/jars/QueryData-*.jar .
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/tools/query_experiment.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH $HOME_PATH/query_experiment.sh
scp -r $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/iotdb-server-0.12.4 .
scp -r $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/iotdb-cli-0.12.4 .
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/tools/iotdb-engine-example.properties .
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/tools/ProcessResult.java .
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/tools/SumResultUnify.java .
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

#====prepare run bash for each dataset====
cd $HOME_PATH
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/bash/run-tsfileLevel-exp.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH run-tsfileLevel-exp.sh
$HOME_PATH/tool.sh DATASET BallSpeed run-tsfileLevel-exp.sh
$HOME_PATH/tool.sh DEVICE "root.game" run-tsfileLevel-exp.sh
$HOME_PATH/tool.sh MEASUREMENT "s6" run-tsfileLevel-exp.sh
$HOME_PATH/tool.sh DATA_TYPE long run-tsfileLevel-exp.sh
$HOME_PATH/tool.sh TIMESTAMP_PRECISION ns run-tsfileLevel-exp.sh
$HOME_PATH/tool.sh DATA_MIN_TIME 0 run-tsfileLevel-exp.sh
$HOME_PATH/tool.sh DATA_MAX_TIME 4259092178974 run-tsfileLevel-exp.sh
$HOME_PATH/tool.sh TOTAL_POINT_NUMBER 7193200 run-tsfileLevel-exp.sh
$HOME_PATH/tool.sh IOTDB_CHUNK_POINT_SIZE 10000 run-tsfileLevel-exp.sh
$HOME_PATH/tool.sh FIX_W 10 run-tsfileLevel-exp.sh
$HOME_PATH/tool.sh VALUE_ENCODING ${VALUE_ENCODING} run-tsfileLevel-exp.sh # four dataset value types are the same, so can assign the same encodingType
$HOME_PATH/tool.sh TIME_ENCODING ${TIME_ENCODING} run-tsfileLevel-exp.sh
$HOME_PATH/tool.sh COMPRESSOR ${COMPRESSOR} run-tsfileLevel-exp.sh
$HOME_PATH/tool.sh use_Mad ${use_Mad} run-tsfileLevel-exp.sh
cp run-tsfileLevel-exp.sh run-BallSpeed.sh

#====prepare directory for each dataset====
datasetArray=("BallSpeed");
for value in ${datasetArray[@]};
do
echo "prepare $value directory, this is for data";
cd $HOME_PATH
mkdir $value
cd $value
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/datasets/$value.csv .
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/tools/OverlapGenerator2.java .
# remove the line starting with "package" in the java file
sed '/^package/d' OverlapGenerator2.java > OverlapGeneratorTmp.java
rm OverlapGenerator2.java
mv OverlapGeneratorTmp.java OverlapGenerator2.java
# then javac it
javac OverlapGenerator2.java

echo "prepare ${value}_testspace directory, this is for write and query";
cd $HOME_PATH
mkdir ${value}_testspace

done;

find $HOME_PATH -type f -iname "*.sh" -exec chmod +x {} \;

echo "finish"
