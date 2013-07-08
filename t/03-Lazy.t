use strict;
use warnings;

use Test::More;
use Params::Lazy;

use Devel::Peek;

sub eeyup { warn "      output of warn inside a sub, \@_: <@_>"; return "ledoof", "daslist" }

use Devel::Peek;

sub delay {
    my $private = "Don't look!";
    local $_ = "hohooh";
    print STDERR "in delay: <@_>\n";
    #Dump($_[0]);
    my $x;
    #Dump(\$x);
    $x = force($_[0]);
    #Dump(\$x);
    #() = $x;
    my @x = force($_[0]);
    my $f = join "", "<", force($_[0]), ">\n";
    print STDERR "$f";
    warn force($_[0]);
    print STDERR "print STDERR MAGIC_VAR: ", force($_[0]), "\n";
    warn "foo", force($_[0]), "bar";
    #Dump($x);
    print STDERR "test: ", $x, "\n";
    print STDERR "\@x:<@x>\n<@_>\n";
    #Dump($_[0]);
    print "Exiting the sub\n\n";
}

BEGIN { Params::Lazy::cv_set_call_checker_delay(\&delay, '^;@') }
my @a = qw( a b );
my @b = qw( c d );
print STDERR "before\n";


delay(warn("     this is a warn\n"));
{
my $t = 0;
delay(print("\tlexwrap test ", $t++, "\n"), @b);# for 1..3;
}

delay(rand(111), 1);
delay(scalar eeyup(1231), @a);
delay(eeyup(1231), @a);
delay(scalar map(print("  scalar map: $_\n"), 1..5), 2);
delay(map(print("  map: $_\n"), 1..5), 2);
delay("dollar under: <$_>");

delay(do { eeyup("How do you sir"), "from do" }, 4);
sub sudo_make_me_a_hashref { warn("Making a hashref"); qw(a 1 b 2) }
delay({ sudo_make_me_a_hashref });

#our $private;
#delay(sub { CORE::say $private }->());

print STDERR "after\n";

sub passover {
    my $delay = shift;
    return takes_delayed($delay);
}
sub takes_delayed {
    my $delay = shift;
    CORE::say "Inside takes_delayed:";
    () = force($delay)
};
BEGIN { Params::Lazy::cv_set_call_checker_delay(\&passover, '^;@') }

passover(warn("  I'm a delayed argument!"));

sub return_delayed { return shift }
BEGIN { Params::Lazy::cv_set_call_checker_delay(\&return_delayed, '^;@') }

my $d = do {
    my $foo = "1234561";
    my $f = return_delayed(warn("Returned delayed argument! <$foo>"));
    () = force($f);
    $f;
};

CORE::say "We got this man: $d";
() = force($d);

#ok(1);

#done_testing;
