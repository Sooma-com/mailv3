#!/bin/sh
PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
MAIL_CONFIG=/etc/postfix
SENDMAIL="/usr/sbin/postmulti -i postfix-profissional-mx -x /usr/sbin/sendmail -G -i" # NEVER NEVER NEVER use "-t" here.

# Exit codes from <sysexits.h>
EX_TEMPFAIL=75
EX_UNAVAILABLE=69

/usr/bin/perl -ne '$state = 0; while (<>) { $state == 0 && do { do { $state = 1; $_ = <>; print("\n${_}") if (!(/^:.$/)); next; } if /^$/; }; print $_; };' | $SENDMAIL "$@"

exit $?
