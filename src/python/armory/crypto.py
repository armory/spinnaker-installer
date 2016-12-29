from Crypto.PublicKey import RSA

def generate_keypair():
    key = RSA.generate(2048)
    private_pem = key.exportKey('PEM')
    pubkey = key.publickey()
    public_openssh = pubkey.exportKey(format='OpenSSH')
    return private_pem.decode('utf-8'), public_openssh.decode('utf-8')
