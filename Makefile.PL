use inc::Module::Install;

name           'AberMUD';
all_from       'lib/AberMUD.pm';

build_requires 'Test::More';
requires       'MooseX::POE';
requires       'MUD';
requires       'KiokuDB::Backend::DBI';

auto_install;
WriteAll;

