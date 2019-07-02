package Pear::LocalLoop::Error;
use Moo;
extends 'Throwable::Error';

package Pear::LocalLoop::ImplementationError;
use Moo;
use namespace::clean;
extends Pear::LocalLoop::Error;

1;