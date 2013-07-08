use strict;
use warnings;
use Params::Lazy;

use Carp qw(carp croak confess);
use Test::More;

sub dies      { die "I died"           }
# test carp() even though it's not really a death,
# since it tends to give "Attempt to free unreferenced scalar"
# warnings
sub carps     { carp("I carped")       }
sub croaks    { croak("I croaked")     }
sub confesses { confess("I confessed") }


sub lazy_death {
    eval { force($_[0]) };
    warn "<$@>";
}

BEGIN { Params::Lazy::cv_set_call_checker_delay(\&lazy_death, '^') }

lazy_death die "DEATH";
#lazy_death dies();
#lazy_death carps();
#lazy_death croaks();
#lazy_death confesses();

sub call_lazy_death {
    lazy_death die "death";
    lazy_death dies();
    lazy_death carps();
    lazy_death croaks();
    lazy_death confesses();
}

#call_lazy_death();