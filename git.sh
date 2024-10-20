#!/bin/sh
str="'$*'"
ruby docs.rb && git add . && git commit -m "$str" && git push
