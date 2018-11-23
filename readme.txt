# Examples

# build simple images database 'photo.db' from given path 

./builddb -i /home/ftp/images/test -v -e darktable_exported > z_log 2> z_errlog

# dump database contents

./dumpdb

# write sidecar xmp files beside the images

./rflickr -j /home/ftp/dl/fox/flickr/ --st ND110 --st long --st exposure
