package ConfigCache;
use strict;
use warnings;

use Cache::FastMmap;

my $CACHE = Cache::FastMmap->new(cache_size => '1k');
my $CONFIGS_KEY = 'CONFIGS';

sub set_configs {
    my ($self, $configs) = @_;
    $CACHE->set($CONFIGS_KEY, $configs);
}

sub get_config_by_filename {
    my ($self, $filename) = @_;
    my $config = $CACHE->get($filename);
    die "filename:$filename is not found" if (!$config);
    return $config;
}

sub set_config_by_pid {
    my ($self, $pid, $config) = @_;
    $CACHE->set($pid, $config);
}

sub set_config_by_filename {
    my ($self,$filename, $pid) = @_;
    my $config = $CACHE->get($pid);
    $CACHE->set($filename, $config);
}

sub pop_configs {
    my $config = '';

    while (!$config){
        $CACHE->get_and_set($CONFIGS_KEY, sub {
            my (undef, $configs) = @_;
            if (scalar @{$configs} != 0){
                $config = pop @{$configs};
            }
            else {
                sleep 1;
            }
            return $configs;
        });
    }
    return $config;
}

sub push_configs {
    my ($self, $config) = @_;
    $CACHE->get_and_set($CONFIGS_KEY, sub {
        my (undef, $configs) = @_;
        unshift @{$configs}, $config;
        return $configs;
    })
}

1;
