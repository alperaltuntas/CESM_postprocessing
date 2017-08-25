__author__       = 'Nathan Collier'
__date__         = 'Feb 2017'
__version__      = '2.1'

from distutils.version import LooseVersion
import platform

# These are guesses at actual requirements
requires = {
    "numpy"                : "1.9.2",
    "matplotlib"           : "1.4.3",
    "netCDF4"              : "1.1.4",
    "cfunits"              : "1.1.4",
    "mpl_toolkits.basemap" : "1.0.7",
    "sympy"                : "0.7.6",
    "mpi4py"               : "1.3.1"
}

froms = {
    "mpl_toolkits.basemap" : "Basemap"
}

for key in requires.keys():
    if "." in key:
        pkg = __import__(key, globals(), locals(), [froms[key]])
    else:
        pkg = __import__(key)
    if LooseVersion(pkg.__version__) < LooseVersion(requires[key]):
        raise ImportError(
            "Bad %s version: ILAMB %s requires %s >= %s got %s" %
            (key,__version__,key,requires[key],pkg.__version__))




