use strict;
use warnings;

use Test::More;

sub delay {
   my $code = shift;
   print("ok 1 - Inside the delayed sub\n");
   force($code);
   print("ok 3 - After the delayed code\n");
}

use Params::Lazy delay => "^";

delay print("ok 2 - Delayed code\n");

my $builder = Test::More->builder();
$builder->current_test(3);

my $msg = "force() requires a delayed argument";
eval { force(undef) };
like($@, qr/\Q$msg/, "force(undef) fails gracefully");
eval { force(1) };
like($@, qr/\Q$msg/, "force(1) fails gracefully");
eval { force(\1) };
like($@, qr/\Q$msg/, "force(\\1) fails gracefully");

done_testing;
