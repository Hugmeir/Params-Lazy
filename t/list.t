use strict;
use warnings;

use Test::More;
use Params::Lazy;

my @test;
sub test_delay {
    my ($delayed, $results, $test) = @_;
    
    my $x = force($delayed);
    
    if (@$results) {
        is($x, $results->[-1], "");
    }
    
    my @x = force($delayed);
    is_deeply(\@x, $results, "Can handle multiple return values: $test");
    
    my $f = join "", "<", force($delayed), ">\n";
    is(
        $f,
        join("", "<", @$results, ">\n"),
        "returning lists works when used as part of an expression: $test"
    );
    
    return 1..10;
}

BEGIN { Params::Lazy::cv_set_call_checker_delay(\&test_delay, '^$;$') }

my @ret1 = test_delay(
    map({ push @test, "map: $_\n"; "map: $_\n" } 1..5),
    [ map "map: $_\n", 1..5 ],
    "map"
);

is_deeply(\@ret1, [1..10], "..and it doesn't corrupt the stack");

#is_deeply(\@tests, )

my @ret2 = test_delay(
    grep(undef, 1..70),
    [  ],
    "grep returning an empty list"
);

is_deeply(\@ret2, [1..10], "..and it doesn't corrupt the stack");


sub empty {}

my @ret3 = test_delay(
    empty(),
    [  ],
    "sub empty {}"
);

is_deeply(\@ret3, [1..10], "..and it doesn't corrupt the stack");

done_testing;