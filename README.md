# joblist-app

Java 25 CLI app that processes Hops (`.hop`) files in the current directory: for each `.hop` file it reads the `;NCNAME=` value and replaces every occurrence of `$JOBLISTNAME` with that value, in place. Files are read and written as Windows-1252 to preserve German umlauts.

## Prerequisites

Java 25+, [zb](https://github.com/AdamBien/zb)

## Build and Run

```
zb
java -jar zbo/app.jar
```

Or launch directly from source:

```
java src/main/java/App.java
```

## Tests

```
java tests/TestApp.java
```

Runs an end-to-end suite against a sample `.hop` file located at `../tasks/26008_01_71.hop`.
