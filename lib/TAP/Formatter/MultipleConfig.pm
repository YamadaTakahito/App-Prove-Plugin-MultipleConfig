package TAP::Formatter::MultipleConfig;
use strict;
use warnings;

use parent 'TAP::Formatter::Console';

use ConfigCache;

sub open_test {
    my ($self, $filename, $parser) = @_;
    my $pid = $parser->_iterator->{pid};
    ConfigCache->set_config_by_filename($filename, $pid);
    $self->SUPER::open_test($filename, $parser);
}

1;
