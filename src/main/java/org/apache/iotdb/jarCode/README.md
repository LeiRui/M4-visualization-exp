# To build Jars
- Firstly install iotdb locally:
```
git clone -b M4-visualization http://github.com/apache/iotdb.git
mvn clean install -DskipTests
```

- Then set the `mainClass` and `artifactId` in the pom.xml as `WriteData`/`QueryData`.

- Finally run `mvn clean package`, and then `WriteData-0.12.4.jar`/`QueryData-0.12.4.jar` will be ready.