use MIME::Base64;
# my $subject = "=?utf-8?B?U3ltYW50ZWMgQ3liZXIgQXBwbGljYXRpb24gRXhlY3V0aW9uIFJlcG9ydC4=?=";
my $subject = "U3ltYW50ZWMgQ3liZXIgQXBwbGljYXRpb24gRXhlY3V0aW9uIFJlcG9ydC4==";

print decode_base64($subject);


