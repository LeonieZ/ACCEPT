This small mex function converts an XML file into a MATLAB structure. 
It can parse any general XML file and with a proper mark-up and strucure, 
It can additionally read general n-dimensional arrays.

For compilation of the C++ mex file, run `make BOOST=<path>` where `<path>` is 
a path to the Boost library include files.

To run a test and see how `test.xml` gets converted, run `make test`. It should 
output

```
          SCS: [1x1 struct]
           TS: [1x1 struct]
           VV: [1x1 struct]
       coords: [1x1 struct]
        elems: [1x1 struct]
       energy: [12x1 struct]
         free: [1x1 struct]
    hirshfeld: [1x1 struct]
        omega: [1x1 struct]
    overlap_c: [2x2 double]
    overlap_x: [2x2 double]
        rsSCS: [1x1 struct]
Elapsed time is 0.076925 seconds.
```
