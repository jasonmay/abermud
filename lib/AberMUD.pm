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

has storage => (
    is  => 'rw',
    isa => 'AberMUD::Storage',
);

1;

__END__

=head1 NAME

AberMUD - A quest-based MUD flavor

=head1 SYNOPSIS

  my $abermud = AberMUD->new;

=head1 DESCRIPTION

AberMUD is a MUD flavor that is known to be quest-driven and
have a more organized item system.

=head1 RUNNING THE SERVER

You will need to be running io-multiplex-intermediary from git.
Please see L<http://github.com/jasonmay/io-multiplex-intermediary> for
more documentation.

Install all the necessary dependencies and run C<./bin/game.pl [port]>.
The port defaults to 6715 if one is not provided.

=head1 AUTHOR

Jason May C<< <jason.a.may@gmail.com> >>

=head1 LICENSE

You may use this code under the same terms of Perl itself.
