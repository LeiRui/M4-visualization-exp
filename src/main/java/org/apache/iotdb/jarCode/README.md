# To build Jars
- Firstly install iotdb locally:
```
git clone -b research/M4-visualization http://github.com/apache/iotdb.git
mvn clean install -DskipTests -pl -distribution
```

- Then set the `finalName` and `mainClass` in the pom.xml as `WriteData`/`QueryData`.

- Run `mvn clean package`, and then `WriteData-jar-with-dependencies.jar`/`QueryData-jar-with-dependencies.jar` will be ready.

- Finally, rename them as `WriteData-0.12.4.jar`/`QueryData-0.12.4.jar` respectively.