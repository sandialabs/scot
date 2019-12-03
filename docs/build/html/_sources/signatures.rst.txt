Signatures
==========

Signature
---------

Signatures are used to integrate the version control of signatures within 3rd party mitigation tools (firewalls, IDS, etc.) while being managed by SCOT as a central repository. Signature's have the same list view as other "things" within SCOT, but they have a slightly modified detail view. 

The detail view of signatures contain metadata editing, where you can modify a description, signature type (yara, ids, firewall, etc.), production and quality signature body versions, signature group that the signature belongs in, and signature options (written in JSON format). The final new item within the detail view is the Signature body editor. This editor should be used to add in the signature's that will be used in the 3rd party tool. The output of the body is converted to a string format, which can then be ingested by the other tool.

Below these new sections, the entries that are found in other "things" still exist.

Signature Metadata
------------------

.. figure:: _static/signaturemetadata.png
    :width: 25%
    :alt: signature metadata editing

Signatures contain their own unique metadata that can be used for version control, describing the signature, and grouping the signatures. The metadata contains the following options:

:Description:   Describes the signature
:Type:          Defines the type of signature being created (yara, firewall, ids, etc.)
:Production Signature Body Version: Declares the version of the signature body to be used in production
:Quality Signature Body Version: Declares the version of the signature body to be used in quality
:Signature Group: Declares a group name if signature will be grouped together.
:Signature Options: This is the first editor window you see that accepts JSON formatted data that can be used to pass on specific options for the signature being applied.
:Signature Body: This is the second and larger editor window you will see that will pass along the contents as a string to the SCOT server that can then be used by the tool ingesting the signature. The signature body editor contains a few options - Editor Theme, Language Handler, Keyboard Handler, Signature Body Version, and the following buttons - Create new version, Create new version using this base, updating displayed version.

Signature Body Options
^^^^^^^^^^^^^^^^^^^^^^

.. figure:: _static/signaturebody.png
    :width: 75%
    :alt: signature body editing

Note: The Editor Theme, Language Handler, and Keyboard Handler all save their settings in a cookie file. If you change these settings, they will persist until you change them again or clear your browser's cookies.

:Editor Theme: You can select the theme you prefer to use for your code editor. There are a variety of color options depending on your color tastes
:Language Handler: You can select the language of the signature that you are writing, or one that closely resembles it
:Keyboard Handler: You can select none, vim, or emacs if you prefer a keyboard handler
:Signature Body Version: You can select the version you would like to view here.
:Create new version: This button will empty the editor and allow editing within the editor so you can create a new signature body.Any other signature body's created will remain attached to this Signature to be viewed/edited. Note that this WILL NOT make the new signature body automatically the "qual/prod" versions, as that must be done manually in the metadata section.
:Create new version using this base: This button will also create a new signature body version, but it will start the editor off with whatever contents are already in the editor based on the version selected.
:Update displayed version: This button will allow editing of the version selected. It will not create a new version of the signature body, but instead just update the version selected.
