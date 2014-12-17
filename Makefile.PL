use inc::Module::Install;
RTx('RT-Extension-RepliesToResolved');
all_from('lib/RT/Extension/RepliesToResolved.pm');
readme_from('lib/RT/Extension/RepliesToResolved.pm');
no_index( package => 'RT::Interface::Email' );
requires_rt '4.0.9';
sign();
WriteAll();
