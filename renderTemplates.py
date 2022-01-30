#!/usr/bin/env python3
# ********************************************
# (C) 2022 Fabian Salamanca <fabs@yunefo.tech>
# ********************************************

import argparse
from jinja2 import Environment, FileSystemLoader

class ReadKey:
    """
    ReadKey class: Simple SSH public key reader. Attributes
    defined in the constructor.
    """
    def __init__(self, keyfilename: str):
        self.keyfilename = keyfilename

    def loadKey(self) -> str:
        fk = open(self.keyfilename, "r") 
        self.thesshkey = fk.read();        
        cleank = self.thesshkey.rstrip()
        return cleank


class RenderTmpl:
    """
    RenderTmpl class: This class assigns required values from the constructor.
    Just local-hostname and ssh-keys are being rendered but more cloud-init
    data could be managed as well, it will need to be included here
    """
    temps = {"user-data": "user-data.tmp", "meta-data": "meta-data.tmp"}
    
    file_loader = FileSystemLoader('templates')
    env = Environment(loader=file_loader)

    def __init__(self, thesshkey: str, hostname: str):
        self.thesshkey = thesshkey
        self.hostname = hostname

    def render(self):
        for file,template in self.temps.items():
            template = self.env.get_template(template)
            output = template.render(thesshkey=self.thesshkey, hostname=self.hostname)
            f = open(file,"w")
            f.write(output)
            print("Template rendered...")
        

if __name__ == "__main__":

    # Using argparser for args management
    parser = argparse.ArgumentParser(description='Render cloud configuration options.')
    parser.add_argument('--ssh-key', type=str,help='SSH Public key filename', required=True)
    parser.add_argument('--hostname', type=str,help='VM Hostname', required=True)
    args = parser.parse_args()
    keyobj = ReadKey(args.ssh_key)
    sshkey = keyobj.loadKey()        
    print(sshkey)
    rend = RenderTmpl(sshkey, args.hostname)
    rend.render()
    print(f"\nFINISHED\n\n")
