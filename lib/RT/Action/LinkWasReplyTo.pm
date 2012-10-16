package RT::Action::LinkWasReplyTo;
use base 'RT::Action';
use strict;

sub Describe {
    my $self = shift;
    return ( ref $self );
}

sub Prepare {
    return 1;
}

sub Commit {
    my $self            = shift;
    my $Transaction     = $self->TransactionObj;
    my $FirstAttachment = $Transaction->Attachments->First;
    return 1 unless $FirstAttachment;

    my $OldTicket = $FirstAttachment->GetHeader('X-RT-Was-Reply-To');
    return 1 unless $OldTicket;

    my $Ticket = $self->TicketObj;

    my ($val, $msg) = $Ticket->AddLink(Type => 'MemberOf',
                                       Target => $OldTicket);

    if ($val == 0) {
        RT->Logger->error('Failed to link '.$Ticket->id.'to '.$OldTicket.": $msg\n");
    }    

    return ($val);
}

RT::Base->_ImportOverlays();

1;
