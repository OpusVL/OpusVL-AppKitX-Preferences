package OpusVL::AppKitX::Preferences;
use Moose::Role;
use CatalystX::InjectComponent;
use File::ShareDir qw/module_dir/;
use namespace::autoclean;

with 'OpusVL::AppKit::RolesFor::Plugin';

our $VERSION = '0.01';

after 'setup_components' => sub {
    my $class = shift;
   
    $class->add_paths(__PACKAGE__);
    
    # .. inject your components here ..
    CatalystX::InjectComponent->inject(
        into      => $class,
        component => 'OpusVL::AppKitX::Preferences::Model::Preferences',
        as        => 'Model::Preferences'
    );
};

1;

=head1 NAME

OpusVL::AppKitX::Preferences - Custom preferences UI

=head1 DESCRIPTION

=head1 METHODS

=head1 BUGS

=head1 AUTHOR

=head1 COPYRIGHT and LICENSE

Copyright (C) 2013 OpusVL

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut

