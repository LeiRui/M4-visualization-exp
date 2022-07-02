# Experiment Guidance

1. Download this `M4-visualization-exp` directory using `git clone https://github.com/LeiRui/M4-visualization-exp.git`

2. Enter the directory `src/main/java/org/apache/iotdb/bash` in this `M4-visualization-exp` directory, and update `prepare-all.sh`:

    - update `M4_VISUALIZATION_EXP` as the downloaded path of this `M4-visualization-exp` directory.

    - update `HOME_PATH` as an empty directory where experiments are going to be executed.

3. Run `prepare-all.sh`, and the directory at `HOME_PATH` will be ready for experiments.

4. Enter the directory at `HOME_PATH`, run experiments using `nohup ./run-datasetName.sh /dev/null 2>&1 &`, where `datasetName` is `BallSpeed`/`MF03`/`KOB`/`RcvTime`. After running the corresponding experiment, the experimental results (exp1/2/3/4/5.csv) are in `datasetName_testspace`.

