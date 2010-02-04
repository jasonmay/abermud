package AberMUD;
use Moose;
use namespace::autoclean;

our $VERSION = '0.01';

has controller => (
    is       => 'rw',
    isa      => 'MUD::Controller',
    required => 1,
    handles  => [ qw(run) ],
);

has universe => (
    is  => 'rw',
    isa => 'AberMUD::Universe',
);

has directory => (
    is  => 'rw',
    isa => 'AberMUD::Directory',
);

1;

__END__

=head1 NAME

AberMUD - A codebase for a quest-based MUD flavor

=head1 SYNOPSIS

  my $abermud = AberMUD->new;

=head1 DESCRIPTION

AberMUD is a MUD flavor that is known to be quest-driven and
have a more organized item system. Unlike most bases for MUD
development, this is a B<framework>, not a B<codebase>.

=head1 RUNNING THE SERVER

In order to run the server, you need to be running an B<intermediary>
that comes with the L<MUD> distribution (C<bin/server.pl>). See
the L<MUD> documentation for more detail on this. Once run, you fire
up C<bin/game.pl> found in this distribution. The default port is
the canonical CDirt port (6715).

=head1 AUTHOR

Jason May C<< <jason.a.may@gmail.com> >>

=head1 LICENSE

You may use this code under the same terms of Perl itself.
