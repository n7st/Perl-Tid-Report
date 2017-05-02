package Tid::Report;

use 5.006;
use strict;
use warnings;

use base "Tid";

use constant { TOTAL_KEY => "_total" };

our $VERSION = "0.01";

sub timesheet {
    my $self = shift;
    my $args = shift || {};

    my %long_timesheet  = ($self->TOTAL_KEY => 0);
    my %short_timesheet = ($self->TOTAL_KEY => 0);
    my $active_workspace_name;

    foreach my $workspace (@{$self->{workspaces}}) {
        my ($long, $short) = $self->_report($workspace, $args);

        if ($workspace->{active}) {
            $active_workspace_name = $workspace->{name};
        }

        if ($long) {
            $long_timesheet{$workspace->{name}} = $long;
            $long_timesheet{$self->TOTAL_KEY} += $long->{$self->TOTAL_KEY};
        }

        if ($short) {
            $short_timesheet{$workspace->{name}} = $short;
            $short_timesheet{$self->TOTAL_KEY} += $short->{$self->TOTAL_KEY};
        }
    }

    $self->_resume($active_workspace_name);

    if ($args->{format} && lc $args->{format} eq "long") {
        return $self->_pretty_print_long(\%long_timesheet);
    } else {
        return $self->_pretty_print_short(\%short_timesheet);
    }
}

sub _pretty_print_short {
    my $self      = shift;
    my $timesheet = shift;

    my $output;

    foreach my $workspace (sort keys %{$timesheet}) {
        next if $workspace eq $self->TOTAL_KEY;

        my $total_seconds = $timesheet->{$workspace}->{$self->TOTAL_KEY};
        my $total         = $self->_convert_seconds_to_date_str($total_seconds);

        $output .= sprintf("Project: %s (Total: %s)\n", $workspace, $total);
        $output .= $self->_pretty_print_entries($timesheet->{$workspace});
    }

    $output .= sprintf("\nTotal: %s\n",
        $self->_convert_seconds_to_date_str($timesheet->{$self->TOTAL_KEY}),
    );

    return $output;
}

sub _pretty_print_entries {
    my $self    = shift;
    my $entries = shift;

    my $output;

    foreach my $entry (keys %{$entries}) {
        next if $entry eq $self->TOTAL_KEY;

        my $duration = $self->_convert_seconds_to_date_str($entries->{$entry});

        $output .= sprintf("  - %s: %s\n", $entry, $duration);
    }

    return $output;
}

sub _pretty_print_long {
    my $self      = shift;
    my $timesheet = shift;

    my ($output, $last_line);

    $timesheet = $self->_format_timesheet_by_date($timesheet);

    foreach my $date (sort keys %{$timesheet}) {
        if ($date eq $self->TOTAL_KEY) {
            $last_line = sprintf("\nTotal: %s\n",
                $self->_convert_seconds_to_date_str($timesheet->{$date}),
            );
        } else {
            $output .= sprintf("Date: %s\n", $date);

            foreach my $workspace (keys %{$timesheet->{$date}}) {
                $output .= sprintf("  Project: %s\n", $workspace);
                $output .= $self->_pretty_print_entries($timesheet->{$date}->{$workspace});
            }
        }
    }

    $output .= $last_line;

    return $output;
}

sub _format_timesheet_by_date {
    my $self  = shift;
    my $input = shift;

    my %output = ($self->TOTAL_KEY => 0);

    foreach my $workspace (keys %{$input}) {
        next if $workspace eq $self->TOTAL_KEY;

        foreach my $date (keys %{$input->{$workspace}}) {
            next if $date eq $self->TOTAL_KEY;

            foreach my $entry (keys %{$input->{$workspace}->{$date}}) {
                my $duration = $input->{$workspace}->{$date}->{$entry};

                if ($entry eq $self->TOTAL_KEY) {
                    $output{$self->TOTAL_KEY} += $duration;
                }

                $output{$date}->{$workspace}->{$entry} = $duration;
            }
        }
    }

    return \%output;
}

sub _report {
    my $self      = shift;
    my $workspace = shift;
    my $args      = shift;

    my ($output, $success, %long, %short);
    my $total = 0;

    ($output, $success) = $self->cmd([ "workspace", "switch", $workspace->{name} ]);

    return unless $success;

    my @command = ("report", "--no-summary", "-f={{.Timesheet}}/{{.Note}}/{{.Duration}}");

    push @command, sprintf("-s=%s", $args->{start}) if $args->{start};
    push @command, sprintf("-e=%s", $args->{end})   if $args->{end};

    ($output, $success) = $self->cmd(\@command);

    return unless $success;

    foreach my $entry (split "\n", $output) {
        my ($date, $note, $duration) = split "/", $entry;
        my $duration_in_seconds = $self->_convert_date_str_seconds($duration);

        $short{$note}                    ||= 0;
        $long{$date}->{$note}            ||= 0;
        $long{$date}->{$self->TOTAL_KEY} ||= 0;

        $short{$note}                    += $duration_in_seconds;
        $long{$date}->{$note}            += $duration_in_seconds;
        $long{$date}->{$self->TOTAL_KEY} += $duration_in_seconds;
        $total                           += $duration_in_seconds;
    }

    $short{$self->TOTAL_KEY} = $total;
    $long{$self->TOTAL_KEY}  = $total;

    return (\%long, \%short);
}

1;
__END__

=head1 NAME

Tid::Report - Timesheet reports across multiple Tid workspaces.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Tid::Report collects data from the Tid time tracking software's workspaces and
formats it.

    use Tid::Report;

    my $tid = Tid::Report->new();

    my $output = $tid->timesheet({
        format => "short",    # or long
        start  => 2017-05-01, # default is today
        end    => 2017-05-31, # default is today
    });

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

