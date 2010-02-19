#!/usr/bin/env perl
package AberMUD::Web::View::TD::Location;
use strict;
use warnings;
use Template::Declare::Tags;
use Data::Dumper;

template 'locations.look' => sub {
    my $class = shift;
    my $c     = shift;
    my $loc = $c->stash->{loc};

    html {
        head {
            title { 'AberMUD::Web KiokuDB Management Interface' }
        }
        body {
            h1 { $loc->title }
            p { $loc->description }
            form {
                attr {method => 'post', action => '/locations/new'};
                foreach my $exit (@{ $loc->directions }) {
                    ul {
                        if ($loc->$exit) {
                            my $id = $loc->$exit->world_id;
                            li {
                                outs(b { ucfirst($exit) });
                                outs ': ';
                                a {
                                    attr { href => "/locations/look/$id" }
                                    $loc->$exit->title
                                }
                            }
                        }
                        else {
                            my $id = $loc->world_id;
                            li {
                                outs(b { ucfirst($exit) });
                                outs(': ');
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
                    type => 'text',
                    name => "title",
                }
            } br {}
            label { 'Description: ' }
            textarea { attr { name => 'description' } } br {}
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

