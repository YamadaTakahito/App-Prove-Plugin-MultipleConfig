package App::Prove::Plugin::MultipleConfig;
use strict;
use warnings;

use POSIX::AtFork;
use Cache::FastMmap;
use Proc::ProcessTable;
use Array::Diff;
use DBI;

our $VERSION = '0.01';

our $CACHE = Cache::FastMmap->new(cache_size => '1k');
our $DSN_KEY = 'DSN';

our $TABLE = Proc::ProcessTable->new();

sub load {
    my ($class, $prove) = @_;

    my @args = @{$prove->{args}};
    foreach (@args) { $_ =~ s/"//g; }
    my $module = shift @args;
    my @dsnes = @args;
    my $jobs = $prove->{ app_prove }->jobs || 1;
    if (scalar @dsnes < $jobs){
        die "the number of dsn(" . scalar @dsnes . ") must be grater than jobs: $jobs.";
    }

    if ($module){
        eval "require $module"  ## no critic
            or die "$@";


        for my $dsn (@dsnes){
            my $valid = do $dsn;
            if (!defined $valid){
                die "argument: $dsn is invalid";
            }
            $module->can("prepare") ? $module->prepare($dsn) : die "$module don't have prepare method";
        }
    }

    $CACHE->clear();
    my %val;
    for my $dsn (@dsnes){
        $val{$dsn} = 0;
    }
    $CACHE->set($DSN_KEY, \%val);
    $prove->{ app_prove }->formatter('TAP::Formatter::MultipleConfig');

    POSIX::AtFork->add_to_child( \&child_hook );
}

sub child_hook {
    my ($call) = @_;
    ($call eq 'fork') or return;

    my $ret_dsn = '';
    while (!$ret_dsn){
        $CACHE->get_and_set($DSN_KEY, sub {
            my ($key, $val) = @_;

            for my $dsn (keys %$val) {
                if ( $val->{ $dsn } == 0 ) {
                    # alloc one from unused
                    $ret_dsn = $dsn;
                    $val->{ $dsn } = $$; # record pid
                    return $val;
                }
            }

            return $val;
        });
        sleep 1 if (!$ret_dsn);
    }

    $ENV{ PERL_MULTI_DB_DSN } = $ret_dsn;
}

{
    package TAP::Formatter::MultipleConfig::Session;
    use parent 'TAP::Formatter::Console::Session';

    sub close_test {
        my ($self) = @_;

        $CACHE->get_and_set($DSN_KEY, sub {
            my ($key, $val) = @_;

            for my $dsn (keys %$val) {
                my $pid = $val->{ $dsn } or next;

                if ( !_pid_lives( $pid ) ) {
                    $val->{ $dsn } = 0; # dealloc
                }
            }
            return $val;
        });

        $self->SUPER::close_test(@_);
    }

    # sub get_closed_pids {
    #     my $pids = @_;
    #     my @running_pids = map { $_->pid } @{$TABLE->table};
    #     my $closed_pids =  Array::Diff->diff($pids, \@running_pids)->deleted;
    #     return $closed_pids;
    # }

    sub _pid_lives {
        my ($pid) = @_;

        my $command = "ps -o pid -p $pid | grep $pid";
        my @lines   = qx{$command};
        return scalar @lines;
    }
}

{
    package TAP::Formatter::MultipleConfig;
    use parent 'TAP::Formatter::Console';

    sub open_test {
        my $self = shift;
        bless $self->SUPER::open_test(@_), 'TAP::Formatter::MultipleConfig::Session';
    }
}

1;
