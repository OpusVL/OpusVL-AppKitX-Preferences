package OpusVL::AppKitX::Preferences::Model::Preferences;

use Moose;

BEGIN {
    extends 'Catalyst::Model::DBIC::Schema';
}

__PACKAGE__->config(
    schema_class => 'OpusVL::Preferences::Schema'
);

1;
