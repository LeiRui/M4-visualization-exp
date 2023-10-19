approachArray=("mac" "cpv" "minmax" "minmax_lsm" "lttb");
for approach in ${approachArray[@]};
do
  for w in 100 200 400 600 1200 2000 3000 4000
  do
      python3 parse.py -i /data1/ruilei/moreBaselinesQueryExp-backup20231017 -a ${approach} -w ${w} -H 100 -tqs 0 -tqe 4259092178974 -o .
  done;
done;
