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
