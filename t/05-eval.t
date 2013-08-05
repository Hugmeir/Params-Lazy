use strict;
use warnings;

use Test::More;

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

lazy_run do {
    eval { die "I died inside an do { eval {} }" }
}; warn "<$@>";

lazy_run eval {
    die "I died inside an eval {}"
}; warn "<$@>";

lazy_run eval q{ die "I died inside an eval STRING" };
warn "<$@>";


done_testing;
