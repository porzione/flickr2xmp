## https://stackoverflow.com/questions/24416653/is-it-possible-to-create-a-custom-namespace-tag-in-xmp-dublin-core-metadata
# exiftool -config exiftool.pl -xmp-flickr:data='qqq' _8141513.ORF.xmp
%Image::ExifTool::UserDefined = (
  'Image::ExifTool::XMP::dc' => {
    flickr => { },
  }
);
1;
