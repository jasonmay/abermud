package AberMUD::Web::Controller::Locations;
use Moose;
use namespace::autoclean;

use List::Util qw(first);
use List::MoreUtils qw(any);
use AberMUD::Location;
use AberMUD::Location::Util qw(directions);
use Data::Dumper;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

AberMUD::Web::Controller::Locations - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub base : Chained PathPart('locations') CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash(heading     => 'AberMUD - Locations');
}

sub index : Path Chained('base') Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched AberMUD::Web::Controller::Locations in Locations.');
}

sub look : Chained('base') PathPart('look') Args(1) {
    my $self    = shift;
    my $c       = shift;
    my $loc_str = shift;

    my $loc = $c->model('kiokudb')->get_loc($loc_str);

    if ($loc) {
        my $new_title       = $c->req->param('new_title');
        my $new_description = $c->req->param('new_description');

        if ($new_title or $new_description) {
            $loc->title($new_title             || $loc->title);
            $loc->description($new_description || $loc->description);
            my $scope = $c->model('kiokudb')->new_scope;
            $c->model('kiokudb')->update($loc);
        }

        $c->stash(
            template    => 'locations/look.tt2',
            loc         => $loc,
            scope       => $c->model('kiokudb')->new_scope,
        );
    }
    else {
        $c->response->body( 'Page not found' );
        $c->response->status(404);
    }
}

sub new_location : Chained('base') PathPart('new') Args(0) {
    my $self    = shift;
    my $c       = shift;

    $c->stash(template => 'locations/new.tt2');

#    if ($c->req->param('loc_link')) {
#        my $link = $c->req->param('loc_link');
#        my $current  = $c->req->param('world_id');
#        my $exit     = $c->req->param('exit');
#
#        my $loc = $c->model('kiokudb')->get_loc($current)
#        or die sprintf(
#            "Could not lookup %s in kiokudb",
#            $current
#        );
#
#        my $loc_link = $c->model('kiokudb')->get_loc($link)
#        or die sprintf(
#            "Could not lookup %s (for linking) in kiokudb",
#            $link
#        );
#
#        $loc->$exit($loc_link);
#        my $scope = $c->model('kiokudb')->new_scope;
#        $c->model('kiokudb')->update($loc);
#        $c->forward('look', [$loc->world_id]);
#        return;
#    }
#
#    if ($c->req->param('new_location')) {
#        my $loc = $c->model('kiokudb')->get_loc(
#            $c->req->param('world_id')
#        );
#        my $new_loc = AberMUD::Location->new(
#            title       => $c->req->param('title'),
#            description => $c->req->param('description'),
#        );
#        my $exit = $c->req->param('exit');
#
#        my $scope = $c->model('kiokudb')->new_scope;
#        $c->model('kiokudb')->txn_do(sub {
#
#            my $new_world_id = $c->model('kiokudb')->gen_world_id($loc->zone);
#            $new_loc->zone($loc->zone);
#            $new_loc->world_id($new_world_id);
#
#            $c->model('kiokudb')->store("location-$new_world_id" => $new_loc);
#            $loc->$exit($new_loc);
#            $c->model('kiokudb')->update($loc);
#        });
#        $c->forward('look', [$loc->world_id]);
#        return;
#    }
#
#    my $action = first { /^edit_/ } keys %{$c->req->params}
#        or die "Could not find an appropriate parameter";
#    my ($world_id, $exit) = $action =~ /^edit_(\w+)_(\w+)/;
#    my $loc = $c->model('kiokudb')->get_loc($world_id);
#    warn $world_id;
#
#    if (!$loc) {
#        $c->forward('create');
#        return;
#    }
#
#    if (not any { $exit eq $_ } directions()) {
#        $c->response->body("What! That's not even a valid exit. >:(");
#        return;
#    }
#
#    if ($loc->$exit) {
#        $c->response->body('There is already a location there! Hmm ' . $loc->$exit->title);
#        return;
#    }
#
#    $c->stash(
#        template  => 'locations/new.tt2',
#        loc       => $loc,
#        scope     => $c->model('kiokudb')->new_scope,
#        exit      => $exit,
#    );
#    $c->forward($c->view('HTML'));
}

sub default :Local {
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

