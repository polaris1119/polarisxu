#!/bin/sh

hugo

cp -rf public/* ../polaris1119.github.io/docs/

cd ../polaris1119.github.io/

git add * && git commit -m 'new article' && git push

cd ../polarisxu/
