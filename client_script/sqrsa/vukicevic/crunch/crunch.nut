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
