#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 14;

BEGIN {
    # main stuff
    use_ok 'AberMUD::Universe';
    use_ok 'AberMUD::Player';
    use_ok 'AberMUD::Util';

    # input states
    use_ok 'AberMUD::Input::State::Login::Name';
    use_ok 'AberMUD::Input::State::Login::Password';
    use_ok 'AberMUD::Input::State::Login::Password::New';
    use_ok 'AberMUD::Input::State::Login::Password::Confirm';
    use_ok 'AberMUD::Input::State::Game';

    # dispatcher stuff
    use_ok 'AberMUD::Input::Dispatcher';
    use_ok 'AberMUD::Input::Dispatcher::Rule';

    # commands
    use_ok 'AberMUD::Input::Command';
    use_ok 'AberMUD::Input::Command::Who';
    use_ok 'AberMUD::Input::Command::Chat';
    use_ok 'AberMUD::Input::Command::Look';
};

