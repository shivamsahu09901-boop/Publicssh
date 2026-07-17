import socket, _thread, sys

def connection(clt_conn, addr):
    try:
        clt_conn.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        request = clt_conn.recv(4096).decode('utf-8', errors='ignore')
        if "Upgrade: websocket" in request or "HTTP/1.1" in request:
            clt_conn.sendall(b"HTTP/1.1 101 Switching Protocols\r\nConnection: Upgrade\r\nUpgrade: websocket\r\n\r\n")
            srv_conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            srv_conn.connect(('127.0.0.1', 22))
            _thread.start_new_thread(forward, (clt_conn, srv_conn))
            forward(srv_conn, clt_conn)
    except: pass

def forward(src, dst):
    try:
        while True:
            data = src.recv(8192)
            if not data: break
            dst.sendall(data)
    except: pass
    finally: src.close(); dst.close()

def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 80
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', port))
    server.listen(2048)
    while True:
        clt_conn, addr = server.accept()
        _thread.start_new_thread(connection, (clt_conn, addr))

if __name__ == '__main__': main()
    
