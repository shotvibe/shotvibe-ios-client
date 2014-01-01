#!/bin/bash

UNCRUSTIFY=./tools/uncrustify

export UNCRUSTIFY

run_uncrustify() {
  # I have chosen to use the "perlcritic" format, since it is one of the formats
  # that the Jenkins Violations plugin supports
  #
  # http://search.cpan.org/~thaljef/Perl-Critic-1.121/lib/Perl/Critic/Violation.pm
  # https://wiki.jenkins-ci.org/display/JENKINS/Violations
  # https://github.com/jenkinsci/violations-plugin/blob/master/src/main/java/hudson/plugins/violations/types/perlcritic/PerlCriticParser.java

  $UNCRUSTIFY -c uncrustify.cfg -l OC -f "$1" | ./tools/diffstyle.py --msg-template="{path}: {msg} at line {line}, column {col}. . (Severity: 1)" "$1"
  return 0
}

export -f run_uncrustify

# Skip the "Vendor" Directory
find shotvibe -path shotvibe/Vendor -prune -o -name '*.[mh]' -print0 | xargs -0 -n 1 -I {} $BASH -c 'run_uncrustify {}'

true
