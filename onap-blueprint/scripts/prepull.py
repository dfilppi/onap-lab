import subprocess
import os
import sys
import stat
import time
from cloudify import ctx

ctx.logger.info("Prepulling images")

p = subprocess.Popen(["sudo","-i","kubectl","get","nodes","-o","wide","--no-headers"], stdout=subprocess.PIPE)
(stdout,_) = p.communicate()

nodes = []
for l in stdout.split('\n'):
    if len(l) != 0 and 'master' not in l:
        nodes.append(l.strip().split()[5])

ARCHIVE="/tmp/oom.tgz"
KEYFILE="/tmp/key"

try:
    subprocess.call(["sudo","rm","-f",KEYFILE])
    with open(KEYFILE,"w") as f:
        f.write(os.environ['KEY'].strip())
    os.chmod(KEYFILE, stat.S_IRUSR)
except Exception as e:
    raise Exception("Failed to write keyfile: " + e.message)

# place archive
try:
    for node in nodes:
        ctx.logger.info("Pushing archive to "+node)
        ret = subprocess.call(["scp","-o","StrictHostKeyChecking=no","-i",KEYFILE,ARCHIVE,"ubuntu@"+node+":."])
        if ret != 0:
            raise Exception("push to node "+node+" failed")  
        ret = subprocess.call(["ssh","-o","StrictHostKeyChecking=no","-i",KEYFILE,"ubuntu@"+node,"tar","xzf",ARCHIVE.split('/')[-1]])
        if ret != 0:
            raise Exception("untar to node "+node+" failed")  
except Exception as e:
    ctx.logger.error("caught exception: " + e.message)
    os.remove(KEYFILE)
    raise Exception("Failed to place archive: " + e.message)

# run prepull in parallel on nodes
ctx.logger.info("kicking off parallel prepull")
procs=[]
for node in nodes:
    p = subprocess.Popen(["ssh","-o","StrictHostKeyChecking=no","-i",KEYFILE,"ubuntu@"+node,"cd oom/kubernetes; sudo config/prepull_docker.sh"])
    procs.append(p)

try:
    for i in range(1000):
        ctx.logger.info("Waiting for image prepulls to finish")
        fcnt = 0
        for p in procs:
            r = p.poll()
            if r is None:
                break
            if r != 0: 
                for p in procs:
                    p.terminate()
                ctx.logger.error("Process returned non 0: "+str(r))
                raise Exception("Prepull failed")
            fcnt += 1
        if fcnt == len(procs):
            sys.exit(0)  
        time.sleep(5)
    
    ctx.logger.error("Timed out waiting for prepull completion")
    sys.exit(1)
finally:
    os.remove(KEYFILE)

