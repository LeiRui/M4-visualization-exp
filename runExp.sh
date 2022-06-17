HOME_PATH=/data/rl/v2

echo 3 |sudo tee /proc/sys/vm/drop_caches
free -m
cd $HOME_PATH
./run-BallSpeed-exp.sh

echo 3 |sudo tee /proc/sys/vm/drop_caches
free -m
cd $HOME_PATH
./run-KOB-exp.sh

echo 3 |sudo tee /proc/sys/vm/drop_caches
free -m
cd $HOME_PATH
./run-MF03-exp.sh

echo 3 |sudo tee /proc/sys/vm/drop_caches
free -m
cd $HOME_PATH
./run-RcvTime-exp.sh