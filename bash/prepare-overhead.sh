BASE_HOME=/root/ubuntu

M4_VISUALIZATION_EXP=${BASE_HOME}/M4-visualization-exp
HOME_PATH=${BASE_HOME}/overheadExp

VALUE_ENCODING=PLAIN # RLE for int/long, GORILLA for float/double
TIME_ENCODING=PLAIN # TS_2DIFF
COMPRESSOR=UNCOMPRESSED

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
cp $M4_VISUALIZATION_EXP/jars/WriteUpdateData-*.jar .
cp $M4_VISUALIZATION_EXP/jars/QueryData-*.jar .
cp $M4_VISUALIZATION_EXP/tools/query_experiment.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH $HOME_PATH/query_experiment.sh
scp -r $M4_VISUALIZATION_EXP/iotdb-server-0.12.4 .
scp -r $M4_VISUALIZATION_EXP/iotdb-cli-0.12.4 .
cp $M4_VISUALIZATION_EXP/tools/iotdb-engine-example.properties .
cp $M4_VISUALIZATION_EXP/tools/ProcessResult.java .
cp $M4_VISUALIZATION_EXP/tools/SumResultUnify.java .
cp $M4_VISUALIZATION_EXP/tools/SumResultUnifyMultiSeries.java .
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
# remove the line starting with "package" in the java file
sed '/^package/d' SumResultUnifyMultiSeries.java > SumResultUnifyMultiSeries2.java
rm SumResultUnifyMultiSeries.java
mv SumResultUnifyMultiSeries2.java SumResultUnifyMultiSeries.java
# then javac it
javac SumResultUnifyMultiSeries.java

#====prepare run bash for ballspeed====
cd $HOME_PATH
cp $M4_VISUALIZATION_EXP/bash/run-overhead-exp.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH run-overhead-exp.sh
$HOME_PATH/tool.sh DATASET BallSpeed run-overhead-exp.sh
$HOME_PATH/tool.sh DEVICE "root.game" run-overhead-exp.sh
$HOME_PATH/tool.sh MEASUREMENT "s6" run-overhead-exp.sh
$HOME_PATH/tool.sh DATA_TYPE long run-overhead-exp.sh
$HOME_PATH/tool.sh TIMESTAMP_PRECISION ns run-overhead-exp.sh
$HOME_PATH/tool.sh DATA_MIN_TIME 0 run-overhead-exp.sh
$HOME_PATH/tool.sh DATA_MAX_TIME 4259092178974 run-overhead-exp.sh
$HOME_PATH/tool.sh TOTAL_POINT_NUMBER 7193200 run-overhead-exp.sh
$HOME_PATH/tool.sh IOTDB_CHUNK_POINT_SIZE 1000 run-overhead-exp.sh
$HOME_PATH/tool.sh VALUE_ENCODING ${VALUE_ENCODING} run-overhead-exp.sh # four dataset value types are the same, so can assign the same encodingType
$HOME_PATH/tool.sh TIME_ENCODING ${TIME_ENCODING} run-overhead-exp.sh
$HOME_PATH/tool.sh COMPRESSOR ${COMPRESSOR} run-overhead-exp.sh
$HOME_PATH/tool.sh hasHeader false run-overhead-exp.sh
cp run-overhead-exp.sh run-BallSpeed-overhead.sh

#====prepare run bash for mf03====
cd $HOME_PATH
cp $M4_VISUALIZATION_EXP/bash/run-overhead-exp.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH run-overhead-exp.sh
$HOME_PATH/tool.sh DATASET MF03 run-overhead-exp.sh
$HOME_PATH/tool.sh DEVICE "root.debs2012" run-overhead-exp.sh
$HOME_PATH/tool.sh MEASUREMENT "mf03" run-overhead-exp.sh
$HOME_PATH/tool.sh DATA_TYPE long run-overhead-exp.sh
$HOME_PATH/tool.sh TIMESTAMP_PRECISION ns run-overhead-exp.sh
$HOME_PATH/tool.sh DATA_MIN_TIME 1329929188967032000 run-overhead-exp.sh
$HOME_PATH/tool.sh DATA_MAX_TIME 1330029647713284600 run-overhead-exp.sh
$HOME_PATH/tool.sh TOTAL_POINT_NUMBER 10000000 run-overhead-exp.sh
$HOME_PATH/tool.sh IOTDB_CHUNK_POINT_SIZE 1000 run-overhead-exp.sh
$HOME_PATH/tool.sh VALUE_ENCODING ${VALUE_ENCODING} run-overhead-exp.sh # four dataset value types are the same, so can assign the same encodingType
$HOME_PATH/tool.sh TIME_ENCODING ${TIME_ENCODING} run-overhead-exp.sh
$HOME_PATH/tool.sh COMPRESSOR ${COMPRESSOR} run-overhead-exp.sh
$HOME_PATH/tool.sh hasHeader false run-overhead-exp.sh
cp run-overhead-exp.sh run-MF03-overhead.sh

#====prepare run bash for train====
cd $HOME_PATH
cp $M4_VISUALIZATION_EXP/bash/run-overhead-exp.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH run-overhead-exp.sh
$HOME_PATH/tool.sh DATASET Train run-overhead-exp.sh #
$HOME_PATH/tool.sh DEVICE "root.group6.d17" run-overhead-exp.sh #
$HOME_PATH/tool.sh MEASUREMENT "Z765" run-overhead-exp.sh #
$HOME_PATH/tool.sh DATA_TYPE long run-overhead-exp.sh #
$HOME_PATH/tool.sh TIMESTAMP_PRECISION ms run-overhead-exp.sh #
$HOME_PATH/tool.sh DATA_MIN_TIME 1591717867194 run-overhead-exp.sh #
$HOME_PATH/tool.sh DATA_MAX_TIME 1605706903793 run-overhead-exp.sh #
$HOME_PATH/tool.sh TOTAL_POINT_NUMBER 127802876 run-overhead-exp.sh #
$HOME_PATH/tool.sh IOTDB_CHUNK_POINT_SIZE 10000 run-overhead-exp.sh #
$HOME_PATH/tool.sh VALUE_ENCODING ${VALUE_ENCODING} run-overhead-exp.sh # four dataset value types are the same, so can assign the same encodingType
$HOME_PATH/tool.sh TIME_ENCODING ${TIME_ENCODING} run-overhead-exp.sh
$HOME_PATH/tool.sh COMPRESSOR ${COMPRESSOR} run-overhead-exp.sh #
$HOME_PATH/tool.sh hasHeader true run-overhead-exp.sh #
cp run-overhead-exp.sh run-Train-overhead.sh

#====prepare run bash for steel====
cd $HOME_PATH
cp $M4_VISUALIZATION_EXP/bash/run-overhead-exp.sh .
$HOME_PATH/tool.sh HOME_PATH $HOME_PATH run-overhead-exp.sh
$HOME_PATH/tool.sh DATASET Steel run-overhead-exp.sh
$HOME_PATH/tool.sh DEVICE "root.group2.d7" run-overhead-exp.sh
$HOME_PATH/tool.sh MEASUREMENT "c60" run-overhead-exp.sh
$HOME_PATH/tool.sh DATA_TYPE double run-overhead-exp.sh
$HOME_PATH/tool.sh TIMESTAMP_PRECISION ms run-overhead-exp.sh
$HOME_PATH/tool.sh DATA_MIN_TIME 1664062557838 run-overhead-exp.sh
$HOME_PATH/tool.sh DATA_MAX_TIME 1683566109697 run-overhead-exp.sh
$HOME_PATH/tool.sh TOTAL_POINT_NUMBER 314572100 run-overhead-exp.sh
$HOME_PATH/tool.sh IOTDB_CHUNK_POINT_SIZE 10000 run-overhead-exp.sh
$HOME_PATH/tool.sh VALUE_ENCODING ${VALUE_ENCODING} run-overhead-exp.sh # four dataset value types are the same, so can assign the same encodingType
$HOME_PATH/tool.sh TIME_ENCODING ${TIME_ENCODING} run-overhead-exp.sh
$HOME_PATH/tool.sh COMPRESSOR ${COMPRESSOR} run-overhead-exp.sh
$HOME_PATH/tool.sh hasHeader true run-overhead-exp.sh
cp run-overhead-exp.sh run-Steel-overhead.sh

#====prepare directory for each dataset====
#datasetArray=("Train" "Steel");
#datasetArray=("Steel");
datasetArray=("BallSpeed" "MF03" "Train" "Steel");
for value in ${datasetArray[@]};
do
echo "prepare $value directory, this is for data";
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

cp $M4_VISUALIZATION_EXP/tools/AppendTool.java .
# remove the line starting with "package" in the java file
sed '/^package/d' AppendTool.java > AppendTool2.java
rm AppendTool.java
mv AppendTool2.java AppendTool.java
# then javac it
javac AppendTool.java

#cp $M4_VISUALIZATION_EXP/tools/OverlapGenerator2.java .
## remove the line starting with "package" in the java file
#sed '/^package/d' OverlapGenerator2.java > OverlapGeneratorTmp.java
#rm OverlapGenerator2.java
#mv OverlapGeneratorTmp.java OverlapGenerator2.java
## then javac it
#javac OverlapGenerator2.java

echo "prepare ${value}_testspace directory, this is for write and query";
cd $HOME_PATH
mkdir ${value}_testspace

done;

find $HOME_PATH -type f -iname "*.sh" -exec chmod +x {} \;

echo "finish"
