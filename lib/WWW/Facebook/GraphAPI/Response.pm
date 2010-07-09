package WWW::Facebook::GraphAPI::Response;

use Moose;
use HTTP::Response;
use LWP::UserAgent;
use JSON::XS;
use URI;
use WWW::Facebook::GraphAPI::Object;
use WWW::Facebook::GraphAPI::ObjectList;
use Data::Dump qw/dump/;

has 'response' => (
	is => 'ro',
	required => 1,
);

has 'parsed_response' => (
	is => 'rw',
);

has '_objects' => ( 'is' => 'rw' );
has 'is_list' => ( 'is' => 'rw' );
has 'is_object' => ( 'is' => 'rw' );


sub has_cursor {
	my ($self) = @_;
}


sub decode {
	my ($self) = @_;
	
	my $response = $self->response;

	if ($response->is_success) {
		$self->parsed_response(decode_json($response->content));
	} else {
		$self->parsed_response({
			error => 1,
			http_response => $response,
		});
	}

}

sub objects {
	my ($self) = @_;

	return $self->_objects if ($self->_objects);

	if (my $list = $self->parsed_response->{data}) {
		$self->is_list(1);
		my $ol = WWW::Facebook::GraphAPI::ObjectList->new;
		$ol->init({
			objects => $self->parsed_response,
		});
		$self->_objects($ol);
	} else {
		$self->is_object(1);
		my $ol = WWW::Facebook::GraphAPI::ObjectList->new;
		$ol->init({
			object => $self->parsed_response,
		});
		$self->_objects($ol);
	}

	return $self->_objects;
}

sub object {
	my ($self) = @_;

	if ($self->is_list) {
		warn 'returning the first item of a list';
	} 
	return $self->objects->first;

}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
