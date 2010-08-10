use inc::Module::Install;

name           'AberMUD';
all_from       'lib/AberMUD.pm';

build_requires 'Test::More';
requires       'Moose';
requires       'MooseX::POE';
requires       'MooseX::ClassAttribute';
requires       'MooseX::Traits';
#requires       'MUD'; XXX
requires       'KiokuDB::Backend::DBI';
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

requires 'Config::General';

requires 'List::Util';
requires 'List::MoreUtils';

install_script glob('script/*.pl');

auto_install;
WriteAll;
