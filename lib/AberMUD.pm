package AberMUD;
use Moose;
use Bread::Board::Declare;

use AberMUD::Special;

our $VERSION = '0.01';

has backend_class => (
    is        => 'ro',
    value     => 'AberMUD::Backend::Reflex',
    lifecycle => 'Singleton',
);

has backend_params => (
    is        => 'ro',
    isa       => 'Ref',
    block     => sub { [ qw/port input_states storage/ ] },
    lifecycle => 'Singleton',
);

has controller => (
    is           => 'ro',
    isa          => 'AberMUD::Controller',
    handles      => [ qw(run) ],
    lifecycle    => 'Singleton',
    dependencies => [
        'universe',
        'storage',
        'backend_class',
        'backend_params',
        'command_composite',
        'special',
    ],
);

has universe => (
    is           => 'ro',
    isa          => 'AberMUD::Universe',
    block        => sub {
        my $service = shift;
        my $u = $service->param('storage')->lookup_universe();

        #$u->special($service->param('special'));
        $u->meta->get_attribute('special')->set_value($u, $service->param('special'));

        return $u;
    },
    lifecycle    => 'Singleton',
    dependencies => ['storage', 'special'],
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

has special => (
    is        => 'ro',
    isa       => 'AberMUD::Special',
    block     => sub {
        my $service = shift;
        my $special = AberMUD::Special->new;
        $special->load_plugins(
            universe => $service->param('universe'),
        );
        return $special;
    },
    lifecycle => 'Singleton',
    dependencies => ['universe'],
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
