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
