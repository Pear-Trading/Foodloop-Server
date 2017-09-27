requires 'Mojolicious';
requires 'Mojolicious::Plugin::Authentication';
requires 'Data::UUID';
requires 'Devel::Dwarn';
requires 'Mojo::JSON';
requires 'Email::Valid';
requires 'Geo::UK::Postcode::Regex';
requires 'Authen::Passphrase::BlowfishCrypt';
requires 'Time::Fake';
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

feature 'schema-graph', 'Draw diagrams of Schema' => sub {
  requires 'GraphViz';
  requires 'SQL::Translator';
};

feature 'postgres', 'PostgreSQL Support' => sub {
  requires 'DBD::Pg';
  requires 'Test::PostgreSQL';
};

feature 'codepoint-open', 'Code Point Open manipulation' => sub {
  requires 'Geo::UK::Postcode::CodePointOpen';
};

