use 5.008003; use strict; use warnings;

package RT::Extension::RepliesToResolved;

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
    make initdb

Register plugin in F<RT_SiteConfig.pm>:

    Set(@Plugins, qw(
        RT::Extension::RepliesToResolved
        ... other plugins ...
    ));


=cut

sub RemoveSubjectTags {
    my $entity = shift;
    my $subject = $entity->head->get('Subject');
    my $rtname = RT->Config->Get('rtname');
    my $test_name = RT->Config->Get('EmailSubjectTagRegex') || qr/\Q$rtname\E/i;
    
    if ( $subject !~ s/\[$test_name\s+\#\d+\s*\]//i ) {
        foreach my $tag ( RT->System->SubjectTag ) {
            next unless $subject =~ s/\[\Q$tag\E\s+\#\d+\s*\]//i;
            last;
        }
    }
    $entity->head->replace(Subject => $subject);
}

require RT::Interface::Email;
package RT::Interface::Email;

{
    my $orig = __PACKAGE__->can('ExtractTicketId')
        or die "It's not RT 4.0.7, you have to patch this RT."
            ." Read documentation for RT::Extension::RepliesToResolved";

    no warnings qw(redefine);

    *ExtractTicketId = sub {
        my $entity = shift;

        my $id = $orig->( $entity );
        return $id unless $id;

        my $ticket = RT::Ticket->new( RT->SystemUser );
        $ticket->Load($id);
        return $id unless $ticket->id;

        return $id unless ( $ticket->Status eq 'resolved' );

        my $r2r_config = RT->Config->Get('RepliesToResolved');
        my $reopen_timelimit = $r2r_config->{'default'}->{'reopen-timelimit'} || 0;
        if (exists($r2r_config->{$ticket->QueueObj->Name})) {
            $reopen_timelimit = $r2r_config->{$ticket->QueueObj->Name}->{'reopen-timelimit'};
        }

        # If the timelimit is undef, follow normal RT behaviour
        return $id unless defined($reopen_timelimit);

        return $id if ($ticket->ResolvedObj->Diff()/-86400 < $reopen_timelimit);

        $RT::Logger->info("A reply to resolved ticket #". $ticket->id .", creating a new ticket");

        $entity->head->replace("X-RT-Was-Reply-To" => Encode::encode_utf8($ticket->id));
        &RT::Extension::RepliesToResolved::RemoveSubjectTags($entity);

        return undef;
    };
}

=head1 AUTHOR

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>
Tim Cutts E<lt>tjrc@sanger.ac.ukE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;
