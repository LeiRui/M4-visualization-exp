# A Step-by-step guide to experiments

1. Download this `M4-visualization-exp` directory using `git clone http://github.com/LeiRui/M4-visualization-exp.git`

2. Enter the directory `src/main/java/org/apache/iotdb/bash` in this `M4-visualization-exp` directory, and update `prepare-all.sh` as follows:

    - update `M4_VISUALIZATION_EXP` as the downloaded path of this `M4-visualization-exp` directory.

    - update `HOME_PATH` as an empty directory where you want the experiments to be executed.

3. Run `prepare-all.sh` and then the directory at `HOME_PATH` will be ready for experiments.

4. Enter the directory at `HOME_PATH`, run experiments using `nohup ./run-[datasetName].sh /dev/null 2>&1 &`, where `[datasetName]` is `BallSpeed`/`MF03`/`KOB`/`RcvTime`.
The running logs are saved in nohup.out, which can be checked by the command: `tail nohup.out`.

5. When the experiment script finishes running ("ALL FINISHED!" appears in nohup.out), the corresponding experimental results are in `[datasetName]_testspace` as follows:
    - `exp1.csv` for varying the number of time spans, 
    - `exp2.csv` for varying query time range, 
    - `exp3.csv` for varying chunk overlap percentage, 
    - `exp4.csv` for varying delete percentage, 
    - `exp5.csv` for varying delete time range.

In these csv, counting from 0, the 8th column is the query execution time of M4-UDF, and the 16th column is the query execution time of M4-LSM.

## About datasets

The datasets in the `src/main/java/org/apache/iotdb/datasets` of this repository are:
- smaller BallSpeed dataset, with 1,200,000 points.
- smaller MF03 dataset, with 1,076,102 points.
- KOB dataset, with 1,943,180 points.
- RcvTime dataset, with 1,330,764 points.

---

How to use the bigger BallSpeed dataset (7,193,200 points) as experimented in paper:

1.   Before following the step-by-step guide above, first download the raw data "full-game" from [link](https://www.iis.fraunhofer.de/en/ff/lv/dataanalytics/ek/download.html).
2.   Then update the values of `inPath` and `outPath` in the `src/main/java/org/apache/iotdb/jarCode/ExtractBallSpeedData.java` as the path of "full-game" and the expected path of the ouput "BallSpeed.csv", respectively. Run `src/main/java/org/apache/iotdb/jarCode/ExtractBallSpeedData.java` to extract "BallSpeed.csv" from "full-game".
3.   Copy the larger "BallSpeed.csv" under `src/main/java/org/apache/iotdb/datasets` to replace the smaller "BallSpeed.csv".
4.   In `src/main/java/org/apache/iotdb/bash`, rename `prepare-all-big.sh` to be `prepare-all.sh`, and follow the step-by-step guide to finish experiments.

---

How to use the bigger MF03 dataset (10,000,000 points) as experimented in paper:

1.   Before following the step-by-step guide above, first download the raw data "DEBS2012-ChallengeData.txt" from [link](https://ftp.mi.fu-berlin.de/pub/debs2012/).
2.   Then update the values of `inPath` and `outPath` in the `src/main/java/org/apache/iotdb/jarCode/ExtractMF03Data.java` as the path of "allData.txt" and the expected path of the ouput "MF03.csv", respectively. Run `src/main/java/org/apache/iotdb/jarCode/ExtractMF03Data.java` to extract "MF03.csv" from "allData.txt".
4.   Copy the larger "MF03.csv" under `src/main/java/org/apache/iotdb/datasets` to replace the smaller "MF03.csv".
5.   In `src/main/java/org/apache/iotdb/bash`, rename `prepare-all-big.sh` to be `prepare-all.sh`, and follow the step-by-step guide to finish experiments.



# Guides to supplemental experiments

## Comparison with Baseline Index

Enter the directory `src/main/java/org/apache/iotdb/jars` in this `M4-visualization-exp` directory, and use `java -jar BPlusTreeBaselineExp-jar-with-dependencies.jar [Param1] [Param2] [Param3]` to perform the experiments.

-   Param1: true to test B+ tree, false to test chunk index with step regression
-   Param2: number of keys
-   Param3:  test data file path

For example, run the following command:

```
java -jar BPlusTreeBaselineExp-jar-with-dependencies.jar true 1000 D:\full-game\BallSpeed.csv
```

and the experimental results on B+ tree with 1000 keys from BallSpeed dataset are printed in the console window:

```
[Experimental Settings]
B+ tree index
on 1000 keys
data source file: D:\full-game\BallSpeed.csv

[Experimental Results]
file size: 82944, total query cost: 3622260 (read index cost: 2287920, search cost: 343090, read data cost: 6253270)
```

Similarly, run the following command:

```
java -jar BPlusTreeBaselineExp-jar-with-dependencies.jar false 1000 D:\full-game\BallSpeed.csv
```

and the experimental results on our proposed chunk index with 1000 keys from BallSpeed dataset are printed in the console window:

```
[Experimental Settings]
Chunk index with step regression
on 1000 keys
data source file is D:\full-game\BallSpeed.csv

[Experimental Results]
file size: 2224, total query cost: 1103260 (read index cost: 16900, search cost: 451180, read data cost: 1571340)
```

The source codes of "BPlusTreeBaselineExp-jar-with-dependencies.jar" are in [another repository](https://github.com/LeiRui/BPlusTreeBaselineExp.git).

## Meta-Info at the TsFile Level

### Step 1: prepare dataset

Use the bigger BallSpeed dataset (7,193,200 points) as experimented in paper:

1.   Download the raw data "full-game" from [link](https://www.iis.fraunhofer.de/en/ff/lv/dataanalytics/ek/download.html).
2.   Then update the values of `inPath` and `outPath` in the `src/main/java/org/apache/iotdb/jarCode/ExtractBallSpeedData.java` as the path of "full-game" and the expected path of the ouput "BallSpeed.csv", respectively. Run `src/main/java/org/apache/iotdb/jarCode/ExtractBallSpeedData.java` to extract "BallSpeed.csv" from "full-game".
3.   Copy the larger "BallSpeed.csv" under `src/main/java/org/apache/iotdb/datasets` to replace the smaller "BallSpeed.csv".

### Step 2: prepare bash

1. Enter the directory `src/main/java/org/apache/iotdb/bash` in this `M4-visualization-exp` directory, and update `prepare-tsfileLevel-exp.sh` as follows:

    - update `M4_VISUALIZATION_EXP` as the downloaded path of this `M4-visualization-exp` directory.

    - update `HOME_PATH` as an empty directory where you want the experiments to be executed.

2. Run `prepare-tsfileLevel-exp.sh` and then the directory at `HOME_PATH` will be ready for experiments.

### Step 3: run bash

Enter the directory at `HOME_PATH`, run experiments using `nohup ./run-BallSpeed.sh /dev/null 2>&1 &`.
The running logs are saved in nohup.out, which can be checked by the command: `tail nohup.out`.

When the experiment script finishes running ("ALL FINISHED!" appears in nohup.out), the corresponding experimental results are in `HOME_PATH/BallSpeed_testspace/allResult.csv`.

## Evaluation of the Proposed Chunk Index

Enter the directory `src/main/java/org/apache/iotdb/jars` in this `M4-visualization-exp` directory, and use `java -jar EvaluateChunkIndexFrontN-jar-with-dependencies.jar [Param1] [Param2]` to perform the experiments.

-   Param1: number of repeated tests
-   Param2: test data file path

For example, run the following command:

```
java -jar EvaluateChunkIndexFrontN-jar-with-dependencies.jar 10000000 D:\full-game\BallSpeed.csv
```

and then the experimental results with different number of keys (denoted as N) are summarized in `evaluateIndexExp.csv`.

The source codes of "EvaluateChunkIndexFrontN-jar-with-dependencies.jar" are in `src/main/java/org/apache/iotdb/jarCode/EvaluateChunkIndexFrontN.java` of this `M4-visualization-exp` directory.

## Ablation Study

### Step 1: prepare dataset

Use the bigger MF03 dataset (10,000,000 points) as experimented in paper:

1.   Before following the step-by-step guide above, first download the raw data "DEBS2012-ChallengeData.txt" from [link](https://ftp.mi.fu-berlin.de/pub/debs2012/).
2.   Then update the values of `inPath` and `outPath` in the `src/main/java/org/apache/iotdb/jarCode/ExtractMF03Data.java` as the path of "allData.txt" and the expected path of the ouput "MF03.csv", respectively. Run `src/main/java/org/apache/iotdb/jarCode/ExtractMF03Data.java` to extract "MF03.csv" from "allData.txt".
3.   Copy the larger "MF03.csv" under `src/main/java/org/apache/iotdb/datasets` to replace the smaller "MF03.csv".

### Step 2: prepare bash

1. Enter the directory `src/main/java/org/apache/iotdb/bash` in this `M4-visualization-exp` directory, and update `prepare-ablation-exp.sh` as follows:

    - update `M4_VISUALIZATION_EXP` as the downloaded path of this `M4-visualization-exp` directory.

    - update `HOME_PATH` as an empty directory where you want the experiments to be executed.

2. Run `prepare-ablation-exp.sh` and then the directory at `HOME_PATH` will be ready for experiments.

### Step 3: run bash

Enter the directory at `HOME_PATH`, run experiments using `nohup ./run-MF03.sh /dev/null 2>&1 &`.
The running logs are saved in nohup.out, which can be checked by the command: `tail nohup.out`.

When the experiment script finishes running ("ALL FINISHED!" appears in nohup.out), the corresponding experimental results are in `HOME_PATH/MF03_testspace/allResult.csv`.
