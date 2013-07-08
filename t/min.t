use strict;
use warnings;
use Params::Lazy;

use Test::More;

sub delayed {
    my @retvals;
    push @retvals, force($_[1]);
    push @retvals, force($_[0]);
    push @retvals, force($_[2]);

    return @retvals;
}

BEGIN { Params::Lazy::cv_set_call_checker_delay(\&delayed, '^^^$') }

my @retvals = delayed
                  print("ok 3\n"),
                  \print("ok 2\n"),
                  do { print("ok 4\n"); "from do" },
                  print("ok 1 - This test was fourth in the file, came up first\n");

my $test_builder = Test::More->builder;
$test_builder->current_test(4);

is_deeply(
    \@retvals,
    [\1, 1, "from do"],
    "..and got the right return values"
);


done_testing;
