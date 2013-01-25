package TestApp::Builder;

use Moose;
extends 'OpusVL::AppKit::Builder';

override _build_superclasses => sub
{
  return [ 'OpusVL::AppKit' ]
};

override _build_plugins => sub {
    my $plugins = super(); # Get what CatalystX::AppBuilder gives you

    push @$plugins, qw(
        +OpusVL::AppKitX::Preferences
    );

    return $plugins;
};

override _build_config => sub {
    my $self   = shift;
    my $config = super(); # Get what CatalystX::AppBuilder gives you

    # point the AppKitAuth Model to the correct DB file....
    $config->{'Model::AppKitAuthDB'} = 
    {
        schema_class => 'OpusVL::AppKit::Schema::AppKitAuthDB',
        connect_info => [
          'dbi:SQLite:' . TestApp->path_to('root','appkit-auth.db'),
        ],
    };
    $config->{'Model::Preferences'} = 
    {
        connect_info => [
          'dbi:SQLite:' . TestApp->path_to('root','preferences.db'),
        ],
    };

    # .. add static dir into the config for Static::Simple..
    $config->{default_view}     = 'AppKitTT';

    $self->add_paths_specified(TestApp->path_to('root'), $config);

    # DEBUGIN!!!!
    $config->{'appkit_can_access_everything'} = 1;
    
    $config->{application_name} = 'AppKit TestApp';
    
    return $config;
};

1;
