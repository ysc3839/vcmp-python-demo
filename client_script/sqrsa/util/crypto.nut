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
