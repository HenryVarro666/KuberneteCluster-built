#初始化ca，该命令会生成运行CA所必需的文件ca-key.pem（私钥）和ca.pem（证书），还会生成ca.csr（证书签名请求），用于交叉签名或重新签名。
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -


#生成新的key(密钥)和签名证书    
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=www server-csr.json | cfssljson -bare server 
