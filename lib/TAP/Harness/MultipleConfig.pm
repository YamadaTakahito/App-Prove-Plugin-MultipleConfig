package TAP::Harness::MultipleConfig;
use strict;
use warnings;

use parent 'TAP::Harness';

use ConfigCache;

sub new {
    my ($self, $params) = @_;
    $params->{callbacks} = +{
        after_test => sub {
            my ($filenames) = @_;
            my $config = ConfigCache->get_config_by_filename($filenames->[0]);
            ConfigCache->push_configs($config);
        },
    };
    $self->SUPER::new($params);
}

1;
