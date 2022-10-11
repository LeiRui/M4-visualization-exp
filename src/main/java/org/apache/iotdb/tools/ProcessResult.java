package org.apache.iotdb.tools;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

public class ProcessResult {

  /**
   * <p>
   * select M4(s6,'tqs'='0','tqe'='25599285705','w'='3') from root.game where time>=0 and
   * time<25599285705	 meta IO: 	16245600	 meta num: 	1	 data IO: 	114957500	 data num: 	500
   * readMemChunk IO: 	22996600	 readMemChunk num: 	500	 total: 	316670600
   * <p>
   * sum meta IO: 	16245600	 sum meta nums: 	1	 sum data IO: 	114957500	 sum data num: 	500	 sum
   * readMemChunkTime: 	22996600	 sum readMemChunkNum: 	500	 avg total time: 	316670600	 isSet:
   * true.
   * <p>
   * timeColumnTS2DIFFLoadBatchCost= 3635400 ns
   * <p>
   * Usage: java ProcessResult result_${i}.txt result_${i}.out ../sumResultMOC.csv
   */
  public static void main(String[] args) throws IOException {

    String inFilePath = args[0];
    String outFilePath = args[1];
    String sumOutFilePath = args[2];

    BufferedReader reader = new BufferedReader(new FileReader(inFilePath));
    FileWriter writer = new FileWriter(outFilePath);

    FileWriter sumWriter = new FileWriter(sumOutFilePath, true); // append
    File file = new File(sumOutFilePath);
    if (!file.exists() || file.length() == 0) { // write header for sumOutFilePath
      sumWriter.write(
          "meta_num,avg_meta(ms),data_num,avg_data(ms),read_mem_chunk_num,avg_read_mem_chunk_time(ms),"
              + "avg_total(ms),avg_timeColumnTS2DIFFLoadBatchCost(ms)\n");
    }

    String readLine = null;
    boolean firstTime = true;
    int metaNum = 0, dataNum = 0, readMemChunkNum = 0;
    long metaTime = 0;
    long dataTime = 0;
    long totalTime = 0;
    long readMemChunkTime = 0;
    int counter = 0;
    long timeColumnTS2DIFFLoadBatchCost = 0;
    while ((readLine = reader.readLine()) != null) {
      if (readLine.startsWith("select")) {
        String[] values = readLine.split("\t");
        if (firstTime) {
          metaNum = Integer.parseInt(values[4]);
          dataNum = Integer.parseInt(values[8]);
          readMemChunkNum = Integer.parseInt(values[12]);
          firstTime = false;
        }
        metaTime += Long.parseLong(values[2]);
        dataTime += Long.parseLong(values[6]);
        readMemChunkTime += Long.parseLong(values[10]);
        totalTime += Long.parseLong(values[14]);
        counter++;
        writer.write(readLine + "\n");
      } else if (readLine.startsWith("timeColumnTS2DIFFLoadBatchCost")) {
        String[] values = readLine.split("\\s+");
        timeColumnTS2DIFFLoadBatchCost += Long.parseLong(values[1]);
        writer.write(readLine + "\n");
      }
    }

    writer.write(
        "meta_num\t avg_meta(ms)\t data_num\t avg_data(ms)\t read_mem_chunk_num\t "
            + "avg_read_mem_chunk_time(ms)\t avg_total(ms)\t avg_timeColumnTS2DIFFLoadBatchCost(ms)\n"
            + metaNum
            + "\t"
            + (double) metaTime / 1000000 / counter
            + "\t"
            + dataNum
            + "\t"
            + (double) dataTime / 1000000 / counter
            + "\t"
            + readMemChunkNum
            + "\t"
            + (double) readMemChunkTime / 1000000 / counter
            + "\t"
            + (double) totalTime / 1000000 / counter
            + "\t"
            + (double) timeColumnTS2DIFFLoadBatchCost / 1000000 / counter)
    ;

    sumWriter.write(
        metaNum
            + ","
            + (double) metaTime / 1000000 / counter
            + ","
            + dataNum
            + ","
            + (double) dataTime / 1000000 / counter
            + ","
            + readMemChunkNum
            + ","
            + (double) readMemChunkTime / 1000000 / counter
            + ","
            + (double) totalTime / 1000000 / counter
            + ","
            + (double) timeColumnTS2DIFFLoadBatchCost / 1000000 / counter
            + "\n");

    reader.close();
    writer.close();
    sumWriter.close();
  }
}
