SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STForceCollection] ...';
GO

PRINT '1. Testing Conversion of Polygon with holes to GEOMETRYCOLLECTION';
GO

select [$(owner)].[STForceCollection](
             geometry::STGeomFromText('POLYGON ((98.4 883.585, 115.729 903.305, 102.284 923.025, 99.148 899.272, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 96.606 926.91, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 101.238 929.002, 101.238 929.002, 101.238 929.002, 101.238 929.002, 101.238 929.002, 101.238 929.002, 101.238 929.002, 101.238 929.002, 101.238 929.002, 119.017 922.28, 119.724 924.15, 101.945 930.873, 101.842 930.909, 101.737 930.939, 101.63 930.963, 101.522 930.982, 101.413 930.994, 101.304 931.001, 101.194 931.002, 101.085 930.996, 95.259 930.548, 95.158 930.538, 95.057 930.522, 94.958 930.502, 94.859 930.476, 94.762 930.446, 94.667 930.41, 94.574 930.37, 94.483 930.325, 94.394 930.275, 94.308 930.221, 94.224 930.163, 94.144 930.101, 94.067 930.034, 93.994 929.964, 93.924 929.89, 93.858 929.813, 93.796 929.732, 93.738 929.649, 93.685 929.562, 93.636 929.473, 93.591 929.382, 93.552 929.288, 93.517 929.193, 93.487 929.096, 93.462 928.997, 93.442 928.898, 93.427 928.797, 93.417 928.696, 93.412 928.595, 93.413 928.493, 93.419 928.391, 93.429 928.29, 93.727 926.049, 93.755 925.89, 93.796 925.733, 93.849 925.579, 93.915 925.431, 93.992 925.288, 94.081 925.152, 94.181 925.024, 94.29 924.905, 94.292 924.902, 91.428 905.295, 91.411 905.297, 91.269 905.305, 91.127 905.302, 79.324 904.704, 79.222 904.697, 79.121 904.684, 79.021 904.666, 78.922 904.643, 78.824 904.615, 78.728 904.582, 78.634 904.544, 78.541 904.501, 78.451 904.454, 78.364 904.402, 78.279 904.346, 78.197 904.286, 78.118 904.221, 78.043 904.153, 77.971 904.081, 77.903 904.005, 77.839 903.926, 77.779 903.844, 77.724 903.758, 77.672 903.671, 77.626 903.58, 77.584 903.488, 77.546 903.393, 77.514 903.297, 77.486 903.199, 77.464 903.099, 77.446 902.999, 77.434 902.898, 77.427 902.797, 77.425 902.695, 77.428 902.593, 77.437 902.492, 77.683 900.217, 74.343 901.496, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 63.291 914.361, 73.036 899.855, 80.022 897.18, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 79.736 888.304, 98.4 883.585), (97.705 885.823, 93.766 886.819, 109.224 898.931, 97.705 885.823), (88.909 888.047, 83.17 889.498, 90.523 899.096, 88.909 888.047), (101.533 902.06, 103.581 917.573, 113.204 903.46, 112.781 902.979, 112.78 902.988, 112.762 903.094, 112.739 903.199, 112.71 903.302, 112.675 903.403, 112.635 903.503, 112.59 903.6, 112.539 903.695, 112.484 903.787, 112.423 903.875, 112.358 903.961, 112.289 904.042, 112.215 904.12, 112.137 904.194, 112.056 904.264, 111.97 904.329, 111.882 904.389, 111.79 904.445, 111.695 904.495, 111.598 904.541, 111.499 904.581, 111.397 904.616, 111.294 904.645, 111.19 904.669, 111.084 904.687, 110.977 904.699, 110.87 904.706, 110.763 904.707, 110.656 904.702, 110.549 904.691, 110.443 904.675, 110.338 904.653, 110.234 904.625, 101.533 902.06))',0),
          0,
          0
       ).AsTextZM() as gCollection;
GO

select [$(owner)].[STForceCollection](
             geometry::STGeomFromText('POLYGON ((98.4 883.585, 115.729 903.305, 102.284 923.025, 99.148 899.272, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 110.8 902.707, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 90.78 887.02, 96.606 926.91, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.71 926.313, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 95.412 928.554, 101.238 929.002, 101.238 929.002, 101.238 929.002, 101.238 929.002, 101.238 929.002, 101.238 929.002, 101.238 929.002, 101.238 929.002, 101.238 929.002, 119.017 922.28, 119.724 924.15, 101.945 930.873, 101.842 930.909, 101.737 930.939, 101.63 930.963, 101.522 930.982, 101.413 930.994, 101.304 931.001, 101.194 931.002, 101.085 930.996, 95.259 930.548, 95.158 930.538, 95.057 930.522, 94.958 930.502, 94.859 930.476, 94.762 930.446, 94.667 930.41, 94.574 930.37, 94.483 930.325, 94.394 930.275, 94.308 930.221, 94.224 930.163, 94.144 930.101, 94.067 930.034, 93.994 929.964, 93.924 929.89, 93.858 929.813, 93.796 929.732, 93.738 929.649, 93.685 929.562, 93.636 929.473, 93.591 929.382, 93.552 929.288, 93.517 929.193, 93.487 929.096, 93.462 928.997, 93.442 928.898, 93.427 928.797, 93.417 928.696, 93.412 928.595, 93.413 928.493, 93.419 928.391, 93.429 928.29, 93.727 926.049, 93.755 925.89, 93.796 925.733, 93.849 925.579, 93.915 925.431, 93.992 925.288, 94.081 925.152, 94.181 925.024, 94.29 924.905, 94.292 924.902, 91.428 905.295, 91.411 905.297, 91.269 905.305, 91.127 905.302, 79.324 904.704, 79.222 904.697, 79.121 904.684, 79.021 904.666, 78.922 904.643, 78.824 904.615, 78.728 904.582, 78.634 904.544, 78.541 904.501, 78.451 904.454, 78.364 904.402, 78.279 904.346, 78.197 904.286, 78.118 904.221, 78.043 904.153, 77.971 904.081, 77.903 904.005, 77.839 903.926, 77.779 903.844, 77.724 903.758, 77.672 903.671, 77.626 903.58, 77.584 903.488, 77.546 903.393, 77.514 903.297, 77.486 903.199, 77.464 903.099, 77.446 902.999, 77.434 902.898, 77.427 902.797, 77.425 902.695, 77.428 902.593, 77.437 902.492, 77.683 900.217, 74.343 901.496, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 64.95 915.476, 63.291 914.361, 73.036 899.855, 80.022 897.18, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 79.425 902.707, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 91.228 903.305, 79.736 888.304, 98.4 883.585), (97.705 885.823, 93.766 886.819, 109.224 898.931, 97.705 885.823), (88.909 888.047, 83.17 889.498, 90.523 899.096, 88.909 888.047), (101.533 902.06, 103.581 917.573, 113.204 903.46, 112.781 902.979, 112.78 902.988, 112.762 903.094, 112.739 903.199, 112.71 903.302, 112.675 903.403, 112.635 903.503, 112.59 903.6, 112.539 903.695, 112.484 903.787, 112.423 903.875, 112.358 903.961, 112.289 904.042, 112.215 904.12, 112.137 904.194, 112.056 904.264, 111.97 904.329, 111.882 904.389, 111.79 904.445, 111.695 904.495, 111.598 904.541, 111.499 904.581, 111.397 904.616, 111.294 904.645, 111.19 904.669, 111.084 904.687, 110.977 904.699, 110.87 904.706, 110.763 904.707, 110.656 904.702, 110.549 904.691, 110.443 904.675, 110.338 904.653, 110.234 904.625, 101.533 902.06))',0),
          1,
          0
       ).AsTextZM() as gCollection;
GO

PRINT '2. Testing Conversion of Polygon with holes to MULTILINESTRING';
GO

select [$(owner)].[STForceCollection](
          geometry::STGeomFromText('POLYGON ((97.705 885.823, 93.766 886.819, 109.224 898.931, 97.705 885.823))',0),               
          1,
          1
       ).STAsText()  as gCollection;
GO


