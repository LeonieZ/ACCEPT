function test_global

% Unit test 1: segmentation
try 
    test_segmentation();
    disp('Unit test 1 segmentation passed !');
catch exception
    disp('Unit test 1 segmentation failed !');
    rethrow(exception);
end