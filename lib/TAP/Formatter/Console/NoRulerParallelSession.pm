package TAP::Formatter::Console::NoRulerParallelSession;
use strict;
use warnings;

use parent 'TAP::Formatter::Console::ParallelSession';

# somehow, show_count isn't set and formatter fails to write stdout correctly. So forcibly set show_count true;
sub _should_show_count {
    return 1;
}

sub _clear_ruler {
}

sub _output_ruler {
}

1;
