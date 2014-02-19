#!/usr/bin/env python

import os
import re
import subprocess

def process_diff(diff_lines):
    try:
        # Eat the first line
        next(diff_lines)
    except StopIteration:
        return {}

    results = {}

    while True:
        filename, lines_set, more = process_diff_file(diff_lines)
        if lines_set:
            results[os.path.normpath(filename)] = lines_set
        if not more:
            return results

def process_diff_file(lines):
    """
    Eats the first line of the next file
    """
    # Skip the first 3 lines of the diff output (header lines that we don't
    try:
        while not next(lines).startswith("---"):
           pass
    except StopIteration: # if the last diff is a binary, there's no line starting with '---'
        return "", set(), False
      
            
    dst_line = next(lines)
    dst_header = "+++ b/"
    dst_filename = dst_line[len(dst_header):]

    lines_set = set()

    while True:
        try:
            l = next(lines)
        except StopIteration:
            return dst_filename, lines_set, False

        if l.startswith("diff"):
            return dst_filename, lines_set, True

        elif l.startswith("@@"):
            current_line = parse_dst_starting_line_num(l)

        elif l.startswith("-"):
            # Ignore
            pass

        elif l.startswith("+"):
            lines_set.add(current_line)
            current_line += 1

        elif l.startswith("\\"):
            # Line of type:
            #
            #     \ No newline at end of file
            #
            # We just ignore it
            pass

        else:
            raise ValueError('Strange line: "' + l + '"')


def parse_dst_starting_line_num(line):
    """
    >>> parse_dst_starting_line_num("@@ -7,2 +6,2 @@")
    6
    >>> parse_dst_starting_line_num("@@ -12 +10 @@")
    10
    """
    startIndex = line.find('+') + 1
    endIndex1 = line.find(',', startIndex)
    endIndex2 = line.find(' ', startIndex)
    if endIndex1 != -1:
        endIndex = endIndex1
    if endIndex2 != -1 and (endIndex1 == -1 or endIndex2 < endIndex):
        endIndex = endIndex2
    numStr = line[startIndex:endIndex]
    return int(numStr)


BASE_COMMIT = "13072373c42078a38432bd4313458d7648e30672"

if __name__ == "__main__":

    diff_output_b = subprocess.check_output(["git", "diff", "--unified=0", BASE_COMMIT])
    diff_output = bytes.decode(diff_output_b, encoding='utf-8')

    changes = process_diff(iter(diff_output.splitlines()))

    warnings_b = subprocess.check_output(["./tools/style_check_xcode.sh"])
    warnings = bytes.decode(warnings_b, encoding='utf-8')

    for w in warnings.splitlines():
        m = re.match(r"^(?P<path>[^:]*):(?P<line>[^:]*):", w)
        path = m.group('path')
        line = int(m.group('line'))

        line_changes = changes.get(os.path.normpath(path), set())
        if line in line_changes:
            print(w)
