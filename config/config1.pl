use strict;
use warnings;

my $config = +{
    'DB' => {
        uri => 'DBI:mysql:database=test_db;hostname=127.0.0.1;port=10001',
        username => 'root',
        password => 'root',
    },
    'DB_READ' => {
        uri => 'dbi:mysql:dbname=test_db;hostname=127.0.0.1;port=10001',
        username => 'readonly',
        password => 'readonly',
    },
    'REDIS' => +{
        server => '127.0.0.1:20001',
    },
};

$config;
