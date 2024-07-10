#gwyd!0n

import os
from robot.api.deco import keyword, library


@library
class lastModified(object):

    @keyword
    def last_modified(self,path):
        files = os.listdir(path)
        paths = [os.path.join(path, basename) for basename in files]
        fname = (max(paths, key=os.path.getctime))
        b = fname.replace(path, '')
        return b