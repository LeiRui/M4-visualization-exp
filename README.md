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

# About datasets
The datasets in the `src/main/java/org/apache/iotdb/datasets` of this repository are:
- smaller BallSpeed dataset, with 1,200,000 points.
- smaller MF03 dataset, with 1,076,102 points.
- KOB dataset, with 1,943,180 points.
- RcvTime dataset, with 1,330,764 points.

---

Steps to use the bigger BallSpeed dataset (7,193,200 points) as experimented in paper:

1.   First download the raw data "full-game" from [link](https://www.iis.fraunhofer.de/en/ff/lv/dataanalytics/ek/download.html).
2.   Then update the values of `inPath` and `outPath` in the `src/main/java/org/apache/iotdb/jarCode/ExtractBallSpeedData.java` as the path of "full-game" and the expected path of the ouput "BallSpeed.csv", respectively.
3.   Run `src/main/java/org/apache/iotdb/jarCode/ExtractBallSpeedData.java` to extract "BallSpeed.csv" from "full-game".
4.   Copy the larger "BallSpeed.csv" under `src/main/java/org/apache/iotdb/datasets` to replace the smaller "BallSpeed.csv".

---

Steps to use the bigger MF03 dataset (10,000,000 points) as experimented in paper:

1.   First download the raw data "DEBS2012-ChallengeData.txt" from [link](https://ftp.mi.fu-berlin.de/pub/debs2012/).
2.   Then update the values of `inPath` and `outPath` in the `src/main/java/org/apache/iotdb/jarCode/ExtractMF03Data.java` as the path of "allData.txt" and the expected path of the ouput "MF03.csv", respectively.
3.   Run `src/main/java/org/apache/iotdb/jarCode/ExtractMF03Data.java` to extract "MF03.csv" from "allData.txt".
4.   Copy the larger "MF03.csv" under `src/main/java/org/apache/iotdb/datasets` to replace the smaller "MF03.csv".





