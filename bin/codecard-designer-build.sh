echo "const ORDS_BASE_URL = 'https://$1/ords/cc';" > designer/resources/url.js
python3 ../bin/bulk-upload.py designer
