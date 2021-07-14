# use Regexp::Debugger;
my $re1 = qr{
    \b
    [0-9a-zA-Z_\-\.]+
    \.
    (
    7z|arg|deb|pkg|rar|rpm|tar|tgz|gz|z|zip|                  # compressed
    aif|mid|midi|mp3|ogg|wav|wma|                             # audio
    bin|dmg|iso|exe|bat|                                      # executables
    csv|dat|log|mdb|sql|xml|                                  # db/data
    eml|ost|oft|pst|vcf|                                      # email
    apk|bat|bin|cgi|exe|jar|                             # executable
    fnt|fon|otf|ttf|                                          # fonts
    ai|bmp|gif|ico|jpeg|jpg|ps|png|psd|svg|tif|tiff|          # images
    asp|aspx|cer|cfm|css|htm|html|js|jsp|part|php|rss|xhtml|  # web serving
    key|odp|pps|ppt|pptx|                                     # presentation
    c|class|cpp|h|vb|swift|py|rb|                             # source code
    ods|xls|xlsm|xlsx|                                        #spreadsheats
    cab|cfg|cpl|dll|ini|lnk|msi|sys|                          # misc sys files
    3g2|3gp|avi|flv|h264|m4v|mkv|mov|mp4|mpg|mpeg|vob|wmv|   # video
    doc|docx|odt|pdf|rtf|tex|txt|wpd|                        # word processing
    jse|jar|
    ipt|
    hta|
    mht|
    ps1|
    sct|
    scr|
    vbe|vbs|
    wsf|wsh|wsc
  )
    \b
}xims;

my $re  = qr{
    \b(
        [0-9a-zA-Z_\-\.]+
        \.
        (
            7z|arg|deb|pkg|rar|rpm|tar|tgz|gz|z|zip|                  # compressed
            aif|mid|midi|mp3|ogg|wav|wma|                             # audio
            bin|dmg|iso|exe|bat|                                      # executables
            csv|dat|log|mdb|sql|xml|                                  # db/data
            eml|ost|oft|pst|vcf|                                      # email
            apk|bat|bin|cgi|exe|jar|                             # executable
            fnt|fon|otf|ttf|                                          # fonts
            ai|bmp|gif|ico|jpeg|jpg|ps|png|psd|svg|tif|tiff|          # images
            asp|aspx|cer|cfm|css|htm|html|js|jsp|part|php|rss|xhtml|  # web serving
            key|odp|pps|ppt|pptx|                                     # presentation
            c|class|cpp|h|vb|swift|py|rb|                             # source code
            ods|xls|xlsm|xlsx|                                        #spreadsheats
            cab|cfg|cpl|dll|ini|lnk|msi|sys|                          # misc sys files
            3g2|3gp|avi|flv|h264|m4v|mkv|mov|mp4|mpg|mpeg|vob|wmv|   # video
            doc|docx|odt|pdf|rtf|tex|txt|wpd|                        # word processing
            jse|jar|
            ipt|
            hta|
            mht|
            ps1|
            sct|
            scr|
            vbe|vbs|
            wsf|wsh|wsc
        )
    )\b
}xims;

my $text = "DirBuster-0.12";

if ( $text =~ m/$re/ ) {
    print "matches\n";
    my $pre     = substr($text, 0, $-[0]);
    my $match   = substr($text, $-[0], $+[0] - $-[0]);
    my $post    = substr($text, $+[0]);

    print "PRE   = $pre\n";
    print "MATCH = $match\n";
    print "POSt  = $post\n";
}

$text = "foo.exe";
if ( $text =~ m/$re/ ) {
    print "matches\n";
    my $pre     = substr($text, 0, $-[0]);
    my $match   = substr($text, $-[0], $+[0] - $-[0]);
    my $post    = substr($text, $+[0]);

    print "PRE   = $pre\n";
    print "MATCH = $match\n";
    print "POSt  = $post\n";
}
