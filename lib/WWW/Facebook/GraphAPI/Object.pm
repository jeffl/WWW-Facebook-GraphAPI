package WWW::Facebook::GraphAPI::Object;

use Moose;
use JSON::XS;
use Data::Dump qw/dump/;
use WWW::Facebook::GraphAPI::ObjectList;

has 'id' => ( 'is' => 'rw' );
has 'obj' => ( 'is' => 'rw' );

sub get {
	my ($self,$key) = @_;
	return $self->obj->{$key};
}

sub init {
	my ($self) = @_;
	$self->id($self->obj->{id});
	my $uo = $self->obj;
	for my $k (keys %$uo) {
		if (ref($uo->{$k}) && ref($uo->{$k}) eq 'HASH' && $uo->{$k}{data}) {
			my $ol = WWW::Facebook::GraphAPI::ObjectList->new;
			$ol->init({objects => $uo->{$k} });
			$uo->{$k} = $ol;
		}
	}
	return $self->obj;
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;
