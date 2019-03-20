/**
 * Copyright (C) 2016-2018 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * DerNode implements the DER node types used in encoding/decoding DER-formatted
 * data.
 */
class DerNode {
  nodeType_ = 0;
  parent_ = null;
  header_ = null;
  payload_ = null;
  payloadPosition_ = 0;

  /**
   * Create a generic DER node with the given nodeType. This is a private
   * constructor used by one of the public DerNode subclasses defined below.
   * @param {integer} nodeType The DER type from the DerNodeType enum.
   */
  constructor(nodeType)
  {
    nodeType_ = nodeType;
    header_ = Buffer(0);
    payload_ = DynamicBlobArray(0);
  }

  /**
   * Return the number of bytes in the DER encoding.
   * @return {integer} The number of bytes.
   */
  function getSize()
  {
    return header_.len() + payloadPosition_;
  }

  /**
   * Encode the given size and update the header.
   * @param {integer} size
   */
  function encodeHeader(size)
  {
    local buffer = DynamicBlobArray(10);
    local bufferPosition = 0;
    buffer.array_[bufferPosition++] = nodeType_;
    if (size < 0)
      // We don't expect this to happen since this is an internal method and
      // always called with the non-negative size() of some buffer.
      throw "DER object has negative length";
    else if (size <= 127)
      buffer.array_[bufferPosition++] = size & 0xff;
    else {
      local tempBuf = DynamicBlobArray(10);
      // We encode backwards from the back.

      local val = size;
      local n = 0;
      while (val != 0) {
        ++n;
        tempBuf.ensureLengthFromBack(n);
        tempBuf.array_[tempBuf.array_.len() - n] = val & 0xff;
        val = val >> 8;
      }
      local nTempBufBytes = n + 1;
      tempBuf.ensureLengthFromBack(nTempBufBytes);
      tempBuf.array_[tempBuf.array_.len() - nTempBufBytes] = ((1<<7) | n) & 0xff;

      buffer.copy(Buffer.from
        (tempBuf.array_, tempBuf.array_.len() - nTempBufBytes), bufferPosition);
      bufferPosition += nTempBufBytes;
    }

    header_ = Buffer.from(buffer.array_, 0, bufferPosition);
  }

  /**
   * Extract the header from an input buffer and return the size.
   * @param {Buffer} inputBuf The input buffer to read from.
   * @param {integer} startIdx The offset into the buffer.
   * @return {integer} The parsed size in the header.
   */
  function decodeHeader(inputBuf, startIdx)
  {
    local idx = startIdx;

    // Use Buffer.get to avoid using the metamethod.
    local nodeType = inputBuf.get(idx) & 0xff;
    idx += 1;

    nodeType_ = nodeType;

    local sizeLen = inputBuf.get(idx) & 0xff;
    idx += 1;

    local header = DynamicBlobArray(10);
    local headerPosition = 0;
    header.array_[headerPosition++] = nodeType;
    header.array_[headerPosition++] = sizeLen;

    local size = sizeLen;
    local isLongFormat = (sizeLen & (1 << 7)) != 0;
    if (isLongFormat) {
      local lenCount = sizeLen & ((1<<7) - 1);
      size = 0;
      while (lenCount > 0) {
        local b = inputBuf.get(idx);
        idx += 1;
        header.ensureLength(headerPosition + 1);
        header.array_[headerPosition++] = b;
        size = 256 * size + (b & 0xff);
        lenCount -= 1;
      }
    }

    header_ = Buffer.from(header.array_, 0, headerPosition);
    return size;
  }

  // TODO: encode

  /**
   * Decode and store the data from an input buffer.
   * @param {Buffer} inputBuf The input buffer to read from. This reads from
   * startIdx (regardless of the buffer's position) and does not change the
   * position.
   * @param {integer} startIdx The offset into the buffer.
   */
  function decode(inputBuf, startIdx)
  {
    local idx = startIdx;
    local payloadSize = decodeHeader(inputBuf, idx);
    local skipBytes = header_.len();
    if (payloadSize > 0) {
      idx += skipBytes;
      payloadAppend(inputBuf.slice(idx, idx + payloadSize));
    }
  }

  /**
   * Copy buffer to payload_ at payloadPosition_ and update payloadPosition_.
   * @param {Buffer} buffer The buffer to copy.
   */
  function payloadAppend(buffer)
  {
    payloadPosition_ = payload_.copy(buffer, payloadPosition_);
  }

  /**
   * Parse the data from the input buffer recursively and return the root as an
   * object of a subclass of DerNode.
   * @param {Buffer} inputBuf The input buffer to read from.
   * @param {integer} startIdx (optional) The offset into the buffer. If
   * omitted, use 0.
   * @return {DerNode} An object of a subclass of DerNode.
   */
  static function parse(inputBuf, startIdx = 0)
  {
    // Use Buffer.get to avoid using the metamethod.
    local nodeType = inputBuf.get(startIdx) & 0xff;
    // Don't increment idx. We're just peeking.

    local newNode;
    if (nodeType == DerNodeType.Boolean)
      newNode = DerNode_DerBoolean();
    else if (nodeType == DerNodeType.Integer)
      newNode = DerNode_DerInteger();
    else if (nodeType == DerNodeType.BitString)
      newNode = DerNode_DerBitString();
    else if (nodeType == DerNodeType.OctetString)
      newNode = DerNode_DerOctetString();
    else if (nodeType == DerNodeType.Null)
      newNode = DerNode_DerNull();
    else if (nodeType == DerNodeType.ObjectIdentifier)
      newNode = DerNode_DerOid();
    else if (nodeType == DerNodeType.Sequence)
      newNode = DerNode_DerSequence();
    else if (nodeType == DerNodeType.PrintableString)
      newNode = DerNode_DerPrintableString();
    else if (nodeType == DerNodeType.GeneralizedTime)
      newNode = DerNode_DerGeneralizedTime();
    else
      throw "Unimplemented DER type " + nodeType;

    newNode.decode(inputBuf, startIdx);
    return newNode;
  }

  /**
   * Convert the encoded data to a standard representation. Overridden by some
   * subclasses (e.g. DerBoolean).
   * @return {Blob} The encoded data as a Blob.
   */
  function toVal() { return encode(); }

  /**
   * Get a copy of the payload bytes.
   * @return {Blob} A copy of the payload.
   */
  function getPayload()
  {
    payload_.array_.seek(0);
    return Blob(payload_.array_.readblob(payloadPosition_), false);
  }

  /**
   * If this object is a DerNode_DerSequence, get the children of this node.
   * Otherwise, throw an exception. (DerSequence overrides to implement this
   * method.)
   * @return {Array<DerNode>} The children as an array of DerNode.
   * @throws string if this object is not a Dernode_DerSequence.
   */
  function getChildren() { throw "not implemented"; }

  /**
   * Check that index is in bounds for the children list, return children[index].
   * @param {Array<DerNode>} children The list of DerNode, usually returned by
   * another call to getChildren.
   * @param {integer} index The index of the children.
   * @return {DerNode_DerSequence} children[index].
   * @throws string if index is out of bounds or if children[index] is not a
   * DerNode_DerSequence.
   */
  static function getSequence(children, index)
  {
    if (index < 0 || index >= children.len())
      throw "Child index is out of bounds";

    if (!(children[index] instanceof DerNode_DerSequence))
      throw "Child DerNode is not a DerSequence";

    return children[index];
  }
}

/**
 * A DerNode_DerStructure extends DerNode to hold other DerNodes.
 */
class DerNode_DerStructure extends DerNode {
  childChanged_ = false;
  nodeList_ = null;
  size_ = 0;

  /**
   * Create a DerNode_DerStructure with the given nodeType. This is a private
   * constructor. To create an object, use DerNode_DerSequence.
   * @param {integer} nodeType One of the defined DER DerNodeType constants.
   */
  constructor(nodeType)
  {
    // Call the base constructor.
    base.constructor(nodeType);

    nodeList_ = []; // Of DerNode.
  }

  /**
   * Get the total length of the encoding, including children.
   * @return {integer} The total (header + payload) length.
   */
  function getSize()
  {
    if (childChanged_) {
      updateSize();
      childChanged_ = false;
    }

    encodeHeader(size_);
    return size_ + header_.len();
  };

  /**
   * Get the children of this node.
   * @return {Array<DerNode>} The children as an array of DerNode.
   */
  function getChildren() { return nodeList_; }

  function updateSize()
  {
    local newSize = 0;

    for (local i = 0; i < nodeList_.len(); ++i) {
      local n = nodeList_[i];
      newSize += n.getSize();
    }

    size_ = newSize;
    childChanged_ = false;
  };

  /**
   * Add a child to this node.
   * @param {DerNode} node The child node to add.
   * @param {bool} (optional) notifyParent Set to true to cause any containing
   * nodes to update their size.  If omitted, use false.
   */
  function addChild(node, notifyParent = false)
  {
    node.parent_ = this;
    nodeList_.append(node);

    if (notifyParent) {
      if (parent_ != null)
        parent_.setChildChanged();
    }

    childChanged_ = true;
  }

  /**
   * Mark the child list as dirty, so that we update size when necessary.
   */
  function setChildChanged()
  {
    if (parent_ != null)
      parent_.setChildChanged();
    childChanged_ = true;
  }

  // TODO: encode

  /**
   * Override the base decode to decode and store the data from an input
   * buffer. Recursively populates child nodes.
   * @param {Buffer} inputBuf The input buffer to read from.
   * @param {integer} startIdx The offset into the buffer.
   */
  function decode(inputBuf, startIdx)
  {
    local idx = startIdx;
    size_ = decodeHeader(inputBuf, idx);
    idx += header_.len();

    local accSize = 0;
    while (accSize < size_) {
      local node = DerNode.parse(inputBuf, idx);
      local size = node.getSize();
      idx += size;
      accSize += size;
      addChild(node, false);
    }
  }
}

////////
// Now for all the node types...
////////

/**
 * A DerNode_DerByteString extends DerNode to handle byte strings.
 */
class DerNode_DerByteString extends DerNode {
  /**
   * Create a DerNode_DerByteString with the given inputData and nodeType. This
   * is a private constructor used by one of the public subclasses such as
   * DerOctetString or DerPrintableString.
   * @param {Buffer} inputData An input buffer containing the string to encode.
   * @param {integer} nodeType One of the defined DER DerNodeType constants.
   */
  constructor(inputData = null, nodeType = null)
  {
    // Call the base constructor.
    base.constructor(nodeType);

    if (inputData != null) {
      payloadAppend(inputData);
      encodeHeader(inputData.len());
    }
  }

  /**
   * Override to return just the byte string.
   * @return {Blob} The byte string as a copy of the payload buffer.
   */
  function toVal() { return getPayload(); }
}

// TODO: DerNode_DerBoolean

/**
 * DerNode_DerInteger extends DerNode to encode an integer value.
 */
class DerNode_DerInteger extends DerNode {
  /**
   * Create a DerNode_DerInteger for the value.
   * @param {integer|Buffer} integer The value to encode. If integer is a Buffer
   * byte array of a positive integer, you must ensure that the first byte is
   * less than 0x80.
   */
  constructor(integer = null)
  {
    // Call the base constructor.
    base.constructor(DerNodeType.Integer);

    if (integer != null) {
      if (Buffer.isBuffer(integer)) {
        if (integer.len() > 0 && integer.get(0) >= 0x80)
          throw "Negative integers are not currently supported";

        if (integer.len() == 0)
          payloadAppend(Buffer([0]));
        else
          payloadAppend(integer);
      }
      else {
        if (integer < 0)
          throw "Negative integers are not currently supported";

        // Convert the integer to bytes the easy/slow way.
        local temp = DynamicBlobArray(10);
        // We encode backwards from the back.
        local length = 0;
        while (true) {
          ++length;
          temp.ensureLengthFromBack(length);
          temp.array_[temp.array_.len() - length] = integer & 0xff;
          integer = integer >> 8;

          if (integer <= 0)
            // We check for 0 at the end so we encode one byte if it is 0.
            break;
        }

        if (temp.array_[temp.array_.len() - length] >= 0x80) {
          // Make it a non-negative integer.
          ++length;
          temp.ensureLengthFromBack(length);
          temp.array_[temp.array_.len() - length] = 0;
        }

        payloadAppend(Buffer.from(temp.array_, temp.array_.len() - length));
      }

      encodeHeader(payloadPosition_);
    }
  }

  function toVal()
  {
    if (payloadPosition_ > 0 && payload_.array[0] >= 0x80)
      throw "Negative integers are not currently supported";

    local result = 0;
    for (local i = 0; i < payloadPosition_; ++i) {
      result = result << 8;
      result += payload_.array_[i];
    }

    return result;
  }

  /**
   * Return an array of bytes, removing the leading zero, if any.
   * @return {Array<integer>} The array of bytes.
   */
  function toUnsignedArray()
  {
    local iFrom = (payloadPosition_ > 1 && payload_.array_[0] == 0) ? 1 : 0;
    local result = array(payloadPosition_ - iFrom);
    local iTo = 0;
    while (iFrom < payloadPosition_)
      result[iTo++] = payload_.array_[iFrom++];

    return result;
  }
}

/**
 * A DerNode_DerBitString extends DerNode to handle a bit string.
 */
class DerNode_DerBitString extends DerNode {
  /**
   * Create a DerBitString with the given padding and inputBuf.
   * @param {Buffer} inputBuf An input buffer containing the bit octets to encode.
   * @param {integer} paddingLen The number of bits of padding at the end of the
   * bit string. Should be less than 8.
   */
  constructor(inputBuf = null, paddingLen = null)
  {
    // Call the base constructor.
    base.constructor(DerNodeType.BitString);

    if (inputBuf != null) {
      payload_.ensureLength(payloadPosition_ + 1);
      payload_.array_[payloadPosition_++] = paddingLen & 0xff;
      payloadAppend(inputBuf);
      encodeHeader(payloadPosition_);
    }
  }
}

/**
 * DerNode_DerOctetString extends DerNode_DerByteString to encode a string of
 * bytes.
 */
class DerNode_DerOctetString extends DerNode_DerByteString {
  /**
   * Create a DerOctetString for the inputData.
   * @param {Buffer} inputData An input buffer containing the string to encode.
   */
  constructor(inputData = null)
  {
    // Call the base constructor.
    base.constructor(inputData, DerNodeType.OctetString);
  }
}

/**
 * A DerNode_DerNull extends DerNode to encode a null value.
 */
class DerNode_DerNull extends DerNode {
  /**
   * Create a DerNull.
   */
  constructor()
  {
    // Call the base constructor.
    base.constructor(DerNodeType.Null);

    encodeHeader(0);
  }
}

/**
 * A DerNode_DerOid extends DerNode to represent an object identifier.
 */
class DerNode_DerOid extends DerNode {
  /**
   * Create a DerOid with the given object identifier. The object identifier
   * string must begin with 0,1, or 2 and must contain at least 2 digits.
   * @param {string|OID} oid The OID string or OID object to encode.
   */
  constructor(oid = null)
  {
    // Call the base constructor.
    base.constructor(DerNodeType.ObjectIdentifier);

    if (oid != null) {
      // TODO: Implement oid decoding.
      throw "not implemented";
    }
  }

  // TODO: prepareEncoding
  // TODO: encode128
  // TODO: decode128
  // TODO: toVal
}

/**
 * A DerNode_DerSequence extends DerNode_DerStructure to contains an ordered
 * sequence of other nodes.
 */
class DerNode_DerSequence extends DerNode_DerStructure {
  /**
   * Create a DerSequence.
   */
  constructor()
  {
    // Call the base constructor.
    base.constructor(DerNodeType.Sequence);
  }
}

// TODO: DerNode_DerPrintableString
// TODO: DerNode_DerGeneralizedTime
