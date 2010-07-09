use inc::Module::Install;



version_from		'lib/WWW/Facebook/GraphAPI.pm';
perl_version_from	'lib/WWW/Facebook/GraphAPI.pm';


name        'WWW-Facebook-GraphAPI';
#all_from    'lib/Net/Twitter.pod';

# core

# CPAN
requires    'HTTP::Request';
requires    'JSON::XS';
requires    'LWP::UserAgent'            => 2.032;
requires    'Moose'                     => 0.90;
requires    'Moose::Role';
requires    'namespace::autoclean'      => 0.09;
requires    'URI'                       => 1.40;

test_requires 'Test::More' => 0.88; # for done_testing


#no_index    directory => 'src';
#no_index    directory => 'examples';

# resources
homepage   'http://github.com/jeffl/WWW-Facebook-GraphAPI';
#bugtracker 'http://rt.cpan.org/Public/Dist/Display.html?Name=Net-Twitter';

auto_set_repository;
auto_manifest;
auto_install;

WriteAll;


