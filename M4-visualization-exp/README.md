# A Step-by-Step Guide to Experiments

The code and data of experiments for our paper "Time Series Representation for Visualization in Apache IoTDB" are available here. The experiments are conducted on machines running Ubuntu. We provide detailed guidelines below to reproduce our experimental results.

**Table of Contents:**

1.   Download Java
2.   Download `M4-visualization-exp` Folder
3.   Guides to "7.2 Experiments with Varying Parameters"
4.   Guides to "7.3 Ablation Study"
5.   Guides to "1.1 Motivation"



## 1. Download Java

Java >= 1.8 is needed. Please make sure the JAVA_HOME environment path has been set. You can follow the steps below to install and configure Java.

```shell
# install
sudo apt-get update
sudo apt-get upgrade
sudo apt install openjdk-8-jdk-headless

# configure
vim /etc/profile
# add the following two lines to the end of /etc/profile
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
export PATH=$JAVA_HOME/bin:$PATH
# save and exit vim, and let the configuration take effect
source /etc/profile
```

## 2. Download `M4-visualization-exp` Folder

The first step is to download this `M4-visualization-exp` folder. For easy download, we provide a compressed zip format, which can be downloaded using the following command:

```shell
# In the following, we assume that the downloaded path of this folder is /root/ubuntu/M4-visualization-exp.
cd /root/ubuntu
wget https://anonymous.4open.science/r/M4-visualization-exp-D378/M4-visualization-exp.zip
unzip M4-visualization-exp.zip 
```

### 2.1 Folder Structure

-   `README.md`: This file.
-   `bash`: Folder of scripts for running experiments.
-   `datasets`: Folder of datasets used in experiments. **Note that this folder is empty right after unzipping. Please follow the instructions in the "Download datasets from Kaggle" section of this README to download datasets from Kaggle before doing experiments.**
-   `iotdb-cli-0.12.4`: Folder of the IoTDB client.
-   `iotdb-server-0.12.4`: Folder of the IoTDB server.
-   `jarCode`: Folder of JAVA source codes for jars used in experiments.
-   `jars`: Folder of jars used in experiments to write data to IoTDB and query data from IoTDB.
-   `tools`: Folder of tools to assist automated experiment scripts.
-   `python-exp`: Folder for the motivation experiment involving remote connections.

### 2.2 Download Datasets from Kaggle

The datasets are available in https://www.kaggle.com/datasets/xxx123456789/exp-datasets.

Here is the method of downloading data from kaggle on Ubuntu.

```shell
# First install kaggle.
pip install kaggle
pip show kaggle 

# Then set up kaggle API credentials.
mkdir ~/.kaggle # or /root/.kaggle
cd ~/.kaggle # or /root/.kaggle
vim kaggle.json # input your Kaggle API, in the format of {"username":"xx","key":"xx"}

# Finally you can download datasets.
cd /root/ubuntu/M4-visualization-exp/datasets
kaggle datasets download xxx123456789/exp-datasets
unzip exp-datasets.zip 
# After unzipping, you will find BallSpeed.csv, MF03.csv, Train.csv, Steel.csv in /root/ubuntu/M4-visualization-exp/datasets.
```

-   BallSpeed dataset, with 7,193,200 points, coming from "[DEBS 2013 Grand Challenge](https://www.iis.fraunhofer.de/en/ff/lv/dataanalytics/ek/download.html)", extracted with `ExtractBallSpeedData.java` in the jarCode folder.
-   MF03 dataset, with 10,000,000 points, coming from "[DEBS 2012 Grand Challenge](https://debs.org/grand-challenges/2012/)", extracted with `ExtractMF03Data.java` in the jarCode folder.
-   Train dataset, with 127,802,876 points, is a 5-month train monitoring data collected by a vibration sensor at around 20Hz frequency, provided by real customers of Apache IoTDB.
-   Steel dataset,  with 314,572,100 points, is 7-month steel production monitoring data collected by a vibration sensor at around 20Hz frequency, provided by real customers of Apache IoTDB.

## 3. Guides to "7.2 Experiments with Varying Parameters"

>   Corresponding to Figures 15~19 in the paper.

Steps:

1. Enter the `bash` folder in the `M4-visualization-exp` folder, and then:

    1. Make all scripts executable by executing `chmod +x *.sh`.

    2. Update `prepare-all.sh` as follows:

        -   Update `M4_VISUALIZATION_EXP` as the downloaded path of the `M4-visualization-exp` folder.

        -   Update `HOME_PATH` as an **empty** folder where you want the experiments to be executed.

    3. Run `prepare-all.sh` and then the folder at `HOME_PATH` will be ready for experiments.

2. Enter the folder at `HOME_PATH`, and run experiments using `nohup ./run-[datasetName].sh 2>&1 &`, where `[datasetName]` is `BallSpeed`/`MF03`/`Train`/`Steel`. The running logs are saved in nohup.out, which can be checked by the command: `tail nohup.out`.

3. When the experiment script finishes running ("ALL FINISHED!" appears in nohup.out), the corresponding experimental results are in `HOME_PATH/[datasetName]_testspace` as follows:
    - `exp1_res.csv` for varying the number of time spans, 
    - `exp2_res.csv` for varying query time range, 
    - `exp3_res.csv` for varying chunk overlap percentage, 
    - `exp4_res.csv` for varying delete percentage, 
    - `exp5_res.csv` for varying delete time range.
4. In the result csv, counting from 1, the second column is the query execution time of M4, and the third column is the query execution time of M4-LSM.
5. `run-[datasetName].sh` is a script that runs all experiments (from exp1 to exp5). If you want to run a single experiment expN (N=1/2/3/4/5), you can run `run-[datasetName]-[N].sh`. Again, the result csv is `exp[N]_res.csv`.

## 4. Guides to "7.3 Ablation Study"

>   Corresponding to Figure 20 in the paper.

Steps:

1. Enter the `bash` folder in the `M4-visualization-exp` folder, and then:
    1. Make all scripts executable by executing `chmod +x *.sh`. If you have done this step before, you can ignore it here.
    2. Update `prepare-ablation.sh` as follows:
        -   Update `M4_VISUALIZATION_EXP` as the downloaded path of the `M4-visualization-exp` folder.
        -   Update `HOME_PATH` as an **empty** folder where you want the experiments to be executed.
    3. Run `prepare-ablation.sh` and then the folder at `HOME_PATH` will be ready for experiments.

2. Enter the folder at `HOME_PATH`, and run experiments using `nohup ./run-ablation.sh 2>&1 &`.
    The running logs are saved in nohup.out, which can be checked by the command: `tail nohup.out`.
3. When the experiment script finishes running ("ALL FINISHED!" appears in nohup.out), the corresponding experimental results are in `HOME_PATH/ablationExp_res.csv`. 
4. In the result csv, counting from 1, the second column is the query execution time of M4-LSM without index and pruning, and the sum of the third and fourth columns is the total number of traversed points of M4-LSM without index and pruning. By analogy, the fifth to seventh columns are the results of M4-LSM with only time index, and the eighth to tenth columns are the results of M4-LSM with both time index and point pruning.


## 5. Guides to "1.1 Motivation"

>   Corresponding to Figure 3 in the paper.

This experiments involves communication between two nodes and is a bit more complicated than the previous two sections in terms of installation preparation. Assume that the server and client nodes have the following IP addresses, usernames, and passwords.

|            | Database Server Node | Rendering Client Node |
| ---------- | -------------------- | --------------------- |
| IP address | A                    | B                     |
| Username   | server               | client                |
| Password   | x                    | y                     |

### 5.1 Environment Setup for Both Nodes

-   **Download Java** as instructed earlier.

-   **Download `M4-visualization-exp` folder** as instructed earlier.

-   Download sshpass:

    ```shell
    sudo apt-get install sshpass
    ```

    After downloading sshpass, run `sshpass -p 'x' ssh server@A "echo 'a'"` on the client node to verify if sshpass works. If sshpass works, you will see an "a" printed on the screen. Otherwise, try executing `ssh server@A "echo 'a'"` on the client node, and then reply "yes" to the prompt ("Are you sure you want to continue connecting (yes/no/[fingerprint])?") and enter the password 'x' manually. Then run again `sshpass -p 'x' ssh server@A "echo 'a'"` on the client node to verify if sshpass works.

-   Download the Python packages to be used:

    ```shell
    sudo apt install python3-pip
    pip install matplotlib
    pip install thrift
    pip install pandas
    pip install pyarrow
    
    pip show matplotlib # this is to check where python packages are installed. 
    
    cd /root/ubuntu/M4-visualization-exp/python-exp
    unzip iotdb.zip
    # In the following, we assume that python packages are installed in "/usr/local/lib/python3.8/dist-packages"
    cp -r iotdb /usr/local/lib/python3.8/dist-packages/. # this step installs iotdb-python-connector
    ```

### 5.2 Populate the Database Server Node

Before doing experiments, follow the steps below to populate the database server with test data.

1. Go to the database server node.

2. Enter the `bash` folder in the `M4-visualization-exp` folder, and then:

    1. Make all scripts executable by executing `chmod +x *.sh`. If you have done this step before, you can ignore it here.

    2. Update `prepare-motivation.sh` as follows:

        -   Update `M4_VISUALIZATION_EXP` as the downloaded path of the `M4-visualization-exp` folder.

        -   Update `HOME_PATH` as an **empty** folder where you want the experiments to be executed.

    3. Run `prepare-motivation.sh` and then the folder at `HOME_PATH` will be ready for experiments.

3. Enter the folder at `HOME_PATH`, and run experiments using `nohup ./run-motivation.sh 2>&1 &`.
    The running logs are saved in nohup.out, which can be checked by the command: `tail nohup.out`.

4. When the experiment script finishes running ("ALL FINISHED!" appears in nohup.out), preparations are complete.

### 5.3 Experiments on the Rendering Client Node

1.   Go to the rendering client node.
2.   Enter the `python-exp` folder in the `M4-visualization-exp` folder, and then:
     1.   Make all scripts executable by executing `chmod +x *.sh`.
     2.   Update `run-python-query-plot-exp.sh` as follows:
          -   Update `READ_METHOD` as `rawQuery`/`mac`/`cpv`.
              -   `rawQuery`: corresponding to "without-M4" in Figure 3 in the paper.
              -   `mac`: corresponding to "M4" in Figure 3 in the paper.
              -   `cpv`: corresponding to "M4-LSM" in Figure 3 in the paper.
          -   Update `M4_VISUALIZATION_EXP` as the downloaded path of the `M4-visualization-exp` folder on the client node.
          -   Update `remote_M4_VISUALIZATION_EXP` as the downloaded path of the `M4-visualization-exp` folder on the server node.
          -   Update `remote_IOTDB_HOME_PATH` to the same path as the "HOME_PATH" set in the "Prepare the Database Server Node" section of this README.
          -   Update `remote_ip` as the IP address of the database server node.
          -   Update `remote_user_name` as the login username of the database server node.
          -   Update `remote_passwd` as the login password of the database server node.
     3.   Run experiments using `nohup ./run-python-query-plot-exp.sh 2>&1 &`. The running logs are saved in nohup.out, which can be checked by the command: `tail nohup.out`. 
     4.   When the experiment script finishes running ("ALL FINISHED!" appears in nohup.out), the corresponding experimental results are in `sumResult-[READ_METHOD].csv`, where `[READ_METHOD]` is `rawQuery`/`mac`/`cpv`. 
     5.   In the result csv, the last four columns are server computation time, communication time, client rendering time, and total response time, and each row corresponds to a different number of raw data points.



