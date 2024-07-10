#gwyd!0n

import os
from robot.api.deco import keyword, library


@library
class lastModified(object):

    @keyword
    def lastModified(self,path):
        files = os.listdir(path)
        paths = [os.path.join(path, basename) for basename in files]
        file_name = (max(paths, key=os.path.getctime))
        #removing full path and keeping only the name  
        lastModifedFileName = file_name.replace(path, '')
        return lastModifedFileName