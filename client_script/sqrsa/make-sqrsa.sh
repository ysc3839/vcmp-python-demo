#!/bin/sh
cat \
  util/imp-compatibility.nut \
  util/buffer.nut \
  util/blob.nut \
  util/crypto.nut \
  util/dynamic-blob-array.nut \
  encoding/der/der-node-type.nut \
  encoding/der/der-node.nut \
  encrypt/algo/rsa-algorithm.nut \
  vukicevic/crunch/crunch.nut \
  > sqrsa.nut
