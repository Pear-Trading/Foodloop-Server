package Pear::LocalLoop::Controller::Admin::Categories;
use Mojo::Base 'Mojolicious::Controller';

has result_set => sub {
    my $c = shift;
    return $c->schema->resultset('Category');
};

sub index {
    my $c = shift;

    my $category_rs = $c->result_set;
    $category_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    $c->stash( categories => [ $category_rs->all ] );
}

# POST
sub create {
    my $c = shift;

    my $validation = $c->validation;
    $validation->required( 'category', 'trim' )
      ->not_in_resultset( 'name', $c->result_set );

    my $category_name = $validation->param('category');

    if ( $validation->has_error ) {
        my $check = shift @{ $c->validation->error('category') };
        if ( $check eq 'required' ) {
            $c->flash( error => 'Category name is required' );
        }
        elsif ( $check eq 'like' ) {
            $c->flash( error =>
'Category name not valid - Alphanumeric characters and Underscore only'
            );
        }
        elsif ( $check eq 'not_in_resultset' ) {
            $c->flash( error => 'Category Already Exists' );
        }
    }
    else {
        $c->flash( success => 'Category Created' );
        $c->result_set->create( { name => $category_name } );
    }
    $c->redirect_to('/admin/categories');
}

# GET
sub read {
    my $c = shift;

    my $id = $c->param('id');

    if ( my $category = $c->result_set->find($id) ) {
        $c->stash( category => $category );
    }
    else {
        $c->flash( error => 'No Category found' );
        $c->redirect_to('/admin/categories');
    }
}

# POST
sub update {
    my $c          = shift;
    my $validation = $c->validation;
    $validation->required('id');
    $validation->required( 'category', 'trim' )->like(qr/^[\w]*$/);
    $validation->optional('line_icon');

    my $id = $c->param('id');

    if ( $validation->has_error ) {
        my $names = $validation->failed;
        $c->flash(
            error => 'Error in submitted data: ' . join( ', ', @$names ) );
        $c->redirect_to( '/admin/categories/' . $id );
    }
    elsif ( my $category = $c->result_set->find($id) ) {
        $category->update(
            {
                id        => $validation->param('id'),
                name      => $validation->param('category'),
                line_icon => (
                    defined $validation->param('line_icon')
                    ? $validation->param('line_icon')
                    : undef
                ),
            }
        );
        $c->flash( success => 'Category Updated' );
        $c->redirect_to( '/admin/categories/' . $validation->param('id') );
    }
    else {
        $c->flash( error => 'No Category found' );
        $c->redirect_to('/admin/categories');
    }
}

# DELETE
sub delete {
    my $c = shift;

    my $id = $c->param('id');

    if ( my $category = $c->result_set->find($id) ) {
        $category->transaction_category->delete;
        $category->delete;
        $c->flash( success => 'Category Deleted' );
    }
    else {
        $c->flash( error => 'No Category found' );
    }
    $c->redirect_to('/admin/categories');
}

1;
