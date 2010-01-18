package Gitalist::Controller::Fragment::Commit;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
with 'Gitalist::URIStructure::Commit';

sub base : Chained('/fragment/repository/find') PathPart('') CaptureArgs(0) {}

after diff => sub {
    my ($self, $c) = @_;
    my $commit = $c->stash->{Commit};
    my($tree, $patch) = $c->stash->{Repository}->diff(
        commit => $commit,
        parent => $c->req->param('hp') || undef,
        patch  => 1,
    );
    $c->stash(
      diff_tree => $tree,
      diff      => $patch,
      # XXX Hack hack hack, see View::SyntaxHighlight
      blobs     => [map $_->{diff}, @$patch],
      language  => 'Diff',
    );
};

after diff_fancy => sub {
    my ($self, $c) = @_;
    $c->forward('View::SyntaxHighlight');
};

after diff_plain => sub {
    my ($self, $c) = @_;
    $c->response->content_type('text/plain; charset=utf-8');
};

after tree => sub {
    my ( $self, $c, @fn ) = @_;
    my $repository = $c->stash->{Repository};
    my $commit  = $c->stash->{Commit};
    my $filename = join('/', @fn);
    my $tree    = $filename
      ? $repository->get_object($repository->hash_by_path($commit->sha1, $filename))
      : $repository->get_object($commit->tree_sha1)
    ;
    $c->stash(
        tree      => $tree,
        tree_list => [$repository->list_tree($tree->sha1)],
        path      => $filename,
    );
};

__PACKAGE__->meta->make_immutable;