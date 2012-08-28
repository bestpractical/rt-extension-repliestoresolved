use 5.008003; use strict; use warnings;

use RT::Extension::RepliesToResolved;

our $VERSION = '0.01';

=head1 NAME

RT::Extension::RepliesToResolved - intercept replies to resolved tickets

=head1 DESCRIPTION

Intercepts replies via email to resolved tickets and creates a new
ticket rather than updates resolved ticket. There are a few reasons
to do this:

=over 4

=item "Thank you" messages re-open tickets and mess with statistics.

=item People keep sending new questions into old tickets.

=back

=head1 RT 4.0.7 required or you have to patch RT

You can fetch patch from github:

L<https://github.com/bestpractical/rt/commit/139f5da162ceb64bf33a31d7013e8b98d6866d18.patch>

=head1 BETA

It's very simple module to give an example on how to do it. I hope
to see patches that improve it.

=head1 INSTALLATION

    perl Makefile.PL
    make
    make install

Register plugin in F<RT_SiteConfig.pm>:

    Set(@Plugins, qw(
        RT::Extension::RepliesToResolved
        ... other plugins ...
    ));


=cut

require RT::Interface::Email;
package RT::Interface::Email;

{
    my $orig = __PACKAGE__->can('ExtractTicketId')
        or die "It's not RT 4.0.7, you have to patch this RT."
            ." Read documentation for RT::Extension::RepliesToResolved";

    *ExtractTicketId = sub {
        my $entity = shift;

        my $id = $orig->( $entity );
        return $id unless $id;

        my $ticket = RT::Ticket->new( RT->SystemUser );
        $ticket->Load($id);
        return $id unless $ticket->id;

        if ( $ticket->Status eq 'resolved' ) {
            $RT::Logger->info("A reply to resolved ticket #". $ticket->id .", creating a new ticket");
            return undef;
        }
        return $id;
    };
}

=head1 AUTHOR

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;