package AberMUD::Web::Controller::Players;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

AberMUD::Web::Controller::Players - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub id : PathPart('players/id') Chained('/') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;


    my $scope = $c->model('dir')->new_scope();
    my $p = $c->model('dir')->lookup("player-$id") or do {
        $c->response->body(qq|Player '$id' doesn't exist.|);
        $c->detach();
        return;
    };

    $c->stash(
        id     => $id,
        player => $p
    );
}

sub require_id : PathPart('players/id') Chained('/') Args(0) {
    my ( $self, $c) = @_;

    $c->response->body('Sorry, what?');
}

sub player_stats : PathPart('') Chained('id') Args(0) {
    my ( $self, $c) = @_;


    my $id = $c->stash->{id};
    my $p  = $c->stash->{player};


    my $data = join "<br />\n", map { ucfirst() . ': ' . $p->$_ }
        qw/name level score damage armor basestrength basemana/;

    $c->response->body($data);
}

sub reset_password : PathPart Chained('id') Args(0) {
    my ( $self, $c ) = @_;

    my $player = $c->stash->{player};

    if (my $new_pass = $c->req->param('new_pass')) {
        $player->password(crypt($new_pass, lc($player->name)));
        $c->model('dir')->scoped_txn(sub { $c->model('dir')->update($player) });

        $c->response->body($player->name . "'s password has been updated!");
        $c->detach();

    }

    $c->response->body(<<HTML);
    <html>
    <body>
    <form method="post">
    <input name="new_pass" />
    <input type="submit" />
    </form>
    </body>
    </html>
HTML
}

sub default :Local {
    my ($self, $c) = @_;

    $c->response->body('404!');
}

=head1 AUTHOR

jasonmay

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
