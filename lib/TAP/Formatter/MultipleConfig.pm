package TAP::Formatter::MultipleConfig;
use strict;
use warnings;

use parent 'TAP::Formatter::Console';

use ConfigCache;
use TAP::Formatter::Console::NoRulerParallelSession;

sub open_test {
    my ($self, $filename, $parser) = @_;
    my $pid = $parser->_iterator->{pid};
    ConfigCache->set_config_by_filename($filename, $pid);

    my $session = TAP::Formatter::Console::NoRulerParallelSession->new({
        name       => $filename,
        formatter  => $self,
        parser     => $parser,
        show_count => $self->show_count,
    });

    $session->header;
    return $session;
}

1;
