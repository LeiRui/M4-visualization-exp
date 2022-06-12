# To build Jars
- Firstly install iotdb locally:
```
git clone -b M4-visualization http://github.com/apache/iotdb.git
mvn clean install -DskipTests
```

- Then set the `mainClass` and `artifactId` in the pom.xml of this repository.

- Finally run `mvn clean package` in this repository.