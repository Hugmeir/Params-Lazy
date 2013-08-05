package Params::Lazy;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Carp;

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

Quick summary of what the module does.

Perhaps a little code snippet.

    sub fakemap {
       my $delayed = shift;
       my @retvals;
       push @retvals, force($delayed) for @_;
       return @retvals;
    }
    use Params::Lazy fakemap => "^@";

    my @goodies = fakemap "<$_>\n", 1..10;
    ...

=head1 EXPORT

=head2 force($delayed)

Runs the delayed code.

=head1 LIMITATIONS

At the moment, running a delayed eval {} or eval STRING will cause
Perl to panic.  That is, this:

    delayed eval { ... };

Is no good, although as a minor workaround, this:

    sub delayed {
       my $ret = eval { force($_[0]) };
       ...
    }

    delayed die();

will work.

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
