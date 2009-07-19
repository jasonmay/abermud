#!/usr/bin/env perl
package AberMUD::Input::Dispatcher;
use Moose;
extends 'Path::Dispatcher';

no Moose;
__PACKAGE__->meta->make_immutable;

require AberMUD::Input::Dispatcher::Rule;

1;

