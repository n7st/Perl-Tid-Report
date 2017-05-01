package Tid::Report;

use 5.006;
use strict;
use warnings;

use Data::Printer;

our $VERSION = "0.01";

use base "Tid";

sub timesheet {
    my $self = shift;
    my $args = shift || {};

    my %long_timesheet  = (_total => 0);
    my %short_timesheet = (_total => 0);
    my $active_workspace_name;

    foreach my $workspace (@{$self->{workspaces}}) {
        my ($long, $short) = $self->_report($workspace, $args);

        if ($workspace->{active}) {
            $active_workspace_name = $workspace->{name};
        }

        if ($long) {
            $long_timesheet{$workspace->{name}} = $long;
            $long_timesheet{_total} += $long->{_total};
        }

        if ($short) {
            $short_timesheet{$workspace->{name}} = $short;
            $short_timesheet{_total} += $short->{_total};
        }
    }

    if ($active_workspace_name) {
        # Return to the originally active workspace
        $self->cmd([ "workspace", "switch", $active_workspace_name ]);
    }

    if ($self->{active_task}) {
        printf STDOUT "Resuming %s", $self->{active_task};
        # If there was an active task when the report started, resume it
        $self->cmd([ "resume", $self->{active_task} ]);
    }

    p %short_timesheet;
    p %long_timesheet;

    return 1;
}

sub _report {
    my $self      = shift;
    my $workspace = shift;
    my $args      = shift;

    my ($output, $success, %long, %short);
    my $total = 0;

    ($output, $success) = $self->cmd([ "workspace", "switch", $workspace->{name} ]);

    return unless $success;

    my @command = (
        "report", "--no-summary", "-f={{.Timesheet}}/{{.Note}}/{{.Duration}}",
    );

    push @command, sprintf("-s=%s") if $args->{start};
    push @command, sprintf("-e=%s") if $args->{end};

    ($output, $success) = $self->cmd(\@command);

    return unless $success;

    foreach my $entry (split "\n", $output) {
        my ($date, $note, $duration) = split "/", $entry;
        my $duration_in_seconds = $self->_convert_date_str_seconds($duration);

        $short{$note}          ||= 0;
        $long{$date}->{$note}  ||= 0;
        $long{$date}->{_total} ||= 0;

        $short{$note}          += $duration_in_seconds;
        $long{$date}->{$note}  += $duration_in_seconds;
        $long{$date}->{_total} += $duration_in_seconds;
        $total                 += $duration_in_seconds;
    }

    $short{_total} = $total;
    $long{_total}  = $total;

    return (\%long, \%short);
}

1;
__END__

=head1 NAME

Tid::Report - The great new Tid::Report!

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Tid::Report;

    my $foo = Tid::Report->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 AUTHOR

Mike Jones, C<< <mike at netsplit.org.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tid>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tid::Report


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tid>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tid>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tid>

=item * Search CPAN

L<http://search.cpan.org/dist/Tid/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Mike Jones.

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

