use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'OpusVL-AppKitX-Preferences';
all_from 'lib/OpusVL/AppKitX/Preferences.pm';
license  'perl';

requires 'OpusVL::AppKit';
requires 'OpusVL::Preferences';
requires 'Moose';
requires 'namespace::autoclean';

build_requires 'Catalyst::Runtime' => '5.80015';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More' => '0.88';

author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Pod' => '1.14';

author_tests 't/author';

resources repository => 'ssh://git/srv/git/OpusVL-AppKitX-Preferences';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/OpusVL/AppKitX/Preferences.pm > README")
        and die $!;
}

WriteAll();
