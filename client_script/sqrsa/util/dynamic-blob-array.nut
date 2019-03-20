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
