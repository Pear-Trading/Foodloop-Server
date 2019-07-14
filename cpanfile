requires 'Mojolicious';
requires 'Mojolicious::Plugin::Authentication';
requires 'Data::UUID';
requires 'Devel::Dwarn';
requires 'Mojo::JSON';
requires 'Email::Valid';
requires 'Geo::UK::Postcode::Regex' => '0.017';
requires 'Authen::Passphrase::BlowfishCrypt';
requires 'Scalar::Util';
requires 'DBIx::Class';
requires 'DBIx::Class::PassphraseColumn';
requires 'DBIx::Class::TimeStamp';
requires 'DBIx::Class::Schema::Loader';
requires 'SQL::Translator';
requires 'DateTime';
requires 'DateTime::Format::Strptime', "1.73";
requires 'DateTime::Format::SQLite';
requires 'Try::Tiny';
requires 'MooX::Options::Actions';
requires 'Module::Runtime';
requires 'DBIx::Class::DeploymentHandler';
requires 'DBIx::Class::Fixtures';
requires 'GIS::Distance';
requires 'Text::CSV';
requires 'Try::Tiny';
requires 'Throwable::Error';
requires 'Minion';

on 'test' => sub {
  requires 'Test::More';
  requires 'Test::MockTime';
};

feature 'schema-graph', 'Draw diagrams of Schema' => sub {
  requires 'GraphViz';
  requires 'SQL::Translator';
};

feature 'postgres', 'PostgreSQL Support' => sub {
  requires 'DBD::Pg';
  requires 'Test::PostgreSQL';
  requires 'Mojo::Pg';
};

feature 'sqlite', 'SQLite Support' => sub {
  requires 'Minion::Backend::SQLite';
};

feature 'codepoint-open', 'Code Point Open manipulation' => sub {
  requires 'Geo::UK::Postcode::CodePointOpen';
};
