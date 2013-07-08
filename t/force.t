use strict;
use warnings;

use Test::More;
use Delay;

BEGIN {
    Delay::cv_set_call_checker_delay(\&delay, "^");
}

sub delay {
   my $code = shift;
   warn "preforce";
   warn force($code);
   warn "postforce";
}



delay warn("doof");