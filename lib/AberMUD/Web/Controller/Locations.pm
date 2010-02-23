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

    my $loc = $c->model('dir')->get_loc($loc_str);

    if ($loc) {
        my $new_title       = $c->req->param('new_title');
        my $new_description = $c->req->param('new_description');


        if ($new_title or $new_description) {
            $loc->title($new_title             || $loc->title);
            $loc->description($new_description || $loc->description);
            $c->model('dir')->update($loc);
        }

        $c->stash(loc => $loc);
        $c->stash(
            template => 'locations.look',
        );
        $c->forward($c->view('HTML'));
    }
    else {
        $c->response->body( 'Page not found' );
        $c->response->status(404);
    }
}

sub new_location :Path(/locations/new) {
    my $self    = shift;
    my $c       = shift;

    if ($c->req->param('loc_link')) {
        my $link = $c->req->param('loc_link');
        my $current  = $c->req->param('world_id');
        my $exit     = $c->req->param('exit');

        my $loc = $c->model('dir')->get_loc($current)
        or die sprintf(
            "Could not lookup %s in kiokudb",
            $current
        );

        my $loc_link = $c->model('dir')->get_loc($link)
        or die sprintf(
            "Could not lookup %s (for linking) in kiokudb",
            $link
        );

        $loc->$exit($loc_link);
        $c->model('dir')->update($loc);
        $c->forward('look', [$loc->world_id]);
        return;
    }

    my $action = first { /^edit_/ } keys %{$c->req->params}
        or die "Could not find an appropriate parameter";
    my ($world_id, $exit) = $action =~ /^edit_(\w+)_(\w+)/;
    my $loc = $c->model('dir')->get_loc($world_id);
    warn $world_id;

    if (!$loc) {
        $c->forward('create');
        return;
    }

    if (not any { $exit eq $_ } @{$loc->directions}) {
        $c->response->body("What! That's not even a valid exit. >:(");
        return;
    }

    if ($loc->$exit) {
        $c->response->body('There is already a location there! Hmm ' . $loc->$exit->title);
        return;
    }

    $c->stash(
        loc       => $loc,
        exit      => $exit,
        template  => 'locations.new',
    );
    $c->forward($c->view('HTML'));
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

