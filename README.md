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

Starting from 0, the 15th column is the M4 aggregation query execution time of M4-UDF, and the 22th column is the M4 aggregation query execution time of M4-LSM.
