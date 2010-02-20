#!/usr/bin/env perl
package AberMUD::Web::View::TD::Location;
use strict;
use warnings;
use Template::Declare::Tags;
use Data::Dumper;

template 'locations.outer' => sub {
    my $class = shift;
    my $c     = shift;
    my $inner_html = $c->stash->{content_template};
#    $c->detach('View::TD');

    html {
        head {
            title { 'AberMUD::Web KiokuDB Management Interface' }
            link {
                attr {
                    rel => 'stylesheet',
                    href => '/static/css/main.css',
                    type => 'text/css',
                    media => 'screen',
                    charset => 'utf-8',
                }
            }
        }
        body {
            div {
                attr { id => 'topmain'}
                h1 { 'AberMUD - Locations' }
            }
            div {
                attr { id => 'sidenav'}
                'foo bar'
            }
            div {
                attr { id => 'contentmain' };
                show $inner_html, $c;
            }
            div {
                attr { id => 'footer' }
                'No rights reserved.'
            }
        }
    };
};

template 'locations.look' => sub {
    my $class = shift;
    my $c     = shift;
    my $loc = $c->stash->{loc};

    h2 { attr { id => 'loc_title' } $loc->title }
    p { attr { class => 'description' } $loc->description }
    form {
        attr {method => 'post', action => '/locations/new'};
        ul {
            attr { class => 'exits' };
            foreach my $exit (@{ $loc->directions }) {
                li {
                    label {
                        attr { class => 'exit' }
                        b { ucfirst("$exit:")  }
                    };
                    if ($loc->$exit) {
                        my $id = $loc->$exit->world_id;
                        a {
                            attr { href => "/locations/look/$id" }
                            $loc->$exit->title
                        }
                    }
                    else {
                        my $id = $loc->world_id;
                        input {
                            attr {
                                type => 'submit',
                                name => "edit_${id}_$exit",
                                value => 'Make an exit'
                            }
                        }
                    }
                }
            }
        }
    }
};

template 'locations.new' => sub {
    html {
        head {
            title { 'AberMUD::Web KiokuDB Management Interface' }
        }
        body {
            h1 { "New Location" }
            label { 'Title: ' }
            input {
                attr {
                    id   => 'new_title',
                    type => 'text',
                    name => "title",
                }
            } br {}
            label { 'Description: ' }
            textarea {
                attr {
                    name => 'description',
                    id   => 'new_description',
                    rows => 5,
                }
            } br {}
            input {
                attr {
                    type  => 'submit',
                    name  => "submit",
                    value => "Submit",
                }
            }
        }
    }
};

1;

