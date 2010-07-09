package WWW::Facebook::GraphAPI;


use 5.008001;

our $VERSION = '1.000';

use Moose;

use LWP::UserAgent;
use URI;
use Data::Dump qw/dump/;
use WWW::Facebook::GraphAPI::Response;

has 'api_path' => (
	is => 'ro',
	isa => 'Str',
	default => 'https://graph.facebook.com',
);

has 'client_secret' => (
	is => 'ro',
	isa => 'Str',
);

has 'client_id' => (
	is => 'ro',
	isa => 'Str',
);

has 'access_token' => (
	is => 'rw',
	isa => 'Str',
);

has 'introspection' => (
	is => 'rw',
	isa => 'Int',
	default => 0,
);

has 'connection_types' => (
	is => 'rw',
	isa => 'HashRef',
	default => sub {
		{
			'friends' => 1,
			'statuses' => 1,
			'accounts' => 1,
			'home' => 1,
			'feed' => 1,
			'likes' => 1,
			'movies' => 1,
			'books' => 1,
			'notes' => 1,
			'photos' => 1,
			'albums' => 1,
			'videos' => 1,
			'events' => 1,
			'groups' => 1,
		}
	},
);

has 'publish_types' => (
	is => 'rw',
	isa => 'HashRef',
	default => sub {
		{
			'feed' => 1,
			'comments' => 1,
			'likes' => 1,
			'notes' => 1,
			'links' => 1,
			'events' => 1,
			'attending' => 1,
			'maybe' => 1,
			'declined' => 1,
			'albums' => 1,
			'photos' => 1,
		}
	},
);

has 'search_types' => (
	is => 'rw',
	isa => 'HashRef',
	default => sub {
		{
			post => 1,
			user => 1,
			page => 1,
			event => 1,
			group => 1,
		};
	},
);

has 'permission_types' => (
	is => 'rw',
	isa => 'HashRef',
	default => sub {
		{
			manage_pages => 1,
			email => 1,
			offline_access => 1,
			publish_stream => 1,
			
			friends_status => 1,
			friends_videos => 1,
			friends_website => 1,
			friends_work_history => 1,
			friends_online_presence => 1,
			friends_events => 1,
			friends_groups => 1,
			friends_location => 1,
			friends_about_me => 1,
			friends_activities => 1,
			friends_birthday => 1,
			friends_education_history => 1,
			friends_hometown => 1,
			friends_interests => 1,
			friends_likes => 1,
			friends_photo_video_tags => 1,
			friends_notes => 1,
			friends_relationships => 1,
			friends_religion_politics => 1,
			friends_photos => 1,

			user_groups => 1,
			user_events => 1,
			user_status => 1,
			user_videos => 1,
			user_website => 1,
			user_work_history => 1,
			user_location => 1,
			user_online_presence => 1,
			user_about_me => 1,
			user_activities => 1,
			user_birthday => 1,
			user_education_history => 1,
			user_hometown => 1,
			user_interests => 1,
			user_likes => 1,
			user_photo_video_tags => 1,
			user_notes => 1,
			user_relationships => 1,
			user_religion_politics => 1,
			user_photos => 1,

			read_requests => 1,
			read_friendlists => 1,
			read_stream => 1,
			read_insights => 1,
		}
	},
);

=head1 NAME

WWW::Facebook::GraphAPI - Facebook Graph API implementation

=head1 VERSION


=head1 SYNOPSIS

    use WWW::Facebook::GraphAPI;

	from inside a catalyst controller actions

    my $client = WWW::Facebook::GraphAPI->new(
        client_id => 'your application id',
        client_secret => 'your secret key',
    );
    
	$client->get_authorize_url($c->uri_for("/verify/receive_fb"),'page','all')

	inside action 'verify/receive_fb':

		my $code = $c->request->params->{code};	

		#SAME as url passed to 'get_authorize_url'
		my $redirect_to = $c->uri_for("/verify/receive_fb");

		my $ga = GraphAPI->new({
			client_id => $client_id,
			client_secret => $client_secret,
		});
	
		#automatically sets the access_token on success
		my $token = $ga->get_access_token($code,$redirect_to);


		#publish a status update
		my $result = $ga->publish('feed',{
			id => 'me',
			message => 'Hello Graph API',
		});





=head1 DESCRIPTION

Basic interface to the GraphAPI

See
http://developers.facebook.com/docs/api


=head1 SUBROUTINES/METHODS

=over

=item get_authorize_url ( $return_url, $display, \%permissions )
=cut
=item get_authorize_url ( $return_url, $display, $permissions )
=cut


sub get_authorize_url {
	my ($self,$return_url,$display,$permissions) = @_;

	my $args = {
		client_id => $self->client_id,
		redirect_uri => $return_url,
		display => $display || 'page',
	};
	if ($permissions) {
		if (ref($permissions) eq 'ARRAY') {
			$args->{scope} = join(',',@{$permissions});
		} elsif ($permissions eq 'all') {
			$args->{scope} = join(',',(keys %{$self->permission_types}));
		}
	}

	return $self->get_uri( $self->api_path . "/oauth/authorize", $args, 'skip merge with defaults' );
}

=item get_access_token ( $code, $redirect_uri )

=cut

sub get_access_token {
	my ($self,$code,$redirect_uri) = @_;

	my $uri = $self->get_uri( $self->api_path . "/oauth/access_token",{
	    client_id => $self->client_id,
	    client_secret => $self->client_secret,
		redirect_uri => $redirect_uri,
	    code => $code,
	},'skip merge with defaults flag');

	my $resp = LWP::UserAgent->new->get($uri);

	if ($resp->is_success) {
		my $cnt = $resp->content;
		chomp $cnt;
		$cnt =~ s/access_token=//;
		$self->access_token($cnt);
		warn $cnt;
		return $cnt;
	}
	
	return undef;
}



sub get_uri {
	my ($self,$uri,$params,$skip_merge) = @_;
	
	my $endpoint = URI->new($uri);
	
	if ($skip_merge) {
		$endpoint->query_form($params);
	} else {
		$endpoint->query_form($self->_merge_with_defaults($params));
	}

	$endpoint->as_string;
	return $endpoint;
}


sub get_and_decode {
	my ($self,$uri,$params) = @_;
	my $ep = $self->get_uri($uri,$params);
	my $resp = LWP::UserAgent->new->get($ep);
	
	my $wfgar = WWW::Facebook::GraphAPI::Response->new({
		response => $resp,
		api_params => $self->_merge_with_defaults(),
	});
	
	$wfgar->decode;

	return $wfgar;
}

sub post_and_decode {
	my ($self,$uri,$params) = @_;
	
	my $ep = $self->get_uri($uri,$params);
	my $resp = LWP::UserAgent->new->post($ep);
	
	my $wfgar = WWW::Facebook::GraphAPI::Response->new({
		response => $resp,
	});
	$wfgar->decode;
	return $wfgar;
}

sub test_me {
	my ($self) = @_;

	return $self->object('me');
}

sub test_publish {
	my ($self) = @_;

	my $resp = $self->publish("feed",{
		id => 'me',
		message => 'birding',
		link => 'http://www.angelfire.com/mi/upbirding/',
	});

	return $resp;

}

=item search ($query,$params)

params->{restriction} = '/me/home' (search feed)


=cut 

sub search {
	my ($self,$query,$params) = @_;

	my $path = "https://graph.facebook.com";

	if ($params->{type}) {
		unless ($self->search_types->{$params->{type}}) {
			die "invalid publish type: " . $params->{type};
		}
	}

	#restrictions throwing errors at the moment 07-07-2010
	if ($params->{restriction}) {
		$path .= $params->{restriction};
		delete $params->{restriction};
	} else {
		$path .= '/search';
	}
	$params->{q} = $query;
	return $self->get_and_decode($path,$params);
}

sub _merge_with_defaults {
	my ($self,$params) = @_;
	my $res = {};
	$params = $params || {};
	$res->{metadata} = 1 if ($self->introspection);
	$res->{access_token} = $self->access_token if ($self->access_token);
	
	for my $k (keys %{$params}) {
		$res->{$k} = $params->{$k};
	}
	#warn dump($res);
	return $res;
}

sub publish {
	my ($self,$publish_type,$params) = @_;
	
	unless ($self->publish_types->{$publish_type}) {
		die "invalid publish type: $publish_type";
	}
	my $id = $params->{id} || 'me';
	delete $params->{id};

	my $path = $self->api_path . "/$id/$publish_type";
	return $self->post_and_decode($path,$params);
	
}

sub object {
	my ($self,$params) = @_;
	
	my $id = $params->{id} || 'me';
	
	my $path =  $self->api_path . "/$id";
	return $self->get_and_decode($path,$params);

}

sub connections {
	my ($self,$connection_type,$params) = @_;
	
	unless ($self->connection_types->{$connection_type}) {
		warn "using unknown connection type: $connection_type";
	}

	my $id = $params->{id} || 'me';
	delete $params->{id};

	my $path =  $self->api_path . "/$id/$connection_type";
	return $self->get_and_decode($path,$params);
	
}



no Moose;
1;
