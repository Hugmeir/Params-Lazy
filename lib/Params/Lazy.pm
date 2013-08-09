package Params::Lazy;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Carp;

# The call checker API is available on newer Perls;
# making the dependency on D::CC conditional lets me
# test this on an uninstalled blead.
use if $] < 5.014, "Devel::CallChecker";

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = "force";
our @EXPORT_OK = "force";

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Params::Lazy', $VERSION);

sub import {
    my $self = shift;
    while (@_) {
        my ($name, $proto) = splice(@_, 0, 2);
        if (grep !defined, $name, $proto) {
           croak("yadda");
        }

        if ($name !~ /::/) {
           $name = scalar caller() . "::" . $name;
        }

        my $glob = do { no strict "refs"; *$name };

        Params::Lazy::cv_set_call_checker_delay(*{$glob}{CODE}, $proto);
    }

    $self->export_to_level(1);
}

1;

=head1 NAME

Params::Lazy - The great new Params::Lazy!

=head1 VERSION

Version 0.01

=cut



=head1 SYNOPSIS

    sub delay {
        say "One";
        force($_[0]);
        say "Three";
    }
    use Params::Lazy delay => '^';

    delay say "Two"; # Will output One, Two, Three

    sub fakemap {
       my $delayed = shift;
       my @retvals;
       push @retvals, force($delayed) for @_;
       return @retvals;
    }
    use Params::Lazy fakemap => '^@';

    my @goodies = fakemap "<$_>", 1..10; # same as map "<$_>", 1..10;
    ...
    
    sub fakegrep (&@) {
        my $delayed = shift;
        my $coderef = ref($delayed) eq 'CODE';
        my @retvals;
        for (@_) {
            if ($coderef ? $delayed->() : force($delayed)) {
                push @retvals, $_;
            }
        }
    }
    use Params::Lazy fakegrep => ':@';
    
    say fakegrep { $_ % 2 } 9, 16, 25, 36;
    say fakegrep   $_ % 2,  9, 16, 25, 36;

=head1 DESCRIPTION

The Params::Lazy module provides a way to transparently create lazy
arguments for a function, without the callers being aware that anything
unusual is happening under the hood.

You can enable a lazy argument by defining a function normally, then
C<use> the module, followed by the function name, and a 
prototype-looking string.  Besides the normal characters allowed in a
prototype, that string takes two new options: A caret (C<^>) which means
"make this argument lazy", and a colon (C<:>), which will be explained
later.
After that, when the function is called, instead of receiving the
result of whatever expression the caller put there, the delayed
arguments will instead be a simple scalar reference.  Only if you
pass that variable to C<force()> will the delayed expression be run.

The colon (C<:>) is special cased to work with the C<&> prototype. 
The gist of it is that, if the expression is something that the
C<&> prototype would allow, it stays out of the way and gives you that.
Otherwise, it gives you a delayed argument you can use with C<force()>.

=head1 EXPORT

=head2 force($delayed)

Runs the delayed code.

=head1 LIMITATIONS

Strange things will happen if you goto LABEL out of a lazy argument.

It's also important to note that delayed arguments are *not* closures,
so storing them for later use will likely lead to crashes, segfaults,
and a general feeling of malignancy to descend upon you, your family,
and your cat.  Passing them to other functions should work fine, but
returning them to the place where they were delayed is generally a
bad idea.

Throwing an exception within a delayed eval might not work properly
on older Perls (particularly, the 5.8 series).  Similarly, there's
a bug in Perl 5.10.1 that makes delaying a regular expression likely
to crash the program.

Finally, delayed arguments, although intended to be faster & more light
weight than coderefs, are currently about twice as slow as passing
a coderef and dereferencing it, so beware!

=head1 AUTHOR

Brian Fraser, C<< <fraserbn at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-params-lazy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Lazy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Params::Lazy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Params-Lazy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Params-Lazy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Params-Lazy>

=item * Search CPAN

L<http://search.cpan.org/dist/Params-Lazy/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Brian Fraser.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Params::Lazy
