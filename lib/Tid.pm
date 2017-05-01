package Tid;

use 5.006;
use strict;
use warnings;

use IPC::Run 'run';
use Time::Piece;

our $VERSION  = "0.01";

sub new {
    my $self = bless {}, shift;
    my $args = shift;

    $self->{location} = $args->{location} || "tid";

    my ($output, $success) = $self->_active_task();

    # "No timer to check the status of" is a successful response in Tid
    if ($success && $output !~ /No timer to check the status of/) {
        $self->{active_task} = $output;
    }

    $self->{workspaces} = $self->_workspace_information();

    return $self;
}

sub cmd {
    my $self = shift;
    my $args = shift;

    my $exit_code = run [ $self->{location}, @{$args} ], '>', \my $output;

    chomp $output;

    return ($output, $exit_code);
}

sub _active_task {
    my $self = shift;

    return $self->cmd([ "status", "-f={{.ShortHash}}" ]);
}

sub _convert_date_str_seconds {
    my $self  = shift;
    my $input = shift;

    my $time_piece = $self->_convert_date_str_time_piece($input);

    return $time_piece->[9];
}

sub _convert_seconds_to_date_str {
    my $self    = shift;
    my $seconds = shift;

    my $time_piece = gmtime($seconds);

    return sprintf("%dd%dh%dm%ds",
        $time_piece->[7],
        $time_piece->[2],
        $time_piece->[1],
        $time_piece->[0],
    );
}

sub _convert_date_str_time_piece {
    my $self  = shift;
    my $input = shift;

    my ($hours, $minutes, $seconds) = $input =~ /(\d{1,2}h)?(\d{1,2}m)?(\d{1,2}s)?$/;

    $hours   ||= "0h";
    $minutes ||= "0m";
    $seconds ||= "0s";

    my $duration   = sprintf("%s%s%s", $hours, $minutes, $seconds);
    my $time_piece = Time::Piece->strptime($duration, "%Hh%Mm%Ss");

    return $time_piece;
}

sub _resume {
    my $self                  = shift;
    my $active_workspace_name = shift;

    if ($active_workspace_name) {
        # Return to the originally active workspace
        $self->cmd([ "workspace", "switch", $active_workspace_name ]);
    }

    if ($self->{active_task}) {
        # If there was an active task when the report started, resume it
        $self->cmd([ "resume", $self->{active_task} ]);
    }

    return 1;
}

sub _workspace_information {
    my $self = shift;

    my ($output, $success) = $self->cmd([ "workspace", "ls" ]);

    return unless $success;

    my @workspace_rows = split "\n", $output;
    my @workspaces;

    foreach my $name (@workspace_rows) {
        my @row  = split / /, $name;
        my $flag = pop @row;

        push @workspaces, {
            name   => $flag && $flag eq '*' ? join ' ', @row : $name,
            active => $flag && $flag eq '*' ? 1 : 0,
        };
    }

    return \@workspaces;
}

1;
__END__

=head1 NAME

Perl interface to the Tid time tracking software.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

This class provides a base for formatted multi-workspace Tid reports.

=head1 AUTHOR

Mike Jones, C<< <mike at netsplit.org.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tid>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tid

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

