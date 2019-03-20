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
