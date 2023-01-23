package org.apache.iotdb.jarCode;

import java.io.BufferedReader;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.List;
import org.eclipse.collections.impl.list.mutable.primitive.DoubleArrayList;

public class StepRegressExample {

  public static void main(String[] args) throws Exception {
    // read data into memory, assuming that the data is small enough to fit in memory
    // read csvData from row start(inclusive) to end(exclusive), counting from 1
    String csvData = "D:\\github\\m4-lsm\\M4-visualization-exp\\src\\main\\java\\org\\apache\\iotdb\\datasets\\RcvTime.csv";
    int x = 12741; //4232;
    int start = (x - 1) * 100 + 1;
    int end = start + 100;

//    String csvData = "D:\\github\\m4-lsm\\M4-visualization-exp\\src\\main\\java\\org\\apache\\iotdb\\jarCode\\test1.csv";
//    int start = 1;
//    int end = 3;

    StepRegress stepRegress = new StepRegress();
    String line;
    List<Long> timestampList = new ArrayList<>();
    List<Long> intervalList = new ArrayList<>();
    long previousTimestamp = -1;
    long count = 0;
    try (BufferedReader reader = new BufferedReader(new FileReader(csvData))) {
      while ((line = reader.readLine()) != null) {
        count++;
        if (count >= start && count < end) {
          long timestamp = Long.parseLong(line.split(",")[0]);
          stepRegress.insert(timestamp);
          timestampList.add(timestamp);
          if (previousTimestamp > 0) {
            long delta = timestamp - previousTimestamp;
            intervalList.add(delta);
          }
          previousTimestamp = timestamp;
        } else if (count >= end) {
          break;
        }
      }
    }

    stepRegress.learn();
    System.out.println(csvData);
    System.out.println("position=[" + start + "," + end + ")");
    System.out.printf("slope=%.10f%n", stepRegress.getSlope());
    System.out.printf("mean=%.2f%n", stepRegress.getMean());
    System.out.printf("std=%.2f%n", stepRegress.getStdDev());
    System.out.printf("median=%.2f%n", stepRegress.getMedian());
    System.out.printf("mad=%.2f%n", stepRegress.getMad());
    System.out.println("timestamps=" + stepRegress.getTimestamps() + ";");
    System.out.println("intervalsType=" + stepRegress.getIntervalsType() + ";");
    System.out.println("keys=" + stepRegress.getSegmentKeys() + ";");
    System.out.println("intercepts=" + stepRegress.getSegmentIntercepts() + ";");
    System.out.println(
        "intercepts=" + StepRegress.inferInterceptsFromSegmentKeys(stepRegress.getSlope(),
            stepRegress.getSegmentKeys()) + ";");

    DoubleArrayList predicts = new DoubleArrayList();
    for (long t : stepRegress.getTimestamps().toArray()) {
      predicts.add(stepRegress.infer(t));
    }
    System.out.println("predict=" + predicts + ";");

    DoubleArrayList predictsFineGrain = new DoubleArrayList();
    long step = (stepRegress.getTimestamps().getLast() - stepRegress.getTimestamps().get(0)) / 300;
    for (long t = stepRegress.getTimestamps().get(0); t <= stepRegress.getTimestamps().getLast();
        t = t + step) {
      predictsFineGrain.add(stepRegress.infer(t));
    }
    System.out.println("predict2=" + predictsFineGrain + ";");
  }
}

/**
 * figure, plot(chunkTimestamps(x,:),1:range), for i=1:1:range-1 if intervalsType(i)==0 hold
 * on,plot(chunkTimestamps(x,i),i,'b+') % non-outlier & tilt else hold
 * on,plot(chunkTimestamps(x,i),i,'r+') % outlier & level end end hold
 * on,plot(chunkTimestamps(x,range),range,'g+') % the last point
 * <p>
 * K=1/vmedian(x);
 * <p>
 * for i=1:1:length(keys) hold on,xline(keys(i)) end
 * <p>
 * hold on,plot(chunkTimestamps(x,1):30:chunkTimestamps(x,100),predict2)
 * <p>
 * y=1:1:range; max(abs(y-predict))
 */
