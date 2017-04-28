#!/usr/bin/python
from http.server import BaseHTTPRequestHandler, HTTPServer
import os
import glob
import logging
from logging.handlers import RotatingFileHandler

def setup_log(logfile=None, print_stderr=True):
    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)

    formatter = logging.Formatter('%(asctime)s :: %(levelname)s :: %(message)s')
    if logfile is not None:
        file_handler = RotatingFileHandler(logfile, 'a', 100000, 1)
        file_handler.setLevel(logging.DEBUG)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
    if print_stderr:
        stream_handler = logging.StreamHandler()
        stream_handler.setLevel(logging.DEBUG)
        stream_handler.setFormatter(formatter)
        logger.addHandler(stream_handler)

    logging.info('Starting logging')

setup_log('image_server.log', True)

p_image_dir = os.getenv('P_IMAGE_DIR')
if p_image_dir is None:
    p_image_dir = '/home/pi/elec-2103-common/comm/p_img'

fname_template = os.path.join(p_image_dir, 'p{}_{}.jpg')

PORT_NUMBER = 8080

def last_horodated(glob_template):
    glob_list = glob.glob(glob_template)
    logging.debug(glob_list)
    l = [(int(x.split('.')[0].split('_')[-1]), x) for x in glob.glob(glob_template)]
    l.sort()
    return l[-1]

#This class will handles any incoming request from
#the browser
class myHandler(BaseHTTPRequestHandler):
    #Handler for the GET requests
    def do_GET(self):
        if self.path=="/":
            self.path="/index.html"

        try:
            #Check the file extension required and
            #set the right mime type

            sendReply = False
            if self.path.endswith(".html"):
                mimetype='text/html'
                sendReply = True
            if self.path.endswith(".jpg"):
                mimetype='image/jpg'
                sendReply = True
            if self.path.endswith(".gif"):
                mimetype='image/gif'
                sendReply = True
            if self.path.endswith(".js"):
                mimetype='application/javascript'
                sendReply = True
            if self.path.endswith(".css"):
                mimetype='text/css'
                sendReply = True
            if self.path.endswith(".ogg"):
                mimetype='application/ogg'
                sendReply = True

            if sendReply == True:
                #Open the static file requested and send it
                f = open(os.curdir + os.sep + self.path, 'rb')
                self.send_response(200)
                self.send_header('Content-type',mimetype)
                self.end_headers()
                self.wfile.write(f.read())
                f.close()
            return

        except IOError:
            self.send_error(404,'File Not Found: %s' % self.path)

    #Handler for the POST requests
    def do_POST(self):
        if self.path == "/upload1":
            p_id = 1
        elif self.path == "/upload2":
            p_id = 2
        else:
            print("Invalid POST address")
            return
        print("Received player picture for player", p_id)
        last_image_id, _ = last_horodated(fname_template.format(p_id, '*'))
        print('last image found: ', last_image_id)
        image_id = last_image_id + 1
        filename = fname_template.format(p_id, '{:04}'.format(image_id))

        content_length = int(self.headers['Content-Length'])
        print("Length is", content_length)
        post_data = self.rfile.read(content_length)
        with open(filename, 'wb') as f:
            f.write(post_data)
        self.send_response(200)
        self.end_headers()
        self.wfile.write("Thanks !".encode())
        return

try:
    #Create a web server and define the handler to manage the
    #incoming request
    server = HTTPServer(('', PORT_NUMBER), myHandler)
    print('Started httpserver on port %d', PORT_NUMBER)
    #Wait forever for incoming htto requests
    server.serve_forever()

except KeyboardInterrupt:
    print('^C received, shutting down the web server')
    server.socket.close()
