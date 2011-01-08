use inc::Module::Install;

name           'AberMUD';
all_from       'lib/AberMUD.pm';

build_requires 'Test::More';
requires  'Hash::Merge';
requires  'Clone';
requires       'Moose';
requires       'MooseX::POE';
requires       'MooseX::Traits' => '0.09';
#requires       'MUD'; XXX
requires       'KiokuDB::Backend::DBI';
requires       'KiokuX::Model';
requires       'File::Basename';
requires       'String::Util';
requires       'Carp';
requires       'Path::Dispatcher';
requires       'Bread::Board';
requires       'Try::Tiny';
requires       'DateTime';

requires 'Catalyst::Runtime' => '5.8002';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::View::TD';


requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Authentication::Store::KiokuDB';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::Store::KiokuDB';
requires 'Catalyst::Plugin::Session::State::Cookie';

requires 'Config::General';

requires 'List::Util';
requires 'List::MoreUtils';

install_script glob('script/*.pl');

auto_install;
WriteAll;
