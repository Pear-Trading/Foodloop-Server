package Pear::LocalLoop::Controller::Admin::Import;
use Mojo::Base 'Mojolicious::Controller';

use Text::CSV;
use Try::Tiny;

has result_set => sub {
  my $c = shift;
  return $c->schema->resultset('ImportSet');
};

sub index {
  my $c = shift;

  my $import_rs = $c->result_set->search(
    undef,
    {
      page => $c->param('page') || 1,
      rows => 10,
      order_by => { -desc => 'date' },
    },
  );
  $c->stash( import_rs => $import_rs );
}

sub list {
  my $c = shift;
  my $set_id = $c->param('set_id');

  my $import_set      = $c->result_set->find($set_id);
  my $import_value_rs = $c->result_set->get_values($set_id);
  my $import_users_rs = $c->result_set->get_users($set_id);
  my $import_org_rs   = $c->result_set->get_orgs($set_id);

  $c->stash(
    import_set => $import_set,
    import_value_rs => $import_value_rs,
    import_users_rs => $import_users_rs,
    import_org_rs => $import_org_rs,
  );
}

sub get_add {
  my $c = shift;
}

sub post_add {
  my $c = shift;
  
  my $csv_data = $c->param('csv');
  my $date_format = $c->param('date_format');

  my $csv = Text::CSV->new({
    binary => 1,
    allow_whitespace => 1,
  });

  open my $fh, '<', \$csv_data;

  # List context returns the actual headers
  my @csv_headers;
  my $error;
  try {
    @csv_headers = $csv->header( $fh );
  } catch {
    $error = $_;
  };

  if ( defined $error ) {
    $c->flash( error => $error, csv_data => $csv_data, date_format => $date_format );
    $c->redirect_to( '/admin/import/add' );
    return;
  }

  # Text::CSV Already errors on duplicate columns, so this is fine
  my @required = grep {/^user$|^value$|^date$|^organisation$/} @csv_headers;

  unless ( scalar( @required ) == 4 ) {
    $c->flash( error => 'Required columns not available', csv_data => $csv_data, date_format => $date_format );
    $c->redirect_to( '/admin/import/add' );
    return;
  }

  my $csv_output = $csv->getline_hr_all( $fh );

  unless ( scalar( @$csv_output ) ) {
    $c->flash( error => "No data found", csv_data => $csv_data, date_format => $date_format );
    $c->redirect_to( '/admin/import/add' );
    return;
  }

  for my $data ( @$csv_output ) {
    Dwarn $data;
    for my $key ( qw/ user value organisation / ) {
      unless ( defined $data->{$key} ) {
        $c->flash( error => "Undefined [$key] data found", csv_data => $csv_data, date_format => $date_format );
        $c->redirect_to( '/admin/import/add' );
        return;
      }
    }
    if ( defined $data->{date} ) {
      my $dtp = DateTime::Format::Strptime->new( pattern => $date_format );
      my $dt_obj = $dtp->parse_datetime($data->{date});
      unless ( defined $dt_obj ) {
        $c->flash( error => "Undefined or incorrect format for [date] data found", csv_data => $csv_data, date_format => $date_format );
        $c->redirect_to( '/admin/import/add' );
        return;
      }
      $data->{date} = $dt_obj;
    }
  }

  my $value_set;
  $c->schema->txn_do(
    sub {
      $value_set = $c->result_set->create({});

      $value_set->values->populate(
        [
          [ qw/ user_name purchase_value purchase_date org_name / ],
          ( map { [ @{$_}{qw/ user value date organisation /} ] } @$csv_output ),
        ]
      );
    }
  );

  unless ( defined $value_set ) {
    $c->flash( error => 'Error creating new Value Set', csv_data => $csv_data, date_format => $date_format );
    $c->redirect_to( '/admin/import/add' );
    return;
  }

  $c->flash( success => 'Created Value Set' );
  $c->redirect_to( '/admin/import/' . $value_set->id );
}

sub get_value {
  my $c = shift;
  my $set_id = $c->param('set_id');
}

sub post_value {
  my $c = shift;
  my $set_id = $c->param('set_id');
}

1;
