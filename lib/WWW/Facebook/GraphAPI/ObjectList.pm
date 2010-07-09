package WWW::Facebook::GraphAPI::ObjectList;

use Moose;
use HTTP::Response;
use LWP::UserAgent;
use JSON::XS;
use WWW::Facebook::GraphAPI::Object;
use Data::Dump qw/dump/;


has 'next_url' => ( 'is' => 'rw' );
has 'previous_url' => ( 'is' => 'rw' );
has 'objects' => ( 'is' => 'rw', isa => 'ArrayRef' );

has 'cursor' => ( 'is' => 'rw', isa => 'Int', default => 0 );

sub reset {
	my ($self) = @_;
	$self->cursor(0);
}

sub next {
	my ($self) = @_;
	my $nc = $self->cursor+1;
	if (my $res = $self->objects->[$nc]) {
		$self->cursor($nc);
		return $res;
	} 
	return undef;
}

sub init {
	my ($self,$args) = @_;

	if ($args->{object}) {
		$self->objects([ $self->parse_object($args->{object}) ]);
	} else {	
		my @objects = ();
		if (my $p = $args->{objects}->{paging}) {
			$self->next_url($p->{next}) if ($p->{next});
			$self->previous_url($p->{previous}) if ($p->{previous});
		}
		for my $obj (@{$args->{objects}{data}}) {
			push @objects, $self->parse_object($obj);	
		}
		$self->objects(\@objects);
	}
	
}

sub all {
	my ($self) = @_;

	return $self->objects;
}

sub parse_object {
	my ($self,$obj) = @_;
	my $bobj = WWW::Facebook::GraphAPI::Object->new({
		obj => $obj,
	});
	$bobj->init();
	return $bobj;
}

sub first {
	my ($self) = @_;
	return $self->objects->[0];
}

sub next_page {
	my ($self) = @_;
	
	if ($self->next_url) {
		my $resp = LWP::UserAgent->new->get($self->next_url);
		my $wfgar = WWW::Facebook::GraphAPI::Response->new({
			response => $resp
		});
		$wfgar->decode;
		return $wfgar;
	}
}

sub previous_page {
	my ($self) = @_;
	
	if ($self->previous_url) {
		my $resp = LWP::UserAgent->new->get($self->previous_url);
		my $wfgar = WWW::Facebook::GraphAPI::Response->new({
			response => $resp
		});
		$wfgar->decode;
		return $wfgar;
	}
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
