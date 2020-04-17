package App::Prove::Plugin::MultipleConfig;
use strict;
use warnings;

use POSIX::AtFork;
use DBI;

use ConfigCache;

our $VERSION = '0.01';

sub load {
    my ($class, $prove) = @_;

    my @args = @{$prove->{args}};
    foreach (@args) { $_ =~ s/"//g; }
    my $module = shift @args;
    my @configs = @args;
    my $jobs = $prove->{ app_prove }->jobs || 1;
    if (scalar @configs < $jobs){
        die "the number of dsn(" . scalar @configs . ") must be grater than jobs: $jobs.";
    }

    if ($module){
        eval "require $module"  ## no critic
            or die "$@";


        for my $config (@configs){
            my $valid = do $config;
            if (!defined $valid){
                die "argument: $config is invalid";
            }
            $module->can("prepare") ? $module->prepare($config) : die "$module don't have prepare method";
        }
    }

    ConfigCache->set_configs(\@configs);

    $prove->{ app_prove }->formatter('TAP::Formatter::MultipleConfig');
    $prove->{ app_prove }->harness('TAP::Harness::MultipleConfig');

    POSIX::AtFork->add_to_child( \&child_hook );
}


sub child_hook {
    my ($call) = @_;
    ($call eq 'fork') or return;

    my $config = ConfigCache->pop_configs();
    ConfigCache->set_config_by_pid($$, $config);
    $ENV{ PERL_MULTI_DB_DSN } = $config;
}

1;
