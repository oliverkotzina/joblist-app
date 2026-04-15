String version = "2026-04-15.1";

String JOBLISTNAME_PLACEHOLDER = "$JOBLISTNAME";
String NCNAME_PREFIX = ";NCNAME=";
String HOP_SUFFIX = ".hop";
Charset HOP_CHARSET = Charset.forName("windows-1252");

void main() throws IOException {
    try (var entries = Files.list(Path.of("."))) {
        entries.filter(this::isHopFile).forEach(this::processHopFile);
    }
}

boolean isHopFile(Path file) {
    return file.getFileName().toString().endsWith(HOP_SUFFIX);
}

void processHopFile(Path file) {
    try {
        var content = Files.readString(file, HOP_CHARSET);
        var ncname = extractNcName(content);
        if (ncname.isEmpty()) {
            IO.println("skip (no NCNAME): " + file.getFileName());
            return;
        }
        Files.writeString(file, content.replace(JOBLISTNAME_PLACEHOLDER, ncname.get()), HOP_CHARSET);
        IO.println("processed: " + file.getFileName() + " -> " + ncname.get());
    } catch (IOException e) {
        IO.println("error: " + file.getFileName() + " " + e.getMessage());
    }
}

Optional<String> extractNcName(String content) {
    return content.lines()
        .filter(this::isNcNameLine)
        .map(this::ncNameValue)
        .findFirst();
}

boolean isNcNameLine(String line) {
    return line.startsWith(NCNAME_PREFIX);
}

String ncNameValue(String line) {
    return line.substring(NCNAME_PREFIX.length()).trim();
}
