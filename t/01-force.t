use strict;
use warnings;

print "1..3\n";

sub delay {
   my $code = shift;
   print("ok 1 - Inside the delayed sub\n");
   force($code);
   print("ok 3 - After the delayed code\n");
}

use Params::Lazy delay => "^";

delay print("ok 2 - Delayed code\n");

