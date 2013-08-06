use strict;
use warnings;

use Test::More tests => 16;

sub lazy_run { force($_[0]) };

use Params::Lazy lazy_run => '^';

sub runs_eval {
    my $msg = "eval q{ die } inside a sub";
    eval qq{ die '$msg' };
    like($@, qr/\Q$msg/, $msg);

    $msg = "do { eval { die } } inside a sub";
    do { eval { die $msg } };
    like($@, qr/\Q$msg/, $msg);
    
    $msg = "eval { die } inside a sub";
    eval { die $msg };
    like($@, qr/\Q$msg/, $msg);
    
    is(
        eval "10",
        10,
        "eval q{lives} inside a sub"
    );
}

lazy_run runs_eval();
pass("Survived this far without crashing");

is(
    lazy_run(eval q{ 10 }),
    10,
    "lazy_run eval q{ lives } works"
);

my $msg = "eval q{die}";
lazy_run eval qq{ die "$msg" };
like($@, qr/\Q$msg/, $msg);

$msg = "evalbytes q{die}";
lazy_run CORE::evalbytes qq{ die "$msg" };
like($@, qr/\Q$msg/, $msg);

$msg = "eval { eval q{die}; foo; die }";
lazy_run eval {
    eval 'die q{Inner}';
    like($@, qr/Inner/, "eval q{die} inside a delayed eval {}");
    die $msg;
};
like($@, qr/\Q$msg/, $msg);

$msg = "do { eval {die}; foo() }";
lazy_run do {
    eval { die $msg };
    pass("Code after an eval { die } inside a do.");
};
like($@, qr/\Q$msg/, $msg);

$msg = "eval {die}";
lazy_run eval {
    die $msg
};
like($@, qr/\Q$msg/, $msg);

$msg = "map eval { die }, 1..10";
lazy_run map eval { die $msg }, 1..10;
like($@, qr/\Q$msg/, $msg);

$msg = "map { eval {die}; \$_ } 1..10";
my @ret = lazy_run map { eval { die $msg }; $_ } 1..10;
like($@, qr/\Q$msg/, $msg);
is_deeply(\@ret, [1..10]);

