import socket
import _thread
import sys

def connection(clt_conn, addr):
    try:
        clt_conn.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        clt_conn.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 65536)
        clt_conn.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 65536)
        
        request = clt_conn.recv(4096).decode('utf-8', errors='ignore')
        
        if "Upgrade: websocket" in request or "HTTP/1.1" in request:
            color_payload = b"HTTP/1.1 101 Switching Protocols\r\nConnection: Upgrade\r\nUpgrade: websocket\r\n\r\n"
            clt_conn.sendall(color_payload)
            
            srv_conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            srv_conn.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            srv_conn.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 65536)
            srv_conn.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 65536)
            srv_conn.connect(('127.0.0.1', 22))
            
            _thread.start_new_thread(forward, (clt_conn, srv_conn))
            forward(srv_conn, clt_conn)
    except:
        pass

def forward(src, dst):
    try:
        while True:
            data = src.recv(16384)
            if not data: 
                break
            dst.sendall(data)
    except:
        pass
    finally:
        try: src.close()
        except: pass
        try: dst.close()
        except: pass

def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 80
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    try:
        server.bind(('0.0.0.0', port))
    except Exception as e:
        print(f"Port Bind Error: {e}")
        return

    server.listen(4096)
    while True:
        try:
            clt_conn, addr = server.accept()
            _thread.start_new_thread(connection, (clt_conn, addr))
        except:
            pass

if __name__ == '__main__':
    main()
    
