package Pear::LocalLoop::Plugin::Validators;
use Mojo::Base 'Mojolicious::Plugin';

use Email::Valid;
use Geo::UK::Postcode::Regex qw/ is_valid_pc /;
use Scalar::Util qw/ looks_like_number /;
use File::Basename qw/ fileparse /;
use DateTime::Format::Strptime;
use Try::Tiny;

sub register {
    my ( $plugin, $app, $conf ) = @_;

    $app->validator->add_check(
        email => sub {
            my ( $validation, $name, $email ) = @_;
            return Email::Valid->address($email) ? undef : 1;
        }
    );

    $app->validator->add_check(
        in_resultset => sub {
            my ( $validation, $name, $value, $key, $rs ) = @_;
            return $rs->search( { $key => $value } )->count ? undef : 1;
        }
    );

    $app->validator->add_check(
        not_in_resultset => sub {
            my ( $validation, $name, $value, $key, $rs ) = @_;
            return $rs->search( { $key => $value } )->count ? 1 : undef;
        }
    );

    $app->validator->add_check(
        postcode => sub {
            my ( $validation, $name, $value ) = @_;
            return is_valid_pc($value) ? undef : 1;
        }
    );

    $app->validator->add_check(
        number => sub {
            my ( $validation, $name, $value ) = @_;
            return looks_like_number($value) ? undef : 1;
        }
    );

    $app->validator->add_check(
        gt_num => sub {
            my ( $validation, $name, $value, $check ) = @_;
            return $value > $check ? undef : 1;
        }
    );

    $app->validator->add_check(
        lt_num => sub {
            my ( $validation, $name, $value, $check ) = @_;
            return $value < $check ? undef : 1;
        }
    );

    $app->validator->add_check(
        filetype => sub {
            my ( $validation, $name, $value, $filetype ) = @_;
            my ( undef, undef, $extension ) = fileparse $value->filename,
              qr/\.[^.]*/;
            $extension =~ s/^\.//;
            return $app->types->type($extension) eq $filetype ? undef : 1;
        }
    );

    $app->validator->add_check(
        is_iso_date => sub {
            my ( $validation, $name, $value ) = @_;
            $value = $app->iso_date_parser->parse_datetime($value);
            return defined $value ? undef : 1;
        }
    );

    $app->validator->add_check(
        is_full_iso_datetime => sub {
            my ( $validation, $name, $value ) = @_;
            $value = $app->parse_iso_datetime($value);
            return defined $value ? undef : 1;
        }
    );

    $app->validator->add_check(
        is_object => sub {
            my ( $validation, $name, $value ) = @_;
            return ref($value) eq 'HASH' ? undef : 1;
        }
    );

    $app->validator->add_check(
        in_range => sub {
            my ( $validation, $name, $value, $low, $high ) = @_;
            return $low < $value && $value < $high ? undef : 1;
        }
    );

    $app->helper( validation_error => sub { _validation_error(@_) } );

    return 1;
}

=head2 validation_error

Returns undef if there is no validation error, returns true otherwise - having
set the errors up as required. Renders out the errors as an array, with status
400

=cut

sub _validation_error {
    my ( $c, $sub_name ) = @_;

    my $val_data = $c->validation_data->{$sub_name};
    return unless defined $val_data;
    my $data = $c->stash->{api_json};

    my @errors = _validate_set( $c, $val_data, $data );

    if ( scalar @errors ) {
        my @sorted_errors = sort @errors;
        $c->render(
            json => {
                success => Mojo::JSON->false,
                errors  => \@sorted_errors,
            },
            status => 400,
        );
        return \@errors;
    }

    return;
}

sub _validate_set {
    my ( $c, $val_data, $data, $parent_name ) = @_;

    my @errors;

    # MUST get a raw validation object
    my $validation = $c->app->validator->validation;
    $validation->input($data);

    for my $val_data_key ( keys %$val_data ) {

        $validation->topic($val_data_key);

        my $val_set = $val_data->{$val_data_key};

        my $custom_check_prefix = {};

        for my $val_error ( @{ $val_set->{validation} } ) {
            my ($val_validator) = keys %$val_error;

            unless ( $validation->validator->checks->{$val_validator}
                || $val_validator =~ /required|optional/ )
            {
                $c->app->log->warn(
                    'Unknown Validator [' . $val_validator . ']' );
                next;
            }

            if ( my $custom_prefix =
                $val_error->{$val_validator}->{error_prefix} )
            {
                $custom_check_prefix->{$val_validator} = $custom_prefix;
            }
            my $val_args = $val_error->{$val_validator}->{args};

            $validation->$val_validator(
                ( $val_validator =~ /required|optional/ ? $val_data_key : () ),
                ( defined $val_args                     ? @$val_args    : () )
            );

       # stop bothering checking if failed, validation stops after first failure
            last if $validation->has_error($val_data_key);
        }

        if ( $validation->has_error($val_data_key) ) {
            my ($check) = @{ $validation->error($val_data_key) };
            my $error_prefix =
              defined $custom_check_prefix->{$check}
              ? $custom_check_prefix->{$check}
              : $check;
            my $error_string = join( '_',
                $error_prefix, ( defined $parent_name ? $parent_name : () ),
                $val_data_key, );
            push @errors, $error_string;
        }
        elsif ( defined $val_set->{children} ) {
            push @errors,
              _validate_set( $c, $val_set->{children}, $data->{$val_data_key},
                $val_data_key );
        }
    }

    return @errors;
}

1;
