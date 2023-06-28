package org.apache.iotdb.jarCode;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class Tmptest {

  public static void main(String[] args) throws IOException {
    List<Long> minTimestamps = new ArrayList<>();
    List<Long> maxTimestamps = new ArrayList<>();
    WriteDataVaryChunkSize.getMinMaxTimeForEachChunk(minTimestamps, maxTimestamps,
        "src/main/java/org/apache/iotdb/datasets/BallSpeed.csv", 0, 1, 1000);
    System.out.println(minTimestamps.get(0));
    System.out.println(maxTimestamps.get(0));
    System.out.println(minTimestamps.get(1));
    System.out.println(maxTimestamps.get(1));

    int[] Mlist = new int[]{1,5,10,15,20,30,40,50};
    for(int M:Mlist) {
      List<Boolean> flags = WriteDataVaryChunkSize.checkIfSplit(minTimestamps, maxTimestamps,
          0, 617426057626L, 4, M);
      int cnt = 0;
      for (boolean flag : flags) {
        if (flag) {
          cnt++;
        }
      }
      System.out.println("split ratio: " + cnt * 1.0 / flags.size());
    }
  }

}
