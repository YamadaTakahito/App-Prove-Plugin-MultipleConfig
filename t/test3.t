#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use DBI;
use Redis;

subtest 'test3' => sub {
    my $config_path = $ENV{PERL_MULTI_DB_DSN};
    print "\n $0 uses $config_path\n";
    my $conf = do $config_path;

    my $dbh = DBI->connect($conf->{DB}->{uri}, $conf->{DB}->{username}, $conf->{DB}->{password});
    $dbh->do("INSERT INTO example values (1, 'name1')");

    my $redis = Redis->new ( server => $conf->{REDIS}->{server});
    $redis->set($0, $conf);

    ok 1;
};

done_testing();
