package Pear::LocalLoop::Controller::Api::User;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Mojo::JSON;
use DateTime;
use DateTime::Duration;
use TryCatch;

sub post_user_history {
  my $self = shift;

  my $userId = $self->stash->{api_user}->id;
  my $json = $self->req->json;
  if ( ! defined $json ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'JSON is missing.',
    },
    status => 400,); #Malformed request   
  }

  my $retrieveType = $json->{retrieveType};
  if ( ! defined $retrieveType ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'retrieveType is missing.',
    },
    status => 400,); #Malformed request   
  }
  elsif (! Scalar::Util::looks_like_number($retrieveType)){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'retrieveType does not look like a number.',
    },
    status => 400,); #Malformed request   
  }

  #Date time.
  my $startDateTime;
  my $endDateTime;

  #One day
  if ($retrieveType == 1){
    my $startDayNumber = $json->{dayNumber};
    if ( ! defined $startDayNumber ) {
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'dayNumber is missing.',
      },
      status => 400,); #Malformed request   
    }
    elsif (! Scalar::Util::looks_like_number($startDayNumber)){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'dayNumber does not look like a number.',
      },
      status => 400,); #Malformed request   
    }

    my $startMonthNumber = $json->{monthNumber};
    if ( ! defined $startMonthNumber ) {
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'monthNumber is missing.',
      },
      status => 400,); #Malformed request   
    }
    elsif (! Scalar::Util::looks_like_number($startMonthNumber)){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'monthNumber does not look like a number.',
      },
      status => 400,); #Malformed request   
    }

    my $startYear = $json->{year};
    if ( ! defined $startYear ) {
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'year is missing.',
      },
      status => 400,); #Malformed request   
    }
    elsif (! Scalar::Util::looks_like_number($startYear)){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'year does not look like a number.',
      },
      status => 400,); #Malformed request   
    }

    try
    {
      $startDateTime = DateTime->new(
        year => $startYear,
        month => $startMonthNumber,
        day => $startDayNumber,
      );
    }
    catch
    {
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'date is invalid.',
      },
      status => 400,); #Malformed request 
    };

    $endDateTime = $startDateTime->clone();

  }
  elsif ($retrieveType == 2){
    my $startDayNumber = $json->{startDayNumber};
    if ( ! defined $startDayNumber ) {
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'startDayNumber is missing.',
      },
      status => 400,); #Malformed request   
    }
    elsif (! Scalar::Util::looks_like_number($startDayNumber)){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'startDayNumber does not look like a number.',
      },
      status => 400,); #Malformed request   
    }

    my $startMonthNumber = $json->{startMonthNumber};
    if ( ! defined $startMonthNumber ) {
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'startMonthNumber is missing.',
      },
      status => 400,); #Malformed request   
    }
    elsif (! Scalar::Util::looks_like_number($startMonthNumber)){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'startMonthNumber does not look like a number.',
      },
      status => 400,); #Malformed request   
    }

    my $startYear = $json->{startYear};
    if ( ! defined $startYear ) {
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'startYear is missing.',
      },
      status => 400,); #Malformed request   
    }
    elsif (! Scalar::Util::looks_like_number($startYear)){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'startYear does not look like a number.',
      },
      status => 400,); #Malformed request   
    }

    try
    {
      $startDateTime = DateTime->new(
        year => $startYear,
        month => $startMonthNumber,
        day => $startDayNumber,
      );
    }
    catch
    {
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'start date is invalid.',
      },
      status => 400,); #Malformed request 
    };


    my $endDayNumber = $json->{endDayNumber};
    if ( ! defined $endDayNumber ) {
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'endDayNumber is missing.',
      },
      status => 400,); #Malformed request   
    }
    elsif (! Scalar::Util::looks_like_number($endDayNumber)){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'endDayNumber does not look like a number.',
      },
      status => 400,); #Malformed request   
    }

    my $endMonthNumber = $json->{endMonthNumber};
    if ( ! defined $endMonthNumber ) {
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'endMonthNumber is missing.',
      },
      status => 400,); #Malformed request   
    }
    elsif (! Scalar::Util::looks_like_number($endMonthNumber)){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'endMonthNumber does not look like a number.',
      },
      status => 400,); #Malformed request   
    }

    my $endYear = $json->{endYear};
    if ( ! defined $endYear ) {
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'endYear is missing.',
      },
      status => 400,); #Malformed request   
    }
    elsif (! Scalar::Util::looks_like_number($endYear)){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'endYear does not look like a number.',
      },
      status => 400,); #Malformed request   
    }

    try
    {
      $endDateTime = DateTime->new(
        year => $endYear,
        month => $endMonthNumber,
        day => $endDayNumber,
      );
    }
    catch
    {
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'end date is invalid.',
      },
      status => 400,); #Malformed request 
    };

  }
  else{
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'retrieveType can only be 1 or 2.',
    },
    status => 400,); #Malformed request   
  }

  $endDateTime->add(days => 1);

  my $startEpoch = $startDateTime->epoch();
  my $endEpoch = $endDateTime->epoch();

  $self->app->log->debug( "startEpoch: " . Dumper($startEpoch));
  $self->app->log->debug( "endEpoch: " . Dumper($endEpoch));

  my $dataSpend = {};

  my $statementSelectPendingTrans = $self->db->prepare("SELECT TimeDateSubmitted, ValueMicroCurrency FROM Transactions WHERE BuyerUserId_FK = ? AND ? <= TimeDateSubmitted AND TimeDateSubmitted < ? ORDER BY TimeDateSubmitted ASC");
  $statementSelectPendingTrans->execute($userId, $startEpoch, $endEpoch);

  #We assume "microCurrencySum" is always more than 0 due to database and input constraints in "/upload".
  sub add_value_to_hash {
    my ($self, $microCurrencySum, $dateTimePreviousState, $dataSpend) = @_;

    #if ($microCurrencySum != 0) {
    my $year = $dateTimePreviousState->year();
    my $month = $dateTimePreviousState->month();
    my $day = $dateTimePreviousState->day();

    $dataSpend->{$year}{$month}{$day} = $microCurrencySum;
    #}
  }

  if (my ($timeDateSubmitted, $valueMicroCurrency) = $statementSelectPendingTrans->fetchrow_array()) {
    my $dateTimeTruncator = DateTime->from_epoch(epoch => $timeDateSubmitted);
    $dateTimeTruncator->truncate( to => 'day');

    #Set to 0 then add the current value like the else block.
    my $microCurrencySum = $valueMicroCurrency;
    #Set to the first row time
    my $dateTimePreviousState = $dateTimeTruncator;

    while (my ($timeDateSubmitted, $valueMicroCurrency) = $statementSelectPendingTrans->fetchrow_array()) {
      $dateTimeTruncator = DateTime->from_epoch(epoch => $timeDateSubmitted);
      $dateTimeTruncator->truncate( to => 'day');

      if (DateTime->compare($dateTimePreviousState, $dateTimeTruncator) != 0 ){
        add_value_to_hash($self, $microCurrencySum, $dateTimePreviousState, $dataSpend);
        $microCurrencySum = $valueMicroCurrency; #Reset to 0 then add the current value like the else block.
        $dateTimePreviousState = $dateTimeTruncator;
      }   
      else{ 
        $microCurrencySum += $valueMicroCurrency; #Same day to keep adding the values.
      }
    } 

    add_value_to_hash($self, $microCurrencySum, $dateTimePreviousState, $dataSpend);
  }


  $self->app->log->debug('Path Success: file:' . __FILE__ . ', line: ' . __LINE__);
  return $self->render( json => {
    microCurencySpent => $dataSpend, 
    success => Mojo::JSON->true,
  },
  status => 200,);  

}

1;

