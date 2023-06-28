# To build Jars
- Firstly install iotdb locally:
```
git clone -b research/M4-visualization http://github.com/apache/iotdb.git
mvn clean install -DskipTests -pl -distribution
```

- Then set the `finalName` and `mainClass` in the pom.xml as `WriteData`/`QueryData`.

- Run `mvn clean package`, and then `WriteData-jar-with-dependencies.jar`/`QueryData-jar-with-dependencies.jar` will be ready.

- Finally, rename them as `WriteData-0.12.4.jar`/`QueryData-0.12.4.jar` respectively, and copy them to the "jars" directory.

# To debug

1. Start iotdb server.
2. Use WriteData tool to write example data: `root.game s6 long ms 617426057626 1200000 100 D:\github\m4-lsm\M4-visualization-exp\src\main\java\org\apache\iotdb\datasets\BallSpeed.csv 49 50 0 1 PLAIN`
3. Close iotdb server. Move the written data directory from server target directory to the iotdb parent directory.
4. Add breakpoints in the iotdb server code, and then start IoTDB in the IDEA.
5. Use QueryData tool to issue queries: `root.game s6 ns 0 617426057626 617426057626 10000 cpv`.
6. Debug.