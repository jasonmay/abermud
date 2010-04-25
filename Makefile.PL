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

auto_install;
WriteAll;

