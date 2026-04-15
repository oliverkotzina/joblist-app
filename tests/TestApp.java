String SAMPLE_NAME = "26008_01_71.hop";
String SAMPLE_SOURCE = "../tasks/" + SAMPLE_NAME;
String APP_SOURCE = "src/main/java/App.java";
String JOBLISTNAME_PLACEHOLDER = "$JOBLISTNAME";
String EXPECTED_NCNAME = "01.71_Stollen_L";
String TMP_PREFIX = "joblist-test";
Charset HOP_CHARSET = Charset.forName("windows-1252");

record Test(String name, Callable<Void> body) {}

void main() throws Exception {
    var tests = List.of(
        new Test("replaces $JOBLISTNAME with full NCNAME", this::testReplacement),
        new Test("preserves windows-1252 umlauts", this::testUmlauts),
        new Test("second run is byte-identical (idempotent)", this::testIdempotent),
        new Test("file without NCNAME is left unchanged", this::testNoNcName),
        new Test("non-hop files are ignored", this::testIgnoresNonHop)
    );
    var failed = 0;
    for (var t : tests) {
        try {
            t.body().call();
            IO.println("PASS  " + t.name());
        } catch (Throwable e) {
            failed++;
            IO.println("FAIL  " + t.name() + ": " + e.getMessage());
        }
    }
    IO.println("---");
    if (failed == 0) {
        IO.println("all " + tests.size() + " tests passed");
    } else {
        IO.println(failed + " of " + tests.size() + " failed");
        System.exit(1);
    }
}

Void testReplacement() throws Exception {
    var tmp = Files.createTempDirectory(TMP_PREFIX);
    var file = copySample(tmp);
    runApp(tmp);
    var content = Files.readString(file, HOP_CHARSET);
    assertContains(content, "SetNCName ('" + EXPECTED_NCNAME + "_____LI_____')");
    assertContains(content, "SetNCName ('" + EXPECTED_NCNAME + "___Rechts___')");
    assertMissing(content, JOBLISTNAME_PLACEHOLDER);
    deleteRecursive(tmp);
    return null;
}

Void testUmlauts() throws Exception {
    var tmp = Files.createTempDirectory(TMP_PREFIX);
    var file = copySample(tmp);
    runApp(tmp);
    var content = Files.readString(file, HOP_CHARSET);
    assertContains(content, "Rückwandnut");
    assertContains(content, "Rückwandfalz");
    assertContains(content, "Fräser_Formatieren");
    deleteRecursive(tmp);
    return null;
}

Void testIdempotent() throws Exception {
    var tmp = Files.createTempDirectory(TMP_PREFIX);
    var file = copySample(tmp);
    runApp(tmp);
    var afterFirst = Files.readAllBytes(file);
    runApp(tmp);
    var afterSecond = Files.readAllBytes(file);
    if (!Arrays.equals(afterFirst, afterSecond)) {
        throw new AssertionError("second run modified the file");
    }
    deleteRecursive(tmp);
    return null;
}

Void testNoNcName() throws Exception {
    var tmp = Files.createTempDirectory(TMP_PREFIX);
    var file = tmp.resolve("bare.hop");
    Files.writeString(file, "SetNCName ('" + JOBLISTNAME_PLACEHOLDER + "_test')\r\n", HOP_CHARSET);
    runApp(tmp);
    var content = Files.readString(file, HOP_CHARSET);
    assertContains(content, JOBLISTNAME_PLACEHOLDER + "_test");
    deleteRecursive(tmp);
    return null;
}

Void testIgnoresNonHop() throws Exception {
    var tmp = Files.createTempDirectory(TMP_PREFIX);
    var txt = tmp.resolve("other.txt");
    Files.writeString(txt, ";NCNAME=foo\r\nSetNCName ('" + JOBLISTNAME_PLACEHOLDER + "')\r\n", HOP_CHARSET);
    runApp(tmp);
    var content = Files.readString(txt, HOP_CHARSET);
    assertContains(content, JOBLISTNAME_PLACEHOLDER);
    deleteRecursive(tmp);
    return null;
}

Path copySample(Path dir) throws IOException {
    var target = dir.resolve(SAMPLE_NAME);
    Files.copy(Path.of(SAMPLE_SOURCE), target);
    return target;
}

void runApp(Path dir) throws Exception {
    var pb = new ProcessBuilder("java", Path.of(APP_SOURCE).toAbsolutePath().toString());
    pb.directory(dir.toFile());
    pb.redirectErrorStream(true);
    var process = pb.start();
    var output = new String(process.getInputStream().readAllBytes());
    var exit = process.waitFor();
    if (exit != 0) {
        throw new RuntimeException("app exited " + exit + ": " + output);
    }
}

void assertContains(String haystack, String needle) {
    if (!haystack.contains(needle)) {
        throw new AssertionError("expected to contain: " + needle);
    }
}

void assertMissing(String haystack, String needle) {
    if (haystack.contains(needle)) {
        throw new AssertionError("expected to be missing: " + needle);
    }
}

void deleteRecursive(Path dir) throws IOException {
    try (var stream = Files.walk(dir)) {
        var paths = stream.sorted(Comparator.reverseOrder()).toList();
        for (var p : paths) Files.delete(p);
    }
}
