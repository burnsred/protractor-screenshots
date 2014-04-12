#!/bin/sh

echo "Running tests for protractor-demo"

cd protractor-demo
node app/expressserver.js > /dev/null 2>&1 &
../../node_modules/.bin/protractor test/conf.js > /dev/null 2>&1
cd ..

kill $!

# Compare the screenshots to make sure the right ones failed.
diff --exclude "\.DS_Store" -r expected-screenshots protractor-demo/test/screenshots

if [ $? -eq 0 ]; then
    echo PASS
else
    echo FAIL
fi
