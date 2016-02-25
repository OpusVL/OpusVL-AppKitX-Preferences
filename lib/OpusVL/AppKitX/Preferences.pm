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

Copyright 2013 Opus Vision Limited.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

If you require assistance, support, or further development of this software, please contact OpusVL using the details below:

=over 4

=item *

Telephone: +44 (0)1788 298 410

=item *

Email: community@opusvl.com

=item *

Web: L<http://opusvl.com>

=back

=cut

