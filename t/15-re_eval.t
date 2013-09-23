use strict;
use warnings;
use Test::More;

BEGIN {
    # XXX These probably work fine in older perls, but
    # for this, I'm not sure if I care to support them.
    plan skip_all => "re_eval not sane in older perls"
        if $] < 5.018;
}

use re 'eval';

use Params::Lazy lazy_run => q(^);
sub lazy_run { force shift }

$_ = "abcdef";
my @here;
my $here = 0;
my ($ret) = lazy_run /^(...)(?{ push @here, [++$here, $^N] })/;

is($ret, "abc", "");
is($here, 1, "");
is_deeply(\@here, [[1, "abc"]]);

my $eval = '(?{ push @here, [++$here, $^N] })';
@here = ();
$_ = "fusrodah";
($ret) = lazy_run /^([^r]+)$eval/;
is($ret, "fus", "");
is($here, 2, "");
is_deeply(\@here, [[2, "fus"]]);

use Params::Lazy no_re_eval => q(^);
sub no_re_eval {
    no re 'eval';
    force shift
}

@here = ();
($ret) = no_re_eval /^([^r]+)$eval/;
is($ret, "fus", "");
is($here, 3, "");
is_deeply(\@here, [[3, "fus"]], "");

my $re = qr/^([^r]+)$eval/;
@here = ();
($ret) = lazy_run $_ =~ $re;
is($ret, "fus", "");
is($here, 4, "");
is_deeply(\@here, [[4, "fus"]]);

my $x = "a";
my $code = 'B(??{$x})';
my @ret = lazy_run "A$x-B$x" =~ /^(A(??{$x}))-($code)$/;
is_deeply(\@ret, [qw(Aa Ba)], "can delay a regex that mixes runtime and literal code blocks");

@here = ();
$_ = 12345;
1 while lazy_run scalar(/\G(.)(?{push @here, $^N})/g);
is_deeply(\@here, [qw(1 2 3 4 5)]);

done_testing;
