package TestApp::Controller::Items::Preferences;

use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller::HTML::FormFu'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';
with 'OpusVL::AppKitX::Preferences::Roles::PreferencesController';

has resultset => (is => 'ro', isa => 'Str', default => 'TestOwner');

__PACKAGE__->config
(
    appkit_name                 => 'Preferences',
    appkit_myclass              => 'TestApp',
    # ... usual gubbins
);

sub auto
    : Action
{
    my ($self, $c) =@_;
    my $index_url = $c->uri_for($self->action_for('index'));
    $c->stash->{index_url} = $index_url;
    $self->add_breadcrumb($c, { name => 'Parameters', url => $index_url });
}

sub index
    : Path
    : Args(0)
    : NavigationName('TestOwner Parameters')
    : AppKitFeature('TestOwner Parameters')
    : NavigationHome
{
    my ($self, $c) = @_;
    $self->index_preferences($c);
}

sub add
    : Local
    : Args(0)
    : AppKitFeature('TestOwner Parameters')
    : FormConfig('modules/preferences/add.yml')
{
    my ($self, $c) = @_;

    $self->add_prefences($c);
}

sub preference_chain
    : Chained('/')
    : CaptureArgs(1)
    : AppKitFeature('TestOwner Parameters')
    : PathPart('modules/currencies/preferences')
{
    my ($self, $c, $id) = @_;
    $self->do_preference_chain($c, $id);
}

sub edit
    : Chained('preference_chain')
    : Args(0)
    : AppKitFeature('TestOwner Parameters')
    : FormConfig('modules/preferences/add.yml')
    : PathPart('edit')
{
    my ($self, $c) = @_;
    $self->edit_prefences($c);
}

sub values
    : Chained('preference_chain')
    : Args(0)
    : AppKitFeature('TestOwner Parameters')
    : FormConfig('modules/preferences/values.yml')
    : PathPart('values')
{
    my ($self, $c) = @_;
    $self->prefence_values($c);
}

1;

