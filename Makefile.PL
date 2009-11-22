use inc::Module::Install;

name           'AberMUD';
all_from       'lib/AberMUD.pm';

build_requires 'Test::More';
requires       'MooseX::POE';
#requires       'MUD'; XXX
requires       'KiokuDB::Backend::DBI';
requires       'File::Basename';
requires       'String::Util';
requires       'Carp';
requires       'Path::Dispatcher';
requires       'Bread::Board';

auto_install;
WriteAll;

