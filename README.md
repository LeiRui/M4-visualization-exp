# Experiment Guidance

## On BallSpeed Dataset
Before running `run-BallSpeed-exp.sh`, update the HOME_PATH in it and prepare the workspace as follows.
```
$HOME_PATH/BallSpeed
---- BallSpeed.csv
---- OverlapGenerator.class
---- OverlapGenerator.java (before javac, remove package header in the source code)
$HOME_PATH/iotdb-server-0.12.4 (`chmod +x *` on the bash files in the sbin directory)
$HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh
$HOME_PATH/ProcessResult.class
$HOME_PATH/ProcessResult.java (before javac, remove package header in the source code)
$HOME_PATH/SumResultUnify.class
$HOME_PATH/SumResultUnify.java (before javac, remove package header in the source code)
$HOME_PATH/BallSpeed_testspace
---- WriteBallSpeed-0.12.4.jar
---- QueryBallSpeed-0.12.4.jar
---- query_experiment.sh [Remember to update the HOME_PATH in it]
```

Then you can run `run-BallSpeed-exp.sh` to perform the experiments.

The experimental results are in:
```
FOR EXP1: BallSpeed_testspace/O_10_10_D_0_0/vary_w/result.csv
FOR EPX2: BallSpeed_testspace/O_10_10_D_0_0/vary_tqe/result.csv
FOR EXP3: BallSpeed_testspace/exp3.csv
FOR EXP4: BallSpeed_testspace/exp4.csv
FOR EXP5: BallSpeed_testspace/exp5.csv
```

## On MF03 Dataset
Before running `run-MF03-exp.sh`, update the HOME_PATH in it and prepare the workspace as follows.
```
$HOME_PATH/MF03
---- MF03.csv
---- OverlapGenerator.class
---- OverlapGenerator.java (before javac, remove package header in the source code)
$HOME_PATH/iotdb-server-0.12.4 (`chmod +x *` on the bash files in the sbin directory)
$HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh
$HOME_PATH/ProcessResult.class
$HOME_PATH/ProcessResult.java (before javac, remove package header in the source code)
$HOME_PATH/SumResultUnify.class
$HOME_PATH/SumResultUnify.java (before javac, remove package header in the source code)
$HOME_PATH/MF03_testspace
---- WriteMF03-0.12.4.jar
---- QueryMF03-0.12.4.jar
---- query_experiment.sh [Remember to update the HOME_PATH in it]
```

Then you can run `run-MF03-exp.sh` to perform the experiments.

The experimental results are in:
```
FOR EXP1: MF03_testspace/O_10_10_D_0_0/vary_w/result.csv
FOR EPX2: MF03_testspace/O_10_10_D_0_0/vary_tqe/result.csv
FOR EXP3: MF03_testspace/exp3.csv
FOR EXP4: MF03_testspace/exp4.csv
FOR EXP5: MF03_testspace/exp5.csv
```

## On KOB Dataset
Before running `run-KOB-exp.sh`, update the HOME_PATH in it and prepare the workspace as follows.
```
$HOME_PATH/KOB
---- KOB.csv
---- OverlapGenerator.class
---- OverlapGenerator.java (before javac, remove package header in the source code)
$HOME_PATH/iotdb-server-0.12.4 (`chmod +x *` on the bash files in the sbin directory)
$HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh
$HOME_PATH/ProcessResult.class
$HOME_PATH/ProcessResult.java (before javac, remove package header in the source code)
$HOME_PATH/SumResultUnify.class
$HOME_PATH/SumResultUnify.java (before javac, remove package header in the source code)
$HOME_PATH/KOB_testspace
---- WriteKOB-0.12.4.jar
---- QueryKOB-0.12.4.jar
---- query_experiment.sh [Remember to update the HOME_PATH in it]
```

Then you can run `run-KOB-exp.sh` to perform the experiments.

The experimental results are in:
```
FOR EXP1: KOB_testspace/O_10_10_D_0_0/vary_w/result.csv
FOR EPX2: KOB_testspace/O_10_10_D_0_0/vary_tqe/result.csv
FOR EXP3: KOB_testspace/exp3.csv
FOR EXP4: KOB_testspace/exp4.csv
FOR EXP5: KOB_testspace/exp5.csv
```

## On RcvTime Dataset
Before running `run-RcvTime-exp.sh`, update the HOME_PATH in it and prepare the workspace as follows.
```
$HOME_PATH/RcvTime
---- RcvTime.csv
---- OverlapGenerator.class
---- OverlapGenerator.java (before javac, remove package header in the source code)
$HOME_PATH/iotdb-server-0.12.4 (`chmod +x *` on the bash files in the sbin directory)
$HOME_PATH/iotdb-engine-example.properties
$HOME_PATH/tool.sh
$HOME_PATH/ProcessResult.class
$HOME_PATH/ProcessResult.java (before javac, remove package header in the source code)
$HOME_PATH/SumResultUnify.class
$HOME_PATH/SumResultUnify.java (before javac, remove package header in the source code)
$HOME_PATH/RcvTime_testspace
---- WriteRcvTime-0.12.4.jar
---- QueryRcvTime-0.12.4.jar
---- query_experiment.sh [Remember to update the HOME_PATH in it]
```

Then you can run `run-RcvTime-exp.sh` to perform the experiments.

The experimental results are in:
```
FOR EXP1: RcvTime_testspace/O_10_10_D_0_0/vary_w/result.csv
FOR EPX2: RcvTime_testspace/O_10_10_D_0_0/vary_tqe/result.csv
FOR EXP3: RcvTime_testspace/exp3.csv
FOR EXP4: RcvTime_testspace/exp4.csv
FOR EXP5: RcvTime_testspace/exp5.csv
```

