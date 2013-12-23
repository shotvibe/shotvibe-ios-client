#!/bin/sh -e

# I have chosen to use the "perlcritic" format, since it is one of the formats
# that the Jenkins Violations plugin supports
#
# http://search.cpan.org/~thaljef/Perl-Critic-1.121/lib/Perl/Critic/Violation.pm
# https://wiki.jenkins-ci.org/display/JENKINS/Violations
# https://github.com/jenkinsci/violations-plugin/blob/master/src/main/java/hudson/plugins/violations/types/perlcritic/PerlCriticParser.java

./tools/uncrustify -c uncrustify.cfg -l OC -f "$1" | ./tools/diffstyle.py --msg-template="{path}: {msg} at line {line}, column {col}. . (Severity: 1)" "$1"
