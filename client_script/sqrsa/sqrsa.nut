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
 * Standard Squirrel code should include this first to use Electric Imp Squirrel
 * code written with math.abs(x), etc.
 */
if (!("math" in getroottable())) {
  // We are not on the Imp, so define math.
  math <- {
    function abs(x) { return ::abs(x); }
    function acos(x) { return ::acos(x); }
    function asin(x) { return ::asin(x); }
    function atan(x) { return ::atan(x); }
    function atan2(x, y) { return ::atan2(x, y); }
    function ceil(x) { return ::ceil(x); }
    function cos(x) { return ::cos(x); }
    function exp(x) { return ::exp(x); }
    function fabs(x) { return ::fabs(x); }
    function floor(x) { return ::floor(x); }
    function log(x) { return ::log(x); }
    function log10(x) { return ::log10(x); }
    function pow(x, y) { return ::pow(x, y); }
    function rand() { return ::rand(); }
    function sin(x) { return ::sin(x); }
    function sqrt(x) { return ::sqrt(x); }
    function tan(x) { return ::tan(x); }
  }
}
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
 * A Buffer wraps a Squirrel blob and provides an API imitating the Node.js
 * Buffer class, especially where the slice method returns a view onto the
 * same underlying blob array instead of making a copy. The size of the
 * underlying Squirrel blob is fixed and can't be resized.
 */
class Buffer {
  blob_ = ::blob(0);
  offset_ = 0;
  len_ = 0;

  /**
   * Create a new Buffer based on the value.
   * @param {integer|Buffer|blob|array<integer>|string} value If value is an
   * integer, create a new underlying blob of the given size. If value is a
   * Buffer, copy its bytes into a new underlying blob of size value.len(). (If
   * you want a new Buffer without copying, use value.size().) If value is a
   * Squirrel blob, copy its bytes into a new underlying blob. (If you want a
   * new Buffer without copying the blob, use Buffer.from(value).) If value is a
   * byte array, copy into a new underlying blob. If value is a string, treat it
   * as "raw" and copy to a new underlying blob without UTF-8 encoding.
   * @param {string} encoding (optional) If value is a string, convert it to a
   * byte array as follows. If encoding is "raw" or omitted, copy value to a new
   * underlying blob without UTF-8 encoding. If encoding is "hex", value must be
   * a sequence of pairs of hexadecimal digits, so convert them to integers.
   * @throws string if the encoding is unrecognized or a hex string has invalid
   * characters (or is not a multiple of 2 in length).
   */
  constructor(value, encoding = "raw")
  {
    local valueType = typeof value;

    if (valueType == "blob") {
      // Copy.
      if (value.len() > 0) {
        // Copy the value blob. Set and restore its read/write pointer.
        local savePointer = value.tell();
        value.seek(0);
        blob_ = value.readblob(value.len());
        value.seek(savePointer);

        len_ = value.len();
      }
    }
    else if (valueType == "integer") {
      if (value > 0) {
        blob_ = ::blob(value);
        len_ = value;
      }
    }
    else if (valueType == "array") {
      // Assume the array has integer values.
      blob_ = ::blob(value.len());
      foreach (x in value)
        blob_.writen(x, 'b');

      len_ = value.len();
    }
    else if (valueType == "string") {
      if (encoding == "raw") {
        // Just copy the string. Don't UTF-8 decode.
        blob_ = ::blob(value.len());
        // Don't use writestring since Standard Squirrel doesn't have it.
        foreach (x in value)
          blob_.writen(x, 'b');

        len_ = value.len();
      }
      else if (encoding == "hex") {
        if (value.len() % 2 != 0)
          throw "Invalid hex value";
        len_ = value.len() / 2;
        blob_ = ::blob(len_);

        local iBlob = 0;
        for (local i = 0; i < value.len(); i += 2) {
          local hi = ::Buffer.fromHexChar(value[i]);
          local lo = ::Buffer.fromHexChar(value[i + 1]);
          if (hi < 0 || lo < 0)
            throw "Invalid hex value";

          blob_[iBlob++] = 16 * hi + lo;
        }
      }
      else
        throw "Unrecognized encoding";
    }
    else if (value instanceof ::Buffer) {
      if (value.len_ > 0) {
        // Copy only the bytes we needed from the value's blob.
        value.blob_.seek(value.offset_);
        blob_ = value.blob_.readblob(value.len_);

        len_ = value.len_;
      }
    }
    else
      throw "Unrecognized type";
  }

  /**
   * Get a new Buffer which wraps the given Squirrel blob, sharing its array.
   * @param {blob} blob The Squirrel blob to use for the new Buffer.
   * @param {integer} offset (optional) The index where the new Buffer will
   * start. If omitted, use 0.
   * @param {integer} len (optional) The number of bytes from the given blob
   * that this Buffer will share. If omitted, use blob.len() - offset.
   * @return {Buffer} A new Buffer.
   */
  static function from(blob, offset = 0, len = null)
  {
    if (len == null)
      len = blob.len() - offset;

    // TODO: Do a bounds check?
    // First create a Buffer with default values, then set the blob_ and len_.
    local result = Buffer(0);
    result.blob_ = blob;
    result.offset_ = offset;
    result.len_ = len;
    return result;
  }

  /**
   * Get the length of this Buffer.
   * @return {integer} The length.
   */
  function len() { return len_; }

  /**
   * Copy bytes from a region of this Buffer to a region in target even if the
   * target region overlaps this Buffer.
   * @param {Buffer|blob|array} target The Buffer or Squirrel blob or array of
   * integers to copy to.
   * @param {integer} targetStart (optional) The start index in target to copy
   * to. If omitted, use 0.
   * @param {integer} sourceStart (optional) The start index in this Buffer to
   * copy from. If omitted, use 0.
   * @param {integer} sourceEnd (optional) The end index in this Buffer to copy
   * from (not inclusive). If omitted, use len().
   * @return {integer} The number of bytes copied.
   */
  function copy(target, targetStart = 0, sourceStart = 0, sourceEnd = null)
  {
    if (sourceEnd == null)
      sourceEnd = len_;

    local nBytes = sourceEnd - sourceStart;

    // Get the index in the source and target blobs.
    local iSource = offset_ + sourceStart;
    local targetBlob;
    local iTarget;
    if (target instanceof ::Buffer) {
      targetBlob = target.blob_;
      iTarget = target.offset_ + targetStart;
    }
    else if (typeof target == "array") {
      // Special case. Just copy bytes to the array and return.
      iTarget = targetStart;
      local iEnd = offset_ + sourceEnd;
      while (iSource < iEnd)
        target[iTarget++] = blob_[iSource++];
      return nBytes;
    }
    else {
      targetBlob = target;
      iTarget = targetStart;
    }

    if (targetBlob == blob_) {
      // We are copying within the same blob.
      if (iTarget > iSource && iTarget < offset_ + sourceEnd)
        // Copying to the target will overwrite the source.
        throw "Buffer.copy: Overlapping copy is not supported yet";
    }

    if (iSource == 0 && sourceEnd == blob_.len()) {
      // We can use writeblob to copy the entire blob_.
      // Set and restore its read/write pointer.
      local savePointer = targetBlob.tell();
      targetBlob.seek(iTarget);
      targetBlob.writeblob(blob_);
      targetBlob.seek(savePointer);
    }
    else {
      // Don't use blob's readblob since it makes its own copy.
      // TODO: Does Squirrel have a memcpy?
      local iEnd = offset_ + sourceEnd;
      while (iSource < iEnd)
        targetBlob[iTarget++] = blob_[iSource++];
    }

    return nBytes;
  }

  /**
   * Get a new Buffer that references the same underlying blob array as the
   * original, but offset and cropped by the start and end indices. Note that
   * modifying the new Buffer slice will modify the original Buffer because the
   * allocated blob array portions of the two objects overlap.
   * @param {integer} start (optional) The index where the new Buffer will start.
   * If omitted, use 0.
   * @param {integer} end (optional) The index where the new Buffer will end
   * (not inclusive). If omitted, use len().
   */
  function slice(start = 0, end = null)
  {
    if (end == null)
      end = len_;

    if (start == 0 && end == len_)
      return this;

    // TODO: Do a bounds check?
    local result = ::Buffer.from(blob_);
    // Fix offset_ and len_.
    result.offset_ = offset_ + start;
    result.len_ = end - start;
    return result;
  }

  /**
   * Return a new Buffer which is the result of concatenating all the Buffer 
   * instances in the list together.
   * @param {Array<Buffer>} list An array of Buffer instances to concat. If the
   * list has no items, return a new zero-length Buffer.
   * @param {integer} (optional) totalLength The total length of the Buffer
   * instances in list when concatenated. If omitted, calculate the total
   * length, but this causes an additional loop to be executed, so it is faster
   * to provide the length explicitly if it is already known. If the total
   * length is zero, return a new zero-length Buffer.
   * @return {Buffer} A new Buffer.
   */
  static function concat(list, totalLength = null)
  {
    if (list.len() == 1)
      // A simple case.
      return ::Buffer(list[0]);
  
    if (totalLength == null) {
      totalLength = 0;
      foreach (buffer in list)
        totalLength += buffer.len();
    }

    local result = ::blob(totalLength);
    local offset = 0;
    foreach (buffer in list) {
      buffer.copy(result, offset);
      offset += buffer.len();
    }

    return ::Buffer.from(result);
  }

  /**
   * Get a string with the bytes in the blob array using the given encoding.
   * @param {string} encoding If encoding is "hex", return the hex
   * representation of the bytes in the blob array. If encoding is "raw",
   * return the bytes of the byte array as a raw str of the same length. (This
   * does not do any character encoding such as UTF-8.)
   * @return {string} The encoded string.
   */
  function toString(encoding)
  {
    if (encoding == "hex") {
      // TODO: Does Squirrel have a StringBuffer?
      local result = "";
      for (local i = 0; i < len_; ++i)
        result += ::format("%02x", get(i));

      return result;
    }
    else if (encoding == "raw") {
      // Don't use readstring since Standard Squirrel doesn't have it.
      local result = "";
      // TODO: Does Squirrel have a StringBuffer?
      for (local i = 0; i < len_; ++i)
        result += get(i).tochar();

      return result;
    }
    else
      throw "Unrecognized encoding";
  }

  /**
   * Return a copy of the bytes of the array as a Squirrel blob.
   * @return {blob} A new Squirrel blob with the copied bytes.
   */
  function toBlob()
  {
    if (len_ <= 0)
      return ::blob(0);

    blob_.seek(offset_);
    return blob_.readblob(len_);
  }

  /**
   * A utility function to convert the hex character to an integer from 0 to 15.
   * @param {integer} c The integer character.
   * @return (integer} The hex value, or -1 if x is not a hex character.
   */
  static function fromHexChar(c)
  {
    if (c >= '0' && c <= '9')
      return c - '0';
    else if (c >= 'A' && c <= 'F')
      return c - 'A' + 10;
    else if (c >= 'a' && c <= 'f')
      return c - 'a' + 10;
    else
      return -1;
  }

  /**
   * Get the value at the index.
   * @param {integer} i The zero-based index into the buffer array.
   * @return {integer} The value at the index.
   */
  function get(i) { return blob_[offset_ + i]; }

  /**
   * Set the value at the index.
   * @param {integer} i The zero-based index into the buffer array.
   * @param {integer} value The value to set.
   */
  function set(i, value) { blob_[offset_ + i] = value; }

  function _get(i)
  {
    // Note: In this class, we always reference globals with :: to avoid
    // invoking this _get metamethod.

    if (typeof i == "integer")
      // TODO: Do a bounds check?
      return blob_[offset_ + i];
    else
      throw "Unrecognized type";
  }

  function _set(i, value)
  {
    if (typeof i == "integer")
      // TODO: Do a bounds check?
      blob_[offset_ + i] = value;
    else
      throw "Unrecognized type";
  }

  function _nexti(previdx)
  {
    if (len_ <= 0)
      return null;
    else if (previdx == null)
      return 0;
    else if (previdx == len_ - 1)
      return null;
    else
      return previdx + 1;
  }
}
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
 * A Blob holds an immutable byte array implemented as a Buffer. This should be
 * treated like a string which is a pointer to an immutable string. (It is OK to
 * pass a pointer to the string because the new owner can’t change the bytes of
 * the string.)  Instead you must call buf() to get the byte array which reminds
 * you that you should not change the contents.  Also remember that buf() can
 * return null.
 */
class Blob {
  buffer_ = null;

  /**
   * Create a new Blob which holds an immutable array of bytes.
   * @param {Blob|SignedBlob|Buffer|blob|array<integer>|string} value (optional)
   * If value is a Blob or SignedBlob, take another pointer to its Buffer
   * without copying. If value is a Buffer or Squirrel blob, optionally copy.
   * If value is a byte array, copy to create a new Buffer. If value is a string,
   * treat it as "raw" and copy to a byte array without UTF-8 encoding.  If
   * omitted, buf() will return null.
   * @param {bool} copy (optional) If true, copy the contents of value into a 
   * new Buffer. If value is a Squirrel blob, copy the entire array, ignoring
   * the location of its blob pointer given by value.tell().  If copy is false,
   * and value is a Buffer or Squirrel blob, just use it without copying. If
   * omitted, then copy the contents (unless value is already a Blob).
   * IMPORTANT: If copy is false, if you keep a pointer to the value then you
   * must treat the value as immutable and promise not to change it.
   */
  constructor(value = null, copy = true)
  {
    if (value == null)
      buffer_ = null;
    else if (value instanceof Blob)
      // Use the existing buffer. Don't need to check for copy.
      buffer_ = value.buffer_;
    else {
      if (copy)
        // We are copying, so just make another Buffer.
        buffer_ = Buffer(value);
      else {
        if (value instanceof Buffer)
          // We can use it as-is.
          buffer_ = value;
        else if (typeof value == "blob")
          buffer_ = Buffer.from(value);
        else
          // We need a Buffer, so copy.
          buffer_ = Buffer(value);
      }
    }
  }

  /**
   * Return the length of the immutable byte array.
   * @return {integer} The length of the array.  If buf() is null, return 0.
   */
  function size()
  {
    if (buffer_ != null)
      return buffer_.len();
    else
      return 0;
  }

  /**
   * Return the immutable byte array.  DO NOT change the contents of the buffer.
   * If you need to change it, make a copy.
   * @return {Buffer} The Buffer holding the immutable byte array, or null.
   */
  function buf() { return buffer_; }

  /**
   * Return true if the array is null, otherwise false.
   * @return {bool} True if the array is null.
   */
  function isNull() { return buffer_ == null; }

  /**
   * Return the hex representation of the bytes in the byte array.
   * @return {string} The hex string.
   */
  function toHex()
  {
    if (buffer_ == null)
      return "";
    else
      return buffer_.toString("hex");
  }

  /**
   * Return the bytes of the byte array as a raw str of the same length. This
   * does not do any character encoding such as UTF-8.
   * @return The buffer as a string, or "" if isNull().
   */
  function toRawStr()
  {
    if (buffer_ == null)
      return "";
    else
      return buffer_.toString("raw");
  }

  /**
   * Check if the value of this Blob equals the other blob.
   * @param {Blob} other The other Blob to check.
   * @return {bool} if this isNull and other isNull or if the bytes of this Blob
   * equal the bytes of the other.
   */
  function equals(other)
  {
    if (isNull())
      return other.isNull();
    else if (other.isNull())
      return false;
    else {
      if (buffer_.len() != other.buffer_.len())
        return false;

      // TODO: Does Squirrel have a native buffer compare?
      for (local i = 0; i < buffer_.len(); ++i) {
        if (buffer_.get(i) != other.buffer_.get(i))
          return false;
      }

      return true;
    }
  }
}
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
 * Crypto has static methods for basic cryptography operations.
 */
class Crypto {
  /**
   * Fill the value with random bytes. Note: If not on the Imp, you must seed
   * with srand().
   * @param {Buffer|blob} value Write the random bytes to this array from
   * startIndex to endIndex. If this is a Squirrel blob, it ignores the location
   * of the blob pointer given by value.tell() and does not update the blob
   * pointer.
   * @param startIndex (optional) The index of the first byte in value to set.
   * If omitted, start from index 0.
   * @param endIndex (optional) Set bytes in value up to endIndex - 1. If
   * omitted, set up to value.len() - 1.
   */
  static function generateRandomBytes(value, startIndex = 0, endIndex = null)
  {
    if (endIndex == null)
      endIndex = value.len();

    local valueIsBuffer = (value instanceof Buffer);
    for (local i = startIndex; i < endIndex; ++i) {
      local x = ((1.0 * math.rand() / RAND_MAX) * 256).tointeger();
      if (valueIsBuffer)
        // Use Buffer.set to avoid using the metamethod.
        value.set(i, x);
      else
        value[i] = x;
    }
  }

  /**
   * Get the Crunch object, creating it if necessary. (To save memory, we don't
   * want to create it until needed.)
   * @return {Crunch} The Crunch object.
   */
  static function getCrunch()
  {
    if (::Crypto_crunch_ == null)
      ::Crypto_crunch_ = Crunch();
    return ::Crypto_crunch_;
  }
}

Crypto_crunch_ <- null;
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
 * A DynamicBlobArray holds a Squirrel blob and provides methods to ensure a
 * minimum length, resizing if necessary.
 */
class DynamicBlobArray {
  array_ = null;        // blob

  /**
   * Create a new DynamicBlobArray with an initial length.
   * @param initialLength (optional) The initial length of the allocated array.
   * If omitted, use a default
   */
  constructor(initialLength = 16)
  {
    array_ = blob(initialLength);
  }

  /**
   * Ensure that the array has the minimal length, resizing it if necessary.
   * The new length of the array may be greater than the given length.
   * @param {integer} length The minimum length for the array.
   */
  function ensureLength(length)
  {
    // array_.len() is always the full length of the array.
    if (array_.len() >= length)
      return;

    // See if double is enough.
    local newLength = array_.len() * 2;
    if (length > newLength)
      // The needed length is much greater, so use it.
      newLength = length;

    // Instead of using resize, we manually copy to a new blob so that
    // array_.len() will be the full length.
    local newArray = blob(newLength);
    newArray.writeblob(array_);
    array_ = newArray;
  }

  /**
   * Copy the given buffer into this object's array, using ensureLength to make
   * sure there is enough room.
   * @param {Buffer} buffer A Buffer with the bytes to copy.
   * @param {integer} offset The offset in this object's array to copy to.
   * @return {integer} The new offset which is offset + buffer.length.
   */
  function copy(buffer, offset)
  {
    ensureLength(offset + buffer.len());
    buffer.copy(array_, offset);

    return offset + buffer.len();
  }

  /**
   * Ensure that the array has the minimal length. If necessary, reallocate the
   * array and shift existing data to the back of the new array. The new length
   * of the array may be greater than the given length.
   * @param {integer} length The minimum length for the array.
   */
  function ensureLengthFromBack(length)
  {
    // array_.len() is always the full length of the array.
    if (array_.len() >= length)
      return;

    // See if double is enough.
    local newLength = array_.len() * 2;
    if (length > newLength)
      // The needed length is much greater, so use it.
      newLength = length;

    local newArray = blob(newLength);
    // Copy to the back of newArray.
    newArray.seek(newArray.len() - array_.len());
    newArray.writeblob(array_);
    array_ = newArray;
  }

  /**
   * First call ensureLengthFromBack to make sure the bytearray has
   * offsetFromBack bytes, then copy the given buffer into this object's array
   * starting offsetFromBack bytes from the back of the array.
   * @param {Buffer} buffer A Buffer with the bytes to copy.
   * @param {integer} offset The offset from the back of the array to start
   * copying.
   */
  function copyFromBack(buffer, offsetFromBack)
  {
    ensureLengthFromBack(offsetFromBack);
    buffer.copy(array_, array_.len() - offsetFromBack);
  }

  /**
   * Wrap this object's array in a Buffer slice starting lengthFromBack from the
   * back of this object's array and make a Blob. Finally, set this object's
   * array to null to prevent further use.
   * @param {integer} lengthFromBack The final length of the allocated array.
   * @return {Blob} A new NDN Blob with the bytes from the array.
   */
  function finishFromBack(lengthFromBack)
  {
    local result = Blob
      (Buffer.from(array_, array_.len() - lengthFromBack), false);
    array_ = null;
    return result;
  }
}
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
 * The DerNodeType enum defines the known DER node types.
 */
enum DerNodeType {
  Eoc = 0,
  Boolean = 1,
  Integer = 2,
  BitString = 3,
  OctetString = 4,
  Null = 5,
  ObjectIdentifier = 6,
  ObjectDescriptor = 7,
  External = 40,
  Real = 9,
  Enumerated = 10,
  EmbeddedPdv = 43,
  Utf8String = 12,
  RelativeOid = 13,
  Sequence = 48,
  Set = 49,
  NumericString = 18,
  PrintableString = 19,
  T61String = 20,
  VideoTexString = 21,
  Ia5String = 22,
  UtcTime = 23,
  GeneralizedTime = 24,
  GraphicString = 25,
  VisibleString = 26,
  GeneralString = 27,
  UniversalString = 28,
  CharacterString = 29,
  BmpString = 30
}
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

// This requires contrib/vukicevic/crunch/crunch.nut .

/**
 * The RsaAlgorithm class provides static methods to manipulate keys, encrypt
 * and decrypt using RSA.
 * @note This class is an experimental feature. The API may change.
 */
class RsaAlgorithm {
  /**
   * Generate a new random decrypt key for RSA based on the given params.
   * @param {RsaKeyParams} params The key params with the key size (in bits).
   * @return {DecryptKey} The new decrypt key (containing a PKCS8-encoded
   * private key).
   */
  /*static function generateKey(params)
  {
    // TODO: Implement
    throw "not implemented"
  }*/

  /**
   * Derive a new encrypt key from the given decrypt key value.
   * @param {Blob} keyBits The key value of the decrypt key (PKCS8-encoded
   * private key).
   * @return {EncryptKey} The new encrypt key.
   */
  /*static function deriveEncryptKey(keyBits)
  {
    // TODO: Implement
    throw "not implemented"
  }*/

  /**
   * Decrypt the encryptedData using the keyBits according the encrypt params.
   * @param {Blob} keyBits The key value (PKCS8-encoded private key).
   * @param {Blob} encryptedData The data to decrypt.
   * @param {EncryptParams} params This decrypts according to
   * params.getAlgorithmType().
   * @return {Blob} The decrypted data.
   */
  static function decrypt(keyBits, encryptedData/*, params*/)
  {
    // keyBits is PKCS #8 but we need the inner RSAPrivateKey.
    local rsaPrivateKeyDer = RsaAlgorithm.getRsaPrivateKeyDer(keyBits);

    // Decode the PKCS #1 RSAPrivateKey.
    local parsedNode = DerNode.parse(rsaPrivateKeyDer.buf(), 0);
    local children = parsedNode.getChildren();
    local n = children[1].toUnsignedArray();
    local e = children[2].toUnsignedArray();
    local d = children[3].toUnsignedArray();
    local p = children[4].toUnsignedArray();
    local q = children[5].toUnsignedArray();
    local dp1 = children[6].toUnsignedArray();
    local dq1 = children[7].toUnsignedArray();

    local crunch = Crypto.getCrunch();
    // Apparently, we can't use the private key's coefficient which is inv(q, p);
    local u = crunch.inv(p, q);
    local encryptedArray = array(encryptedData.buf().len());
    encryptedData.buf().copy(encryptedArray);
    local padded = crunch.gar(encryptedArray, p, q, d, u, dp1, dq1);

    // We have to remove the padding.
    // Note that Crunch strips the leading zero.
    if (padded[0] != 0x02)
      return "Invalid decrypted value";
    local iEndZero = padded.find(0x00);
    if (iEndZero == null)
      return "Invalid decrypted value";
    local iFrom = iEndZero + 1;
    local plainData = blob(padded.len() - iFrom);
    local iTo = 0;
    while (iFrom < padded.len())
      plainData[iTo++] = padded[iFrom++];

    return Blob(Buffer.from(plainData), false);
  }

  /**
   * Encrypt the plainData using the keyBits according the encrypt params.
   * @param {Blob} keyBits The key value (DER-encoded public key).
   * @param {Blob} plainData The data to encrypt.
   * @param {EncryptParams} params This encrypts according to
   * params.getAlgorithmType().
   * @return {Blob} The encrypted data.
   */
  static function encrypt(keyBits, plainData/*, params*/)
  {
    // keyBits is SubjectPublicKeyInfo but we need the inner RSAPublicKey.
    local rsaPublicKeyDer = RsaAlgorithm.getRsaPublicKeyDer(keyBits);

    // Decode the PKCS #1 RSAPublicKey.
    // TODO: Decode keyBits.
    local parsedNode = DerNode.parse(rsaPublicKeyDer.buf(), 0);
    local children = parsedNode.getChildren();
    local n = children[0].toUnsignedArray();
    local e = children[1].toUnsignedArray();

    // We have to do the padding.
    local padded = array(n.len());
    //if (params.getAlgorithmType() == EncryptAlgorithmType.RsaPkcs) {
      padded[0] = 0x00;
      padded[1] = 0x02;

      // Fill with random non-zero bytes up to the end zero.
      local iEndZero = n.len() - 1 - plainData.size();
      if (iEndZero < 2)
        throw "Plain data size is too large";
      for (local i = 2; i < iEndZero; ++i) {
        local x = 0;
        while (x == 0)
          x = ((1.0 * math.rand() / RAND_MAX) * 256).tointeger();
        padded[i] = x;
      }

      padded[iEndZero] = 0x00;
      plainData.buf().copy(padded, iEndZero + 1);
    /*}
    else
      throw "Unsupported padding scheme";*/

    return Blob(Crypto.getCrunch().exp(padded, e, n));
  }

  /**
   * Decode the SubjectPublicKeyInfo, check that the algorithm is RSA, and
   * return the inner RSAPublicKey DER.
   * @param {Blob} The DER-encoded SubjectPublicKeyInfo.
   * @param {Blob} The DER-encoded RSAPublicKey.
   */
  static function getRsaPublicKeyDer(subjectPublicKeyInfo)
  {
    local parsedNode = DerNode.parse(subjectPublicKeyInfo.buf(), 0);
    local children = parsedNode.getChildren();
    local algorithmIdChildren = DerNode.getSequence(children, 0).getChildren();
/*  TODO: Finish implementing DerNode_DerOid
    local oidString = algorithmIdChildren[0].toVal();

    if (oidString != PrivateKeyStorage.RSA_ENCRYPTION_OID)
      throw "The PKCS #8 private key is not RSA_ENCRYPTION";
*/

    local payload = children[1].getPayload();
    // Remove the leading zero.
    return Blob(payload.buf().slice(1), false);
  }

  /**
   * Decode the PKCS #8 private key, check that the algorithm is RSA, and return
   * the inner RSAPrivateKey DER.
   * @param {Blob} The DER-encoded PKCS #8 private key.
   * @param {Blob} The DER-encoded RSAPrivateKey.
   */
  static function getRsaPrivateKeyDer(pkcs8PrivateKeyDer)
  {
    local parsedNode = DerNode.parse(pkcs8PrivateKeyDer.buf(), 0);
    local children = parsedNode.getChildren();
    local algorithmIdChildren = DerNode.getSequence(children, 1).getChildren();
/*  TODO: Finish implementing DerNode_DerOid
    local oidString = algorithmIdChildren[0].toVal();

    if (oidString != PrivateKeyStorage.RSA_ENCRYPTION_OID)
      throw "The PKCS #8 private key is not RSA_ENCRYPTION";
*/

    return children[2].getPayload();
  }
}
/**
 * Crunch - Arbitrary-precision integer arithmetic library
 * Copyright (C) 2014 Nenad Vukicevic crunch.secureroom.net/license
 */

/**
 * @module Crunch
 * Radix: 28 bits
 * Endianness: Big
 *
 * @param {boolean} rawIn   - expect 28-bit arrays
 * @param {boolean} rawOut  - return 28-bit arrays
 */
function Crunch (rawIn = false, rawOut = false) {
  /**
   * BEGIN CONSTANTS
   * primes and ptests for Miller-Rabin primality
   */

/* Remove support for primes until we need it.
  // sieve of Eratosthenes for first 1900 primes
  local primes = (function(n) {
    local arr  = array(math.ceil((n - 2) / 32).tointeger(), 0),
          maxi = (n - 3) / 2,
          p    = [2];

    for (local q = 3, i, index, bit; q < n; q += 2) {
      i     = (q - 3) / 2;
      index = i >> 5;
      bit   = i & 31;

      if ((arr[index] & (1 << bit)) == 0) {
        // q is prime
        p.push(q);
        i += q;

        for (local d = q; i < maxi; i += d) {
          index = i >> 5;
          bit   = i & 31;

          arr[index] = arr[index] | (1 << bit);
        }
      }
    }

    return p;

  })(16382);

  local ptests = primes.slice(0, 10).map(function (v) {
    return [v];
  });
*/

  /* END CONSTANTS */

  // Create a scope for the private methods so that they won't call the public
  // ones with the same name. This is different than JavaScript which has
  // different scoping rules.
  local priv = {

  function cut (x) {
    while (x[0] == 0 && x.len() > 1) {
      x.remove(0);
    }

    return x;
  }

  function cmp (x, y) {
    local xl = x.len(),
          yl = y.len(), i; //zero front pad problem

    if (xl < yl) {
      return -1;
    } else if (xl > yl) {
      return 1;
    }

    for (i = 0; i < xl; i++) {
      if (x[i] < y[i]) return -1;
      if (x[i] > y[i]) return 1;
    }

    return 0;
  }

  /**
   * Most significant bit, base 28, position from left
   */
  function msb (x) {
    if (x != 0) {
      local z = 0;
      for (local i = 134217728; i > x; z++) {
        i /= 2;
      }

      return z;
    }
  }

  /**
   * Most significant bit, base 14, position from left.
   * This is only needed for div14.
   */
  function msb14 (x) {
    if (x != 0) {
      local z = 0;
      // Start with 2^13.
      for (local i = 0x2000; i > x; z++) {
        i /= 2;
      }

      return z;
    }
  }

  /**
   * Least significant bit, position from right
   */
  function lsb (x) {
    if (x != 0) {
      local z = 0;
      for (; !(x & 1); z++) {
        x /= 2;
      }

      return z;
    }
  }

  function add (x, y) {
    local n = x.len(),
          t = y.len(),
          i = (n > t ? n : t),
          c = 0,
          z = array(i, 0);

    if (n < t) {
      x = concat(array(t-n, 0), x);
    } else if (n > t) {
      y = concat(array(n-t, 0), y);
    }

    for (i -= 1; i >= 0; i--) {
      z[i] = x[i] + y[i] + c;

      if (z[i] > 268435455) {
        c = 1;
        z[i] -= 268435456;
      } else {
        c = 0;
      }
    }

    if (c == 1) {
      z.insert(0, c);
    }

    return z;
  }

  /**
   * Effectively does abs(x) - abs(y).
   * The result is negative if cmp(x, y) < 0.
   */
  function sub (x, y, internal = false) {
    local n = x.len(),
          t = y.len(),
          i = (n > t ? n : t),
          c = 0,
          z = array(i, 0);

    if (n < t) {
      x = concat(array(t-n, 0), x);
    } else if (n > t) {
      y = concat(array(n-t, 0), y);
    }

    for (i -= 1; i >= 0; i--) {
      z[i] = x[i] - y[i] - c;

      if (z[i] < 0) {
        c = 1;
        z[i] += 268435456;
      } else {
        c = 0;
      }
    }

    if (c == 1 && !internal) {
      z = sub(array(z.len(), 0), z, true);
    }

    return z;
  }

  // The same as sub(x, y) except x and y are base 14.
  // This is only needed for div14.
  function sub14 (x, y, internal = false) {
    local n = x.len(),
          t = y.len(),
          i = (n > t ? n : t),
          c = 0,
          z = array(i, 0);

    if (n < t) {
      x = concat(array(t-n, 0), x);
    } else if (n > t) {
      y = concat(array(n-t, 0), y);
    }

    for (i -= 1; i >= 0; i--) {
      z[i] = x[i] - y[i] - c;

      if (z[i] < 0) {
        c = 1;
        // Add 2^14
        z[i] += 0x4000;
      } else {
        c = 0;
      }
    }

    if (c == 1 && !internal) {
      z = sub14(array(z.len(), 0), z, true);
    }

    return z;
  }

  /**
   * Signed Addition
   * Inputs and outputs are a table with arr and neg.
   */
  function sad (x, y) {
    local z;

    if (x.neg) {
      if (y.neg) {
        z = {arr = add(x.arr, y.arr), neg = true};
      } else {
        z = {arr = cut(sub(y.arr, x.arr, false)), neg = cmp(y.arr, x.arr) < 0};
      }
    } else {
      z = y.neg
        ? {arr = cut(sub(x.arr, y.arr, false)), neg = cmp(x.arr, y.arr) < 0}
        : {arr = add(x.arr, y.arr), neg = false};
    }

    return z;
  }

  /**
   * Signed Subtraction
   * Inputs and outputs are a table with arr and neg.
   */
  function ssb (x, y) {
    local z;

    if (x.neg) {
      if (y.neg) {
        z = {arr = cut(sub(y.arr, x.arr, false)), neg = cmp(y.arr, x.arr) < 0};
      } else {
        z = {arr = add(x.arr, y.arr), neg = true};
      }
    } else {
      z = y.neg
        ? {arr = add(x.arr, y.arr), neg = false}
        : {arr = cut(sub(x.arr, y.arr, false)), neg = cmp(x.arr, y.arr) < 0};
    }

    return z;
  }

  /**
   * Multiplication - HAC 14.12
   */
  function mul (x, y) {
    local yl, yh, c,
          n = x.len(),
          i = y.len(),
          z = array(n+i, 0);

    while (i--) {
      c = 0;

      yl = y[i] & 16383;
      yh = y[i] >> 14;

      for (local j = n-1, xl, xh, t1, t2; j >= 0; j--) {
        xl = x[j] & 16383;
        xh = x[j] >> 14;

        t1 = yh*xl + xh*yl;
        t2 = yl*xl + ((t1 & 16383) << 14) + z[j+i+1] + c;

        z[j+i+1] = t2 & 268435455;
        c = yh*xh + (t1 >> 14) + (t2 >> 28);
      }

      z[i] = c;
    }

    if (z[0] == 0) {
      z.remove(0);
    }

    return z;
  }

  // Same as mul(x, y) but x and y are base 14.
  // This is only needed for div14.
  function mul14 (x, y) {
    local yl, yh, c,
          n = x.len(),
          i = y.len(),
          z = array(n+i, 0);

    while (i--) {
      c = 0;

      // Mask with 2^7 - 1
      yl = y[i] & 0x7f;
      yh = y[i] >> 7;

      for (local j = n-1, xl, xh, t1, t2; j >= 0; j--) {
        xl = x[j] & 0x7f;
        xh = x[j] >> 7;

        t1 = yh*xl + xh*yl;
        t2 = yl*xl + ((t1 & 0x7f) << 7) + z[j+i+1] + c;

        // Mask with 2^14 - 1
        z[j+i+1] = t2 & 0x3fff;
        c = yh*xh + (t1 >> 7) + (t2 >> 14);
      }

      z[i] = c;
    }

    if (z[0] == 0) {
      z.remove(0);
    }

    return z;
  }

  /**
   *  Karatsuba Multiplication, works faster when numbers gets bigger
   */
/* Don't support mulk.
  function mulk (x, y) {
    local z, lx, ly, negx, negy, b;

    if (x.len() > y.len()) {
      z = x; x = y; y = z;
    }
    lx = x.len();
    ly = y.len();
    negx = x.negative,
    negy = y.negative;
    x.negative = false;
    y.negative = false;

    if (lx <= 100) {
      z = mul(x, y);
    } else if (ly / lx >= 2) {
      b = (ly + 1) >> 1;
      z = sad(
        lsh(mulk(x, y.slice(0, ly-b)), b * 28),
        mulk(x, y.slice(ly-b, ly))
      );
    } else {
      b = (ly + 1) >> 1;
      var
          x0 = x.slice(lx-b, lx),
          x1 = x.slice(0, lx-b),
          y0 = y.slice(ly-b, ly),
          y1 = y.slice(0, ly-b),
          z0 = mulk(x0, y0),
          z2 = mulk(x1, y1),
          z1 = ssb(sad(z0, z2), mulk(ssb(x1, x0), ssb(y1, y0)));
      z2 = lsh(z2, b * 2 * 28);
      z1 = lsh(z1, b * 28);

      z = sad(sad(z2, z1), z0);
    }

    z.negative = (negx ^ negy) ? true : false;
    x.negative = negx;
    y.negative = negy;

    return z;
  }
*/

  /**
   * Squaring - HAC 14.16
   */
  function sqr (x) {
    local l1, h1, t1, t2, c,
          i = x.len(),
          z = array(2*i, 0);

    while (i--) {
      l1 = x[i] & 16383;
      h1 = x[i] >> 14;

      t1 = 2*h1*l1;
      t2 = l1*l1 + ((t1 & 16383) << 14) + z[2*i+1];

      z[2*i+1] = t2 & 268435455;
      c = h1*h1 + (t1 >> 14) + (t2 >> 28);

      for (local j = i-1, l2, h2; j >= 0; j--) {
        l2 = (2 * x[j]) & 16383;
        h2 = x[j] >> 13;

        t1 = h2*l1 + h1*l2;
        t2 = l2*l1 + ((t1 & 16383) << 14) + z[j+i+1] + c;
        z[j+i+1] = t2 & 268435455;
        c = h2*h1 + (t1 >> 14) + (t2 >> 28);
      }

      z[i] = c;
    }

    if (z[0] == 0) {
      z.remove(0);
    }

    return z;
  }

  function rsh (x, s) {
    local ss = s % 28,
          ls = math.floor(s/28).tointeger(),
          l  = x.len() - ls,
          z  = x.slice(0,l);

    if (ss) {
      while (--l) {
        z[l] = ((z[l] >> ss) | (z[l-1] << (28-ss))) & 268435455;
      }

      z[l] = z[l] >> ss;

      if (z[0] == 0) {
        z.remove(0);
      }
    }

    return z;
  }

  /**
   * Inputs and outputs are a table with arr and neg.
   * Call rsh, passing through neg.
   */
  function rshSigned (x, s) {
    return {arr = rsh(x.arr, s), neg = x.neg};
  }

  function lsh (x, s) {
    local ss = s % 28,
          ls = math.floor(s/28).tointeger(),
          l  = x.len(),
          z  = [],
          t  = 0;

    if (ss) {
      z.resize(l);
      while (l--) {
        z[l] = ((x[l] << ss) + t) & 268435455;
        t    = x[l] >>> (28 - ss);
      }

      if (t != 0) {
        z.insert(0, t);
      }
    } else {
      z = x;
    }

    return (ls) ? concat(z, array(ls, 0)) : z;
  }

  // x is a base 14 array.
  // This is only needed for div14.
  function lsh14 (x, s) {
    local ss = s % 14,
          ls = math.floor(s/14).tointeger(),
          l  = x.len(),
          z  = [],
          t  = 0;

    if (ss) {
      z.resize(l);
      while (l--) {
        // Mask with 2^14 - 1.
        z[l] = ((x[l] << ss) + t) & 0x3fff;
        t    = x[l] >>> (14 - ss);
      }

      if (t != 0) {
        z.insert(0, t);
      }
    } else {
      z = x;
    }

    return (ls) ? concat(z, array(ls, 0)) : z;
  }

  /**
   * Division - HAC 14.20
   */
  function div (x, y, internal) {
    local u, v, xt, yt, d, q, k, i, z,
          s = msb(y[0]) - 1;

    if (s > 0) {
      u = lsh(x, s);
      v = lsh(y, s);
    } else {
      u = x.slice(0);
      v = y.slice(0);
    }

    d  = u.len() - v.len();
    q  = [0];
    k  = concat(v, array(d, 0));
    yt = v.slice(0, 2);

    // only cmp as last resort
    while (u[0] > k[0] || (u[0] == k[0] && cmp(u, k) > -1)) {
      q[0]++;
      u = sub(u, k, false);
    }

    q.resize(d + 1);
    for (i = 1; i <= d; i++) {
      if (u[i-1] == v[0])
        q[i] = 268435455;
      else {
/* Avoid 64-bit arithmetic.
        local x1 = (u[i-1]*268435456 + u[i])/v[0];
*/
        local t14 = div14(toBase14(u.slice(i-1, i+1)), toBase14([v[0]]));
        // We expect the result to be less than 28 bits.
        local x1 = t14.len() == 1 ? t14[0] : t14[0] * 0x4000 + t14[1];
        q[i] = ~~x1;
      }

      xt = u.slice(i-1, i+2);

      while (cmp(mul([q[i]], yt), xt) > 0) {
        q[i]--;
      }

      k = concat(mul(v, [q[i]]), array(d-i, 0)); //concat after multiply, save cycles
      local u_negative = (cmp(u, k) < 0);
      u = sub(u, k, false);

      if (u_negative) {
        u = sub(concat(v, array(d-i, 0)), u, false);
        // Now, u is non-negative.
        q[i]--;
      }
    }

    if (internal) {
      z = (s > 0) ? rsh(cut(u), s) : cut(u);
    } else {
      z = cut(q);
    }

    return z;
  }

  // Convert the array from base 28 to base 14.
  // This is only needed for div14.
  function toBase14 (x) {
    local hi = x[0] >>> 14;
    // Mask with 2^14 - 1.
    local lo = x[0] & 0x3fff;
    local j, result;

    if (hi == 0) {
      result = array(1 + 2 * (x.len() - 1));
      result[0] = lo;
      j = 1;
    }
    else {
      result = array(2 + 2 * (x.len() - 1));
      result[0] = hi;
      result[1] = lo;
      j = 2;
    }

    for (local i = 1; i < x.len(); ++i) {
      result[j++] = x[i] >>> 14;
      result[j++] = x[i] & 0x3fff;
    }

    return result;
  }

  /**
   * Division base 14. 
   * We need this so that we can do 32-bit integer division on the Imp.
   */
  function div14 (x, y) {
    local u, v, xt, yt, d, q, k, i, z,
          s = msb14(y[0]) - 1;

    if (s > 0) {
      u = lsh14(x, s);
      v = lsh14(y, s);
    } else {
      u = x.slice(0);
      v = y.slice(0);
    }

    d  = u.len() - v.len();
    q  = [0];
    k  = concat(v, array(d, 0));
    yt = v.slice(0, 2);

    // only cmp as last resort
    while (u[0] > k[0] || (u[0] == k[0] && cmp(u, k) > -1)) {
      q[0]++;
      u = sub14(u, k);
    }

    q.resize(d + 1);
    for (i = 1; i <= d; i++) {
      if (u[i-1] == v[0])
        // Set to 2^14 - 1.
        q[i] = 0x3fff;
      else {
        // This is dividing a 28-bit value by a 14-bit value.
        local x1 = (u[i-1]*0x4000 + u[i])/v[0];
        q[i] = ~~x1;
      }

      xt = u.slice(i-1, i+2);

      while (cmp(mul14([q[i]], yt), xt) > 0) {
        q[i]--;
      }

      k = concat(mul14(v, [q[i]]), array(d-i, 0)); //concat after multiply, save cycles
      local u_negative = (cmp(u, k) < 0);
      u = sub14(u, k);

      if (u_negative) {
        u = sub14(concat(v, array(d-i, 0)), u, false);
        // Now, u is non-negative.
        q[i]--;
      }
    }

    z = cut(q);

    return z;
  }

  function mod (x, y) {
    switch (cmp(x, y)) {
      case -1:
        return x;
      case 0:
        return [0];
      default:
        return div(x, y, true);
    }
  }

  /**
   * Greatest Common Divisor - HAC 14.61 - Binary Extended GCD, used to calc inverse, x <= modulo, y <= exponent
   * Result is a table with arr and neg.
   */
  function gcd (x, y) {
    local min1 = lsb(x[x.len()-1]);
    local min2 = lsb(y[y.len()-1]);
    local g = (min1 < min2 ? min1 : min2),
          u = rsh(x, g),
          v = rsh(y, g),
          a = {arr = [1], neg = false}, b = {arr = [0], neg = false},
          c = {arr = [0], neg = false}, d = {arr = [1], neg = false}, s,
          xSigned = {arr = x, neg = false},
          ySigned = {arr = y, neg = false};

    while (u.len() != 1 || u[0] != 0) {
      s = lsb(u[u.len()-1]);
      u = rsh(u, s);
      while (s--) {
        if ((a.arr[a.arr.len()-1]&1) == 0 && (b.arr[b.arr.len()-1]&1) == 0) {
          a = rshSigned(a, 1);
          b = rshSigned(b, 1);
        } else {
          a = rshSigned(sad(a, ySigned), 1);
          b = rshSigned(ssb(b, xSigned), 1);
        }
      }

      s = lsb(v[v.len()-1]);
      v = rsh(v, s);
      while (s--) {
        if ((c.arr[c.arr.len()-1]&1) == 0 && (d.arr[d.arr.len()-1]&1) == 0) {
          c = rshSigned(c, 1);
          d = rshSigned(d, 1);
        } else {
          c = rshSigned(sad(c, ySigned), 1);
          d = rshSigned(ssb(d, xSigned), 1);
        }
      }

      if (cmp(u, v) >= 0) {
        u = sub(u, v, false);
        a = ssb(a, c);
        b = ssb(b, d);
      } else {
        v = sub(v, u, false);
        c = ssb(c, a);
        d = ssb(d, b);
      }
    }

    if (v.len() == 1 && v[0] == 1) {
      return d;
    }
  }

  /**
   * Inverse 1/x mod y
   */
  function inv (x, y) {
    local z = gcd(y, x);
    return (z != null && z.neg) ? sub(y, z.arr, false) : z.arr;
  }

  /**
   * Barret Modular Reduction - HAC 14.42
   */
  function bmr (x, m, mu = null) {
    local q1, q2, q3, r1, r2, z, s, k = m.len();

    if (cmp(x, m) < 0) {
      return x;
    }

    if (mu == null) {
      mu = div(concat([1], array(2*k, 0)), m, false);
    }

    q1 = x.slice(0, x.len()-(k-1));
    q2 = mul(q1, mu);
    q3 = q2.slice(0, q2.len()-(k+1));

    s  = x.len()-(k+1);
    r1 = (s > 0) ? x.slice(s) : x.slice(0);

    r2 = mul(q3, m);
    s  = r2.len()-(k+1);

    if (s > 0) {
      r2 = r2.slice(s);
    }

    z = cut(sub(r1, r2, false));

    while (cmp(z, m) >= 0) {
      z = cut(sub(z, m, false));
    }

    return z;
  }

  /**
   * Modular Exponentiation - HAC 14.76 Right-to-left binary exp
   */
  function exp (x, e, n) {
    local c = 268435456,
          r = [1],
          u = div(concat(r, array(2*n.len(), 0)), n, false);

    for (local i = e.len()-1; i >= 0; i--) {
      if (i == 0) {
        c = 1 << (27 - msb(e[0]));
      }

      for (local j = 1; j < c; j *= 2) {
        if (e[i] & j) {
          r = bmr(mul(r, x), n, u);
        }
        x = bmr(sqr(x), n, u);
      }
    }

    return bmr(mul(r, x), n, u);
  }

  /**
   * Garner's algorithm, modular exponentiation - HAC 14.71
   */
  function gar (x, p, q, d, u, dp1 = null, dq1 = null) {
    local vp, vq, t;

    if (dp1 == null) {
      dp1 = mod(d, dec(p));
      dq1 = mod(d, dec(q));
    }

    vp = exp(mod(x, p), dp1, p);
    vq = exp(mod(x, q), dq1, q);

    if (cmp(vq, vp) < 0) {
      t = cut(sub(vp, vq, false));
      t = cut(bmr(mul(t, u), q, null));
      t = cut(sub(q, t, false));
    } else {
      t = cut(sub(vq, vp, false));
      t = cut(bmr(mul(t, u), q, null)); //bmr instead of mod, div can fail because of precision
    }

    return cut(add(vp, mul(t, p)));
  }

  /**
   * Simple Mod - When n < 2^14
   */
/* Remove support for primes until we need it.
  function mds (x, n) {
    local z;
    for (local i = 0, z = 0, l = x.len(); i < l; i++) {
      z = ((x[i] >> 14) + (z << 14)) % n;
      z = ((x[i] & 16383) + (z << 14)) % n;
    }

    return z;
  }
*/

  function dec (x) {
    local z;

    if (x[x.len()-1] > 0) {
      z = x.slice(0);
      z[z.len()-1] -= 1;
    } else {
      z = sub(x, [1], false);
    }

    return z;
  }

  /**
   * Miller-Rabin Primality Test
   */
/* Remove support for primes until we need it.
  function mrb (x, iterations) {
    local m = dec(x),
          s = lsb(m[x.len()-1]),
          r = rsh(x, s);

    for (local i = 0, j, t, y; i < iterations; i++) {
      y = exp(ptests[i], r, x);

      if ( (y.len() > 1 || y[0] != 1) && cmp(y, m) != 0 ) {
        j = 1;
        t = true;

        while (t && s > j++) {
          y = mod(sqr(y), x);

          if (y.len() == 1 && y[0] == 1) {
            return false;
          }

          t = cmp(y, m) != 0;
        }

        if (t) {
          return false;
        }
      }
    }

    return true;
  }

  function tpr (x) {
    if (x.len() == 1 && x[0] < 16384 && primes.indexOf(x[0]) >= 0) {
      return true;
    }

    for (local i = 1, l = primes.len(); i < l; i++) {
      if (mds(x, primes[i]) == 0) {
        return false;
      }
    }

    return mrb(x, 3);
  }
*/

  /**
   * Quick add integer n to arbitrary precision integer x avoiding overflow
   */
/* Remove support for primes until we need it.
  function qad (x, n) {
    local l = x.len() - 1;

    if (x[l] + n < 268435456) {
      x[l] += n;
    } else {
      x = add(x, [n]);
    }

    return x;
  }

  function npr (x) {
    x = qad(x, 1 + x[x.len()-1] % 2);

    while (!tpr(x)) {
      x = qad(x, 2);
    }

    return x;
  }

  function fct (n) {
    local z = [1],
          a = [1];

    while (a[0]++ < n) {
      z = mul(z, a);
    }

    return z;
  }
*/

  /**
   * Convert byte array to 28 bit array
   * a[0] must be non-negative.
   */
  function ci (a) {
    local x = [0,0,0,0,0,0].slice((a.len()-1)%7),
          z = [];

    if (a[0] < 0) {
      throw "ci: a[0] is negative";
    }

    x = concat(x, a);

    for (local i = 0; i < x.len(); i += 7) {
      z.push(x[i]*1048576 + x[i+1]*4096 + x[i+2]*16 + (x[i+3]>>4));
      z.push((x[i+3]&15)*16777216 + x[i+4]*65536 + x[i+5]*256 + x[i+6]);
    }

    return cut(z);
  }

  /**
   * Convert 28 bit array to byte array
   */
  function co (a = null) {
    if (a != null) {
      local x = concat([0].slice((a.len()-1)%2), a),
            z = [];

      for (local u, v, i = 0; i < x.len();) {
        u = x[i++];
        v = x[i++];

        z.push(u >> 20);
        z.push(u >> 12 & 255);
        z.push(u >> 4 & 255);
        z.push((u << 4 | v >> 24) & 255);
        z.push(v >> 16 & 255);
        z.push(v >> 8 & 255);
        z.push(v & 255);
      }

      z = cut(z);

      return z;
    }
  }

/* Don't support stringify.
  function stringify (x) {
    local a = [],
          b = [10],
          z = [0],
          i = 0, q;

    do {
      q      = x;
      x      = div(q, b);
      a[i++] = sub(q, mul(b, x)).pop();
    } while (cmp(x, z));

    return a.reverse().join("");
  }
*/

/* Don't support parse.
  function parse (s) {
    local x = s.split(""),
          p = [1],
          a = [0],
          b = [10],
          n = false;

    if (x[0] == "-") {
      n = true;
      x.remove(0);
    }

    while (x.len()) {
      a = add(a, mul(p, [x.pop()]));
      p = mul(p, b);
    }

    a.negative = n;

    return a;
  }
*/

  /**
   * Imitate the JavaScript concat method to return a new array with the
   * concatenation of a1 and a2.
   * @param {Array} a1 The first array.
   * @param {Array} a2 The second array.
   * @return {Array} A new array.
   */
  function concat(a1, a2)
  {
    local result = a1.slice(0);
    result.extend(a2);
    return result;
  }

  // Imitate JavaScript apply. Squirrel has different scoping rules.
  function apply(func, args) {
    if (args.len() == 0) return func();
    else if (args.len() == 1) return func(args[0]);
    else if (args.len() == 2) return func(args[0], args[1]);
    else if (args.len() == 3) return func(args[0], args[1], args[2]);
    else if (args.len() == 4) return func(args[0], args[1], args[2], args[3]);
    else if (args.len() == 5)
      return func(args[0], args[1], args[2], args[3], args[4]);
    else if (args.len() == 6)
      return func(args[0], args[1], args[2], args[3], args[4], args[5]);
    else if (args.len() == 7)
      return func(args[0], args[1], args[2], args[3], args[4], args[5], args[6]);
  }

  }; // End priv.

  local transformIn = function(a) {
    return rawIn ? a : a.map(function (v) {
      return priv.ci(v.slice(0))
    });
  }

  local transformOut = function(x) {
    return rawOut ? x : priv.co(x);
  }

  return {
    /**
     * Return zero array length n
     *
     * @method zero
     * @param {Number} n
     * @return {Array} 0 length n
     */
    zero = function (n) {
      return array(n, 0);
    },

    /**
     * Signed Addition - Safe for signed MPI
     *
     * @method add
     * @param {Array} x
     * @param {Array} y
     * @return {Array} x + y
     */
/* Don't export add until we need it.
    add = function (x, y) {
      return transformOut(
        priv.apply(priv.add, transformIn([x, y]))
      );
    },
*/

    /**
     * Signed Subtraction - Safe for signed MPI
     *
     * @method sub
     * @param {Array} x
     * @param {Array} y
     * @return {Array} x - y
     */
/* Don't export sub until we need it.
    sub = function (x, y) {
      local args = transformIn([x, y]);
      if (priv.apply(priv.cmp, args) < 0)
        throw "Negative result for sub not supported";
      return transformOut(
        priv.apply(priv.sub, args)
      );
    },

    /**
     * Multiplication
     *
     * @method mul
     * @param {Array} x
     * @param {Array} y
     * @return {Array} x * y
     */
/* Don't export mul until we need it.
    mul = function (x, y) {
      return transformOut(
        priv.apply(priv.mul, transformIn([x, y]))
      );
    },
*/

    /**
     * Multiplication, with karatsuba method
     *
     * @method mulk
     * @param {Array} x
     * @param {Array} y
     * @return {Array} x * y
     */
/* Don't support mulk.
    mulk = function (x, y) {
      return transformOut(
        priv.apply(priv.mulk, transformIn([x, y]))
      );
    },
*/

    /**
     * Squaring
     *
     * @method sqr
     * @param {Array} x
     * @return {Array} x * x
     */
/* Don't export sqr until we need it.
    sqr = function (x) {
      return transformOut(
        priv.apply(priv.sqr, transformIn([x]))
      );
    },
*/

    /**
     * Modular Exponentiation
     *
     * @method exp
     * @param {Array} x
     * @param {Array} e
     * @param {Array} n
     * @return {Array} x^e % n
     */
    exp = function (x, e, n) {
      return transformOut(
        priv.apply(priv.exp, transformIn([x, e, n]))
      );
    },

    /**
     * Division
     *
     * @method div
     * @param {Array} x
     * @param {Array} y
     * @return {Array} x / y || undefined
     */
/* Don't export div until we need it.
    div = function (x, y) {
      if (y.len() != 1 || y[0] != 0) {
        return transformOut(
          priv.apply(priv.div, transformIn([x, y]))
        );
      }
    },
*/

    /**
     * Modulus
     *
     * @method mod
     * @param {Array} x
     * @param {Array} y
     * @return {Array} x % y
     */
/* Don't export mod until we need it.
    mod = function (x, y) {
      return transformOut(
        priv.apply(priv.mod, transformIn([x, y]))
      );
    },
*/

    /**
     * Barret Modular Reduction
     *
     * @method bmr
     * @param {Array} x
     * @param {Array} y
     * @param {Array} [mu]
     * @return {Array} x % y
     */
/* Don't export bmr until we need it.
    bmr = function (x, y, mu = null) {
      return transformOut(
        priv.apply(priv.bmr, transformIn([x, y, mu]))
      );
    },
*/

    /**
     * Garner's Algorithm
     *
     * @method gar
     * @param {Array} x
     * @param {Array} p
     * @param {Array} q
     * @param {Array} d
     * @param {Array} u
     * @param {Array} [dp1]
     * @param {Array} [dq1]
     * @return {Array} x^d % pq
     */
    gar = function (x, p, q, d, u, dp1 = null, dq1 = null) {
      return transformOut(
        priv.apply(priv.gar, transformIn([x, p, q, d, u, dp1, dq1]))
      );
    },

    /**
     * Mod Inverse
     *
     * @method inv
     * @param {Array} x
     * @param {Array} y
     * @return {Array} 1/x % y || undefined
     */
    inv = function (x, y) {
      return transformOut(
        priv.apply(priv.inv, transformIn([x, y]))
      );
    },

    /**
     * Remove leading zeroes
     *
     * @method cut
     * @param {Array} x
     * @return {Array} x without leading zeroes
     */
    cut = function (x) {
      return transformOut(
        priv.apply(priv.cut, transformIn([x]))
      );
    },


    /**
     * Factorial - for n < 268435456
     *
     * @method factorial
     * @param {Number} n
     * @return {Array} n!
     */
/* Don't export factorial until we need it.
    factorial = function (n) {
      return transformOut(
        priv.apply(priv.fct, [n%268435456])
      );
    },
*/

    /**
     * Bitwise AND, OR, XOR
     * Undefined if x and y different lengths
     *
     * @method OP
     * @param {Array} x
     * @param {Array} y
     * @return {Array} x OP y
     */
/* Don't export bitwise operations until we need them.
    and = function (x, y) {
      if (x.len() == y.len()) {
        for (local i = 0, z = []; i < x.len(); i++) { z[i] = x[i] & y[i] }
        return z;
      }
    },

    or = function (x, y) {
      if (x.len() == y.len()) {
        for (local i = 0, z = []; i < x.len(); i++) { z[i] = x[i] | y[i] }
        return z;
      }
    },

    xor = function (x, y) {
      if (x.len() == y.len()) {
        for (local i = 0, z = []; i < x.len(); i++) { z[i] = x[i] ^ y[i] }
        return z;
      }
    },
*/

    /**
     * Bitwise NOT
     *
     * @method not
     * @param {Array} x
     * @return {Array} NOT x
     */
/* Don't export bitwise operations until we need them.
    not = function (x) {
      for (local i = 0, z = [], m = rawIn ? 268435455 : 255; i < x.len(); i++) { z[i] = ~x[i] & m }
      return z;
    },
*/

    /**
     * Left Shift
     *
     * @method leftShift
     * @param {Array} x
     * @param {Integer} s
     * @return {Array} x << s
     */
/* Don't export bitwise operations until we need them.
    leftShift = function (x, s) {
      return transformOut(priv.lsh(transformIn([x]).pop(), s));
    },
*/

    /**
     * Zero-fill Right Shift
     *
     * @method rightShift
     * @param {Array} x
     * @param {Integer} s
     * @return {Array} x >>> s
     */
/* Don't export bitwise operations until we need them.
    rightShift = function (x, s) {
      return transformOut(priv.rsh(transformIn([x]).pop(), s));
    },
*/

    /**
     * Decrement
     *
     * @method decrement
     * @param {Array} x
     * @return {Array} x - 1
     */
/* Don't export decrement until we need it.
    decrement = function (x) {
      return transformOut(
        priv.apply(priv.dec, transformIn([x]))
      );
    },
*/

    /**
     * Compare values of two MPIs - Not safe for signed or leading zero MPI
     *
     * @method compare
     * @param {Array} x
     * @param {Array} y
     * @return {Number} 1: x > y
     *                  0: x = y
     *                 -1: x < y
     */
/* Don't export compare until we need it.
    compare = function (x, y) {
      return priv.cmp(x, y);
    },
*/

    /**
     * Find Next Prime
     *
     * @method nextPrime
     * @param {Array} x
     * @return {Array} 1st prime > x
     */
/* Remove support for primes until we need it.
    nextPrime = function (x) {
      return transformOut(
        priv.apply(priv.npr, transformIn([x]))
      );
    },
*/

    /**
     * Primality Test
     * Sieve then Miller-Rabin
     *
     * @method testPrime
     * @param {Array} x
     * @return {boolean} is prime
     */
/* Remove support for primes until we need it.
    testPrime = function (x) {
      return (x[x.len()-1] % 2 == 0) ? false : priv.apply(priv.tpr, transformIn([x]));
    },
*/

    /**
     * Array base conversion
     *
     * @method transform
     * @param {Array} x
     * @param {boolean} toRaw
     * @return {Array}  toRaw: 8 => 28-bit array
     *                 !toRaw: 28 => 8-bit array
     */
    transform = function (x, toRaw) {
      return toRaw ? priv.ci(x) : priv.co(x);
    }
//    ,

    /**
     * Integer to String conversion
     *
     * @method stringify
     * @param {Array} x
     * @return {String} base 10 number as string
     */
/* Don't support stringify.
    stringify = function (x) {
      return stringify(priv.ci(x));
    },
*/

    /**
     * String to Integer conversion
     *
     * @method parse
     * @param {String} s
     * @return {Array} x
     */
/* Don't support parse.
    parse = function (s) {
      return priv.co(parse(s));
    }
*/
  }
}
