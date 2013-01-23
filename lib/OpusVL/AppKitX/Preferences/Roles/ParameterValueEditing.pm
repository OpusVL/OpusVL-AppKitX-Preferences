package OpusVL::AppKitX::Preferences::Roles::ParameterValueEditing;

use 5.010;
use Moose::Role;

sub add_prefs_defaults
{
    my $self = shift;
    my $c = shift;
    my $args = shift;
    my $defaults = $args->{defaults};
    my $resultset = $args->{resultset};
    my $object = $args->{object};

    my $field_rs = $resultset ? $resultset->prf_defaults : $object->prf_defaults;
    my @fields = $field_rs->active->all;
    for my $field (@fields)
    {
        my $value;
        if($object) {
            $value = $object->prf_get($field->name);
        } else {
            $value = $field->default_value;
        }
        $defaults->{'global_fields_' . $field->name} = $value;
    }
    return $defaults;
}

sub update_prefs_values
{
    my ($self, $c, $object) = @_;

    # FIXME: to use two methods below instead.
    my $form = $c->stash->{form};
    my @fields = $object->prf_defaults->active->all;
    for my $field (@fields)
    {
        my $name = $field->name;
        my $value = $form->param_value('global_fields_' . $name);
        unless($object->prf_get($name) eq $value)
        {
            $object->prf_set($name, $value);
        }
    }
}

sub get_prefs_values_from_form
{
    my ($self, $c, $object) = @_;

    my @fields = $object->prf_defaults->active->all;
    return $self->collect_values_from_form($c, @fields);
}

sub collect_values_from_form
{
    my ($self, $c, @fields) = @_;
    my $form = $c->stash->{form};
    my $values = {};

    for my $field (@fields)
    {
        my $name = $field->name;
        my $value = $c->req->param('global_fields_' . $name);
        $values->{$name} = $value;
    }
    return $values;
}

sub prefs_hash_to_array
{
    my $self = shift;
    my $rs = shift;
    my $hash = shift;

    # FIXME: if we ever order the parameters, this is where
    # we should apply it.
    my @d = map { { 
        name => $_, 
        value => $hash->{$_}, 
        param => $rs->prf_defaults->find({ name => $_ }),
    } } keys %$hash;
    return @d;
}

sub update_prefs_from_hash
{
    my ($self, $object, $hash) = @_;

    for my $name (keys %$hash)
    {
        my $value = $hash->{$name};
        unless($object->prf_get($name) eq $value)
        {
            $object->prf_set($name, $value);
        }
    }
}

sub construct_global_data_form
{
    my $self = shift;
    my $c = shift;
    my $args = shift;
    my $source = $args->{resultset} || $args->{object};
    my $search = $args->{search_form};

    my @fields = $source->prf_defaults->active->display_order;
    $self->construct_form_fields($c, $search, @fields);
    unless($search)
    {
        my $owner_id = $source->can('get_owner_type') ? $source->get_owner_type->id : $source->prf_owner_type_id;
        my $form = $c->stash->{form};
        my $global_fields = $form->get_all_element('prf_fields');
        $global_fields->element({
            name => 'prf_owner_type_id',
            type => 'Hidden',
            default => $owner_id,
        });
        unless($form->get_all_element('id'))
        {
            $global_fields->element({
                name => 'id',
                type => 'Hidden',
                default => $source->id,
            });
        }
    }
}

sub construct_global_data_search_form
{
    my $self = shift;
    my $c = shift;
    my $args = shift;
    $args->{search_form} = 1;
    return $self->construct_global_data_form($c, $args);
}

sub construct_form_fields
{
    my $self = shift;
    my $c = shift;
    my $search = shift;
    my @fields = @_;

    my $form = $c->stash->{form};

    if(@fields)
    {
        my $global_fields = $form->get_all_element('prf_fields');
        my $no_fields = $form->get_all_element('no_fields');
        for my $field (@fields)
        {
            my $details;
            my $extra = "li";
            $details = {
                type => 'Text',
                label => $field->comment,
                name => "global_fields_".$field->name,
            };
            given($field->data_type)
            {
                when(/email/) {
                    $details->{constraints} = [ { type => 'Email' } ];
                }
                when(/textarea/) {
                    $details->{type} = 'Textarea';
                }
                when(/text/) {
                }
                when(/number/) {
                    $details->{constraints} = [ { type => 'Number' } ];
                    $extra = '';
                }
                when(/boolean/) {
                    $details->{type} = 'Checkbox';
                    $extra = '';
                }
                when(/date/) {
                    $details->{attributes} = {
                        autocomplete => 'off',
                        class => 'date_picker',
                    };
                    $details->{size} = 12;
                    $details->{inflators} = {
                        type => 'DateTime',
                        strptime => '%Y-%m-%d 00:00:00',
                        parser => {
                            strptime => '%d/%m/%Y',
                        }
                    };
                    $details->{deflator} = {
                        type => 'Strftime',
                        strftime => '%d/%m/%Y',
                    };
                    $extra = '';
                }
                when(/integer/) {
                    $details->{constraints} = [ { type => 'Integer' } ];
                    $extra = '';
                }
                when(/select/) {
                    $details->{type} = 'Select';
                    $details->{empty_first} = 1;
                    $details->{options} = $field->form_options;
                    $extra = '';
                }
            }
            if($search)
            {
                $details->{type} = 'Text' if($details->{type} eq 'Textarea');
                $details->{name} =~ s/^global_fields_/global_fields__/;
                $details->{name} = $details->{name} . ' ' . $extra 
                    if $extra;
            }
            else
            {
                if($field->required) # note this isn't applied for searches
                {
                    $details->{constraints} = [] unless(exists $details->{constraints});
                    push @{$details->{constraints}}, { type => 'Required' };
                    $details->{label} .= ' *';
                }
                if($field->can('unique_field') && $field->unique_field)
                {
                    $details->{validator} = [] unless(exists $details->{validator});
                    push @{$details->{validator}}, { 
                        type => '+OpusVL::AppKitX::TokenProcessor::Admin::FormFu::Validator::UniquePreference',
                    };
                }
            }
            my $element = $global_fields->element($details);
        }
        $global_fields->remove_element($no_fields);
    }
    # NOTE: caller must call $form->process afterwards
}

sub field_type_info
{
    my ($self, $c, $fields, @field_list) = @_;

    for my $field (@field_list)
    {
        my $name = $field->name;
        my $field_name = "extra_field_$name";
        my $field_info = {
            name => $field_name,
            type => $field->data_type,
            label => $field->comment,
        };
        if($field->data_type eq 'select')
        {
            $field_info->{options} = $field->form_options;
        }
        if($field->required)
        {
            $field_info->{required} = 1;
        }
        if($field->can('unique_field') && $field->unique_field)
        {
            $field_info->{unique_field} = 1;
        }
        push @$fields, $field_info;
    }
}

1;

=head1 NAME

OpusVL::AppKitX::TokenProcessor::Admin::Role::ParameterValueEditing

=head1 DESCRIPTION

=head1 METHODS

=head2 add_prefs_defaults

=head2 update_prefs_values

=head2 get_prefs_values_from_form

=head2 collect_values_from_form

=head2 prefs_hash_to_array

=head2 update_prefs_from_hash

=head2 construct_global_data_form

=head2 construct_global_data_search_form

=head2 construct_form_fields

=head2 field_type_info


=head1 ATTRIBUTES


=head1 LICENSE AND COPYRIGHT

Copyright 2013 OpusVL.

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut
