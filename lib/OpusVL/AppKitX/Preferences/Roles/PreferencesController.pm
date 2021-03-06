package OpusVL::AppKitX::Preferences::Roles::PreferencesController;

use Moose::Role;

sub index_preferences
{
    my ($self, $c) = @_;

    $self->add_final_crumb($c, 'Search');
    my $form = $c->stash->{form};
    my $rs = $c->model('Preferences')->resultset($self->resultset);
    $c->stash->{preferences} = [$rs->prf_defaults->active_first];
}

sub do_form_setup
{
    my ($self, $c, $form) = @_;
}

sub do_form_gather
{
    my ($self, $c, $form, $data, $args) = @_;
    # expect resultset or object in args.
}

sub do_form_set_defaults
{
    my ($self, $c, $form, $defaults, $args) = @_;
}

sub add_prefences
{
    my ($self, $c) = @_;

    my $form = $c->stash->{form};
    $self->add_final_crumb($c, 'Add');

    my $rs = $c->model('Preferences')->resultset($self->resultset);
    $self->do_form_setup($c, $form);
    if($form->submitted_and_valid)
    {
        my $name = $form->param_value('name');
        if($rs->prf_defaults->find({ name => $name }))
        {
            # it clashes with an existing setting.
            $form->get_field('name')->get_constraint({ type => 'Callback' })->callback(sub { 0 });
            $form->process;
            $c->detach;
        }
        my $data = {
            name => $name,
            active => $form->param_value('active') || 0,
            required => $form->param_value('required') || 0,
            hidden => $form->param_value('hidden') || 0,
            display_order => $form->param_value('display_order') || 0,
            data_type => $form->param_value('data_type'),
            default_value => $form->param_value('default_value'),
            comment => $form->param_value('comment'),
        };
        $self->do_form_gather($c, $form, $data, { resultset => $rs });
        $rs->prf_defaults->create($data);
        $c->flash->{status_msg} = 'Parameter created';
        $c->res->redirect($c->stash->{index_url});
    }
    else
    {
        my $count = $rs->prf_defaults->count;
        my $defaults = {
            active => 1,
            display_order => $count + 1,
        };
        $self->do_form_set_defaults($c, $form, $defaults, { resultset => $rs });
        my $owner_type = $rs->get_owner_type;;
        if($owner_type)
        {
            $defaults->{prf_owner_type_id} = $owner_type->prf_owner_type_id;
        }
        $form->default_values($defaults);
    }
}

sub do_preference_chain
{
    my ($self, $c, $id) = @_;

    $c->detach('/not_found') unless $id;
    my $preference = $c->model('Preferences')->resultset($self->resultset)->prf_defaults->find({ name => $id });
    $c->detach('/not_found') unless $preference;
    $c->stash->{preference} = $preference;
    $c->stash->{preference_name} = $id;
    $self->add_breadcrumb($c, { name => $preference->name, url => $c->uri_for($self->action_for('edit'), [ $id ] ) });
}

sub edit_prefences
{
    my ($self, $c) = @_;

    my $form = $c->stash->{form};
    $self->add_final_crumb($c, 'Edit');

    my $preference = $c->stash->{preference};
    $self->do_form_setup($c, $form);
    if($form->submitted_and_valid)
    {
        # FIXME: check for rename.
        my $name = $form->param_value('name');
        unless($c->stash->{preference_name} eq $name)
        {
            my $rs = $c->model('Preferences')->resultset($self->resultset);
            if($rs->prf_defaults->find({ name => $name }))
            {
                # they are trying to rename the preference and it clashes
                # with an existing setting.
                $form->get_field('name')->get_constraint({ type => 'Callback' })->callback(sub { 0 });
                $form->process;
                $c->detach;
            }
        }

        my $data = {
            name => $name,
            data_type => $form->param_value('data_type'),
            active => $form->param_value('active') || 0,
            required => $form->param_value('required') || 0,
            hidden => $form->param_value('hidden') || 0,
            display_order => $form->param_value('display_order') || 0,
            default_value => $form->param_value('default_value'),
            comment => $form->param_value('comment'),
        };
        $self->do_form_gather($c, $form, $data, { object => $preference });
        $preference->update($data);
        $c->flash->{status_msg} = 'Parameter updated';
        $c->res->redirect($c->stash->{index_url});
    }
    else
    {
        my $defaults = {
            name => $preference->name,
            data_type => $preference->data_type,
            default_value => $preference->default_value,
            prf_owner_type_id => $preference->prf_owner_type_id,
            comment => $preference->comment,
            active => $preference->active,
            hidden => $preference->hidden,
            display_order => $preference->display_order,
            required => $preference->required,
        };
        $self->do_form_set_defaults($c, $form, $defaults, { object => $preference });
        $form->default_values($defaults);
    }
}

sub prefence_values
{
    my ($self, $c) = @_;

    my $prev_link = $c->stash->{index_url};
    if ($c->req->param('cancel')) {
        $c->res->redirect($prev_link);
        $c->detach;
    }
    my $value = $c->stash->{preference};
    $self->add_final_crumb($c, 'Values');
    my $type_rs = $value->values;
    my @types = $type_rs->all;
    my $form = $c->stash->{form};

    my $fieldset = $form->get_all_element('current_values');
    my $repeater = $form->get_all_element('rep');
    my $count = $form->param_value('element_count');
    unless($count)
    {
        $count = scalar @types;
        $repeater->repeat($count);
        $form->process;
    }
    unless(@types)
    {
        $fieldset->element({
            type    => 'Block',
            tag     => 'p',
            content => 'No values have been setup.',
        });
    }

    if($form->submitted_and_valid)
    {
        my $value = $form->param_value('value');
        if($value)
        {
            my $source = $type_rs->create({ 
                value => $value,
            });
        }
        for(my $i = 1; $i <= $count; $i++)
        {
            my $id = $form->param_value("id_$i");
            my $delete_flag = $form->param_value("delete_$i");
            my $source = $type_rs->find({ id => $id });
            if($delete_flag)
            {
                $source->delete;
            }
            else
            {
                my $value = $form->param_value("value_$i");
                $source->update({ 
                    value => $value,
                });
            }
        }

        $c->flash->{status_msg} = 'Saved';
        $c->res->redirect($c->req->uri);
        $c->detach;
    }
    else
    {
        my $defaults = {
            name => $value->name,
            prf_owner_type_id => $value->prf_owner_type_id,
        };
        my $i = 1;
        for my $type (@types)
        {
            $defaults->{"id_$i"} = $type->id;
            $defaults->{"name_$i"} = $type->name;
            $defaults->{"prf_owner_type_id_$i"} = $type->prf_owner_type_id;
            $defaults->{"value_$i"} = $type->value;
            $i++;
        }
        $form->default_values($defaults);
    }
}


1;

__END__

=pod

=head1 NAME

OpusVL::AppKitX::Preferences::Roles::PreferencesController

=head1 DESCRIPTION

This role provides all the methods you need to create a preferences setup
page for your DBIC result that is hooked up to the OpusVL::Preferences.


    package OpusVL::AppKitX::TokenProcessor::Admin::Controller::Currencies::Preferences;

    use Moose;
    use namespace::autoclean;
    BEGIN { extends 'Catalyst::Controller::HTML::FormFu'; };
    with 'OpusVL::AppKit::RolesFor::Controller::GUI';
    with 'OpusVL::AppKitX::Preferences::Roles::PreferencesController';

    has resultset => (is => 'ro', isa => 'Str', default => 'Currency');

    __PACKAGE__->config
    (
        appkit_name                 => 'Admin',
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
        : NavigationName('Currency Parameters')
        : AppKitFeature('Currency Parameters')
    {
        my ($self, $c) = @_;
        $self->index_preferences($c);
    }

    sub add
        : Local
        : Args(0)
        : AppKitFeature('Currency Parameters')
        : FormConfig('modules/preferences/add.yml')
    {
        my ($self, $c) = @_;

        $self->add_prefences($c);
    }

    sub preference_chain
        : Chained('/')
        : CaptureArgs(1)
        : AppKitFeature('Currency Parameters')
        : PathPart('modules/currencies/preferences')
    {
        my ($self, $c, $id) = @_;
        $self->do_preference_chain($c, $id);
    }

    sub edit
        : Chained('preference_chain')
        : Args(0)
        : AppKitFeature('Currency Parameters')
        : FormConfig('modules/preferences/add.yml')
        : PathPart('edit')
    {
        my ($self, $c) = @_;
        $self->edit_prefences($c);
    }

    sub values
        : Chained('preference_chain')
        : Args(0)
        : AppKitFeature('Currency Parameters')
        : FormConfig('modules/preferences/values.yml')
        : PathPart('values')
    {
        my ($self, $c) = @_;
        $self->prefence_values($c);
    }

    1;

=head1 METHODS

=head2 index_preferences

=head2 add_prefences

=head2 do_preference_chain

=head2 edit_prefences

=head2 prefence_values

=head2 do_form_setup

    sub do_form_setup
    {
        my ($self, $c, $form) = @_;
    }

=head2 do_form_set_defaults

This is a hook point for the forms gather of the data for saving.
Add to the data hash any extra data you want to be saved.

Args will either contain object, pointing to the currently edited
object, or resultset, the current resultset of the type being added.

    sub do_form_set_defaults
    {
        my ($self, $c, $form, $data, $args) = @_;
    }

=head2 do_form_gather

This is a hook point for the forms gather of the data for saving.
Add to the data hash any extra data you want to be saved.

Args will either contain object, pointing to the currently edited
object, or resultset, the current resultset of the type being added.

    sub do_form_gather
    {
        my ($self, $c, $form, $data, $args) = @_;
        # expect resultset or object in args.
    }

=head1 ATTRIBUTES


=head1 LICENSE AND COPYRIGHT

Copyright 2013 OpusVL.

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut
