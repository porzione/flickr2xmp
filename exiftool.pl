# exiftool -config exiftool.pl -XMP-flickr:id _8141513.ORF.xmp
# exiftool -config exiftool.pl -xmp-flickr:id="test" -xmp-pdfx:description="Description Test" _8141513.ORF.xmp
%Image::ExifTool::XMP::flickr = (
  %xmpTableDefaults,
  GROUPS    => { 0 => 'XMP', 1 => 'XMP-flickr', 2 => 'Image' },
  NAMESPACE => 'flickr',
);
%Image::ExifTool::UserDefined = (
  'Image::ExifTool::XMP::pdfx' => {
    document_id => { Writable => 'string', },
    description => { Writable => 'string', },
  },
  'Image::ExifTool::XMP::flickr' => {
    id        => { Writable => 'integer' },
    url       => { Writable => 'string' },
    data      => { Writable => 'lang-alt' },
    views     => { Writable => 'integer' },
    faves     => { Writable => 'integer' },
  },
);
1;
