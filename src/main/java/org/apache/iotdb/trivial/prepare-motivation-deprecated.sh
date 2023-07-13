M4_VISUALIZATION_EXP=/root/ubuntu/M4-visualization-exp
HOME_PATH=/root/ubuntu/motivationExp

VALUE_ENCODING=PLAIN # RLE for int/long, GORILLA for float/double
TIME_ENCODING=PLAIN # TS_2DIFF
COMPRESSOR=UNCOMPRESSED

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
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/jars/WriteData-*.jar .
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
#cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/bash/run-motivation-deprecated.sh .
#$HOME_PATH/tool.sh HOME_PATH $HOME_PATH run-motivation-deprecated.sh
#$HOME_PATH/tool.sh DATASET MF03 run-motivation-deprecated.sh
#$HOME_PATH/tool.sh DEVICE "root.debs2012" run-motivation-deprecated.sh
#$HOME_PATH/tool.sh MEASUREMENT "mf03" run-motivation-deprecated.sh
#$HOME_PATH/tool.sh DATA_TYPE long run-motivation-deprecated.sh
#$HOME_PATH/tool.sh TIMESTAMP_PRECISION ns run-motivation-deprecated.sh
#$HOME_PATH/tool.sh DATA_MIN_TIME 1329929188967032000 run-motivation-deprecated.sh
#$HOME_PATH/tool.sh DATA_MAX_TIME 1331034235275774600 run-motivation-deprecated.sh
#$HOME_PATH/tool.sh TOTAL_POINT_NUMBER 100000000 run-motivation-deprecated.sh
#$HOME_PATH/tool.sh IOTDB_CHUNK_POINT_SIZE 1000 run-motivation-deprecated.sh
#$HOME_PATH/tool.sh VALUE_ENCODING ${VALUE_ENCODING} run-motivation-deprecated.sh # four dataset value types are the same, so can assign the same encodingType
#$HOME_PATH/tool.sh TIME_ENCODING ${TIME_ENCODING} run-motivation-deprecated.sh
#$HOME_PATH/tool.sh COMPRESSOR ${COMPRESSOR} run-motivation-deprecated.sh
#cp run-motivation-deprecated.sh run-MF03.sh

cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/bash/run-motivation-deprecated.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH run-motivation-deprecated.sh
$HOME_PATH/tool.sh DATASET Train run-motivation-deprecated.sh # todo
$HOME_PATH/tool.sh DEVICE "root.group6.d17" run-motivation-deprecated.sh # todo
$HOME_PATH/tool.sh MEASUREMENT "Z765" run-motivation-deprecated.sh # todo
$HOME_PATH/tool.sh DATA_TYPE long run-motivation-deprecated.sh # todo
$HOME_PATH/tool.sh TIMESTAMP_PRECISION ms run-motivation-deprecated.sh # todo
$HOME_PATH/tool.sh DATA_MIN_TIME 1591717867194 run-motivation-deprecated.sh # todo
$HOME_PATH/tool.sh DATA_MAX_TIME 1605706903793 run-motivation-deprecated.sh # todo
$HOME_PATH/tool.sh TOTAL_POINT_NUMBER 127802876 run-motivation-deprecated.sh # todo todo
$HOME_PATH/tool.sh IOTDB_CHUNK_POINT_SIZE 1000 run-motivation-deprecated.sh # todo
$HOME_PATH/tool.sh VALUE_ENCODING ${VALUE_ENCODING} run-motivation-deprecated.sh # four dataset value types are the same, so can assign the same encodingType
$HOME_PATH/tool.sh TIME_ENCODING ${TIME_ENCODING} run-motivation-deprecated.sh
$HOME_PATH/tool.sh COMPRESSOR ${COMPRESSOR} run-motivation-deprecated.sh # todo todo
$HOME_PATH/tool.sh hasHeader true run-motivation-deprecated.sh # todo
cp run-motivation-deprecated.sh run-Train.sh

#====prepare directory for each dataset====
datasetArray=("Train");
for value in ${datasetArray[@]};
do
echo "prepare $value directory, this is for data";
cd $HOME_PATH
mkdir $value
cd $value
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/datasets/$value.csv .

#cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/tools/AppendDatasetByCopy.java .
## remove the line starting with "package" in the java file
#sed '/^package/d' AppendDatasetByCopy.java > AppendDatasetByCopy2.java
#rm AppendDatasetByCopy.java
#mv AppendDatasetByCopy2.java AppendDatasetByCopy.java
## then javac it
#javac AppendDatasetByCopy.java
#java AppendDatasetByCopy $value.csv $value-cp10.csv 10
#rm $value.csv
#mv $value-cp10.csv $value.csv

cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/tools/OverlapGenerator.java .
# remove the line starting with "package" in the java file
sed '/^package/d' OverlapGenerator.java > OverlapGenerator2.java
rm OverlapGenerator.java
mv OverlapGenerator2.java OverlapGenerator.java
# then javac it
javac OverlapGenerator.java

echo "prepare ${value}_testspace directory, this is for write and query";
cd $HOME_PATH
mkdir ${value}_testspace

done;

find $HOME_PATH -type f -iname "*.sh" -exec chmod +x {} \;

echo "finish"
