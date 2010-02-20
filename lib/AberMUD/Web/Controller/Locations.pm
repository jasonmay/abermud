package AberMUD::Web::Controller::Locations;
use Moose;
use namespace::autoclean;

use List::Util qw(first);
use List::MoreUtils qw(any);

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

AberMUD::Web::Controller::Locations - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched AberMUD::Web::Controller::Locations in Locations.');
}

sub look :Path(/locations/look) {
    my $self    = shift;
    my $c       = shift;
    my $loc_str = shift;

    my $loc = $c->model('dir')->lookup("location-$loc_str");
    if ($loc) {
        $c->stash(loc => $loc);
        $c->stash(content_template => 'locations.look');
        warn $c->view('TD')->template('locations.outer');
        $c->detach('View::TD');
        $c->response->body($c->view('TD')->template('locations.outer'));
    }
    else {
        $c->response->body( 'Page not found' );
        $c->response->status(404);
    }
}

sub new_location :Path(/locations/new) {
    my $self    = shift;
    my $c       = shift;

    my $action = first { /^edit_/ } keys %{$c->req->params};
    my ($world_id, $exit) = $action =~ /^edit_(\w+)_(\w+)/;
    my $loc = $c->model('dir')->lookup("location-$world_id");

    warn $world_id;
    warn $exit;
    if (!$loc) {
        $c->forward('create');
        return;
    }

    if (not any { warn $_;$exit eq $_ } @{$loc->directions}) {
        $c->body("What! That's not even a valid exit. >:(");
        return;
    }

    if ($loc->$exit) {
        $c->body('There is already a location there! Hmm');
        return;
    }

    $c->stash(loc => $loc);
    $c->stash(content_template => 'locations.new');
    $c->response->body($c->view('TD')->template('locations.outer'));
    $c->detach('View::TD');
}

sub create :Path(/locations/create) {
    my $self = shift;
    my $c    = shift;
    $c->response->body("I have no idea what I'm doing :D");
}

sub default :Path(/locations) {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

