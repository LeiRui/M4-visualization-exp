for w in 100 200 400 600 1200 2000 3000 4000
do
  approachArray=("mac" "cpv" "minmax" "minmax_lsm" "lttb" "rawQuery");
  for approach in ${approachArray[@]};
  do
      python3 /data1/ruilei/M4-visualization-exp/tools/parse.py -i /data1/ruilei/moreBaselinesQueryExp-backup20231017 -a ${approach} -w ${w} -H 100 -tqs 0 -tqe 4259092178974 -o /data1/ruilei/M4-visualization-exp/tools
      echo "target/release/line-density ${w} 100 /data1/ruilei/M4-visualization-exp/tools/ts-${approach}-${w}.csv true 0 4259092178974" >> rustPlot.sh
      echo "python3 /data1/ruilei/M4-visualization-exp/tools/calcDSSIM.py -f1 /data1/ruilei/M4-visualization-exp/tools/ts-${approach}-${w}.csv-${w}.png -f2 /data1/ruilei/M4-visualization-exp/tools/ts-rawQuery-${w}.csv-${w}.png" >> dssimCompare.sh
  done;
done;

