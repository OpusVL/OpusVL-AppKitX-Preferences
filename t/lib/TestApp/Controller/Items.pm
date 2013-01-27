package TestApp::Controller::Items;

use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller::HTML::FormFu'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';
with 'OpusVL::AppKitX::Preferences::Roles::ParameterValueEditing';

__PACKAGE__->config
(
    appkit_name                 => 'Items',
    # appkit_icon                 => 'static/images/flagA.jpg',
    appkit_myclass              => 'TestApp',
    # appkit_method_group         => 'Extension A',
    # appkit_method_group_order   => 2,
    # appkit_shared_module        => 'ExtensionA',
);

sub auto
    : Action
{
    my ($self, $c) = @_;
    my $list_url = $c->uri_for($self->action_for('index'));
    $c->stash->{list_url} = $list_url;
    $self->add_breadcrumb($c, { name => 'Items', url => $list_url });
}

sub index
    :Path
    :Args(0)
    :NavigationHome
    :AppKitFeature('Test')
{
    my ($self, $c) = @_;
    $c->stash->{items} = [$c->model('Preferences::TestOwner')->all];
    $c->stash->{item_url} = sub {
        my $action_name = shift;
        my $item = shift;
        my $action = $self->action_for($action_name);
        return $c->uri_for($action, [ $item->id ]);
    };
}

sub add
    : FormConfig
    : Local
{
    my ($self, $c) = @_;

    my $form = $c->stash->{form};
    my $rs = $c->model('Preferences::TestOwner');
    $self->construct_global_data_form($c, {
        resultset => $rs,
    });
    $form->process;
    if($form->submitted_and_valid)
    {
        # FIXME: add the extra stuff
        my $item = $rs->create({
            name => $form->param_value('name'),
        });
        $self->update_prefs_values($c, $item);
        $c->flash->{status_msg} = 'Saved';
        $c->res->redirect($c->stash->{list_url});
    }
    else
    {
        my $defaults = {};
        $defaults = $self->add_prefs_defaults($c, { 
            defaults => $defaults, 
            resultset => $c->model('Preferences::TestOwner'),
        });
        $form->default_values($defaults);
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
    : FormConfig('items/add.yml')
{
    my ($self, $c) = @_;
    my $item = $c->stash->{item};
    my $form = $c->stash->{form};

    $self->construct_global_data_form($c, {
        object => $item,
    });
    $form->process;
    if($form->submitted_and_valid)
    {
        $item->update({
            name => $form->param_value('name'),
        });
        $self->update_prefs_values($c, $item);
        $c->flash->{status_msg} = 'Updated';
        $c->res->redirect($c->stash->{list_url});
    }
    else
    {
        my $defaults = {
            name => $item->name,
        };
        $defaults = $self->add_prefs_defaults($c, {
            defaults => $defaults,
            object => $item,
        });
        $form->default_values($defaults);
    }
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

