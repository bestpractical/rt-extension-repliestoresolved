use inc::Module::Install;
RTx('RT-Extension-RepliesToResolved');

repository('https://github.com/bestpractical/rt-extension-repliestoresolved');

no_index( package => 'RT::Interface::Email' );

requires_rt '4.0.9';

sign();
WriteAll();
