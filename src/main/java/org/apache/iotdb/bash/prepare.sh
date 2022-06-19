M4_VISUALIZATION_EXP=/data/rl/M4-visualization-exp
HOME_PATH=/data/rl/v4

mkdir -p $HOME_PATH

find $M4_VISUALIZATION_EXP -type f -iname "*.sh" -exec chmod +x {} \;

#====prepare general environment====
cd $HOME_PATH
scp -r $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/iotdb-server-0.12.4 .
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/tools/iotdb-engine-example.properties .
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/tools/tool.sh .
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


#====prepare directory for each dataset====
datasetArray=("BallSpeed" "KOB" "MF03" "RcvTime");
for value in ${datasetArray[@]};
do
echo "prepare $value directory, this is for data";
cd $HOME_PATH
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/bash/run-${value}-exp.sh .
# update paths in the bash
./tool.sh HOME_PATH $HOME_PATH run-${value}-exp.sh

cd $HOME_PATH
mkdir $value
cd $value
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/datasets/$value.csv .
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
cd ${value}_testspace
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/jars/Write${value}-*.jar .
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/jars/Query${value}-*.jar .
cp $M4_VISUALIZATION_EXP/src/main/java/org/apache/iotdb/tools/query_experiment.sh .
# update paths in the bash
./../tool.sh HOME_PATH $HOME_PATH query_experiment.sh
./../tool.sh JAR_RELATIVE_PATH ${value}_testspace/Query${value}-*.jar query_experiment.sh

done;

find $HOME_PATH -type f -iname "*.sh" -exec chmod +x {} \;

