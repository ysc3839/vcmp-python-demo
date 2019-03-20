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
