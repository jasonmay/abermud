package AberMUD;
use Moose;
use namespace::autoclean;

our $VERSION = '0.01';

has controller => (
    is       => 'rw',
    isa      => 'AberMUD::Controller',
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

TODO TODO TODO TODO TODO 

=head1 AUTHOR

Jason May C<< <jason.a.may@gmail.com >>

=head1 LICENSE

You may use this code under the same terms of Perl itself.
