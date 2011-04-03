package AberMUD;
use Moose;
use Bread::Board::Declare;

our $VERSION = '0.01';

has controller => (
    is           => 'ro',
    isa          => 'AberMUD::Controller',
    handles      => [ qw(run) ],
    lifecycle    => 'Singleton',
    dependencies => [
        'universe',
        'storage',
        'special_composite',
        'command_composite',
    ],
);

has universe => (
    is        => 'ro',
    isa       => 'AberMUD::Universe',
    lifecycle => 'Singleton',
);

has storage => (
    is        => 'ro',
    isa       => 'AberMUD::Storage',
    lifecycle => 'Singleton',
);

has command_composite => (
    is        => 'ro',
    isa       => 'AberMUD::Input::Command::Composite',
    lifecycle => 'Singleton',
);

has special_composite => (
    is        => 'ro',
    isa       => 'AberMUD::Special',
    lifecycle => 'Singleton',
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
