package TestApp::Controller::Items;

use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller::HTML::FormFu'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

__PACKAGE__->config
(
    appkit_name                 => 'Items',
    # appkit_icon                 => 'static/images/flagA.jpg',
    appkit_myclass              => 'TestApp',
    # appkit_method_group         => 'Extension A',
    # appkit_method_group_order   => 2,
    # appkit_shared_module        => 'ExtensionA',
);

sub index
    :Path
    :Args(0)
    :NavigationHome
    :AppKitFeature('Test')
{
    my ($self, $c) = @_;
    $c->stash->{items} = [$c->model('Preferences::TestOwner')->all];
}

sub add
    : FormConfig
    : Local
{
    my ($self, $c) = @_;

    my $form = $c->stash->{form};
    if($form->submitted_and_valid)
    {
        # FIXME: add the extra stuff
        $c->model('Preferences::TestOwner')->create({
            name => $form->param_value('name'),
        });
    }
}

sub item_chain
    : Chained('/')
    : PathPart('preferences')
    : CaptureArgs(1)
{
    my ($self, $c, $id) = @_;

    $c->detach('/not_found') unless $id;
    my $item = $c->model('Preferences::TestOwner')->find({ id => $id });
    $c->detach('/not_found') unless $item;
    $c->stash->{item} = $item;
}

sub edit
    : Chained('item_chain')
    : PathPart('edit')
    : FormConfig
{
}

sub view
    : Chained('item_chain')
    : PathPart('view')
{
}

=head1 NAME

TestApp::Controller::Items - Demo preferences controller.

=head1 DESCRIPTION

=head1 METHODS

=head1 BUGS

=head1 AUTHOR

=head1 COPYRIGHT and LICENSE

Copyright (C) 2013 OpusVL

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut

